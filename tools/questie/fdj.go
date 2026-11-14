package main

// Bosse und Boss-Beute aus dem lokalen Addon ForeverDungeonJournal (WTFPL, Data/Dungeons.lua und Data/Bosses.lua):
// ergänzt die Forever-eigenen Instanzen, die QuestieDB nicht kennt, um ihre Bosse und Rare samt Level, und alle
// Instanzen um Beute ab rar, die QuestieDB und die Führer-Recherche nicht führen. Trash-Beute nennt nur Mob-Namen und
// wird über den englischen Namen den NPCs der Instanz zugeordnet. Zusätzlich liefert FDJ die Bestätigung, welche
// Drops auf Forever belegt sind (markUnverified).

import (
	"fmt"
	"path/filepath"
	"sort"
	"strconv"
	"strings"

	lua "github.com/yuin/gopher-lua"
)

const (
	rareEliteRank = 2
	rareRank      = 4
	// Item-IDs ab hier gibt es nur in WoW Forever; FDJ mischt laut SOURCES.txt beobachtete Forever-Beute mit
	// übernommenen Classic-Zuordnungen, daher gilt ein Classic-Item als bestätigt, wenn FDJ und unsere Quelle übereinstimmen.
	foreverItemMin = 250000
)

// fdjInstances: FDJ-Dungeonname -> Instanz-Karten-ID (Flügel teilen sich die Karte).
var fdjInstances = map[string]int{
	"Ragefire Chasm": 389, "Wailing Caverns": 43, "The Deadmines": 36, "Shadowfang Keep": 33,
	"Blackfathom Deeps": 48, "The Stockade": 34, "Gnomeregan": 90, "Razorfen Kraul": 47,
	"Scarlet Monastery: Graveyard": 189, "Scarlet Monastery: Library": 189, "Scarlet Monastery: Armory": 189,
	"Scarlet Monastery: Cathedral": 189, "Razorfen Downs": 129, "Uldaman": 70, "Zul'Farrak": 209,
	"Maraudon": 349, "Sunken Temple": 109, "Blackrock Depths": 230, "Lower Blackrock Spire": 229,
	"Upper Blackrock Spire": 229, "Dire Maul: East": 429, "Dire Maul: West": 429, "Dire Maul: North": 429,
	"Stratholme: Living": 329, "Stratholme: Undead": 329, "Scholomance": 289,
	"City of Dalaran": 2959, "The Drowned City": 2970, "Blackmaw Hold": 2974, "Alcaz Prison": 2994,
	"Excavation Site: Wetlands": 2998, "Ruins of Lordaeron": 2999, "Shaper's Terrace": 3001,
	"Krol'dok Stronghold": 3039, "Hall of Thanes": 3065,
}

type fdjItem struct {
	ID, Quality int
	Name        string
}

type fdjBoss struct {
	Name               string
	NpcID              int
	Rare, Trash        bool
	MinLevel, MaxLevel int
	Loot               []fdjItem
	Sources            [][]string // nur Trash: Mob-Namen je Item (gleicher Index wie Loot)
}

type fdjDungeon struct {
	Name   string
	MapID  int
	Bosses []fdjBoss
}

// fdjStats: Zählung für die Zusammenfassung.
type fdjStats struct {
	guideStats
	NpcsNew, Unverified int
}

// readFDJ führt Data/Dungeons.lua und Data/Bosses.lua mit einem leeren Addon-Namespace aus und liest FDJ.DB und
// FDJ.BOSS_LEVELS; Dungeons ohne Kartenzuordnung zählen als Fehler (neuer Dungeon in FDJ = Tabelle ergänzen).
func readFDJ(dir string) ([]fdjDungeon, error) {
	L := lua.NewState()
	defer L.Close()
	ns := L.NewTable()
	L.SetField(ns, "Constants", L.NewTable())
	for _, file := range []string{"Dungeons.lua", "Bosses.lua"} {
		fn, err := L.LoadFile(filepath.Join(dir, "Data", file))
		if err != nil {
			return nil, err
		}
		if err := L.CallByParam(lua.P{Fn: fn, Protect: true}, lua.LString("ForeverDungeonJournal"), ns); err != nil {
			return nil, fmt.Errorf("%s: %w", file, err)
		}
	}
	db, levels := fromLua(L.GetField(ns, "DB")), fromLua(L.GetField(ns, "BOSS_LEVELS"))
	m, _ := db.(map[any]any)
	if len(m) == 0 {
		return nil, fmt.Errorf("FDJ.DB in %s leer", dir)
	}
	var out []fdjDungeon
	for key, d := range m {
		name, _ := key.(string)
		mapID, ok := fdjInstances[name]
		if !ok {
			return nil, fmt.Errorf("FDJ-Dungeon %q ohne Instanz-Karten-ID (fdjInstances ergänzen)", name)
		}
		dg := fdjDungeon{Name: name, MapID: mapID}
		for _, b := range luaList(luaField(d, "bosses")) {
			dg.Bosses = append(dg.Bosses, readFDJBoss(b, luaField(luaField(levels, name), str(luaField(b, "name")))))
		}
		out = append(out, dg)
	}
	sort.Slice(out, func(a, b int) bool { return out[a].Name < out[b].Name })
	return out, nil
}

