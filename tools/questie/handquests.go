package main

// Von Hand gepflegte Dungeonquests (docs/research/dungeon_quests.json): Zuordnungen, die QuestieDB nicht herleitet
// (Klassenquests ohne Ziel in der Instanz, Quests, die in der Instanz beginnen, Forever-Instanzen ohne Eintrag in
// instanceIdToAreaId), Korrekturen falscher oder fehlender QuestieDB-Werte und Quests, die QuestieDB gar nicht
// kennt. So ist dungeon_db.lua die eine Quelle für alle Dungeonquests.

import (
	"encoding/json"
	"fmt"
	"os"
	"sort"
)

type handQuests struct {
	Quests map[int][]int     `json:"quests"` // Karten-ID -> questIDs
	Data   map[int]*questOut `json:"data"`   // questID -> Korrektur (gesetzte Felder) bzw. ganze Quest ohne QuestieDB
}

func readHandQuests(path string) (*handQuests, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var h handQuests
	if err := json.Unmarshal(data, &h); err != nil {
		return nil, fmt.Errorf("%s: %w", path, err)
	}
	return &h, nil
}

// mergeHandQuests hängt die Zuordnungen an die Instanzen (unbekannte Instanzen ohne NPCs neu) und baut ihre
// Vorquest-Ketten; Quests ohne QuestieDB-Eintrag kommen ganz aus data, sonst korrigiert data einzelne Felder.
func mergeHandQuests(res *result, db *questieDB, z *zoneData, h *handQuests) error {
	prev, depth := predecessors(db), map[int]int{}
	for _, mapID := range sortedKeys(h.Quests) {
		inst := res.Instances[mapID]
		if inst == nil {
			inst = &instanceOut{MapID: mapID}
			res.Instances[mapID] = inst
		}
		var known []int
		for _, id := range h.Quests[mapID] {
			var out *questOut
			switch {
			case db.quests[id] != nil:
				out = res.quest(db, z, id)
				known = append(known, id)
			case h.Data[id] != nil:
				out = res.Quests[id]
				if out == nil {
					out = &questOut{ID: id, Name: h.Data[id].Name}
					res.Quests[id] = out
				}
			default:
				return fmt.Errorf("Hand-Quest %d (Karte %d): weder in QuestieDB noch unter data", id, mapID)
			}
			out.Instances = appendUnique(out.Instances, mapID)
			inst.Quests = appendUnique(inst.Quests, id)
		}
		sort.Ints(inst.Quests)
		res.addChains(db, z, prev, depth, mapID, known)
	}
	for _, id := range sortedKeys(h.Data) {
		out := res.Quests[id]
		if out == nil {
			return fmt.Errorf("Hand-Korrektur %d: Quest steht in keiner Instanz", id)
		}
		out.override(h.Data[id])
	}
	return nil
}

// override übernimmt die gesetzten Felder einer Hand-Korrektur (0 bzw. leer = Wert bleibt).
func (out *questOut) override(h *questOut) {
	if h.Level > 0 {
		out.Level = h.Level
	}
	if h.ReqLevel > 0 {
		out.ReqLevel = h.ReqLevel
	}
	if h.Faction != "" {
		out.Faction = h.Faction
	}
	if h.Giver != nil {
		out.Giver = h.Giver
	}
}
