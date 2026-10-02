// Records holt die schnellsten Leveling-Läufe von speedrun.com und schreibt sie als Lua-Datei
// (SpeedrunRecords.lua), damit das Addon ohne Netzwerk dagegen vergleichen kann.
// Aufruf über "make records".
package main

import (
	"flag"
	"fmt"
	"net/http"
	"os"
	"time"
)

const requestTimeout = 30 * time.Second

func main() {
	out := flag.String("out", "SpeedrunRecords.lua", "Ziel-Datei (Lua)")
	baseURL := flag.String("api", "https://www.speedrun.com/api/v1", "speedrun.com API")
	flag.Parse()

	if err := run(*out, *baseURL); err != nil {
		fmt.Fprintln(os.Stderr, "Fehler:", err)
		os.Exit(1)
	}
	fmt.Println("Rekorde:", *out)
}

func run(out, baseURL string) error {
	fetcher := Fetcher{Client: &http.Client{Timeout: requestTimeout}, BaseURL: baseURL}
	all, err := fetcher.FetchAll()
	if err != nil {
		return err
	}
	file, err := os.Create(out)
	if err != nil {
		return err
	}
	defer file.Close()
	return WriteLua(file, all, time.Now().Format("2006-01-02"))
}
