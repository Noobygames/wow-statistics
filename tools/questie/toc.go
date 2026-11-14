package main

// Liest den "Baked"-Speicher von QuestieDB: alle Datensätze stehen als TOC-Metadaten
// "## X-<Entity>-<id>-S: <base64 CBOR>" (Skalar-Zeile, Map Feldindex -> Wert) und
// "## X-<Entity>-<id>-<Feld>: <base64 CBOR>" (Tabellenfelder). Lange Werte sind gestückelt:
// Wert "~N~", Teile unter "<key>-1" .. "<key>-N". Die ID-Liste "X-<Entity>-IDS" ist zusätzlich
// zlib-komprimiert (C_EncodingUtil.DecompressString(..., Enum.CompressionMethod.Zlib)).
// Nachbau von src/read/baked.lua und src/meta/codec.lua aus QuestieDB.

import (
	"bufio"
	"bytes"
	"compress/zlib"
	"encoding/base64"
	"fmt"
	"io"
	"os"
	"regexp"
	"strconv"
	"strings"
)

type tocStore struct {
	values   map[string]string
	firstErr error // erster Dekodierfehler eines Tabellenfelds
}

const tocPrefix = "## "

func readTOC(path string) (*tocStore, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	return parseTOC(f)
}

func parseTOC(r io.Reader) (*tocStore, error) {
	store := &tocStore{values: map[string]string{}}
	sc := bufio.NewScanner(r)
	sc.Buffer(make([]byte, 1<<20), 1<<24)
	for sc.Scan() {
		line := strings.TrimRight(sc.Text(), "\r")
		if !strings.HasPrefix(line, tocPrefix) {
			continue
		}
		key, value, ok := strings.Cut(line[len("## "):], ":")
		if ok {
			store.values[strings.TrimSpace(key)] = strings.TrimSpace(value)
		}
	}
	return store, sc.Err()
}

var chunkHeader = regexp.MustCompile(`^~(\d+)~$`)

// stored setzt gestückelte Werte wieder zusammen (wie getStored in baked.lua).
func (s *tocStore) stored(key string) (string, bool, error) {
	value, ok := s.values[key]
	if !ok {
		return "", false, nil
	}
	m := chunkHeader.FindStringSubmatch(value)
	if m == nil {
		return value, true, nil
	}
	parts, _ := strconv.Atoi(m[1])
	var b strings.Builder
	for i := 1; i <= parts; i++ {
		part, ok := s.values[fmt.Sprintf("%s-%d", key, i)]
		if !ok {
			return "", false, fmt.Errorf("%s: Teil %d von %d fehlt", key, i, parts)
		}
		b.WriteString(part)
	}
	return b.String(), true, nil
}

// decoded liest einen Wert als base64 + CBOR; nil, wenn der Schlüssel fehlt.
func (s *tocStore) decoded(key string) (any, error) {
	value, ok, err := s.stored(key)
	if err != nil || !ok {
		return nil, err
	}
	raw, err := base64.StdEncoding.DecodeString(value)
	if err != nil {
		return nil, fmt.Errorf("%s: %w", key, err)
	}
	v, err := decodeCBOR(raw)
	if err != nil {
		return nil, fmt.Errorf("%s: %w", key, err)
	}
	return v, nil
}

// ids liest die zlib-komprimierte ID-Liste einer Entität.
func (s *tocStore) ids(entity string) ([]int, error) {
	key := "X-" + entity + "-IDS"
	value, ok, err := s.stored(key)
	if err != nil {
		return nil, err
	}
	if !ok {
		return nil, fmt.Errorf("%s fehlt", key)
	}
	raw, err := base64.StdEncoding.DecodeString(value)
	if err != nil {
		return nil, fmt.Errorf("%s: %w", key, err)
	}
	zr, err := zlib.NewReader(bytes.NewReader(raw))
	if err != nil {
		return nil, fmt.Errorf("%s: %w", key, err)
	}
	plain, err := io.ReadAll(zr)
	if err != nil {
		return nil, fmt.Errorf("%s: %w", key, err)
	}
	v, err := decodeCBOR(plain)
	if err != nil {
		return nil, fmt.Errorf("%s: %w", key, err)
	}
	return intList(v), nil
}

// record ist ein Datensatz: Skalar-Zeile plus nachgeladene Tabellenfelder.
type record struct {
	store  *tocStore
	prefix string
	row    any
}

func (s *tocStore) record(entity string, id int) (*record, error) {
	prefix := fmt.Sprintf("X-%s-%d-", entity, id)
	row, err := s.decoded(prefix + "S")
	if err != nil || row == nil {
		return nil, err
	}
	return &record{store: s, prefix: prefix, row: row}, nil
}

func (r *record) num(field int) int {
	n, _ := toInt(luaIndex(r.row, field))
	return n
}

func (r *record) str(field int) string {
	s, _ := luaIndex(r.row, field).(string)
	return s
}

// table liest ein Tabellenfeld aus seinem eigenen Metadaten-Schlüssel; Fehler merkt sich der Speicher.
func (r *record) table(field int) any {
	v, err := r.store.decoded(r.prefix + strconv.Itoa(field))
	if err != nil && r.store.firstErr == nil {
		r.store.firstErr = err
	}
	return v
}
