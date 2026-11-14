package main

// Baut aus den QuestieDB-Daten die Instanz-Sicht: Quests je Instanz samt vollständiger Vorquest-Kette,
// NPCs je Instanz und Drops dieser NPCs.

import (
	"math"
	"sort"
)

// Rassen-Bits (ChrRaces) der beiden Fraktionen; weitere Bits (Forever-Erweiterungen) bleiben unberücksichtigt.
const (
	allianceRaces = 1 | 4 | 8 | 64    // Mensch, Zwerg, Nachtelf, Gnom
	hordeRaces    = 2 | 16 | 32 | 128 // Orc, Untoter, Tauren, Troll
)

const unknown = -1

type giverOut struct {
	Kind    string  `json:"kind"` // npc | object | item
	ID      int     `json:"id"`
	UiMapID int     `json:"uiMapID,omitempty"`
	X       float64 `json:"x"` // 0-1 auf der Zonenkarte, -1 = unbekannt bzw. in der Instanz
	Y       float64 `json:"y"`
}

type chainOut struct {
	MapID  int `json:"mapID"`
	Target int `json:"targetQuestID"` // Instanz-Quest, zu der die Kette führt
	Step   int `json:"step"`          // Tiefe ab Kettenanfang (1 = Start)
	Total  int `json:"total"`         // Tiefe der Ziel-Quest
}

type questOut struct {
	ID        int       `json:"id"`
	Name      string    `json:"name"`
	Level     int       `json:"level"`
	ReqLevel  int       `json:"requiredLevel"`
	Faction   string    `json:"faction,omitempty"` // A | H | leer = beide
	Races     int       `json:"raceMask"`
	Classes   int       `json:"classMask"`
	Giver     *giverOut `json:"giver,omitempty"`
	Pre       []int     `json:"preQuestGroup,omitempty"`
	PreAny    []int     `json:"preQuestSingle,omitempty"`
	Excl      []int     `json:"exclusiveTo,omitempty"`
	Instances []int     `json:"instances,omitempty"` // Karten-IDs, in denen die Quest spielt
	Chain     *chainOut `json:"chain,omitempty"`
}

type npcOut struct {
	ID       int    `json:"id"`
	Name     string `json:"name"`
	MinLevel int    `json:"minLevel"`
	MaxLevel int    `json:"maxLevel"`
	Rank     int    `json:"rank"` // 0 normal, 1 Elite, 2 Rar-Elite, 3 Boss, 4 Rar
}

type dropOut struct {
	Item    int     `json:"item"`
	Name    string  `json:"name"`
	Class   int     `json:"itemClass"`
	Quality int     `json:"quality"` // 3 rar, 4 episch, 5 legendär (ItemSparse)
	Chance  float64 `json:"chance"`  // Prozent, -1 = unbekannt
}

type instanceOut struct {
	MapID   int    `json:"mapID"`
	AreaID  int    `json:"areaID"`
	Name    string `json:"name"`
	AreaIDs []int  `json:"areaIDs"`
	Quests  []int  `json:"quests"`
	Npcs    []int  `json:"npcs"`
}

type result struct {
	Instances map[int]*instanceOut
	Quests    map[int]*questOut
	Npcs      map[int]*npcOut
	Loot      map[int][]dropOut
	Givers    map[string]map[int][]int // npc | object | item -> ID -> Quest-IDs
	NoQuality int                      // Drops ohne Eintrag in ItemSparse (fehlen in loot)
}

