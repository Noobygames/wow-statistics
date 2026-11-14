package main

// Zonen- und Dropdaten aus den Lua-Hilfsdateien von QuestieDB (support/Forever/..., src/corrections/enum/zones.lua).
// Die Dateien sind einfache Tabellen-Literale; statt sie auszuführen, lesen wir die Zeilen per Muster.

import (
	"bufio"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
)

// Klassische Instanzen (Dungeons und Schlachtzüge), Schlüssel wie im Addon: Instanz-Karten-ID.
var classicInstanceMapIDs = []int{
	33, 34, 36, 43, 47, 48, 70, 90, 109, 129, 189, 209, 229, 230, 249, 289, 309, 329, 349, 389,
	409, 429, 469, 509, 531, 533,
}

type zoneData struct {
	instanceArea map[int]int    // Instanz-Karten-ID -> AreaID
	dungeonName  map[int]string // AreaID -> Name (enUS)
	altAreas     map[int][]int  // AreaID -> weitere AreaIDs (Etagen, Quest-Sortierung)
	parent       map[int]int    // Unterzone -> Elternzone
	uiMap        map[int]int    // AreaID -> uiMapID
}

func readFileLines(path string) ([]string, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	var lines []string
	sc := bufio.NewScanner(f)
	sc.Buffer(make([]byte, 1<<20), 1<<24)
	for sc.Scan() {
		lines = append(lines, sc.Text())
	}
	return lines, sc.Err()
}

var (
	pairLine     = regexp.MustCompile(`^\s*\[(\d+)\]\s*=\s*(-?\d+),`)
	enumLine     = regexp.MustCompile(`^\s*([A-Z0-9_]+)\s*=\s*(\d+),`)
	instanceLine = regexp.MustCompile(`^\s*\[(\d+)\]\s*=\s*ZoneDB\.zoneIDs\.([A-Z0-9_]+),`)
	dungeonLine  = regexp.MustCompile(`^\s*\[(\d+)\]\s*=\s*\{"([^"]+)",(nil|\{[\d,]*\})`)
)

// intPairs liest "[a] = b," Zeilen; der erste Treffer gewinnt (Override-Tabellen stehen vorn).
func intPairs(lines []string) map[int]int {
	out := map[int]int{}
	for _, line := range lines {
		if m := pairLine.FindStringSubmatch(line); m != nil {
			k, _ := strconv.Atoi(m[1])
			if _, seen := out[k]; !seen {
				out[k], _ = strconv.Atoi(m[2])
			}
		}
	}
	return out
}

func readZones(root string) (*zoneData, error) {
	zonesDir := filepath.Join(root, "support", "Forever", "Zones")
	files := map[string][]string{}
	for name, path := range map[string]string{
		"enum":      filepath.Join(root, "src", "corrections", "enum", "zones.lua"),
		"instances": filepath.Join(zonesDir, "instanceIdToAreaId.lua"),
		"dungeons":  filepath.Join(zonesDir, "dungeons.lua"),
		"subzones":  filepath.Join(zonesDir, "subZoneToParentZone.lua"),
		"uimap":     filepath.Join(zonesDir, "areaIdToUiMapId.lua"),
	} {
		lines, err := readFileLines(path)
		if err != nil {
			return nil, err
		}
		files[name] = lines
	}

	enum := map[string]int{}
	for _, line := range files["enum"] {
		if m := enumLine.FindStringSubmatch(line); m != nil {
			if _, seen := enum[m[1]]; !seen {
				enum[m[1]], _ = strconv.Atoi(m[2])
			}
		}
	}
	z := &zoneData{
		instanceArea: map[int]int{},
		dungeonName:  map[int]string{},
		altAreas:     map[int][]int{},
		parent:       intPairs(files["subzones"]),
		uiMap:        intPairs(files["uimap"]),
	}
	for _, line := range files["instances"] {
		if m := instanceLine.FindStringSubmatch(line); m != nil {
			if area, ok := enum[m[2]]; ok {
				id, _ := strconv.Atoi(m[1])
				z.instanceArea[id] = area
			}
		}
	}
	for _, line := range files["dungeons"] {
		m := dungeonLine.FindStringSubmatch(line)
		if m == nil {
			continue
		}
		area, _ := strconv.Atoi(m[1])
		z.dungeonName[area] = m[2]
		if m[3] != "nil" {
			for _, s := range strings.Split(strings.Trim(m[3], "{}"), ",") {
				if n, err := strconv.Atoi(s); err == nil {
					z.altAreas[area] = append(z.altAreas[area], n)
				}
			}
		}
	}
	return z, nil
}

// npcAreas: AreaIDs, deren Spawns in der Instanz liegen (Hauptzone, eigene Etagen, Unterzonen).
// Alternativ-IDs, die einer anderen (Außen-)Zone gehören (z.B. 133 New Tinkertown), zählen nicht.
func (z *zoneData) npcAreas(area int) map[int]bool {
	set := map[int]bool{area: true}
	for _, alt := range z.altAreas[area] {
		if p, ok := z.parent[alt]; !ok || p == area {
			set[alt] = true
		}
	}
	for child, p := range z.parent {
		if p == area {
			set[child] = true
		}
	}
	return set
}

// questAreas: AreaIDs, die als zoneOrSort einer Quest die Instanz meinen (inkl. "quests are X"-Aliasse).
func (z *zoneData) questAreas(area int) map[int]bool {
	set := z.npcAreas(area)
	for _, alt := range z.altAreas[area] {
		set[alt] = true
	}
	return set
}

// uiMapFor liefert die uiMapID einer AreaID, notfalls über die Elternzone.
func (z *zoneData) uiMapFor(area int) int {
	for i := 0; i < 4 && area != 0; i++ {
		if m, ok := z.uiMap[area]; ok && m != 0 {
			return m
		}
		area = z.parent[area]
	}
	return 0
}

var (
	dropItemLine = regexp.MustCompile(`^\s*\[(\d+)\]\s*=\s*\{`)
	dropNpcLine  = regexp.MustCompile(`^\s*\[(\d+)\]\s*=\s*([\d.]+),`)
)

// readDropRates liest QuestieClassicItemDrops.wowheadData: Item -> NPC -> Dropchance in Prozent.
// shortcut: itemDropCorrections.lua (fast nur Verweise auf dieselben Wowhead-Werte) wird nicht gelesen;
// einbauen, falls dort echte Zahlen-Korrekturen für Instanz-Items auftauchen.
func readDropRates(root string) (map[int]map[int]float64, error) {
	lines, err := readFileLines(filepath.Join(root, "support", "Forever", "DropTables", "classicItemDrops.lua"))
	if err != nil {
		return nil, err
	}
	out := map[int]map[int]float64{}
	item := 0
	for _, line := range lines {
		if m := dropItemLine.FindStringSubmatch(line); m != nil {
			item, _ = strconv.Atoi(m[1])
			out[item] = map[int]float64{}
		} else if m := dropNpcLine.FindStringSubmatch(line); m != nil && item != 0 {
			npc, _ := strconv.Atoi(m[1])
			out[item][npc], _ = strconv.ParseFloat(m[2], 64)
		}
	}
	return out, nil
}