func readFDJBoss(b, level any) fdjBoss {
	boss := fdjBoss{Name: str(luaField(b, "name")), Rare: luaField(b, "rare") == true, Trash: luaField(b, "trash") == true}
	boss.NpcID, _ = toInt(luaField(b, "npcID"))
	// Level "28" oder "19-21"
	lo, hi, _ := strings.Cut(str(level), "-")
	boss.MinLevel, _ = strconv.Atoi(lo)
	boss.MaxLevel, _ = strconv.Atoi(hi)
	if boss.MaxLevel == 0 {
		boss.MaxLevel = boss.MinLevel
	}
	for _, it := range luaList(luaField(b, "loot")) {
		id, _ := toInt(luaIndex(it, 1))
		q, _ := toInt(luaIndex(it, 4))
		boss.Loot = append(boss.Loot, fdjItem{ID: id, Quality: q, Name: str(luaIndex(it, 2))})
		boss.Sources = append(boss.Sources, strings.Split(str(luaIndex(it, 5)), " / "))
	}
	return boss
}

func str(v any) string {
	s, _ := v.(string)
	return s
}

// mergeFDJ nimmt Bosse und Rare in ihre Instanz auf (QuestieDB-NPC, sonst neu mit FDJ-Name und -Level), stuft Bosse
// auf Rang 3, hängt geprüfte Beute an und liefert je NPC die von FDJ genannten Items (für markUnverified).
// Fehlt ein Item in der Forever-ItemSparse (foreverItems), gilt die FDJ-Qualität statt der aus Classic Era: FDJ
// beobachtet Forever, wo manche Classic-Items aufgewertet sind (z. B. Rhahk'Zors Hammer rar statt selten).
func mergeFDJ(res *result, db *questieDB, dungeons []fdjDungeon, qualities map[int]int, foreverItems map[int]bool) (fdjStats, map[int]map[int]bool) {
	var st fdjStats
	confirmed := map[int]map[int]bool{}
	drop := func(npcID int, it fdjItem) {
		if confirmed[npcID] == nil {
			confirmed[npcID] = map[int]bool{}
		}
		confirmed[npcID][it.ID] = true
		known := qualities
		if !foreverItems[it.ID] {
			known = nil // nur Rückfall: FDJ-Qualität
		}
		st.addDrop(res, npcID, it.ID, it.Name, it.Quality, known)
	}
	for _, dg := range dungeons {
		inst := res.Instances[dg.MapID]
		if inst == nil {
			inst = &instanceOut{MapID: dg.MapID}
			res.Instances[dg.MapID] = inst
		}
		if inst.Name == "" {
			inst.Name = dg.Name
		}
		for _, boss := range dg.Bosses {
			if boss.Trash {
				for i, it := range boss.Loot {
					for _, name := range boss.Sources[i] {
						if id := matchNpc(db, inst.Npcs, guideNpc{Name: name}); id != 0 {
							drop(id, it)
						}
					}
				}
				continue
			}
			id := st.addFDJNpc(res, db, inst, boss)
			if id == 0 {
				st.Unmatched = append(st.Unmatched, fmt.Sprintf("%s: %s", dg.Name, boss.Name))
				continue
			}
			for _, it := range boss.Loot {
				drop(id, it)
			}
			sort.Slice(res.Loot[id], func(a, b int) bool { return res.Loot[id][a].Item < res.Loot[id][b].Item })
		}
	}
	return st, confirmed
}

// addFDJNpc liefert die NPC-ID des FDJ-Bosses in der Instanz und legt ihn bei Bedarf an; 0 ohne npcID und ohne
// Namenstreffer unter den NPCs der Instanz.
func (st *fdjStats) addFDJNpc(res *result, db *questieDB, inst *instanceOut, boss fdjBoss) int {
	id := boss.NpcID
	if id == 0 {
		if id = matchNpc(db, inst.Npcs, guideNpc{Name: boss.Name}); id == 0 {
			return 0
		}
	}
	switch {
	case db.npcs[id] != nil:
		res.addNpc(db, inst, id)
	case res.Npcs[id] == nil:
		rank := bossRank
		if boss.Rare {
			rank = rareRank
		}
		res.Npcs[id] = &npcOut{ID: id, Name: boss.Name, MinLevel: boss.MinLevel, MaxLevel: boss.MaxLevel, Rank: rank}
		st.NpcsNew++
		fallthrough
	default:
		inst.Npcs = appendUnique(inst.Npcs, id)
		sort.Ints(inst.Npcs)
	}
	n := res.Npcs[id]
	if n.MinLevel == 0 && boss.MinLevel > 0 {
		n.MinLevel, n.MaxLevel = boss.MinLevel, boss.MaxLevel // QuestieDB kennt viele Forever-NPCs ohne Level
	}
	if boss.Rare && n.Rank < rareEliteRank {
		n.Rank = rareRank // QuestieDB führt manche Forever-Rare als normale NPCs
	}
	if !boss.Rare && n.Rank != bossRank {
		n.Rank = bossRank
		st.Ranked++
	}
	return id
}

// markUnverified kennzeichnet Drops, die nur aus Classic-Daten stammen (QuestieDB-Era-Drops, Classic-Führer) und die
// FDJ für diesen NPC nicht nennt; Forever-eigene Item-IDs gelten als bestätigt. Nur Bosse und Rare (Rang ab 3), denn
// nur deren Beute zeigt das Addon an (Assist/BossLoot.lua); das hält dungeon_db.lua klein.
func markUnverified(res *result, confirmed map[int]map[int]bool) int {
	n := 0
	for npcID, drops := range res.Loot {
		if res.Npcs[npcID] == nil || res.Npcs[npcID].Rank < bossRank {
			continue
		}
		for i := range drops {
			d := &drops[i]
			d.Unverified = d.Item < foreverItemMin && !confirmed[npcID][d.Item]
			if d.Unverified {
				n++
			}
		}
	}
	return n
}
