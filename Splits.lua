-- Splits wie bei LiveSplit: Zeit je Level gegen eine Vergleichszeit für dieses Level.
-- Vergleich (Einstellung splitComparison):
--   "best"       schnellste Zeit je Level über alle anderen Charaktere ("Sum of Best")
--   "pb"         persönliche Bestzeit: der andere Charakter, der am schnellsten bis zum aktuellen Level kam
--                (Summe seiner Level-Zeiten ab dem ersten eigenen Level; er braucht alle diese Level)
--   "character"  ein fester Charakter (db.splitCharacter, gesetzt mit /lt compare Name)
-- Abweichung < 0 = schneller als der Vergleich. Ohne Vergleichswert für ein Level gibt es keinen Split.
local _, ns = ...
local Stats = ns.Stats
local History = ns.History

local Splits = {
  BEST = "best",
  PERSONAL_BEST = "pb",
  CHARACTER = "character",
}
ns.Splits = Splits

---------------------------------------------------------------------------
-- Vergleichszeiten
---------------------------------------------------------------------------

-- Abgeschlossene Level-Zeiten eines Charakters: level -> Sekunden
local function levelTimes(characterKey)
  local times = {}
  for _, record in ipairs(History.GetLevelRecords(characterKey)) do
    if not record.isCurrent and record.seconds then times[record.level] = record.seconds end
  end
  return times
end

local function otherCharacters()
  local keys = {}
  for _, key in ipairs(History.GetCharacterKeys()) do
    if key ~= ns.characterKey then table.insert(keys, key) end
  end
  return keys
end

local function bestPerLevel()
  local best = {}
  for _, key in ipairs(otherCharacters()) do
    for level, seconds in pairs(levelTimes(key)) do
      if not best[level] or seconds < best[level] then best[level] = seconds end
    end
  end
  return best
end

-- Erstes Level, ab dem der eingeloggte Charakter Zeiten hat (Addon evtl. später installiert)
local function firstOwnLevel()
  local first = ns.level
  for level in pairs(ns.character.levelHistory) do
    first = math.min(first, level)
  end
  return first
end

-- Summe der Zeiten von Level from bis to; nil, wenn eines davon fehlt
local function sumOfLevels(times, from, to)
  local sum = 0
  for level = from, to do
    if not times[level] then return nil end
    sum = sum + times[level]
  end
  return sum
end

-- Zeiten des schnellsten anderen Charakters bis einschließlich des aktuellen Levels
local function personalBest()
  local from = firstOwnLevel()
  local bestTimes, bestSum
  for _, key in ipairs(otherCharacters()) do
    local times = levelTimes(key)
    local sum = sumOfLevels(times, from, ns.level)
    if sum and (not bestSum or sum < bestSum) then bestTimes, bestSum = times, sum end
  end
  return bestTimes or {}
end

local function fixedCharacter()
  local key = ns.db.splitCharacter
  if not key or key == ns.characterKey or not History.GetCharacter(key) then return {} end
  return levelTimes(key)
end

local REFERENCES = {
  [Splits.BEST] = bestPerLevel,
  [Splits.PERSONAL_BEST] = personalBest,
  [Splits.CHARACTER] = fixedCharacter,
}

-- Neu berechnet, wenn sich Vergleich, Level, eingeloggter Charakter oder die Zahl der Charaktere
-- ändert (Löschen). Innerhalb eines Levels bleibt der Vergleich damit fest.
local cachedTimes
local cachedFor

local function cacheKey()
  local count = 0
  for _ in pairs(ns.Database.GetCharacters()) do count = count + 1 end
  return table.concat({ ns.characterKey, count, ns.level, ns.db.splitComparison, ns.db.splitCharacter or "" }, ":")
end

local function referenceTimes()
  local key = cacheKey()
  if cachedTimes and cachedFor == key then return cachedTimes end
  local build = REFERENCES[ns.db.splitComparison] or REFERENCES[Splits.BEST]
  cachedTimes, cachedFor = build(), key
  return cachedTimes
end

---------------------------------------------------------------------------
-- Abweichungen
---------------------------------------------------------------------------
function Splits.GetReference(level)
  return referenceTimes()[level]
end

-- Abweichung des laufenden Levels zum Vergleich; nil ohne Vergleichswert oder solange /played fehlt
function Splits.GetCurrentDelta()
  local reference = Splits.GetReference(ns.level)
  local seconds = Stats.GetSeconds(Stats.LEVEL)
  if not reference or not seconds then return nil end
  return seconds - reference
end

-- Abweichung eines abgeschlossenen eigenen Levels; nil ohne Vergleichswert
function Splits.GetLevelDelta(level)
  local record = ns.character.levelHistory[level]
  local reference = Splits.GetReference(level)
  if not record or not record.seconds or not reference then return nil end
  return record.seconds - reference
end

-- Summe der Abweichungen aller Level mit Vergleichswert, inklusive des laufenden; nil ohne Vergleichswert
function Splits.GetTotalDelta()
  local total
  for level in pairs(ns.character.levelHistory) do
    local delta = Splits.GetLevelDelta(level)
    if delta then total = (total or 0) + delta end
  end
  local current = Splits.GetCurrentDelta()
  if current then total = (total or 0) + current end
  return total
end

-- Fester Vergleichs-Charakter per Name (erster Treffer, Groß-/Kleinschreibung egal); false ohne Treffer
function Splits.CompareWith(name)
  local wanted = name:lower()
  for _, key in ipairs(otherCharacters()) do
    local character = History.GetCharacter(key)
    if (character.name or ""):lower() == wanted then
      ns.db.splitCharacter = key
      ns.Set("splitComparison", Splits.CHARACTER)
      return true
    end
  end
  return false
end
