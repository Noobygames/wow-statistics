package main

// Schreibt das Ergebnis als JSON (dist/questie/*.json, vollständig mit Namen) und als kompakte Lua-Datei für das Addon.

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

func writeJSON(dir string, res *result) error {
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}
	quests := map[string]any{"instances": res.Instances, "quests": res.Quests, "givers": res.Givers}
	npcs := map[int][]*npcOut{}
	for mapID, inst := range res.Instances {
		for _, id := range inst.Npcs {
			npcs[mapID] = append(npcs[mapID], res.Npcs[id])
		}
	}
	for name, v := range map[string]any{"quests.json": quests, "npcs.json": npcs, "loot.json": res.Loot} {
		data, err := json.MarshalIndent(v, "", "  ")
		if err != nil {
			return err
		}
		if err := os.WriteFile(filepath.Join(dir, name), append(data, '\n'), 0o644); err != nil {
			return err
		}
	}
	return nil
}

const luaHeader = `-- GENERIERT von tools/questie ("make questie"), nicht von Hand bearbeiten.
-- Quelle: QuestieDB %s (WoW-Forever-Build, TOC-Metadaten "Baked", WTFPL; Daten stammen aus Questie), siehe sources.md.
-- Instanzen: alle klassischen Dungeons und Schlachtzüge und die Forever-eigenen, Schlüssel = Instanz-Karten-ID (wie
-- ns.InstanceData); dazu von Hand gepflegte Zuordnungen und Quests aus docs/research/dungeon_quests.json.
-- ns.DungeonDB = {
--   quests     = { [Karten-ID] = { questID, ... } }   Quests mit Ziel, Abgabe oder Zonen-Sortierung in der Instanz,
--   questInfo  = { [questID] = { Questlevel, Mindestlevel, Fraktion ("A"/"H", nil = beide), Klassenmaske (0 = alle),
--                  Geber-Art ("n" NPC, "o" Objekt, "i" Item, nil = unbekannt), Geber-ID, uiMapID, x, y (0-1, nil wenn
--                  unbekannt oder in einer Instanz), pre = { alle diese Vorquests }, preAny = { eine davon },
--                  excl = { schließen sie aus }, giverH = { Geber-Art, Geber-ID, uiMapID, x, y } (Horde-Geber einer
--                  Quest für beide Fraktionen, wenn er laut Fraktions-Korrektur ein anderer ist), name = Questname
--                  (enUS, Rückfall für ungecachte Titel) } }   Item-Geber mit dem Ort ihrer Drop-Quelle
--                  für alle Instanz- und Kettenquests,
--   questChains = { [questID] = { Karten-ID, Ziel-questID, Stufe, Gesamt } }   Vorquest-Kette bis zum Kettenanfang
--                  (Stufe 1 = Anfang, Gesamt = Stufe der Instanz-Quest; Vorquests, Breadcrumbs, nextQuestInChain rückwärts,
--                  exclusiveTo als Alternative auf derselben Stufe; führt eine Quest zu mehreren, gilt die nächste),
--   givers     = { npc = { [npcID] = { questID, ... } }, object = { ... }, item = { ... } },
--   objectNames = { [objectID] = Name }   Objekt-Geber, nur englisch (QuestieDB führt keine Übersetzungen),
--   npcs       = { [Karten-ID] = { [npcID] = { MinLevel, MaxLevel, Rang } } }   Rang: 0 normal, 1 Elite, 2 Rar-Elite,
--                  3 Boss, 4 Rar; Bosse der Führer-Recherche und aus boss_npcs.lua immer 3 (QuestieDB führt manche
--                  Endbosse wie Edwin van Cleef nur als Rar-Elite),
--   loot       = { [npcID] = { { itemID, Qualität, Chance }, ... } }   nur rar (3), episch (4), legendär (5): Drops aus
--                  QuestieDB plus Boss-Beute der eigenen Führer-Recherche (docs/research/mechanics, öffentliche Fakten;
--                  enthält Forever-eigene Items, Era filtert unbekannte IDs zur Laufzeit); keine vollständigen
--                  Beutetabellen; jedes Item gegen ItemSparse geprüft, Qualität aus ItemSparse
--                  (wago.tools: %s;
--                  Forever-Server-Items ohne ItemSparse-Eintrag mit der Führer-Qualität);
--                  Chance in Prozent oder nil (QuestieDB kennt sie nur für Quest-Items, Führer-Drops immer nil),
--                  viertes Feld 1 = für Forever unbestätigt (nur Classic-Daten, FDJ nennt das Item für diesen NPC nicht,
--                  keine Forever-eigene Item-ID); Bosse, Rare und Beute zusätzlich aus ForeverDungeonJournal (WTFPL),
-- }
local _, ns = ...
-- Nur Classic Era und Forever (klassische Instanzen, Forever-Questdaten); sonst keinen Speicher belegen.
local flavor = ns.Client.Flavor()
if flavor ~= "forever" and flavor ~= "classic_era" then return end

`

