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
-- Instanzen: alle klassischen Dungeons und Schlachtzüge, Schlüssel = Instanz-Karten-ID (wie ns.InstanceData).
-- ns.DungeonDB = {
--   quests     = { [Karten-ID] = { questID, ... } }   Quests mit Ziel, Abgabe oder Zonen-Sortierung in der Instanz,
--   questInfo  = { [questID] = { Questlevel, Mindestlevel, Fraktion ("A"/"H", nil = beide), Klassenmaske (0 = alle),
--                  Geber-Art ("n" NPC, "o" Objekt, "i" Item, nil = unbekannt), Geber-ID, uiMapID, x, y (0-1, nil wenn
--                  unbekannt oder in einer Instanz), pre = { alle diese Vorquests }, preAny = { eine davon },
--                  excl = { schließen sie aus } } }   für alle Instanz- und Kettenquests,
--   questChains = { [questID] = { Karten-ID, Ziel-questID, Stufe, Gesamt } }   Vorquest-Kette bis zum Kettenanfang
--                  (Stufe 1 = Anfang, Gesamt = Stufe der Instanz-Quest; Vorquests, Breadcrumbs, nextQuestInChain rückwärts,
--                  exclusiveTo als Alternative auf derselben Stufe; führt eine Quest zu mehreren, gilt die nächste),
--   givers     = { npc = { [npcID] = { questID, ... } }, object = { ... }, item = { ... } },
--   npcs       = { [Karten-ID] = { [npcID] = { MinLevel, MaxLevel, Rang } } }   Rang: 0 normal, 1 Elite, 2 Rar-Elite,
--                  3 Boss, 4 Rar,
--   loot       = { [npcID] = { { itemID, Qualität, Chance }, ... } }   nur rar (3), episch (4), legendär (5), soweit
--                  QuestieDB den Drop kennt (keine vollständigen Beutetabellen); Qualität aus ItemSparse, da QuestieDB
--                  keine führt (wago.tools: %s);
--                  Chance in Prozent oder nil (QuestieDB kennt sie nur für Quest-Items),
-- }
local _, ns = ...
-- Nur Classic Era und Forever (klassische Instanzen, Forever-Questdaten); sonst keinen Speicher belegen.
local flavor = ns.Client.Flavor()
if flavor ~= "forever" and flavor ~= "classic_era" then return end

`

func writeLua(path, version, itemBuild string, res *result) error {
	var b strings.Builder
	fmt.Fprintf(&b, luaHeader, version, itemBuild)
	b.WriteString("ns.DungeonDB = {\n")

	b.WriteString("  quests = {\n")
	for _, mapID := range sortedKeys(res.Instances) {
		fmt.Fprintf(&b, "    [%d]={%s},\n", mapID, ints(res.Instances[mapID].Quests))
	}
	b.WriteString("  },\n  questInfo = {\n")
	for _, id := range sortedKeys(res.Quests) {
		q := res.Quests[id]
		fields := []string{strconv.Itoa(q.Level), strconv.Itoa(q.ReqLevel), luaStr(q.Faction), strconv.Itoa(q.Classes)}
		if g := q.Giver; g != nil {
			fields = append(fields, luaStr(g.Kind[:1]), strconv.Itoa(g.ID), luaInt(g.UiMapID), luaNum(g.X), luaNum(g.Y))
		} else {
			fields = append(fields, "nil", "nil", "nil", "nil", "nil")
		}
		fields = trimNil(fields)
		for _, list := range []struct {
			key string
			ids []int
		}{{"pre", q.Pre}, {"preAny", q.PreAny}, {"excl", q.Excl}} {
			if len(list.ids) > 0 {
				fields = append(fields, fmt.Sprintf("%s={%s}", list.key, ints(list.ids)))
			}
		}
		fmt.Fprintf(&b, "    [%d]={%s},\n", id, strings.Join(fields, ","))
	}
	b.WriteString("  },\n  questChains = {\n")
	for _, id := range sortedKeys(res.Quests) {
		if c := res.Quests[id].Chain; c != nil {
			fmt.Fprintf(&b, "    [%d]={%d,%d,%d,%d},\n", id, c.MapID, c.Target, c.Step, c.Total)
		}
	}
	b.WriteString("  },\n  givers = {\n")
	for _, kind := range []string{"npc", "object", "item"} {
		fmt.Fprintf(&b, "    %s = {\n", kind)
		for _, id := range sortedKeys(res.Givers[kind]) {
			fmt.Fprintf(&b, "      [%d]={%s},\n", id, ints(res.Givers[kind][id]))
		}
		b.WriteString("    },\n")
	}
	b.WriteString("  },\n  npcs = {\n")
	for _, mapID := range sortedKeys(res.Instances) {
		fmt.Fprintf(&b, "    [%d] = {\n", mapID)
		for _, id := range res.Instances[mapID].Npcs {
			n := res.Npcs[id]
			fmt.Fprintf(&b, "      [%d]={%d,%d,%d},\n", id, n.MinLevel, n.MaxLevel, n.Rank)
		}
		b.WriteString("    },\n")
	}
	b.WriteString("  },\n  loot = {\n")
	for _, id := range sortedKeys(res.Loot) {
		var drops []string
		for _, d := range res.Loot[id] {
			if d.Chance == unknown {
				drops = append(drops, fmt.Sprintf("{%d,%d}", d.Item, d.Quality))
			} else {
				drops = append(drops, fmt.Sprintf("{%d,%d,%s}", d.Item, d.Quality, luaNum(d.Chance)))
			}
		}
		fmt.Fprintf(&b, "    [%d]={%s},\n", id, strings.Join(drops, ","))
	}
	b.WriteString("  },\n}\n")
	return os.WriteFile(path, []byte(b.String()), 0o644)
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
