package main

import (
	"os"
	"path/filepath"
	"runtime"
	"sort"
	"strings"
)

// Flavor ist eine Spielversion innerhalb der WoW-Installation, z.B. _retail_ oder _classic_era_.
type Flavor struct {
	Name string
	Dir  string
}

func (f Flavor) AddOnsDir() string {
	return filepath.Join(f.Dir, "Interface", "AddOns")
}

func isFlavorDirName(name string) bool {
	return len(name) > 2 && strings.HasPrefix(name, "_") && strings.HasSuffix(name, "_")
}

// NormalizeRoot erlaubt auch die Angabe eines Flavor-Ordners (z.B. ...\_retail_).
func NormalizeRoot(dir string) string {
	dir = filepath.Clean(dir)
	if isFlavorDirName(filepath.Base(dir)) {
		return filepath.Dir(dir)
	}
	return dir
}

func FindFlavors(root string) ([]Flavor, error) {
	entries, err := os.ReadDir(root)
	if err != nil {
		return nil, err
	}
	var flavors []Flavor
	for _, e := range entries {
		if !e.IsDir() || !isFlavorDirName(e.Name()) {
			continue
		}
		flavors = append(flavors, Flavor{Name: e.Name(), Dir: filepath.Join(root, e.Name())})
	}
	sort.Slice(flavors, func(i, j int) bool { return flavors[i].Name < flavors[j].Name })
	return flavors, nil
}

// DetectRoots sucht WoW an den üblichen Installationsorten.
func DetectRoots() []string {
	var candidates []string
	switch runtime.GOOS {
	case "windows":
		subdirs := []string{
			`World of Warcraft`,
			`Games\World of Warcraft`,
			`Program Files (x86)\World of Warcraft`,
			`Program Files\World of Warcraft`,
			`Blizzard\World of Warcraft`,
		}
		for drive := 'C'; drive <= 'Z'; drive++ {
			root := string(drive) + `:\`
			if _, err := os.Stat(root); err != nil {
				continue
			}
			for _, sub := range subdirs {
				candidates = append(candidates, filepath.Join(root, sub))
			}
		}
	case "darwin":
		candidates = append(candidates, "/Applications/World of Warcraft")
	}

	var roots []string
	for _, c := range candidates {
		if flavors, err := FindFlavors(c); err == nil && len(flavors) > 0 {
			roots = append(roots, c)
		}
	}
	return roots
}
