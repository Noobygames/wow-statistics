-- Formatierung von Zahlen, Zeiten und Geld für die Anzeige.
local _, ns = ...

local Format = {}
ns.Format = Format

local SECONDS_PER_MINUTE = 60
local SECONDS_PER_HOUR = 3600
local SECONDS_PER_DAY = 86400
local COPPER_PER_SILVER = 100
local COPPER_PER_GOLD = 10000

local function splitDuration(totalSeconds)
  totalSeconds = math.floor(totalSeconds)
  return math.floor(totalSeconds / SECONDS_PER_DAY),
    math.floor(totalSeconds / SECONDS_PER_HOUR) % 24,
    math.floor(totalSeconds / SECONDS_PER_MINUTE) % 60,
    totalSeconds % 60
end

-- Laufende Uhr mit Sekunden: "01h 02m 03s", ab einem Tag "1d 01h 02m 03s"
function Format.Clock(totalSeconds)
  local days, hours, minutes, seconds = splitDuration(totalSeconds)
  if days > 0 then
    return string.format("%dd %02dh %02dm %02ds", days, hours, minutes, seconds)
  end
  return string.format("%02dh %02dm %02ds", hours, minutes, seconds)
end

-- Kompakte Dauer mit den zwei größten Einheiten: "2d 3h", "1h 05m", "4m 10s", "35s"
function Format.Duration(totalSeconds)
  local days, hours, minutes, seconds = splitDuration(totalSeconds)
  if days > 0 then
    return string.format("%dd %dh", days, hours)
  elseif hours > 0 then
    return string.format("%dh %02dm", hours, minutes)
  elseif minutes > 0 then
    return string.format("%dm %02ds", minutes, seconds)
  end
  return string.format("%ds", seconds)
end

-- Große Zahlen kürzen: 950, 12.3k, 1.2M
function Format.Number(value)
  if value >= 1000000 then
    return string.format("%.1fM", value / 1000000)
  elseif value >= 1000 then
    return string.format("%.1fk", value / 1000)
  end
  return string.format("%d", value)
end

-- Anteil in Prozent, "-" wenn es keine Gesamtmenge gibt
function Format.Percent(part, total)
  if total <= 0 then return "-" end
  return string.format("%d%%", math.floor(part / total * 100 + 0.5))
end

-- Geld mit Münzsymbolen
function Format.Money(copper)
  copper = math.floor(copper)
  if GetCoinTextureString then
    return GetCoinTextureString(copper)
  end
  return string.format("%dg %ds %dc",
    math.floor(copper / COPPER_PER_GOLD),
    math.floor(copper / COPPER_PER_SILVER) % 100,
    copper % 100)
end

-- Nur volles Gold, für schmale Tabellenspalten
function Format.Gold(copper)
  return string.format("%dg", math.floor(copper / COPPER_PER_GOLD))
end

-- Text ohne Farbcodes und Link-Markup (z.B. Item-Links), für Suche und Export
function Format.PlainText(value)
  local text = tostring(value or "")
  text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|cnIQ%d+:", ""):gsub("|r", "")
  text = text:gsub("|H.-|h", ""):gsub("|h", "")
  return text
end
