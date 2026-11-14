package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestLoadAndRender(t *testing.T) {
	dir := t.TempDir()
	write := func(name, body string) {
		if err := os.WriteFile(filepath.Join(dir, name), []byte(body), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	// ASCII-Datei: Umlaute werden ergänzt, "Feuer" bleibt
	write("a.json", `{"instance":"A","bosses":[{"name":"Boss","npcID":2,"mechanics":[
		{"spellID":5,"type":"interrupt","en":"Heals","de":"Feuer; Verbuendete toeten"},
		{"spellID":6,"type":"avoid","en":"","de":""}]}],"trash":[]}`)
	// Datei mit echten Umlauten bleibt unverändert; Einheit ohne Text fällt weg
	write("b.json", `{"instance":"B","bosses":[{"name":"X","npcID":3,"mechanics":[]}],
		"rares":[{"name":"R","npcID":1,"mechanics":[{"spellID":0,"type":"tank","en":"Say \"hi\"","de":"Grüße toeten"}]}]}`)
	entries, files, err := load(dir)
	if err != nil || files != 2 || len(entries) != 2 {
		t.Fatalf("load: %v files=%d entries=%d", err, files, len(entries))
	}
	out := render(entries)
	for _, want := range []string{
		`{ 0, "tank", "Grüße toeten", "Say \"hi\"" }`,
		`{ 5, "interrupt", "Feuer; Verbündete töten", "Heals" }`,
	} {
		if !strings.Contains(out, want) {
			t.Errorf("fehlt %s in\n%s", want, out)
		}
	}
	if strings.Index(out, "[1]") > strings.Index(out, "[2]") {
		t.Error("nicht nach NPC-ID sortiert")
	}
}
