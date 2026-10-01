// Package addontest führt die Lua-Szenarien aus tests/ gegen das Addon aus.
// Jede *_test.lua bekommt einen frischen Lua-5.1-Zustand (wie der WoW-Client),
// in den tests/wow_stub.lua die WoW-API nachbaut und das Addon lädt.
package addontest

import (
	"path/filepath"
	"strings"
	"testing"

	lua "github.com/yuin/gopher-lua"
)

const repoRoot = "../.."

func TestScenarios(t *testing.T) {
	root, err := filepath.Abs(repoRoot)
	if err != nil {
		t.Fatal(err)
	}
	scenarios, err := filepath.Glob(filepath.Join(root, "tests", "*_test.lua"))
	if err != nil {
		t.Fatal(err)
	}
	if len(scenarios) == 0 {
		t.Fatal("keine Szenarien in tests/ gefunden")
	}

	for _, scenario := range scenarios {
		name := strings.TrimSuffix(filepath.Base(scenario), "_test.lua")
		t.Run(name, func(t *testing.T) {
			runScenario(t, root, scenario)
		})
	}
}

func runScenario(t *testing.T, root, scenario string) {
	L := lua.NewState()
	defer L.Close()

	L.SetGlobal("ADDON_DIR", lua.LString(filepath.ToSlash(root)))
	if err := L.DoFile(filepath.Join(root, "tests", "wow_stub.lua")); err != nil {
		t.Fatalf("Addon laden: %v", err)
	}
	if err := L.DoFile(scenario); err != nil {
		t.Fatalf("Szenario abgebrochen: %v", err)
	}

	failures, ok := L.GetGlobal("TEST_FAILURES").(*lua.LTable)
	if !ok {
		t.Fatal("TEST_FAILURES fehlt")
	}
	failures.ForEach(func(_, failure lua.LValue) {
		t.Error(failure.String())
	})
}
