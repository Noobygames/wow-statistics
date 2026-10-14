package main

import (
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

// setupSuite legt LevelTimer mit dem Schwester-Addon StreamGoal im Unterordner an.
func setupSuite(t *testing.T) string {
	t.Helper()
	src := filepath.Join(t.TempDir(), "src")
	writeFile(t, filepath.Join(src, "LevelTimer.toc"), "## Title: LevelTimer\nCore.lua\n")
	writeFile(t, filepath.Join(src, "Core.lua"), "core")
	writeFile(t, filepath.Join(src, "StreamGoal", "StreamGoal.toc"), "## Dependencies: LevelTimer\n\n# Grundlagen\nGoals.lua\n")
	writeFile(t, filepath.Join(src, "StreamGoal", "Goals.lua"), "goals")
	writeFile(t, filepath.Join(src, "tests", "x_test.lua"), "kein Addon")
	writeFile(t, filepath.Join(src, "Unrelated", "Other.toc"), "Ordnername passt nicht zur .toc")
	return src
}

func TestLoadAddonsFindsSisterAddonsInSubfolders(t *testing.T) {
	addons, err := LoadAddons(setupSuite(t), "v2")
	if err != nil {
		t.Fatal(err)
	}
	var names []string
	for _, a := range addons {
		names = append(names, a.Name)
	}
	if want := []string{"LevelTimer", "StreamGoal"}; !reflect.DeepEqual(names, want) {
		t.Fatalf("Addons = %v, want %v", names, want)
	}
	// Das Hauptaddon enthält die Dateien des Schwester-Addons nicht
	for _, f := range addons[0].Files {
		if strings.HasPrefix(f, "StreamGoal") {
			t.Errorf("LevelTimer enthält %s", f)
		}
	}
	if want := []string{"StreamGoal.toc", "Goals.lua"}; !reflect.DeepEqual(addons[1].Files, want) {
		t.Errorf("StreamGoal Files = %v, want %v", addons[1].Files, want)
	}
}

func TestSelectAddons(t *testing.T) {
	addons, err := LoadAddons(setupSuite(t), "v2")
	if err != nil {
		t.Fatal(err)
	}
	for names, want := range map[string]int{"": 2, "all": 2, "streamgoal": 1, "LevelTimer, StreamGoal": 2} {
		got, err := SelectAddons(addons, names)
		if err != nil || len(got) != want {
			t.Errorf("SelectAddons(%q) = %d Addons, err %v, want %d", names, len(got), err, want)
		}
	}
	if _, err := SelectAddons(addons, "Nope"); err == nil {
		t.Error("unbekanntes Addon wurde akzeptiert")
	}
}

func TestSisterAddonInstallsIntoOwnFolder(t *testing.T) {
	a, flavor := setup(t)
	suite, err := LoadAddons(setupSuite(t), "v2")
	if err != nil {
		t.Fatal(err)
	}
	goal := suite[1]
	p, err := BuildPlan(goal, flavor)
	if err != nil {
		t.Fatal(err)
	}
	if want := filepath.Join(flavor.AddOnsDir(), "StreamGoal"); p.Target != want {
		t.Errorf("Target = %s, want %s", p.Target, want)
	}
	if err := p.Apply(goal); err != nil {
		t.Fatal(err)
	}
	if got := readFile(t, filepath.Join(p.Target, "Goals.lua")); got != "goals" {
		t.Errorf("Goals.lua = %q", got)
	}
	// Das andere Addon bleibt unberührt
	if _, err := BuildPlan(a, flavor); err != nil {
		t.Fatal(err)
	}
}
