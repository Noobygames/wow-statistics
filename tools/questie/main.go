// Questie liest das lokale Addon QuestieDB (WoW-Forever-Build, WTFPL) und erzeugt daraus die Instanz-Daten
// für Level Time: Quests je klassischer Instanz mit vollständiger Vorquest-Kette, NPCs je Instanz und deren Drops.
// Ergänzt die Boss-Beute aus der eigenen Führer-Recherche (docs/research/mechanics, siehe guide.go).
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
	guideDir := flag.String("guide", "../../docs/research/mechanics", "Ordner der Führer-Recherche (JSON je Instanz)")
	bossNpcsPath := flag.String("bossnpcs", "../../Assist/InstanceData/boss_npcs.lua", "Boss-NPC-Liste (ns.BossNpcs)")
	itemSparse := flag.String("itemsparse", "", "lokale ItemSparse-CSVs (kommagetrennt, Vorrang in Reihenfolge) statt Download von wago.tools")
	flag.Parse()

	qualities, itemBuild, err := loadQualities(*itemSparse)
	var res *result
	var version string
	var guide guideStats
	if err == nil {
		res, version, guide, err = run(*dir, *guideDir, *bossNpcsPath, qualities)
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
	printSummary(res, guide, *luaOut)
}

func run(dir, guideDir, bossNpcsPath string, qualities map[int]int) (*result, string, guideStats, error) {
	var st guideStats
	store, err := readTOC(filepath.Join(dir, "QuestieDB_Forever.toc"))
	if err != nil {
		return nil, "", st, err
	}
	db, err := loadDB(store)
	if err != nil {
		return nil, "", st, err
	}
	zones, err := readZones(dir)
	if err != nil {
		return nil, "", st, err
	}
	rates, err := readDropRates(dir)
	if err != nil {
		return nil, "", st, err
	}
	guides, err := readGuides(guideDir)
	if err != nil {
		return nil, "", st, err
	}
	bossNpcs, err := readBossNpcs(bossNpcsPath)
	if err != nil {
		return nil, "", st, err
	}
	res := build(db, zones, rates, qualities)
	st = mergeGuide(res, db, guides, qualities, bossNpcs)
	return res, store.values["Version"], st, nil
}

func printSummary(res *result, guide guideStats, luaOut string) {
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
	fmt.Printf("Führer: %d Items ergänzt, %d schon bekannt, %d nicht in ItemSparse, %d unter rar; %d Bosse auf Rang 3\n",
		guide.Added, guide.Duplicate, guide.NotFound, guide.BelowRare, guide.Ranked)
	for _, u := range guide.Unmatched {
		fmt.Println("  Führer-NPC ohne Zuordnung:", u)
	}
	fmt.Printf("%s: %d KB\n", luaOut, size/1024)
}
