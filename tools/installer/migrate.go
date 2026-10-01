package main

import (
	"io/fs"
	"path/filepath"
	"sort"
	"strings"
)

// migration passt eine bestehende Installation an ein neues Layout an.
// Sie ergänzt nur den Plan (z.B. Remove), ausgeführt wird alles in Plan.Apply.
// Angewendete IDs landen im Manifest und laufen nie zweimal.
// SavedVariables-Migrationen gehören in den Lua-Code (applyDefaults beim Login), nicht hierher.
type migration struct {
	id          string
	description string
	applies     func(p *Plan) bool
	plan        func(p *Plan, a *Addon) error
}

var migrations = []migration{
	{
		id:          "001-adopt-legacy-install",
		description: "Manuelle Installation ohne Manifest übernehmen, veraltete Addon-Dateien entfernen",
		applies:     func(p *Plan) bool { return p.Legacy },
		plan:        planLegacyCleanup,
	},
}

func planMigrations(p *Plan, a *Addon) error {
	done := map[string]bool{}
	if p.Existing != nil {
		for _, id := range p.Existing.Migrations {
			done[id] = true
		}
	}
	for _, m := range migrations {
		if done[m.id] || !m.applies(p) {
			continue
		}
		if err := m.plan(p, a); err != nil {
			return err
		}
		p.Migrations = append(p.Migrations, m)
	}
	return nil
}

// Ohne Manifest wissen wir nicht, welche Dateien von uns stammen. Daher nur
// Addon-Code (.lua/.toc/.xml) entfernen, der in der aktuellen .toc nicht mehr vorkommt.
func planLegacyCleanup(p *Plan, a *Addon) error {
	var present []string
	err := filepath.WalkDir(p.Target, func(path string, d fs.DirEntry, err error) error {
		if err != nil || d.IsDir() {
			return err
		}
		switch strings.ToLower(filepath.Ext(path)) {
		case ".lua", ".toc", ".xml":
			rel, err := filepath.Rel(p.Target, path)
			if err != nil {
				return err
			}
			present = append(present, filepath.ToSlash(rel))
		}
		return nil
	})
	if err != nil {
		return err
	}
	p.Remove = mergeUnique(p.Remove, staleFiles(present, a.Files))
	return nil
}

func mergeUnique(a, b []string) []string {
	seen := map[string]bool{}
	var out []string
	for _, s := range append(append([]string{}, a...), b...) {
		if !seen[s] {
			seen[s] = true
			out = append(out, s)
		}
	}
	sort.Strings(out)
	return out
}
