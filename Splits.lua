-- Splits wie bei LiveSplit: Zeit je Level gegen die Bestzeit für dieses Level.
-- Bestzeit = schnellste abgeschlossene Zeit für das Level über alle anderen Charaktere ("Sum of Best").
-- Abweichung < 0 = schneller als die Bestzeit. Ohne Vergleichswert für ein Level gibt es keinen Split.
local _, ns = ...
local Stats = ns.Stats
local History = ns.History

local Splits = {}
ns.Splits = Splits

-- Bestzeiten je Level; neu berechnet, sobald sich die Zahl der Charaktere ändert (Löschen)
-- oder der eingeloggte Charakter wechselt. Andere Charaktere ändern sich sonst nicht.
local bestByLevel
local cachedFor  -- "Charakter-Schlüssel:Anzahl" der Berechnung

local function cacheKey()
  local count = 0
  for _ in pairs(ns.Database.GetCharacters()) do count = count + 1 end
  return ns.characterKey .. ":" .. count
end

local function bestTimes()
  local key = cacheKey()
  if bestByLevel and cachedFor == key then return bestByLevel end
  bestByLevel, cachedFor = {}, key
  for _, characterKey in ipairs(History.GetCharacterKeys()) do
    if characterKey ~= ns.characterKey then
      for _, record in ipairs(History.GetLevelRecords(characterKey)) do
        local best = bestByLevel[record.level]
        if not record.isCurrent and record.seconds and (not best or record.seconds < best) then
          bestByLevel[record.level] = record.seconds
        end
      end
    end
  end
  return bestByLevel
end

function Splits.GetBest(level)
  return bestTimes()[level]
end

-- Abweichung des laufenden Levels zur Bestzeit; nil ohne Bestzeit oder solange /played fehlt
function Splits.GetCurrentDelta()
  local best = Splits.GetBest(ns.level)
  local seconds = Stats.GetSeconds(Stats.LEVEL)
  if not best or not seconds then return nil end
  return seconds - best
end

-- Summe der Abweichungen aller Level mit Bestzeit, inklusive des laufenden; nil ohne Vergleichswert
function Splits.GetTotalDelta()
  local total
  for level, record in pairs(ns.character.levelHistory) do
    local best = Splits.GetBest(level)
    if best and record.seconds then
      total = (total or 0) + record.seconds - best
    end
  end
  local current = Splits.GetCurrentDelta()
  if current then total = (total or 0) + current end
  return total
end
