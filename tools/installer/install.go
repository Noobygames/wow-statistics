package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

const manifestName = ".install-manifest.json"

// Manifest liegt im Addon-Ordner und merkt sich, welche Dateien der Installer besitzt.
type Manifest struct {
	Addon       string    `json:"addon"`
	Version     string    `json:"version"`
	Files       []string  `json:"files"`
	Migrations  []string  `json:"migrations"`
	InstalledAt time.Time `json:"installedAt"`
}

type FileStatus int

const (
	StatusNew FileStatus = iota
	StatusUpdated
	StatusUnchanged
)

type FileAction struct {
	Path   string
	Status FileStatus
}

type Plan struct {
	Flavor     Flavor
	Target     string
	Existing   *Manifest // nil, wenn kein Manifest vorhanden
	Legacy     bool      // Ordner existiert, aber ohne Manifest (alte manuelle Installation)
	Files      []FileAction
	Remove     []string
	Migrations []migration
}

func (p *Plan) Installed() bool {
	return p.Existing != nil || p.Legacy
}

// NeedsRestart: Änderungen an der .toc (oder Neuinstallation) erkennt WoW erst nach Neustart.
func (p *Plan) NeedsRestart() bool {
	return len(p.Files) > 0 && p.Files[0].Status != StatusUnchanged
}

func (p *Plan) HasChanges() bool {
	if len(p.Remove) > 0 || len(p.Migrations) > 0 {
		return true
	}
	for _, f := range p.Files {
		if f.Status != StatusUnchanged {
			return true
		}
	}
	return false
}

func BuildPlan(a *Addon, f Flavor) (*Plan, error) {
	target := filepath.Join(f.AddOnsDir(), a.Name)
	if err := ensureNotConfigPath(target); err != nil {
		return nil, err
	}
	p := &Plan{Flavor: f, Target: target}

	info, err := os.Stat(target)
	switch {
	case errors.Is(err, fs.ErrNotExist):
	case err != nil:
		return nil, err
	case !info.IsDir():
		return nil, fmt.Errorf("%s ist kein Verzeichnis", target)
	default:
		m, err := readManifest(target)
		if err != nil {
			return nil, err
		}
		p.Existing = m
		p.Legacy = m == nil
	}

	for _, rel := range a.Files {
		status, err := compareFile(filepath.Join(a.Dir, filepath.FromSlash(rel)), filepath.Join(target, filepath.FromSlash(rel)))
		if err != nil {
			return nil, err
		}
		p.Files = append(p.Files, FileAction{Path: rel, Status: status})
	}

	if p.Existing != nil {
		p.Remove = staleFiles(p.Existing.Files, a.Files)
	}

	if err := planMigrations(p, a); err != nil {
		return nil, err
	}
	return p, nil
}

func (p *Plan) Apply(a *Addon) error {
	for _, f := range p.Files {
		if f.Status == StatusUnchanged {
			continue
		}
		src := filepath.Join(a.Dir, filepath.FromSlash(f.Path))
		dst, err := safeJoin(p.Target, f.Path)
		if err != nil {
			return err
		}
		if err := copyFile(src, dst); err != nil {
			return fmt.Errorf("%s kopieren: %w", f.Path, err)
		}
	}

	for _, rel := range p.Remove {
		dst, err := safeJoin(p.Target, rel)
		if err != nil {
			return err
		}
		if err := os.Remove(dst); err != nil && !errors.Is(err, fs.ErrNotExist) {
			return fmt.Errorf("%s entfernen: %w", rel, err)
		}
	}

	applied := []string{}
	if p.Existing != nil {
		applied = append(applied, p.Existing.Migrations...)
	}
	for _, m := range p.Migrations {
		applied = append(applied, m.id)
	}

	return writeManifest(p.Target, &Manifest{
		Addon:       a.Name,
		Version:     a.Version,
		Files:       a.Files,
		Migrations:  applied,
		InstalledAt: time.Now(),
	})
}

// ensureNotConfigPath: SavedVariables liegen unter WTF und werden niemals angefasst.
func ensureNotConfigPath(p string) error {
	for _, part := range strings.Split(filepath.ToSlash(filepath.Clean(p)), "/") {
		if strings.EqualFold(part, "WTF") {
			return fmt.Errorf("Pfad im Config-Verzeichnis (WTF) verweigert: %s", p)
		}
	}
	return nil
}

func safeJoin(base, rel string) (string, error) {
	joined := filepath.Join(base, filepath.FromSlash(rel))
	r, err := filepath.Rel(base, joined)
	if err != nil || r == ".." || strings.HasPrefix(r, ".."+string(filepath.Separator)) {
		return "", fmt.Errorf("Pfad außerhalb des Addon-Ordners: %s", rel)
	}
	if err := ensureNotConfigPath(joined); err != nil {
		return "", err
	}
	return joined, nil
}

func compareFile(src, dst string) (FileStatus, error) {
	want, err := os.ReadFile(src)
	if err != nil {
		return 0, err
	}
	have, err := os.ReadFile(dst)
	switch {
	case errors.Is(err, fs.ErrNotExist):
		return StatusNew, nil
	case err != nil:
		return 0, err
	case bytes.Equal(want, have):
		return StatusUnchanged, nil
	default:
		return StatusUpdated, nil
	}
}

// copyFile schreibt erst in eine temporäre Datei und benennt dann um,
// damit WoW nie eine halb geschriebene Datei liest.
func copyFile(src, dst string) error {
	data, err := os.ReadFile(src)
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
		return err
	}
	tmp, err := os.CreateTemp(filepath.Dir(dst), ".install-*")
	if err != nil {
		return err
	}
	defer os.Remove(tmp.Name())
	if _, err := tmp.Write(data); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	return os.Rename(tmp.Name(), dst)
}

func staleFiles(old, current []string) []string {
	keep := make(map[string]bool, len(current))
	for _, f := range current {
		keep[strings.ToLower(f)] = true
	}
	var stale []string
	for _, f := range old {
		if !keep[strings.ToLower(f)] {
			stale = append(stale, f)
		}
	}
	sort.Strings(stale)
	return stale
}

func readManifest(dir string) (*Manifest, error) {
	data, err := os.ReadFile(filepath.Join(dir, manifestName))
	if errors.Is(err, fs.ErrNotExist) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	var m Manifest
	if err := json.Unmarshal(data, &m); err != nil {
		return nil, fmt.Errorf("Manifest in %s defekt: %w", dir, err)
	}
	return &m, nil
}

func writeManifest(dir string, m *Manifest) error {
	data, err := json.MarshalIndent(m, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(filepath.Join(dir, manifestName), append(data, '\n'), 0o644)
}
