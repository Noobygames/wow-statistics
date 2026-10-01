package main

import (
	"image"
	"image/color"
	"math"
)

// Zeichnung auf einer 512er-Leinwand: Stoppuhr mit steigenden Balken in den Addon-Farben.
// Wird beim Rendern auf die Zielgröße skaliert.
const canvas = 512.0

type style struct {
	background bool // dunkler Verlauf statt Transparenz (Logo) oder transparent (Icon)
	ticks      bool // feine Striche auf dem Zifferblatt; bei kleinen Größen weglassen
}

var (
	logoStyle = style{background: true, ticks: true}
	iconStyle = style{background: false, ticks: false}
)

type rgb struct{ r, g, b float64 }

func mix(a, b rgb, t float64) rgb {
	t = math.Max(0, math.Min(1, t))
	return rgb{a.r + (b.r-a.r)*t, a.g + (b.g-a.g)*t, a.b + (b.b-a.b)*t}
}

var (
	bgInner   = rgb{0.10, 0.12, 0.22}
	bgOuter   = rgb{0.03, 0.035, 0.07}
	goldDark  = rgb{0.62, 0.43, 0.12}
	goldLight = rgb{0.98, 0.83, 0.42}
	faceColor = rgb{0.05, 0.06, 0.12}
	tickColor = rgb{0.85, 0.68, 0.32}
)

const (
	centerX, centerY = 256.0, 290.0
	ringOuter        = 178.0
	ringInner        = 150.0
	tickOuter        = 140.0
	tickInner        = 124.0
	barBottom        = 360.0
	barWidth         = 44.0
)

var bars = []struct{ x, height float64 }{
	{178, 62},
	{234, 108},
	{290, 158},
}

func inRoundRect(x, y, x0, y0, x1, y1, radius float64) bool {
	if x < x0 || x > x1 || y < y0 || y > y1 {
		return false
	}
	nx := math.Max(x0+radius, math.Min(x, x1-radius))
	ny := math.Max(y0+radius, math.Min(y, y1-radius))
	return math.Hypot(x-nx, y-ny) <= radius
}

// Gold mit Verlauf von oben (hell) nach unten (dunkel)
func gold(y, top, bottom float64) rgb {
	return mix(goldLight, goldDark, (y-top)/(bottom-top))
}

func inCrown(x, y float64) bool {
	return inRoundRect(x, y, 230, 72, 282, 118, 6) || inRoundRect(x, y, 208, 52, 304, 80, 10)
}

// Seitenknopf, um 45° gedreht
func inSideButton(x, y float64) bool {
	rx, ry := x-centerX, y-centerY
	angle := -math.Pi / 4
	ux := rx*math.Cos(angle) - ry*math.Sin(angle)
	uy := rx*math.Sin(angle) + ry*math.Cos(angle)
	return inRoundRect(ux, uy, -16, -ringOuter-26, 16, -ringOuter+4, 5)
}

func onTick(x, y, dist float64) bool {
	if dist < tickInner || dist > tickOuter {
		return false
	}
	step := math.Pi / 6
	offset := math.Abs(math.Remainder(math.Atan2(y-centerY, x-centerX), step))
	return offset*dist < 3.2
}

// sample liefert Farbe und Deckkraft (0 = transparent) an einem Punkt der Leinwand
func sample(x, y float64, s style) (rgb, float64) {
	c, alpha := rgb{}, 0.0
	if s.background {
		c, alpha = mix(bgInner, bgOuter, math.Hypot(x-256, y-256)/360), 1
	}

	// Reihenfolge = Ebenen von oben nach unten: der Ring verdeckt Krone und Seitenknopf
	dist := math.Hypot(x-centerX, y-centerY)
	switch {
	case dist <= ringOuter && dist >= ringInner:
		return gold(y, centerY-ringOuter, centerY+ringOuter), 1
	case inCrown(x, y):
		return gold(y, 52, 140), 1
	case inSideButton(x, y):
		return gold(y, 52, 200), 1
	case dist < ringInner:
		for _, bar := range bars {
			if inRoundRect(x, y, bar.x, barBottom-bar.height, bar.x+barWidth, barBottom, 6) {
				return gold(y, barBottom-180, barBottom), 1
			}
		}
		if s.ticks && onTick(x, y, dist) {
			return tickColor, 1
		}
		return mix(faceColor, bgInner, dist/ringInner*0.6), 1
	}
	return c, alpha
}

// render zeichnet mit Supersampling (Kantenglättung) in der gewünschten Größe
func render(size int, s style) *image.NRGBA {
	const supersample = 4
	img := image.NewNRGBA(image.Rect(0, 0, size, size))
	scale := canvas / float64(size)

	for py := 0; py < size; py++ {
		for px := 0; px < size; px++ {
			var r, g, b, a float64
			for sy := 0; sy < supersample; sy++ {
				for sx := 0; sx < supersample; sx++ {
					x := (float64(px) + (float64(sx)+0.5)/supersample) * scale
					y := (float64(py) + (float64(sy)+0.5)/supersample) * scale
					c, alpha := sample(x, y, s)
					r += c.r * alpha
					g += c.g * alpha
					b += c.b * alpha
					a += alpha
				}
			}
			if a == 0 {
				continue
			}
			n := float64(supersample * supersample)
			img.SetNRGBA(px, py, color.NRGBA{
				R: uint8(r / a * 255),
				G: uint8(g / a * 255),
				B: uint8(b / a * 255),
				A: uint8(a / n * 255),
			})
		}
	}
	return img
}
