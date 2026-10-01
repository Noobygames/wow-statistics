package main

import (
	"archive/zip"
	"errors"
	"io/fs"
	"os"
	"path"
	"path/filepath"
	"time"
)

// Zusätzlich zu den Dateien aus der .toc ins Paket, falls vorhanden
var packageExtras = []string{"LICENSE"}

// WritePackage erstellt eine ZIP, wie WoW sie in Interface/AddOns erwartet:
// ein Ordner <AddonName>/ mit allen Dateien aus der .toc (Version eingesetzt) und packageExtras.
func WritePackage(a *Addon, zipPath string) error {
	files := append([]string{}, a.Files...)
	for _, extra := range packageExtras {
		if _, err := os.Stat(filepath.Join(a.Dir, extra)); err == nil {
			files = append(files, extra)
		} else if !errors.Is(err, fs.ErrNotExist) {
			return err
		}
	}

	if err := os.MkdirAll(filepath.Dir(zipPath), 0o755); err != nil {
		return err
	}
	out, err := os.Create(zipPath)
	if err != nil {
		return err
	}
	defer out.Close()

	archive := zip.NewWriter(out)
	builtAt := time.Now()
	for _, rel := range files {
		data, err := a.ReadFile(rel)
		if err != nil {
			return err
		}
		entry, err := archive.CreateHeader(&zip.FileHeader{
			Name:     path.Join(a.Name, rel),
			Method:   zip.Deflate,
			Modified: builtAt,
		})
		if err != nil {
			return err
		}
		if _, err := entry.Write(data); err != nil {
			return err
		}
	}
	if err := archive.Close(); err != nil {
		return err
	}
	return out.Close()
}
