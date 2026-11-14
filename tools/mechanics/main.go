// Mechanics erzeugt aus der Guide-Recherche (docs/research/mechanics/*.json, je Instanz eine Datei) die Tooltip-Daten
// Assist/InstanceData/mechanics.lua: Boss- und Trash-Fähigkeiten je NPC-ID. Liest jede vorhandene Datei, neue Instanzen
// kommen also einfach durch eine weitere JSON-Datei dazu. Aufruf über "make mechanics".
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

// Gruppen einer Instanzdatei, deren Einheiten Tooltipzeilen bekommen
var groups = []string{"bosses", "rares"}

// Erlaubte Typen (Farbe und Symbol im Addon: Assist/Mechanics.lua)
var types = map[string]bool{"avoid": true, "interrupt": true, "dispel": true, "tank": true, "survive": true,
	"adds": true, "positioning": true}

type mechanic struct {
	SpellID int    `json:"spellID"`
	Spell   string `json:"spell"`
	Type    string `json:"type"`
	En      string `json:"en"`
	De      string `json:"de"`
}

type unit struct {
	Name      string     `json:"name"`
	NpcID     int        `json:"npcID"`
	Mechanics []mechanic `json:"mechanics"`
}

type entry struct {
	unit
	instance string
}

func main() {
	dir := flag.String("dir", "docs/research/mechanics", "Ordner der Recherche-Dateien (*.json)")
	luaOut := flag.String("lua", "Assist/InstanceData/mechanics.lua", "Ziel-Datei (Lua)")
	flag.Parse()
	entries, files, err := load(*dir)
	if err == nil {
		err = os.WriteFile(*luaOut, []byte(render(entries)), 0o644)
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, "Fehler:", err)
		os.Exit(1)
	}
	lines := 0
	for _, e := range entries {
		lines += len(e.Mechanics)
	}
	fmt.Printf("%s: %d Instanzdateien, %d NPCs, %d Mechaniken\n", *luaOut, files, len(entries), lines)
}

// load liest alle Instanzdateien; Ergebnis nach NPC-ID sortiert, nur Einheiten mit mindestens einer Mechanik mit Text
func load(dir string) ([]entry, int, error) {
	paths, err := filepath.Glob(filepath.Join(dir, "*.json"))
	if err != nil || len(paths) == 0 {
		return nil, 0, fmt.Errorf("keine Recherche-Dateien in %s (%v)", dir, err)
	}
	byID := map[int]entry{}
	for _, path := range paths {
		raw, err := os.ReadFile(path)
		if err != nil {
			return nil, 0, err
		}
		var file map[string]json.RawMessage
		if err := json.Unmarshal(raw, &file); err != nil {
			return nil, 0, fmt.Errorf("%s: %w", path, err)
		}
		var instance string
		_ = json.Unmarshal(file["instance"], &instance)
		var units []unit
		for _, group := range groups {
			var list []unit
			if file[group] != nil {
				if err := json.Unmarshal(file[group], &list); err != nil {
					return nil, 0, fmt.Errorf("%s (%s): %w", path, group, err)
				}
			}
			units = append(units, list...)
		}
		fix := asciiUmlauts(units)
		for _, u := range units {
			kept := u.Mechanics[:0:0]
			for _, m := range u.Mechanics {
				if m.En == "" || m.De == "" {
					continue
				}
				if !types[m.Type] {
					return nil, 0, fmt.Errorf("%s: %s hat unbekannten Typ %q", path, u.Name, m.Type)
				}
				if fix {
					m.De = umlautFixer.Replace(m.De)
				}
				kept = append(kept, m)
			}
			if u.NpcID <= 0 || len(kept) == 0 {
				continue
			}
			if old, dup := byID[u.NpcID]; dup {
				return nil, 0, fmt.Errorf("NPC %d doppelt (%s, %s)", u.NpcID, old.instance, instance)
			}
			u.Mechanics = kept
			byID[u.NpcID] = entry{u, instance}
		}
	}
	entries := make([]entry, 0, len(byID))
	for _, e := range byID {
		entries = append(entries, e)
	}
	sort.Slice(entries, func(i, j int) bool { return entries[i].NpcID < entries[j].NpcID })
	return entries, len(paths), nil
}

// asciiUmlauts: Dateien, deren deutsche Texte nirgends ä/ö/ü/ß enthalten, schreiben Umlaute als ae/oe/ue/ss
func asciiUmlauts(units []unit) bool {
	for _, u := range units {
		for _, m := range u.Mechanics {
			if strings.ContainsAny(m.De, "äöüÄÖÜß") {
				return false
			}
		}
	}
	return true
}

// Ausdrückliche Wortstämme statt einer Regel: "Feuer", "zuerst" oder "lassen" dürfen nicht umgeschrieben werden
var umlautFixer = strings.NewReplacer(
	"Beschwoer", "Beschwör", "Betaeub", "Betäub", "betaeub", "betäub", "Flaech", "Fläch", "schlaege", "schläge",
	"Naehe", "Nähe", "kaempf", "kämpf", "Schlaef", "Schläf", "schlaef", "schläf", "Verbuend", "Verbünd",
	"Weisskraehe", "Weißkrähe", "ausser", "außer", "erhoeh", "erhöh", "moeglich", "möglich", "schwaech", "schwäch",
	"toet", "töt", "Uebern", "Übern", "uebern", "übern", "wuetend", "wütend", "zurueck", "zurück", "Feuerstoss", "Feuerstoß",
)

func luaString(s string) string {
	return `"` + strings.NewReplacer(`\`, `\\`, `"`, `\"`, "\n", `\n`).Replace(s) + `"`
}

func render(entries []entry) string {
	var b strings.Builder
	b.WriteString(`-- GENERIERT von tools/mechanics ("make mechanics"), nicht von Hand bearbeiten.
-- Quelle: Guide-Recherche docs/research/mechanics/*.json (je Instanz eine Datei), siehe sources.md.
-- ns.Mechanics = { [npcID] = { { spellID, Typ, Text deDE, Text enUS }, ... } }
--   spellID 0 = keine passende Zauber-ID (Zeile ohne Zaubersymbol), Typ: avoid, interrupt, dispel, tank, survive, adds,
--   positioning. Deutsche Clients lesen den deutschen Text, alle anderen (auch frFR/esES) den englischen; die Texte
--   laufen bewusst nicht über Locales (Spieldaten, kein UI-Text). Leser: Assist/Mechanics.lua.
local _, ns = ...
-- Nur Classic Era und Forever: klassische Instanzen, Retail hat andere Fähigkeiten an denselben NPCs.
local flavor = ns.Client.Flavor()
if flavor ~= "forever" and flavor ~= "classic_era" then return end

ns.Mechanics = {
`)
	for _, e := range entries {
		fmt.Fprintf(&b, "  [%d] = { -- %s (%s)\n", e.NpcID, e.Name, e.instance)
		for _, m := range e.Mechanics {
			fmt.Fprintf(&b, "    { %d, %q, %s, %s },\n", m.SpellID, m.Type, luaString(m.De), luaString(m.En))
		}
		b.WriteString("  },\n")
	}
	b.WriteString("}\n")
	return b.String()
}
