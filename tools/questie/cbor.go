package main

// Minimaler CBOR-Decoder (RFC 8949) für die Zeilen, die QuestieDB mit C_EncodingUtil.SerializeCBOR
// in seine TOC schreibt. Lua-Tabellen kommen als Array (1-basierte Folge) oder Map an; beides
// wird über luaIndex gleich gelesen. Tags werden übersprungen, unbestimmte Längen unterstützt.

import (
	"encoding/binary"
	"fmt"
	"math"
)

type cborReader struct {
	data []byte
	pos  int
}

func decodeCBOR(data []byte) (any, error) {
	r := &cborReader{data: data}
	v, err := r.value()
	if err != nil {
		return nil, err
	}
	return v, nil
}

func (r *cborReader) byte() (byte, error) {
	if r.pos >= len(r.data) {
		return 0, fmt.Errorf("cbor: unerwartetes Ende")
	}
	b := r.data[r.pos]
	r.pos++
	return b, nil
}

func (r *cborReader) take(n uint64) ([]byte, error) {
	if uint64(len(r.data)-r.pos) < n {
		return nil, fmt.Errorf("cbor: unerwartetes Ende")
	}
	b := r.data[r.pos : r.pos+int(n)]
	r.pos += int(n)
	return b, nil
}

// argument liest die Länge/den Wert hinter dem Kopfbyte; indefinite = Info 31.
func (r *cborReader) argument(info byte) (uint64, bool, error) {
	switch {
	case info < 24:
		return uint64(info), false, nil
	case info == 31:
		return 0, true, nil
	case info > 27:
		return 0, false, fmt.Errorf("cbor: ungültige Info %d", info)
	}
	b, err := r.take(1 << (info - 24))
	if err != nil {
		return 0, false, err
	}
	var n uint64
	for _, c := range b {
		n = n<<8 | uint64(c)
	}
	return n, false, nil
}

const cborBreak = 0xff

func (r *cborReader) atBreak() bool {
	if r.pos < len(r.data) && r.data[r.pos] == cborBreak {
		r.pos++
		return true
	}
	return false
}

func (r *cborReader) value() (any, error) {
	head, err := r.byte()
	if err != nil {
		return nil, err
	}
	major, info := head>>5, head&0x1f
	if major == 7 {
		return r.simple(info)
	}
	n, indefinite, err := r.argument(info)
	if err != nil {
		return nil, err
	}
	switch major {
	case 0:
		return int64(n), nil
	case 1:
		return -1 - int64(n), nil
	case 2, 3:
		var buf []byte
		if indefinite {
			for !r.atBreak() {
				part, err := r.value()
				if err != nil {
					return nil, err
				}
				if p, ok := part.(string); ok {
					buf = append(buf, p...)
				}
			}
		} else if buf, err = r.take(n); err != nil {
			return nil, err
		}
		// Lua kennt nur einen String-Typ; Byte- und Text-Strings werden beide zu string.
		return string(buf), nil
	case 4:
		list := []any{}
		for i := uint64(0); indefinite || i < n; i++ {
			if indefinite && r.atBreak() {
				break
			}
			v, err := r.value()
			if err != nil {
				return nil, err
			}
			list = append(list, v)
		}
		return list, nil
	case 5:
		m := map[any]any{}
		for i := uint64(0); indefinite || i < n; i++ {
			if indefinite && r.atBreak() {
				break
			}
			k, err := r.value()
			if err != nil {
				return nil, err
			}
			v, err := r.value()
			if err != nil {
				return nil, err
			}
			m[k] = v
		}
		return m, nil
	case 6:
		return r.value() // Tag ohne Bedeutung für uns
	}
	return nil, fmt.Errorf("cbor: unbekannter Typ %d", major)
}

func (r *cborReader) simple(info byte) (any, error) {
	switch info {
	case 20:
		return false, nil
	case 21:
		return true, nil
	case 22, 23:
		return nil, nil
	case 25:
		b, err := r.take(2)
		if err != nil {
			return nil, err
		}
		return halfToFloat(binary.BigEndian.Uint16(b)), nil
	case 26:
		b, err := r.take(4)
		if err != nil {
			return nil, err
		}
		return float64(math.Float32frombits(binary.BigEndian.Uint32(b))), nil
	case 27:
		b, err := r.take(8)
		if err != nil {
			return nil, err
		}
		return math.Float64frombits(binary.BigEndian.Uint64(b)), nil
	}
	return nil, fmt.Errorf("cbor: unbekannter Simple-Wert %d", info)
}

func halfToFloat(h uint16) float64 {
	exp := int(h>>10) & 0x1f
	mant := float64(h & 0x3ff)
	var v float64
	switch exp {
	case 0:
		v = mant * math.Pow(2, -24)
	case 31:
		v = math.Inf(1)
		if mant != 0 {
			v = math.NaN()
		}
	default:
		v = (1 + mant/1024) * math.Pow(2, float64(exp-15))
	}
	if h&0x8000 != 0 {
		return -v
	}
	return v
}

// luaIndex liest t[i] einer Lua-Tabelle, egal ob sie als CBOR-Array oder Map kam.
func luaIndex(t any, i int) any {
	switch v := t.(type) {
	case []any:
		if i >= 1 && i <= len(v) {
			return v[i-1]
		}
	case map[any]any:
		return v[int64(i)]
	}
	return nil
}

// luaPairs liefert alle Einträge einer Lua-Tabelle mit ganzzahligem Schlüssel.
func luaPairs(t any) map[int]any {
	out := map[int]any{}
	switch v := t.(type) {
	case []any:
		for i, x := range v {
			out[i+1] = x
		}
	case map[any]any:
		for k, x := range v {
			if n, ok := k.(int64); ok {
				out[int(n)] = x
			}
		}
	}
	return out
}

// luaList liefert t[1..n] in Reihenfolge (Lücken enden die Folge wie bei ipairs).
func luaList(t any) []any {
	var out []any
	for i := 1; ; i++ {
		v := luaIndex(t, i)
		if v == nil {
			return out
		}
		out = append(out, v)
	}
}

func toInt(v any) (int, bool) {
	switch n := v.(type) {
	case int64:
		return int(n), true
	case float64:
		return int(n), true
	}
	return 0, false
}

func toFloat(v any) (float64, bool) {
	switch n := v.(type) {
	case int64:
		return float64(n), true
	case float64:
		return n, true
	}
	return 0, false
}

// intList liest eine ID-Liste (idarray) als []int.
func intList(t any) []int {
	var out []int
	for _, v := range luaList(t) {
		if n, ok := toInt(v); ok {
			out = append(out, n)
		}
	}
	return out
}
