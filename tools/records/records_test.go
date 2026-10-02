package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

const sampleBoard = `{"data":{"runs":[{"place":1,"run":{"weblink":"https://www.speedrun.com/x/runs/1","date":"2025-11-20",
"times":{"primary_t":3331.4},"players":[{"rel":"user","id":"p1"}],"values":{"yn219508":"jqzxj621"}}}],
"players":{"data":[{"id":"p1","names":{"international":"Runner \"One\""}}]}}}`

func TestFetchAllAndWriteLua(t *testing.T) {
	requests := 0
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requests++
		if r.URL.Query().Get("var-"+modeVarID) != softcoreID {
			t.Errorf("Softcore-Filter fehlt: %s", r.URL)
		}
		w.Write([]byte(sampleBoard))
	}))
	defer server.Close()

	all, err := Fetcher{Client: server.Client(), BaseURL: server.URL}.FetchAll()
	if err != nil {
		t.Fatal(err)
	}
	if want := len(brackets) * (1 + len(classValues)); requests != want {
		t.Errorf("Anfragen = %d, erwartet %d", requests, want)
	}
	best := all[0].Best
	if best.Seconds != 3331 || best.Class != "PALADIN" || best.Runner != `Runner "One"` {
		t.Errorf("Rekord = %+v", best)
	}

	var out strings.Builder
	if err := WriteLua(&out, all, "2026-10-02"); err != nil {
		t.Fatal(err)
	}
	lua := out.String()
	for _, want := range []string{`fetched = "2026-10-02"`, `label = "1-10"`, `level = 60`,
		`runner = "Runner \"One\""`, `PALADIN = { seconds = 3331`} {
		if !strings.Contains(lua, want) {
			t.Errorf("Lua enthält %q nicht:\n%s", want, lua)
		}
	}
}

func TestEmptyBoardIsSkipped(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(`{"data":{"runs":[],"players":{"data":[]}}}`))
	}))
	defer server.Close()

	all, err := Fetcher{Client: server.Client(), BaseURL: server.URL}.FetchAll()
	if err != nil {
		t.Fatal(err)
	}
	var out strings.Builder
	if err := WriteLua(&out, all, "2026-10-02"); err != nil {
		t.Fatal(err)
	}
	if strings.Contains(out.String(), "label =") {
		t.Errorf("leere Leaderboards dürfen nicht erscheinen:\n%s", out.String())
	}
}

func TestServerErrorIsReported(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		http.Error(w, "rate limited", http.StatusTooManyRequests)
	}))
	defer server.Close()

	if _, err := (Fetcher{Client: server.Client(), BaseURL: server.URL}).FetchAll(); err == nil {
		t.Error("Fehler des Servers muss gemeldet werden")
	}
}