func build(db *questieDB, z *zoneData, rates map[int]map[int]float64, qualities map[int]int) *result {
	res := &result{Instances: map[int]*instanceOut{}, Quests: map[int]*questOut{}, Npcs: map[int]*npcOut{},
		Loot: map[int][]dropOut{}, Givers: map[string]map[int][]int{"npc": {}, "object": {}, "item": {}}}
	prev := predecessors(db)
	depth := map[int]int{}
	npcItems := map[int][]int{}
	for _, it := range db.items {
		for _, n := range it.Npcs {
			npcItems[n] = append(npcItems[n], it.ID)
		}
	}

	for _, mapID := range classicInstanceMapIDs {
		area, ok := z.instanceArea[mapID]
		if !ok {
			continue
		}
		inst := &instanceOut{MapID: mapID, AreaID: area, Name: z.dungeonName[area]}
		res.Instances[mapID] = inst
		npcArea, questArea := z.npcAreas(area), z.questAreas(area)
		inst.AreaIDs = sortedKeys(questArea)
		instNpcs, instObjs := inside(db.npcs, npcArea), inside(db.objects, npcArea)
		instItems := instanceItems(db, instNpcs, instObjs)

		for _, q := range db.quests {
			if q.ZoneOrSort > 0 && questArea[q.ZoneOrSort] || anyIn(q.End[giverNpc], instNpcs) ||
				anyIn(q.End[giverObject], instObjs) || anyIn(q.ObjNpcs, instNpcs) ||
				anyIn(q.ObjObjects, instObjs) || anyIn(q.ObjItems, instItems) {
				inst.Quests = append(inst.Quests, q.ID)
			}
		}
		sort.Ints(inst.Quests)
		for _, id := range inst.Quests {
			out := res.quest(db, z, id)
			out.Instances = append(out.Instances, mapID)
		}
		res.addChains(db, z, prev, depth, mapID, inst.Quests)

		for id := range instNpcs {
			n := db.npcs[id]
			inst.Npcs = append(inst.Npcs, id)
			if res.Npcs[id] != nil {
				continue // NPC steht schon in einer anderen Instanz (gleiche Drops)
			}
			res.Npcs[id] = &npcOut{ID: id, Name: n.Name, MinLevel: n.MinLevel, MaxLevel: n.MaxLevel, Rank: n.Rank}
			for _, itemID := range npcItems[id] {
				quality, known := qualities[itemID]
				if !known {
					res.NoQuality++
				}
				if quality < minLootQuality {
					continue
				}
				chance := float64(unknown)
				if c, ok := rates[itemID][id]; ok {
					chance = c
				}
				it := db.items[itemID]
				res.Loot[id] = append(res.Loot[id], dropOut{Item: itemID, Name: it.Name, Class: it.Class, Quality: quality, Chance: chance})
			}
			sort.Slice(res.Loot[id], func(a, b int) bool { return res.Loot[id][a].Item < res.Loot[id][b].Item })
		}
		sort.Ints(inst.Npcs)
	}

	for id, q := range res.Quests {
		src := db.quests[id]
		for kind, name := range map[int]string{giverNpc: "npc", giverObject: "object", giverItem: "item"} {
			for _, g := range src.Start[kind] {
				res.Givers[name][g] = appendUnique(res.Givers[name][g], q.ID)
			}
		}
	}
	for _, m := range res.Givers {
		for _, ids := range m {
			sort.Ints(ids)
		}
	}
	return res
}

// predecessors: Quest -> Quests, die direkt davor liegen (Vorquests, Breadcrumbs, nextQuestInChain rückwärts).
func predecessors(db *questieDB) map[int][]int {
	prev := map[int][]int{}
	add := func(q, p int) {
		if p > 0 && p != q && db.quests[p] != nil {
			prev[q] = appendUnique(prev[q], p)
		}
	}
	for _, q := range db.quests {
		for _, p := range q.PreSingle {
			add(q.ID, p)
		}
		for _, p := range q.PreGroup {
			add(q.ID, p)
		}
		for _, p := range q.Breadcrumbs {
			add(q.ID, p)
		}
		if q.Next > 0 && db.quests[q.Next] != nil {
			add(q.Next, q.ID)
		}
	}
	for _, ids := range prev {
		sort.Ints(ids)
	}
	return prev
}

// questDepth: 1 = Kettenanfang, sonst 1 + tiefste Vorquest (Zyklen brechen ab).
func questDepth(prev map[int][]int, memo map[int]int, id int) int {
	if d, ok := memo[id]; ok {
		return d
	}
	memo[id] = 1 // Zyklus-Schutz
	d := 1
	for _, p := range prev[id] {
		d = max(d, 1+questDepth(prev, memo, p))
	}
	memo[id] = d
	return d
}

// addChains geht von den Instanz-Quests rückwärts bis zum Kettenanfang; exklusive Alternativen
// (exclusiveTo) zählen als Teil der Kette auf derselben Stufe.
func (res *result) addChains(db *questieDB, z *zoneData, prev map[int][]int, depth map[int]int, mapID int, targets []int) {
	type node struct{ id, target, dist int }
	isTarget := map[int]bool{}
	queue := []node{}
	for _, t := range targets {
		isTarget[t] = true
		queue = append(queue, node{t, t, 0})
	}
	seen := map[int]bool{}
	for len(queue) > 0 {
		n := queue[0]
		queue = queue[1:]
		if seen[n.id] {
			continue
		}
		seen[n.id] = true
		if !isTarget[n.id] {
			out := res.quest(db, z, n.id)
			step, total := questDepth(prev, depth, n.id), questDepth(prev, depth, n.target)
			if out.Chain == nil || out.Chain.Total-out.Chain.Step > total-step {
				out.Chain = &chainOut{MapID: mapID, Target: n.target, Step: step, Total: total}
			}
		}
		for _, p := range prev[n.id] {
			queue = append(queue, node{p, n.target, n.dist + 1})
		}
		for _, e := range db.quests[n.id].Excl {
			if db.quests[e] != nil && !isTarget[e] {
				queue = append(queue, node{e, n.target, n.dist})
			}
		}
	}
}

