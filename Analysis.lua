-- Auswertungen für die Graphen: bereitet Historie und Journal eines Charakters zu Datenreihen auf.
-- Jede Funktion liefert items = { { label, value, text, highlight } }:
-- label = Beschriftung, value = Zahl für die Balkenlänge, text = Anzeige des Werts,
-- highlight = hervorheben (laufendes Level, heutiger Tag).
local _, ns = ...
local L = ns.L
local Format = ns.Format
local Experience = ns.Experience
local History = ns.History

local Analysis = {}
ns.Analysis = Analysis

local MAX_LEVEL_BARS = 30  -- neueste Level; mehr Balken werden zu schmal
local KILL_DAYS = 14
local TOP_COUNT = 10
local SECONDS_PER_DAY = 86400

-- Level aufsteigend, höchstens die neuesten MAX_LEVEL_BARS
local function levelRecordsAscending(characterKey)
  local newestFirst = History.GetLevelRecords(characterKey)
  local records = {}
  for i = math.min(#newestFirst, MAX_LEVEL_BARS), 1, -1 do
    table.insert(records, newestFirst[i])
  end
  return records
end

function Analysis.TimePerLevel(characterKey)
  local items = {}
  for _, record in ipairs(levelRecordsAscending(characterKey)) do
    table.insert(items, {
      label = tostring(record.level),
      value = record.seconds or 0,
      text = record.seconds and Format.Duration(record.seconds) or "?",
      highlight = record.isCurrent,
    })
  end
  return items
end

function Analysis.XpRatePerLevel(characterKey)
  local items = {}
  for _, record in ipairs(levelRecordsAscending(characterKey)) do
    local rate = Experience.CalculateRate(record.xp, record.seconds)
    table.insert(items, {
      label = tostring(record.level),
      value = rate or 0,
      text = rate and Format.Number(rate) or "-",
      highlight = record.isCurrent,
    })
  end
  return items
end

-- Mitternacht des Tages, in dem timestamp liegt
local function startOfDay(timestamp)
  local day = date("*t", timestamp)
  return time({ year = day.year, month = day.month, day = day.day, hour = 0 })
end

-- Kills der letzten KILL_DAYS Tage (heute zuletzt), auch Tage ohne Kills
function Analysis.KillsPerDay(characterKey)
  local today = startOfDay(time())
  local firstDay = today - (KILL_DAYS - 1) * SECONDS_PER_DAY
  local counts = {}
  for _, kill in ipairs(History.GetCharacter(characterKey).killLog) do
    if kill.time >= firstDay then
      local index = math.floor((startOfDay(kill.time) - firstDay) / SECONDS_PER_DAY + 0.5) + 1
      counts[index] = (counts[index] or 0) + 1
    end
  end

  local items = {}
  for index = 1, KILL_DAYS do
    local count = counts[index] or 0
    table.insert(items, {
      label = date(L.DAY_FORMAT, firstDay + (index - 1) * SECONDS_PER_DAY),
      value = count,
      text = tostring(count),
      highlight = index == KILL_DAYS,
    })
  end
  return items
end

-- Häufigkeit je Name, die TOP_COUNT häufigsten absteigend (bei Gleichstand alphabetisch).
-- text zeigt Anzahl und Anteil an allen Einträgen, z.B. "11 (13%)".
local function topCounts(entries, nameOf)
  local counts = {}
  for _, entry in ipairs(entries) do
    local name = nameOf(entry)
    counts[name] = (counts[name] or 0) + 1
  end

  local items = {}
  for name, count in pairs(counts) do
    table.insert(items, {
      label = name,
      value = count,
      text = string.format("%d (%s)", count, Format.Percent(count, #entries)),
    })
  end
  table.sort(items, function(a, b)
    if a.value ~= b.value then return a.value > b.value end
    return a.label < b.label
  end)
  while #items > TOP_COUNT do
    table.remove(items)
  end
  return items
end

-- Zonen mit der besten XP pro Stunde; kurze Aufenthalte sind zu ungenau und fallen weg
local MIN_ZONE_SECONDS = 300

function Analysis.XpRatePerZone(characterKey)
  local items = {}
  for _, record in ipairs(ns.Zones.GetRecords(characterKey)) do
    local rate = record.seconds >= MIN_ZONE_SECONDS and Experience.CalculateRate(record.xp, record.seconds)
    if rate then
      table.insert(items, { label = record.zone, value = rate, text = Format.Number(rate), highlight = record.isCurrent })
    end
  end
  while #items > TOP_COUNT do
    table.remove(items)
  end
  return items
end

function Analysis.TopKills(characterKey)
  return topCounts(History.GetCharacter(characterKey).killLog, function(kill)
    return kill.name or L.UNKNOWN_NAME
  end)
end

function Analysis.DeathCauses(characterKey)
  return topCounts(History.GetCharacter(characterKey).deathLog, History.DeathCauseText)
end
