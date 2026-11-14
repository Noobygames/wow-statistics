package main

// Boss-Beute aus der eigenen Führer-Recherche (docs/research/mechanics/*.json, öffentliche Fakten von
// warcraft.wiki.gg u. a.): ergänzt ns.DungeonDB.loot um Drops, die QuestieDB nicht kennt. Jedes Item wird gegen
// ItemSparse geprüft (muss existieren, Qualität aus ItemSparse statt aus dem Führer, nur ab rar). Forever-eigene
// Items (Führer-Flavor "forever") fehlen oft in der Client-ItemSparse, weil der Server sie liefert; sie kommen mit der
// Führer-Qualität hinein. Der Era-Client filtert unbekannte IDs zur Laufzeit (Assist/BossLoot.lua).

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
)

const bossRank = 3

type guideItem struct {
	ItemID  int    `json:"itemID"`
	Name    string `json:"name"`
	Quality string `json:"quality"` // rare | epic | legendary
	Flavor  string `json:"flavor"`  // "forever" = nur in WoW Forever
}

var guideQualities = map[string]int{"rare": 3, "epic": 4, "legendary": 5}

type guideNpc struct {
	Name  string      `json:"name"`
	NpcID int         `json:"npcID"`
	Rare  bool        `json:"rare"`
	Loot  []guideItem `json:"loot"`
}

type guideInstance struct {
	Name        string     `json:"instance"`
	MapID       int        `json:"instanceMapID"`
	Bosses      []guideNpc `json:"bosses"`
	RareDetails []guideNpc `json:"rareDetails"`
}

// guideStats: Zählung für die Zusammenfassung.
type guideStats struct {
	Added, Duplicate, NotFound, BelowRare, Ranked, ForeverOnly, NpcsAdded int
	Unmatched                                                             []string // Führer-Bosse ohne NPC in QuestieDB
	Missing                                                               []string // Items weder in ItemSparse noch Forever
}

func readGuides(dir string) ([]guideInstance, error) {
	paths, err := filepath.Glob(filepath.Join(dir, "*.json"))
	if err != nil {
		return nil, err
	}
	if len(paths) == 0 {
		return nil, fmt.Errorf("keine Führer-Recherche in %s", dir)
	}
	sort.Strings(paths)
	var out []guideInstance
	for _, path := range paths {
		data, err := os.ReadFile(path)
		if err != nil {
			return nil, err
		}
		var g guideInstance
		if err := json.Unmarshal(data, &g); err != nil {
			return nil, fmt.Errorf("%s: %w", path, err)
		}
		out = append(out, g)
	}
	return out, nil
}

var bossNpcValue = regexp.MustCompile(`\]\s*=\s*(\d+),`)

// readBossNpcs liest die NPC-IDs aus Assist/InstanceData/boss_npcs.lua ("[encounterID] = npcID,").
func readBossNpcs(path string) (map[int]bool, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	out := map[int]bool{}
	for _, m := range bossNpcValue.FindAllSubmatch(data, -1) {
		id, _ := strconv.Atoi(string(m[1]))
		out[id] = true
	}
	return out, nil
}

// mergeGuide ordnet Führer-Bosse den NPCs der Instanz zu (npcID, sonst englischer Name; fehlt die npcID in der
// Instanz, steht sie aber in QuestieDB ohne passenden Spawn, kommt der NPC dazu), hängt deren geprüfte
// Beute an res.Loot an (Chance unbekannt) und stuft Bosse auf Rang 3 hoch (QuestieDB führt manche Endbosse als
// Rar-Elite oder Elite).
func mergeGuide(res *result, db *questieDB, guides []guideInstance, qualities map[int]int, bossNpcs map[int]bool) guideStats {
	var st guideStats
	setBoss := func(id int) {
		if n := res.Npcs[id]; n != nil && n.Rank != bossRank {
			n.Rank = bossRank
			st.Ranked++
		}
	}
	for id := range bossNpcs {
		setBoss(id)
	}
	for _, g := range guides {
		inst := res.Instances[g.MapID]
		if inst == nil {
			continue
		}
		for i, boss := range append(append([]guideNpc{}, g.Bosses...), g.RareDetails...) {
			id := matchNpc(db, inst.Npcs, boss)
			if id != boss.NpcID && db.npcs[boss.NpcID] != nil {
				res.addNpc(db, inst, boss.NpcID)
				id = boss.NpcID
				st.NpcsAdded++
			}
			if id == 0 {
				st.Unmatched = append(st.Unmatched, fmt.Sprintf("%s: %s (%d)", g.Name, boss.Name, boss.NpcID))
				continue
			}
			if i < len(g.Bosses) && !boss.Rare {
				setBoss(id)
			}
			for _, item := range boss.Loot {
				st.addDrop(res, id, item, qualities)
			}
			sort.Slice(res.Loot[id], func(a, b int) bool { return res.Loot[id][a].Item < res.Loot[id][b].Item })
		}
	}
	return st
}

func (st *guideStats) addDrop(res *result, npcID int, item guideItem, qualities map[int]int) {
	quality, known := qualities[item.ItemID]
	if q, ok := guideQualities[item.Quality]; !known && ok && item.Flavor == "forever" && item.ItemID > 0 {
		quality, known = q, true
		st.ForeverOnly++
	}
	switch {
	case !known:
		st.NotFound++
		st.Missing = append(st.Missing, fmt.Sprintf("%d %s", item.ItemID, item.Name))
		return
	case quality < minLootQuality:
		st.BelowRare++
		return
	}
	for _, d := range res.Loot[npcID] {
		if d.Item == item.ItemID {
			st.Duplicate++
			return
		}
	}
	res.Loot[npcID] = append(res.Loot[npcID], dropOut{Item: item.ItemID, Name: item.Name, Quality: quality, Chance: unknown})
	st.Added++
}

// matchNpc: Führer-npcID, wenn sie unter den NPCs der Instanz ist; sonst kleinste ID mit gleichem englischem Namen.
func matchNpc(db *questieDB, instNpcs []int, boss guideNpc) int {
	byName := 0
	for _, id := range instNpcs {
		if id == boss.NpcID {
			return id
		}
		if byName == 0 && db.npcs[id].Name == boss.Name {
			byName = id // instNpcs ist sortiert
		}
	}
	return byName
}
