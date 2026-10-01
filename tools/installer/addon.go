package main

import (
	"bufio"
	"bytes"
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path"
	"path/filepath"
	"strings"
)

// Addon beschreibt die zu installierende Quelle. Die Dateiliste kommt aus der .toc,
// damit es nur eine Stelle gibt, an der Addon-Dateien gepflegt werden.
type Addon struct {
	Name    string   // Name der .toc ohne Endung, gleichzeitig Ordnername in AddOns
	Dir     string   // Quellverzeichnis
	Files   []string // relative Pfade mit "/": die .toc, ihre Dateien und alles aus assetDirs
	Version string
}

// VersionToken in der .toc wird beim Installieren und Packen durch die Version ersetzt.
// Der CurseForge-Packager ersetzt denselben Platzhalter.
const VersionToken = "@project-version@"

// ReadFile liefert den Inhalt einer Addon-Datei so, wie er installiert bzw. verpackt wird
func (a *Addon) ReadFile(rel string) ([]byte, error) {
	data, err := os.ReadFile(filepath.Join(a.Dir, filepath.FromSlash(rel)))
	if err != nil {
		return nil, err
	}
	if strings.EqualFold(path.Ext(rel), ".toc") {
		data = bytes.ReplaceAll(data, []byte(VersionToken), []byte(a.Version))
	}
	return data, nil
}

func LoadAddon(dir, version string) (*Addon, error) {
	tocs, err := filepath.Glob(filepath.Join(dir, "*.toc"))
	if err != nil {
		return nil, err
	}
	if len(tocs) != 1 {
		return nil, fmt.Errorf("genau eine .toc in %s erwartet, gefunden: %d", dir, len(tocs))
	}
	tocName := filepath.Base(tocs[0])

	files, err := parseTocFiles(tocs[0])
	if err != nil {
		return nil, err
	}
	files = append([]string{tocName}, files...)

	assets, err := assetFiles(dir)
	if err != nil {
		return nil, err
	}
	files = append(files, assets...)

	for _, f := range files {
		if _, err := os.Stat(filepath.Join(dir, filepath.FromSlash(f))); err != nil {
			return nil, fmt.Errorf("in .toc gelistete Datei fehlt: %s", f)
		}
	}

	return &Addon{
		Name:    strings.TrimSuffix(tocName, ".toc"),
		Dir:     dir,
		Files:   files,
		Version: version,
	}, nil
}

// Ordner mit Grafiken o.Ä., die nicht in der .toc stehen, aber per Pfad geladen werden
var assetDirs = []string{"Media"}

func assetFiles(dir string) ([]string, error) {
	var files []string
	for _, assetDir := range assetDirs {
		root := filepath.Join(dir, assetDir)
		err := filepath.WalkDir(root, func(p string, d fs.DirEntry, err error) error {
			if errors.Is(err, fs.ErrNotExist) && p == root {
				return filepath.SkipDir
			}
			if err != nil || d.IsDir() {
				return err
			}
			rel, err := filepath.Rel(dir, p)
			if err != nil {
				return err
			}
			files = append(files, filepath.ToSlash(rel))
			return nil
		})
		if err != nil {
			return nil, err
		}
	}
	return files, nil
}

func parseTocFiles(tocPath string) ([]string, error) {
	f, err := os.Open(tocPath)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	var files []string
	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		rel := path.Clean(strings.ReplaceAll(line, `\`, "/"))
		if path.IsAbs(rel) || rel == ".." || strings.HasPrefix(rel, "../") {
			return nil, fmt.Errorf("ungültiger Pfad in .toc: %s", line)
		}
		files = append(files, rel)
	}
	return files, scanner.Err()
}
