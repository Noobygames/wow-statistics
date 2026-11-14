package main

import (
	"bytes"
	"compress/zlib"
	"encoding/base64"
	"encoding/binary"
	"fmt"
	"math"
	"os"
	"path/filepath"
	"strings"
	"testing"

	lua "github.com/yuin/gopher-lua"
)

// Echte Zeile aus QuestieDB_Forever.toc (Quest 2, Skalar-Zeile).
const realQuestRow = "pwFRU2hhcnB0YWxvbidzIENsYXcEFAUYHgYbAAAAAgAAALILGT+xERkBS0FwGgIAUIY="

func TestDecodeRealRow(t *testing.T) {
	store, err := parseTOC(strings.NewReader("## X-Quest-2-S: " + realQuestRow + "\n"))
	if err != nil {
		t.Fatal(err)
	}
	r, err := store.record("Quest", 2)
	if err != nil || r == nil {
		t.Fatalf("record: %v", err)
	}
	if r.str(questName) != "Sharptalon's Claw" || r.num(questLevel) != 30 || r.num(questReqLevel) != 20 {
		t.Fatalf("falsch dekodiert: %#v", r.row)
	}
}

func TestChunkedValue(t *testing.T) {
	enc := cborB64([]any{int64(1), "ab"})
	toc := fmt.Sprintf("## X-Npc-1-7: ~2~\n## X-Npc-1-7-1: %s\n## X-Npc-1-7-2: %s\n", enc[:5], enc[5:])
	store, _ := parseTOC(strings.NewReader(toc))
	v, err := store.decoded("X-Npc-1-7")
	if err != nil || luaIndex(v, 2) != "ab" {
		t.Fatalf("gestückelter Wert: %#v %v", v, err)
	}
}

func TestParseQualities(t *testing.T) {
	csv := "ID,Display_lang,OverallQualityID\n17204,\"Eye, of Sulfuras\",5\n2589,Linen Cloth,1\n"
	out := map[int]int{2589: 2} // Vorrang: vorhandener Eintrag bleibt
	if err := parseQualities(strings.NewReader(csv), out); err != nil {
		t.Fatal(err)
	}
	if out[17204] != 5 || out[2589] != 2 {
		t.Fatalf("Qualitäten: %v", out)
	}
}

func TestReadBossNpcs(t *testing.T) {
	path := filepath.Join(t.TempDir(), "boss_npcs.lua")
	os.WriteFile(path, []byte("ns.BossNpcs = {\n  [227] = 9018, -- Gerstahn\n  [228] = 9025,\n}\n"), 0o644)
	got, err := readBossNpcs(path)
	if err != nil || len(got) != 2 || !got[9018] || !got[9025] {
		t.Fatalf("Boss-NPCs: %v %v", got, err)
	}
}

