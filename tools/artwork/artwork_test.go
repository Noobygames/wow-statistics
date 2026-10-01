package main

import (
	"bytes"
	"encoding/binary"
	"testing"
)

func TestIconIsTransparentAroundTheWatch(t *testing.T) {
	icon := render(iconSize, iconStyle)
	if a := icon.NRGBAAt(0, 0).A; a != 0 {
		t.Errorf("Ecke sollte transparent sein, Alpha = %d", a)
	}
	if a := icon.NRGBAAt(iconSize/2, iconSize*9/16).A; a != 255 {
		t.Errorf("Mitte sollte deckend sein, Alpha = %d", a)
	}
}

func TestLogoHasNoTransparency(t *testing.T) {
	logo := render(32, logoStyle)
	if a := logo.NRGBAAt(0, 0).A; a != 255 {
		t.Errorf("Logo-Hintergrund sollte deckend sein, Alpha = %d", a)
	}
}

func TestWriteTGA(t *testing.T) {
	icon := render(8, iconStyle)
	var buf bytes.Buffer
	if err := writeTGA(&buf, icon); err != nil {
		t.Fatal(err)
	}
	data := buf.Bytes()
	if len(data) != 18+8*8*4 {
		t.Fatalf("Größe = %d", len(data))
	}
	if data[2] != 2 || data[16] != 32 || data[17] != 0x08 {
		t.Errorf("Header = %v", data[:18])
	}
	if w, h := binary.LittleEndian.Uint16(data[12:]), binary.LittleEndian.Uint16(data[14:]); w != 8 || h != 8 {
		t.Errorf("Maße = %dx%d", w, h)
	}
}