// writeLua: Einträge stehen ohne Einrückung am Zeilenanfang (spart rund 20 KB Addon-Datei).
func writeLua(path, version, itemBuild string, res *result) error {
	var b strings.Builder
	fmt.Fprintf(&b, luaHeader, version, itemBuild)
	b.WriteString("ns.DungeonDB = {\n")

	b.WriteString("  quests = {\n")
	for _, mapID := range sortedKeys(res.Instances) {
		fmt.Fprintf(&b, "[%d]={%s},\n", mapID, ints(res.Instances[mapID].Quests))
	}
	b.WriteString("  },\n  questInfo = {\n")
	for _, id := range sortedKeys(res.Quests) {
		q := res.Quests[id]
		fields := []string{strconv.Itoa(q.Level), strconv.Itoa(q.ReqLevel), luaStr(q.Faction), strconv.Itoa(q.Classes)}
		fields = trimNil(append(fields, giverFields(q.Giver)...))
		for _, list := range []struct {
			key string
			ids []int
		}{{"pre", q.Pre}, {"preAny", q.PreAny}, {"excl", q.Excl}} {
			if len(list.ids) > 0 {
				fields = append(fields, fmt.Sprintf("%s={%s}", list.key, ints(list.ids)))
			}
		}
		if q.GiverHorde != nil {
			fields = append(fields, fmt.Sprintf("giverH={%s}", strings.Join(trimNil(giverFields(q.GiverHorde)), ",")))
		}
		if q.Name != "" {
			fields = append(fields, "name="+luaStr(q.Name))
		}
		fmt.Fprintf(&b, "[%d]={%s},\n", id, strings.Join(fields, ","))
	}
	b.WriteString("  },\n  questChains = {\n")
	for _, id := range sortedKeys(res.Quests) {
		if c := res.Quests[id].Chain; c != nil {
			fmt.Fprintf(&b, "[%d]={%d,%d,%d,%d},\n", id, c.MapID, c.Target, c.Step, c.Total)
		}
	}
	b.WriteString("  },\n  givers = {\n")
	for _, kind := range []string{"npc", "object", "item"} {
		fmt.Fprintf(&b, "    %s = {\n", kind)
		for _, id := range sortedKeys(res.Givers[kind]) {
			fmt.Fprintf(&b, "[%d]={%s},\n", id, ints(res.Givers[kind][id]))
		}
		b.WriteString("    },\n")
	}
	b.WriteString("  },\n  objectNames = {\n")
	for _, id := range sortedKeys(res.ObjectNames) {
		fmt.Fprintf(&b, "[%d]=%s,\n", id, luaStr(res.ObjectNames[id]))
	}
	b.WriteString("  },\n  npcs = {\n")
	for _, mapID := range sortedKeys(res.Instances) {
		fmt.Fprintf(&b, "    [%d] = {\n", mapID)
		for _, id := range res.Instances[mapID].Npcs {
			n := res.Npcs[id]
			fmt.Fprintf(&b, "[%d]={%d,%d,%d},\n", id, n.MinLevel, n.MaxLevel, n.Rank)
		}
		b.WriteString("    },\n")
	}
	b.WriteString("  },\n  loot = {\n")
	for _, id := range sortedKeys(res.Loot) {
		var drops []string
		for _, d := range res.Loot[id] {
			fields := []string{strconv.Itoa(d.Item), strconv.Itoa(d.Quality), luaNum(d.Chance), "nil"}
			if d.Unverified {
				fields[3] = "1"
			}
			drops = append(drops, "{"+strings.Join(trimNil(fields), ",")+"}")
		}
		fmt.Fprintf(&b, "[%d]={%s},\n", id, strings.Join(drops, ","))
	}
	b.WriteString("  },\n}\n")
	return os.WriteFile(path, []byte(b.String()), 0o644)
}

// giverFields: Geber-Art (erster Buchstabe), ID, uiMapID, x, y; fünfmal nil ohne Geber.
func giverFields(g *giverOut) []string {
	if g == nil {
		return []string{"nil", "nil", "nil", "nil", "nil"}
	}
	kind := g.Kind
	if kind != "" {
		kind = kind[:1]
	}
	return []string{luaStr(kind), luaInt(g.ID), luaInt(g.UiMapID), luaNum(g.X), luaNum(g.Y)}
}

func ints(ids []int) string {
	s := make([]string, len(ids))
	for i, id := range ids {
		s[i] = strconv.Itoa(id)
	}
	return strings.Join(s, ",")
}

func luaStr(s string) string {
	if s == "" {
		return "nil"
	}
	return strconv.Quote(s)
}

func luaInt(n int) string {
	if n == 0 {
		return "nil"
	}
	return strconv.Itoa(n)
}

func luaNum(v float64) string {
	if v == unknown {
		return "nil"
	}
	return strconv.FormatFloat(v, 'f', -1, 64)
}

// trimNil entfernt nil am Ende (spart Platz, Lua liest fehlende Felder ohnehin als nil).
func trimNil(fields []string) []string {
	for len(fields) > 0 && fields[len(fields)-1] == "nil" {
		fields = fields[:len(fields)-1]
	}
	return fields
}
