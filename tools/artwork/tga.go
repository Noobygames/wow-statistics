package main

import (
	"encoding/binary"
	"image"
	"io"
)

// writeTGA schreibt ein unkomprimiertes 32-Bit-TGA mit Alphakanal, wie es alle WoW-Clients laden.
// Zeilen von unten nach oben (TGA-Standard), Kantenlängen sollten Zweierpotenzen sein.
func writeTGA(w io.Writer, img *image.NRGBA) error {
	bounds := img.Bounds()
	width, height := bounds.Dx(), bounds.Dy()

	header := make([]byte, 18)
	header[2] = 2 // unkomprimiert, Truecolor
	binary.LittleEndian.PutUint16(header[12:], uint16(width))
	binary.LittleEndian.PutUint16(header[14:], uint16(height))
	header[16] = 32   // Bit pro Pixel
	header[17] = 0x08 // 8 Bit Alpha, Ursprung unten links
	if _, err := w.Write(header); err != nil {
		return err
	}

	row := make([]byte, width*4)
	for y := height - 1; y >= 0; y-- {
		for x := 0; x < width; x++ {
			c := img.NRGBAAt(bounds.Min.X+x, bounds.Min.Y+y)
			row[x*4+0] = c.B
			row[x*4+1] = c.G
			row[x*4+2] = c.R
			row[x*4+3] = c.A
		}
		if _, err := w.Write(row); err != nil {
			return err
		}
	}
	return nil
}