// quest legt den Ausgabe-Eintrag einer Quest an (einmal je Quest).
func (res *result) quest(db *questieDB, z *zoneData, id int) *questOut {
	if out, ok := res.Quests[id]; ok {
		return out
	}
	q := db.quests[id]
	out := &questOut{ID: id, Name: q.Name, Level: q.Level, ReqLevel: q.ReqLevel, Races: q.Races, Classes: q.Classes,
		Faction: faction(q.Races), Excl: q.Excl, PreAny: q.PreSingle, Giver: giver(db, z, q)}
	for _, p := range q.PreGroup {
		if p > 0 {
			out.Pre = append(out.Pre, p)
		}
	}
	res.Quests[id] = out
	return out
}

func faction(races int) string {
	a, h := races&allianceRaces != 0, races&hordeRaces != 0
	switch {
	case a && !h:
		return "A"
	case h && !a:
		return "H"
	}
	return ""
}

// giver: erster Questgeber mit Ort (Zone mit den meisten Spawns, erster Punkt).
func giver(db *questieDB, z *zoneData, q *quest) *giverOut {
	pick := func(kind string, id int, e *entity) *giverOut {
		g := &giverOut{Kind: kind, ID: id, X: unknown, Y: unknown}
		if e == nil {
			return g
		}
		best, count := 0, -1
		for area, pts := range e.Spawns {
			if len(pts) > count || len(pts) == count && area < best {
				best, count = area, len(pts)
			}
		}
		if best == 0 {
			best = e.ZoneID
		}
		g.UiMapID = z.uiMapFor(best)
		if pts := e.Spawns[best]; len(pts) > 0 && pts[0].X >= 0 && pts[0].Y >= 0 {
			g.X, g.Y = round3(pts[0].X/100), round3(pts[0].Y/100)
		}
		return g
	}
	switch {
	case len(q.Start[giverNpc]) > 0:
		return pick("npc", q.Start[giverNpc][0], db.npcs[q.Start[giverNpc][0]])
	case len(q.Start[giverObject]) > 0:
		return pick("object", q.Start[giverObject][0], db.objects[q.Start[giverObject][0]])
	case len(q.Start[giverItem]) > 0:
		return pick("item", q.Start[giverItem][0], nil)
	}
	return nil
}

func round3(v float64) float64 { return math.Round(v*1000) / 1000 }

// inside: IDs der Entitäten mit Spawn oder Hauptzone in einer der AreaIDs.
func inside(all map[int]*entity, areas map[int]bool) map[int]bool {
	out := map[int]bool{}
	for id, e := range all {
		if areas[e.ZoneID] {
			out[id] = true
			continue
		}
		for area := range e.Spawns {
			if areas[area] {
				out[id] = true
				break
			}
		}
	}
	return out
}

// instanceItems: Items, deren Quellen (NPCs, Objekte) mindestens zur Hälfte in der Instanz liegen.
// So bleiben Allerwelts-Drops wie Stoff, die auch dort fallen, draußen.
func instanceItems(db *questieDB, npcs, objs map[int]bool) map[int]bool {
	out := map[int]bool{}
	for id, it := range db.items {
		total, in := len(it.Npcs)+len(it.Objects), 0
		for _, n := range it.Npcs {
			if npcs[n] {
				in++
			}
		}
		for _, o := range it.Objects {
			if objs[o] {
				in++
			}
		}
		if in > 0 && 2*in >= total {
			out[id] = true
		}
	}
	return out
}

func anyIn(ids []int, set map[int]bool) bool {
	for _, id := range ids {
		if set[id] {
			return true
		}
	}
	return false
}

func appendUnique(list []int, v int) []int {
	for _, x := range list {
		if x == v {
			return list
		}
	}
	return append(list, v)
}

func sortedKeys[V any](m map[int]V) []int {
	keys := make([]int, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Ints(keys)
	return keys
}
