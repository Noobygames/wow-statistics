package main

// Lädt die benötigten Felder aller Quests, NPCs, Objekte und Items aus dem TOC-Speicher.
// Feldnummern laut src/meta/<entity>Meta.lua von QuestieDB.

import "fmt"

const (
	questName        = 1
	questStartedBy   = 2
	questFinishedBy  = 3
	questReqLevel    = 4
	questLevel       = 5
	questRaces       = 6
	questClasses     = 7
	questObjectives  = 10
	questPreGroup    = 12
	questPreSingle   = 13
	questExclusiveTo = 16
	questZoneOrSort  = 17
	questNextInChain = 22
	questBreadcrumbs = 28

	npcName    = 1
	npcMinLvl  = 4
	npcMaxLvl  = 5
	npcRank    = 6
	npcSpawns  = 7
	npcZoneID  = 9
	objName    = 1
	objSpawns  = 4
	objZoneID  = 5
	itemName   = 1
	itemNpcs   = 2
	itemObjs   = 3
	itemClass  = 12
	itemSubCls = 13
)

// Positionen in questgivers {npcIds, objectIds, itemIds} und objectives {creatures, objects, items, rep, killCredit, spell}.
const (
	giverNpc    = 1
	giverObject = 2
	giverItem   = 3
	objCreature = 1
	objObject   = 2
	objItem     = 3
	objKill     = 5
)

type quest struct {
	ID, Level, ReqLevel, Races, Classes, ZoneOrSort, Next int
	Name                                                  string
	Start, End                                            [4][]int // Index giverNpc/giverObject/giverItem
	PreGroup, PreSingle, Excl, Breadcrumbs                []int
	ObjNpcs, ObjObjects, ObjItems                         []int
}

type spawn struct{ X, Y float64 }

type entity struct {
	ID, MinLevel, MaxLevel, Rank, ZoneID int
	Name                                 string
	Spawns                               map[int][]spawn // AreaID -> Punkte (0-100, -1 = in Instanz)
}

type item struct {
	ID, Class, SubClass int
	Name                string
	Npcs, Objects       []int
}

type questieDB struct {
	quests  map[int]*quest
	npcs    map[int]*entity
	objects map[int]*entity
	items   map[int]*item
}

func loadDB(s *tocStore) (*questieDB, error) {
	db := &questieDB{quests: map[int]*quest{}, npcs: map[int]*entity{}, objects: map[int]*entity{}, items: map[int]*item{}}
	err := eachRecord(s, "Quest", func(id int, r *record) {
		q := &quest{
			ID: id, Name: r.str(questName), Level: r.num(questLevel), ReqLevel: r.num(questReqLevel),
			Races: r.num(questRaces), Classes: r.num(questClasses), ZoneOrSort: r.num(questZoneOrSort),
			Next:     r.num(questNextInChain),
			PreGroup: intList(r.table(questPreGroup)), PreSingle: intList(r.table(questPreSingle)),
			Excl: intList(r.table(questExclusiveTo)), Breadcrumbs: intList(r.table(questBreadcrumbs)),
		}
		for _, kind := range []int{giverNpc, giverObject, giverItem} {
			q.Start[kind] = intList(luaIndex(r.table(questStartedBy), kind))
			q.End[kind] = intList(luaIndex(r.table(questFinishedBy), kind))
		}
		obj := r.table(questObjectives)
		q.ObjNpcs = firstIDs(luaIndex(obj, objCreature))
		q.ObjObjects = firstIDs(luaIndex(obj, objObject))
		q.ObjItems = firstIDs(luaIndex(obj, objItem))
		// killCredit: {{npcIds}, rootNpcId, text}
		for _, kc := range luaList(luaIndex(obj, objKill)) {
			q.ObjNpcs = append(q.ObjNpcs, intList(luaIndex(kc, 1))...)
		}
		db.quests[id] = q
	})
	if err != nil {
		return nil, err
	}
	if err := eachRecord(s, "Npc", func(id int, r *record) {
		db.npcs[id] = &entity{ID: id, Name: r.str(npcName), MinLevel: r.num(npcMinLvl), MaxLevel: r.num(npcMaxLvl),
			Rank: r.num(npcRank), ZoneID: r.num(npcZoneID), Spawns: spawns(r.table(npcSpawns))}
	}); err != nil {
		return nil, err
	}
	if err := eachRecord(s, "Object", func(id int, r *record) {
		db.objects[id] = &entity{ID: id, Name: r.str(objName), ZoneID: r.num(objZoneID), Spawns: spawns(r.table(objSpawns))}
	}); err != nil {
		return nil, err
	}
	err = eachRecord(s, "Item", func(id int, r *record) {
		db.items[id] = &item{ID: id, Name: r.str(itemName), Class: r.num(itemClass), SubClass: r.num(itemSubCls),
			Npcs: intList(r.table(itemNpcs)), Objects: intList(r.table(itemObjs))}
	})
	return db, err
}

func eachRecord(s *tocStore, entity string, fn func(int, *record)) error {
	ids, err := s.ids(entity)
	if err != nil {
		return err
	}
	for _, id := range ids {
		r, err := s.record(entity, id)
		if err != nil {
			return fmt.Errorf("%s %d: %w", entity, id, err)
		}
		if r != nil {
			fn(id, r)
		}
	}
	return s.firstErr
}

// firstIDs liest {{id, text?}, ...} als ID-Liste.
func firstIDs(t any) []int {
	var out []int
	for _, e := range luaList(t) {
		if n, ok := toInt(luaIndex(e, 1)); ok {
			out = append(out, n)
		}
	}
	return out
}

func spawns(t any) map[int][]spawn {
	out := map[int][]spawn{}
	for area, points := range luaPairs(t) {
		for _, p := range luaList(points) {
			x, _ := toFloat(luaIndex(p, 1))
			y, _ := toFloat(luaIndex(p, 2))
			out[area] = append(out[area], spawn{x, y})
		}
		if _, ok := out[area]; !ok {
			out[area] = nil
		}
	}
	return out
}
