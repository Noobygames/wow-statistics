// Questie liest das lokale Addon QuestieDB (WoW-Forever-Build, WTFPL) und erzeugt daraus die Instanz-Daten
// für Level Time: Quests je klassischer Instanz mit vollständiger Vorquest-Kette, NPCs je Instanz und deren Drops.
// Ausgabe: dist/questie/{quests,npcs,loot}.json und Assist/InstanceData/dungeon_db.lua. Aufruf über "make questie".
package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
)

const defaultQuestieDir = `D:\Games\World of Warcraft\_forever_\Interface\AddOns\QuestieDB`

func main() {
	dir := flag.String("questie", defaultQuestieDir, "Ordner des Addons QuestieDB")
	out := flag.String("out", "dist/questie", "Ziel-Ordner der JSON-Dateien")
	luaOut := flag.String("lua", "Assist/InstanceData/dungeon_db.lua", "Ziel-Datei (Lua)")
	itemSparse := flag.String("itemsparse", "", "lokale ItemSparse-CSVs (kommagetrennt, Vorrang in Reihenfolge) statt Download von wago.tools")
	flag.Parse()

	qualities, itemBuild, err := loadQualities(*itemSparse)
	var res *result
	var version string
	if err == nil {
		res, version, err = run(*dir, qualities)
	}
	if err == nil {
		err = writeJSON(*out, res)
	}
	if err == nil {
		err = writeLua(*luaOut, version, itemBuild, res)
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, "Fehler:", err)
		os.Exit(1)
	}
	printSummary(res, *luaOut)
}

func run(dir string, qualities map[int]int) (*result, string, error) {
	store, err := readTOC(filepath.Join(dir, "QuestieDB_Forever.toc"))
	if err != nil {
		return nil, "", err
	}
	db, err := loadDB(store)
	if err != nil {
		return nil, "", err
	}
	zones, err := readZones(dir)
	if err != nil {
		return nil, "", err
	}
	rates, err := readDropRates(dir)
	if err != nil {
		return nil, "", err
	}
	return build(db, zones, rates, qualities), store.values["Version"], nil
}

func printSummary(res *result, luaOut string) {
	chains, rated := 0, 0
	perQuality, items := map[int]int{}, map[int]bool{}
	for _, q := range res.Quests {
		if q.Chain != nil {
			chains++
		}
	}
	for _, list := range res.Loot {
		for _, d := range list {
			if !items[d.Item] {
				items[d.Item] = true
				perQuality[d.Quality]++
			}
			if d.Chance != unknown {
				rated++
			}
		}
	}
	for _, mapID := range sortedKeys(res.Instances) {
		inst := res.Instances[mapID]
		fmt.Printf("%4d %-28s Quests %3d  NPCs %4d\n", mapID, inst.Name, len(inst.Quests), len(inst.Npcs))
	}
	size := int64(0)
	if fi, err := os.Stat(luaOut); err == nil {
		size = fi.Size()
	}
	fmt.Printf("Instanzen %d, Quests %d (davon Kette %d), NPCs %d (mit Beute %d)\n",
		len(res.Instances), len(res.Quests), chains, len(res.Npcs), len(res.Loot))
	fmt.Printf("Beute-Items rar %d, episch %d, legendär %d (Drops mit Chance %d, ohne Qualität übersprungen %d)\n",
		perQuality[3], perQuality[4], perQuality[5], rated, res.NoQuality)
	fmt.Printf("%s: %d KB\n", luaOut, size/1024)
}
