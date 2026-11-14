package main

// Item-Qualität: QuestieDB führt keine, daher kommt sie aus der DB2-Tabelle ItemSparse (Spalte OverallQualityID)
// von wago.tools (dieselbe Quelle wie tools/flights, siehe sources.md Abschnitt 2). Die ItemSparse von WoW Forever
// enthält nur einen Teil der Items (der Rest kommt vom Server), daher füllt Classic Era die Lücken.

import (
	"encoding/csv"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"
)

const (
	wagoBase      = "https://wago.tools"
	wagoUserAgent = "LevelTimer-questie-tool"
	wagoTimeout   = 2 * time.Minute
)

// Produkte in Vorrang-Reihenfolge: WoW Forever, dann Classic Era für fehlende Items.
var qualityProducts = []string{"wowf", "wow_classic_era"}

// Qualitäten, deren Drops in die Beute-Daten kommen: rar (3), episch (4), legendär (5).
const minLootQuality = 3

func wagoGet(client *http.Client, path string) (io.ReadCloser, error) {
	req, err := http.NewRequest(http.MethodGet, wagoBase+path, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("User-Agent", wagoUserAgent)
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		resp.Body.Close()
		return nil, fmt.Errorf("%s: HTTP %d", path, resp.StatusCode)
	}
	return resp.Body, nil
}

// loadQualities liest Item -> Qualität aus lokalen CSV-Dateien (kommagetrennt, Vorrang in Reihenfolge, die erste
// ist die Forever-Tabelle) oder lädt sie von wago.tools; liefert dazu die Items der Forever-Tabelle und die Herkunft
// (Builds bzw. Dateinamen) für den Dateikopf.
func loadQualities(csvPaths string) (map[int]int, map[int]bool, string, error) {
	if csvPaths == "" {
		return fetchQualities()
	}
	out, forever := map[int]int{}, map[int]bool{}
	for i, path := range strings.Split(csvPaths, ",") {
		f, err := os.Open(path)
		if err != nil {
			return nil, nil, "", err
		}
		err = parseQualities(f, out)
		f.Close()
		if err != nil {
			return nil, nil, "", err
		}
		if i == 0 {
			forever = keySet(out)
		}
	}
	return out, forever, csvPaths, nil
}

func keySet(m map[int]int) map[int]bool {
	out := make(map[int]bool, len(m))
	for k := range m {
		out[k] = true
	}
	return out
}

func fetchQualities() (map[int]int, map[int]bool, string, error) {
	client := &http.Client{Timeout: wagoTimeout}
	body, err := wagoGet(client, "/api/builds")
	if err != nil {
		return nil, nil, "", err
	}
	var builds map[string][]struct {
		Version   string `json:"version"`
		CreatedAt string `json:"created_at"`
	}
	err = json.NewDecoder(body).Decode(&builds)
	body.Close()
	if err != nil {
		return nil, nil, "", fmt.Errorf("api/builds: %w", err)
	}
	out, forever := map[int]int{}, map[int]bool{}
	var origin []string
	for _, product := range qualityProducts {
		build, newest := "", ""
		for _, b := range builds[product] {
			if b.CreatedAt > newest {
				build, newest = b.Version, b.CreatedAt
			}
		}
		if build == "" {
			return nil, nil, "", fmt.Errorf("wago.tools: kein Build für %s", product)
		}
		body, err := wagoGet(client, "/db2/ItemSparse/csv?build="+url.QueryEscape(build))
		if err != nil {
			return nil, nil, "", err
		}
		err = parseQualities(body, out)
		body.Close()
		if err != nil {
			return nil, nil, "", err
		}
		if product == qualityProducts[0] {
			forever = keySet(out)
		}
		origin = append(origin, product+" "+build)
	}
	return out, forever, strings.Join(origin, " + "), nil
}

// parseQualities liest ID und OverallQualityID aus einer ItemSparse-CSV; vorhandene Einträge bleiben.
func parseQualities(r io.Reader, out map[int]int) error {
	cr := csv.NewReader(r)
	cr.FieldsPerRecord = -1
	header, err := cr.Read()
	if err != nil {
		return fmt.Errorf("ItemSparse: %w", err)
	}
	idCol, qCol := -1, -1
	for i, name := range header {
		switch name {
		case "ID":
			idCol = i
		case "OverallQualityID":
			qCol = i
		}
	}
	if idCol < 0 || qCol < 0 {
		return fmt.Errorf("ItemSparse: Spalte ID oder OverallQualityID fehlt")
	}
	for {
		row, err := cr.Read()
		if err == io.EOF {
			return nil
		}
		if err != nil {
			return fmt.Errorf("ItemSparse: %w", err)
		}
		if len(row) <= max(idCol, qCol) {
			continue
		}
		id, err1 := strconv.Atoi(row[idCol])
		q, err2 := strconv.Atoi(row[qCol])
		if _, seen := out[id]; err1 == nil && err2 == nil && !seen {
			out[id] = q
		}
	}
}