func TestBuildMoltenCore(t *testing.T) {
	store, err := parseTOC(strings.NewReader(fixtureTOC()))
	if err != nil {
		t.Fatal(err)
	}
	db, err := loadDB(store)
	if err != nil {
		t.Fatal(err)
	}
	zones, err := readZones("testdata")
	if err != nil {
		t.Fatal(err)
	}
	rates, err := readDropRates("testdata")
	if err != nil {
		t.Fatal(err)
	}
	qualities := map[int]int{17204: 5, 2589: 1, 18000: 4, 18001: 3}
	res := build(db, zones, rates, qualities)
	// Hand-Daten: Quest 50 zusätzlich in Molten Core (mit Korrektur), Quest 7777 ohne QuestieDB in neuer Instanz
	hand := &handQuests{Quests: map[int][]int{409: {50}, 3065: {7777}}, Data: map[int]*questOut{
		7777: {Name: "Nur von Hand", Level: 15, ReqLevel: 10},
		50:   {ReqLevel: 12, Giver: &giverOut{UiMapID: 1455, X: 0.5, Y: 0.25}},
	}}
	if err := mergeHandQuests(res, db, zones, hand); err != nil {
		t.Fatal(err)
	}
	if err := mergeHandQuests(res, db, zones, &handQuests{Quests: map[int][]int{409: {4242}}}); err == nil {
		t.Error("unbekannte Hand-Quest ohne data muss scheitern")
	}
	res.addGivers(db)
	guides := []guideInstance{{Name: "Molten Core", MapID: 409, Bosses: []guideNpc{
		// schon bekannt, unter rar, nicht in ItemSparse, neu (Qualität 4 aus ItemSparse statt Führer)
		{Name: "Ragnaros", NpcID: 11502, Loot: []guideItem{{17204, "Eye"}, {2589, "Cloth"}, {99999, "Fake"}, {18000, "New"}}},
		{Name: "Garr", NpcID: 1, Loot: []guideItem{{18001, "Garr Drop"}}}, // falsche npcID: Zuordnung über den Namen
		{Name: "Niemand", NpcID: 2},
	}}}
	st := mergeGuide(res, db, guides, qualities, map[int]bool{12056: true})
	if st.Added != 2 || st.Duplicate != 1 || st.BelowRare != 1 || st.NotFound != 1 || st.Ranked != 2 || len(st.Unmatched) != 1 {
		t.Fatalf("Führer-Zählung: %+v", st)
	}
	path := filepath.Join(t.TempDir(), "dungeon_db.lua")
	if err := writeLua(path, "1.0", "test", res); err != nil {
		t.Fatal(err)
	}

	L := lua.NewState()
	defer L.Close()
	L.SetGlobal("ns", L.NewTable())
	// Flavor-Weiche der Datei: als Forever-Client laden
	if err := L.DoString(`ns.Client = { Flavor = function() return "forever" end }`); err != nil {
		t.Fatal(err)
	}
	fn, err := L.LoadFile(path)
	if err != nil {
		t.Fatalf("Lua-Syntax: %v", err)
	}
	L.Push(fn)
	L.Push(lua.LString("LevelTimer"))
	L.Push(L.GetGlobal("ns"))
	if err := L.PCall(2, 0, nil); err != nil {
		t.Fatal(err)
	}

	for expr, want := range map[string]string{
		`table.concat(ns.DungeonDB.quests[409], ",")`:                               "50,52,53,100",
		`table.concat(ns.DungeonDB.quests[3065], ",")`:                              "7777",
		`ns.DungeonDB.questInfo[7777][1] .. "/" .. ns.DungeonDB.questInfo[7777][2]`: "15/10",
		`ns.DungeonDB.questInfo[7777].name`:                                         "Nur von Hand",
		`ns.DungeonDB.questInfo[100].name`:                                          "Ragnaros",
		`ns.DungeonDB.questInfo[50][2] .. "/" .. ns.DungeonDB.questInfo[50][7]`:     "12/1455",
		`tostring(ns.DungeonDB.questInfo[50][5])`:                                   "nil",
		`table.concat(ns.DungeonDB.questChains[99], ",")`:                           "409,100,1,2",
		`table.concat(ns.DungeonDB.questChains[98], ",")`:                           "409,100,1,2",
		`ns.DungeonDB.questChains[100] == nil`:                                      "true",
		`table.concat(ns.DungeonDB.questInfo[100].preAny, ",")`:                     "99",
		`ns.DungeonDB.questInfo[100][3]`:                                            "H",
		`ns.DungeonDB.questInfo[100][5] .. ns.DungeonDB.questInfo[100][6]`:          "n14387",
		`ns.DungeonDB.questInfo[100][7] .. "/" .. ns.DungeonDB.questInfo[100][8]`:   "1428/0.321",
		`ns.DungeonDB.questInfo[52][7]`:                                             "232",
		`table.concat(ns.DungeonDB.givers.npc[14387], ",")`:                         "98,99,100",
		`table.concat(ns.DungeonDB.npcs[409][11502], ",")`:                          "63,63,3",
		`tostring(ns.DungeonDB.npcs[409][12056] ~= nil)`:                            "true",
		`tostring(ns.DungeonDB.npcs[409][12057] ~= nil)`:                            "true",
		`tostring(ns.DungeonDB.npcs[409][997] == nil)`:                              "true",
		`table.concat(ns.DungeonDB.loot[11502][1], ",")`:                            "17204,5,12.5",
		`tostring(#ns.DungeonDB.loot[11502])`:                                       "2",
		`table.concat(ns.DungeonDB.loot[11502][2], ",")`:                            "18000,4",
		`table.concat(ns.DungeonDB.loot[12057][1], ",")`:                            "18001,3",
		`ns.DungeonDB.npcs[409][12057][3]`:                                          "3",
		`ns.DungeonDB.npcs[409][12056][3]`:                                          "3",
	} {
		if err := L.DoString("result = tostring(" + expr + ")"); err != nil {
			t.Fatalf("%s: %v", expr, err)
		}
		if got := L.GetGlobal("result").String(); got != want {
			t.Errorf("%s = %s, erwartet %s", expr, got, want)
		}
	}
}

