package main

// Fraktions-Korrekturen von QuestieDB (src/corrections/Forever/legacy/classic{Quest,Item}Fixes.lua, LoadFactionFixes):
// Questie wendet sie zur Laufzeit je nach Fraktion (und bei manchen Folgequests je Klasse) des Spielers an, sie stehen
// daher nicht in den gebackenen TOC-Daten. Wir führen beide Funktionen mit gopher-lua für jede Fraktion und Klasse aus
// und übernehmen: Questgeber je Fraktion (startedBy), alle Folgequests (nextQuestInChain, für die Ketten), requiredRaces
// (nur wenn beide Fraktionen denselben Wert setzen) und die Drop-Quellen von Items (npcDrops, objectDrops, vereinigt).

import (
	"path/filepath"
	"sort"

	lua "github.com/yuin/gopher-lua"
)

const (
	factionAlliance = "A"
	factionHorde    = "H"
)

var factionNames = map[string]string{factionAlliance: "Alliance", factionHorde: "Horde"}

var playerClasses = []string{"WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID"}

// Ersatz für QuestieLoader und die importierten Module: Schlüssel-Tabellen liefern den Feldnamen selbst
// (questKeys.startedBy -> "startedBy"), Enums 0 (raceIDs.NONE = 0, andere Werte nutzen wir nicht).
const factionFixStub = `
local function names() return setmetatable({}, { __index = function(_, k) return k end }) end
local function zeros() return setmetatable({}, { __index = function() return 0 end }) end
local modules = {
  QuestieDB = { questKeys = names(), itemKeys = names(), npcKeys = names(), objectKeys = names(),
    raceKeys = zeros(), factionIDs = zeros() },
  ZoneDB = { zoneIDs = zeros() },
  QuestieCorrections = { itemObjectiveFirst = {} },
  l10n = setmetatable({}, { __call = function(_, s) return s end }),
}
QuestieLoader = {
  CreateModule = function(_, name) modules[name] = modules[name] or {} return modules[name] end,
  ImportModule = function(_, name) return modules[name] or {} end,
}
function UnitClassBase() return PLAYER_CLASS end
function UnitFactionGroup() return PLAYER_FACTION end
function factionFixes(module) return modules[module]:LoadFactionFixes() end
`

type factionFixes struct {
	start map[int]map[string][4][]int // questID -> Fraktion -> Questgeber (Index giverNpc/giverObject/giverItem)
	next  map[int][]int               // questID -> alle Folgequests über Fraktionen und Klassen
	races map[int]int                 // questID -> requiredRaces, wenn beide Fraktionen ihn gleich setzen
	drops map[int][2][]int            // itemID -> {npcDrops, objectDrops} beider Fraktionen
}

func readFactionFixes(root string) (*factionFixes, error) {
	dir := filepath.Join(root, "src", "corrections", "Forever", "legacy")
	L := lua.NewState()
	defer L.Close()
	if err := L.DoString(factionFixStub); err != nil {
		return nil, err
	}
	f := &factionFixes{start: map[int]map[string][4][]int{}, next: map[int][]int{}, races: map[int]int{},
		drops: map[int][2][]int{}}
	racesBy := map[string]map[int]int{}
	for _, faction := range []string{factionAlliance, factionHorde} {
		racesBy[faction] = map[int]int{}
		for _, class := range playerClasses {
			L.SetGlobal("PLAYER_FACTION", lua.LString(factionNames[faction]))
			L.SetGlobal("PLAYER_CLASS", lua.LString(class))
			quests, err := loadFixTable(L, filepath.Join(dir, "classicQuestFixes.lua"), "QuestieQuestFixes")
			if err != nil {
				return nil, err
			}
			for id, fix := range luaPairs(quests) {
				if s := luaField(fix, "startedBy"); s != nil {
					var start [4][]int
					for _, kind := range []int{giverNpc, giverObject, giverItem} {
						start[kind] = intList(luaIndex(s, kind))
					}
					if f.start[id] == nil {
						f.start[id] = map[string][4][]int{}
					}
					f.start[id][faction] = start
				}
				if n, ok := toInt(luaField(fix, "nextQuestInChain")); ok && n > 0 {
					f.next[id] = appendUnique(f.next[id], n)
				}
				if r, ok := toInt(luaField(fix, "requiredRaces")); ok {
					racesBy[faction][id] = r
				}
			}
			items, err := loadFixTable(L, filepath.Join(dir, "classicItemFixes.lua"), "QuestieItemFixes")
			if err != nil {
				return nil, err
			}
			for id, fix := range luaPairs(items) {
				d := f.drops[id]
				for _, n := range intList(luaField(fix, "npcDrops")) {
					d[0] = appendUnique(d[0], n)
				}
				for _, o := range intList(luaField(fix, "objectDrops")) {
					d[1] = appendUnique(d[1], o)
				}
				f.drops[id] = d
			}
		}
	}
	for id, r := range racesBy[factionAlliance] {
		if h, ok := racesBy[factionHorde][id]; ok && h == r {
			f.races[id] = r
		}
	}
	for _, ids := range f.next {
		sort.Ints(ids)
	}
	return f, nil
}

// loadFixTable führt die Korrektur-Datei aus und liefert das Ergebnis von <module>:LoadFactionFixes() als Go-Wert.
func loadFixTable(L *lua.LState, path, module string) (any, error) {
	if err := L.DoFile(path); err != nil {
		return nil, err
	}
	if err := L.CallByParam(lua.P{Fn: L.GetGlobal("factionFixes"), NRet: 1, Protect: true}, lua.LString(module)); err != nil {
		return nil, err
	}
	v := fromLua(L.Get(-1))
	L.Pop(1)
	return v, nil
}

// apply trägt die Korrekturen in die Rohdaten ein (vor build): Folgequests und Drop-Quellen vereinigt,
// requiredRaces gesetzt; die Questgeber je Fraktion wertet giverFor aus.
func (f *factionFixes) apply(db *questieDB) {
	for id, next := range f.next {
		if q := db.quests[id]; q != nil {
			q.NextAlt = next
		}
	}
	for id, r := range f.races {
		if q := db.quests[id]; q != nil {
			q.Races = r
		}
	}
	for id, d := range f.drops {
		if it := db.items[id]; it != nil {
			for _, n := range d[0] {
				it.Npcs = appendUnique(it.Npcs, n)
			}
			for _, o := range d[1] {
				it.Objects = appendUnique(it.Objects, o)
			}
		}
	}
	db.factionStart = f.start
}

// fromLua wandelt einen Lua-Wert in die Form der CBOR-Daten (map[any]any mit int64- oder string-Schlüsseln), damit
// luaIndex, luaPairs und intList darauf arbeiten.
func fromLua(v lua.LValue) any {
	switch x := v.(type) {
	case lua.LNumber:
		if f := float64(x); f == float64(int64(f)) {
			return int64(f)
		}
		return float64(x)
	case lua.LString:
		return string(x)
	case *lua.LTable:
		out := map[any]any{}
		x.ForEach(func(k, val lua.LValue) {
			if key := fromLua(k); key != nil {
				out[key] = fromLua(val)
			}
		})
		return out
	}
	return nil
}

// luaField liest t[name] einer Tabelle mit Text-Schlüssel.
func luaField(t any, name string) any {
	if m, ok := t.(map[any]any); ok {
		return m[name]
	}
	return nil
}