// fixtureTOC baut einen kleinen Baked-Speicher: Molten Core mit Ragnaros, einer Kette 98/99 -> 100 und Störfällen.
func fixtureTOC() string {
	var b strings.Builder
	add := func(key string, v any) { fmt.Fprintf(&b, "## X-%s: %s\n", key, cborB64(v)) }
	ids := func(entity string, list ...int64) {
		var raw bytes.Buffer
		w := zlib.NewWriter(&raw)
		w.Write(cborEncode(toAny(list)))
		w.Close()
		fmt.Fprintf(&b, "## X-%s-IDS: %s\n", entity, base64.StdEncoding.EncodeToString(raw.Bytes()))
	}
	row := func(fields ...any) map[any]any {
		m := map[any]any{"p": int64(0)}
		for i := 0; i < len(fields); i += 2 {
			m[int64(fields[i].(int))] = fields[i+1]
		}
		return m
	}
	inst := []any{[]any{float64(-1), float64(-1)}}

	ids("Npc", 11502, 12056, 12057, 14387, 997, 998, 999)
	add("Npc-11502-S", row(npcName, "Ragnaros", npcMinLvl, int64(63), npcMaxLvl, int64(63), npcRank, int64(3), npcZoneID, int64(2717)))
	add("Npc-11502-7", map[any]any{int64(2717): inst})
	add("Npc-12056-S", row(npcName, "Baron Geddon", npcZoneID, int64(2717))) // ohne Spawns, nur Hauptzone
	add("Npc-12057-S", row(npcName, "Garr"))
	add("Npc-12057-7", map[any]any{int64(10098): inst}) // Unterzone der Instanz
	add("Npc-14387-S", row(npcName, "Lothos Riftwaker"))
	add("Npc-14387-7", map[any]any{int64(46): []any{[]any{32.1, 94.7}}})
	add("Npc-997-S", row(npcName, "Außen-Alias"))
	add("Npc-997-7", map[any]any{int64(10099): []any{[]any{1.0, 2.0}}})
	add("Npc-998-S", row(npcName, "Draußen A"))
	add("Npc-999-S", row(npcName, "Draußen B"))
	add("Npc-999-7", map[any]any{int64(46): []any{[]any{5.0, 5.0}}})

	ids("Object")
	ids("Item", 17204, 2589)
	add("Item-17204-S", row(itemName, "Eye of Sulfuras"))
	add("Item-17204-2", []any{int64(11502)})
	add("Item-2589-S", row(itemName, "Linen Cloth"))
	add("Item-2589-2", []any{int64(11502), int64(998), int64(999)})

	ids("Quest", 50, 51, 52, 53, 98, 99, 100)
	giver := map[any]any{int64(1): []any{int64(14387)}}
	add("Quest-100-S", row(questName, "Ragnaros", questLevel, int64(60), questReqLevel, int64(55), questRaces, int64(178)))
	add("Quest-100-2", giver)
	add("Quest-100-10", []any{[]any{[]any{int64(11502)}}})
	add("Quest-100-13", []any{int64(99)})
	add("Quest-99-S", row(questName, "Kettenstart"))
	add("Quest-99-2", giver)
	add("Quest-99-16", []any{int64(98)})
	add("Quest-98-S", row(questName, "Alternative"))
	add("Quest-98-2", giver)
	add("Quest-50-S", row(questName, "Draußen töten"))
	add("Quest-50-10", []any{[]any{[]any{int64(999)}}})
	add("Quest-51-S", row(questName, "Stoff"))
	add("Quest-51-10", map[any]any{int64(3): []any{[]any{int64(2589)}}})
	add("Quest-52-S", row(questName, "Zone", questZoneOrSort, int64(2717)))
	add("Quest-52-2", map[any]any{int64(1): []any{int64(11502)}})
	add("Quest-53-S", row(questName, "Alias-Zone", questZoneOrSort, int64(10099)))
	return b.String()
}

func toAny(list []int64) []any {
	out := make([]any, len(list))
	for i, v := range list {
		out[i] = v
	}
	return out
}

func cborB64(v any) string { return base64.StdEncoding.EncodeToString(cborEncode(v)) }

// cborEncode: kleiner Gegenpart zu decodeCBOR für die Testdaten.
func cborEncode(v any) []byte {
	var b bytes.Buffer
	head := func(major byte, n uint64) {
		switch {
		case n < 24:
			b.WriteByte(major<<5 | byte(n))
		case n < 1<<8:
			b.WriteByte(major<<5 | 24)
			b.WriteByte(byte(n))
		case n < 1<<16:
			b.WriteByte(major<<5 | 25)
			binary.Write(&b, binary.BigEndian, uint16(n))
		default:
			b.WriteByte(major<<5 | 27)
			binary.Write(&b, binary.BigEndian, n)
		}
	}
	var enc func(any)
	enc = func(v any) {
		switch x := v.(type) {
		case int64:
			if x >= 0 {
				head(0, uint64(x))
			} else {
				head(1, uint64(-1-x))
			}
		case float64:
			b.WriteByte(0xfb)
			binary.Write(&b, binary.BigEndian, math.Float64bits(x))
		case string:
			head(3, uint64(len(x)))
			b.WriteString(x)
		case []any:
			head(4, uint64(len(x)))
			for _, e := range x {
				enc(e)
			}
		case map[any]any:
			head(5, uint64(len(x)))
			for k, e := range x {
				enc(k)
				enc(e)
			}
		default:
			panic(fmt.Sprintf("cborEncode: %T", v))
		}
	}
	enc(v)
	return b.Bytes()
}
