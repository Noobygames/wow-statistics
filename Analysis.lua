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

-- Kills der letzten KILL_DAYS Tage (heute zuletzt), auch Tage ohne Kills
function Analysis.KillsPerDay(characterKey)
  local today = ns.Daily.StartOfDay(time())
  local firstDay = today - (KILL_DAYS - 1) * SECONDS_PER_DAY
  local counts = {}
  for _, kill in ipairs(History.GetCharacter(characterKey).killLog) do
    if kill.time >= firstDay then
      local index = math.floor((ns.Daily.StartOfDay(kill.time) - firstDay) / SECONDS_PER_DAY + 0.5) + 1
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

---------------------------------------------------------------------------
-- Spielzeit pro Tag und Woche aus den Tageswerten (Daily.lua)
---------------------------------------------------------------------------
local PLAYTIME_DAYS = 14
local PLAYTIME_WEEKS = 8
local DAYS_PER_WEEK = 7

local function playTimeItem(label, seconds, highlight)
  return { label = label, value = seconds, text = Format.Duration(seconds), highlight = highlight }
end

-- Spielzeit der Tage ab firstDay (Mitternacht), dayCount Tage
local function sumPlayTime(dailyStats, firstDay, dayCount)
  local seconds = 0
  for offset = 0, dayCount - 1 do
    local entry = dailyStats[ns.Daily.DayKey(firstDay + offset * SECONDS_PER_DAY)]
    seconds = seconds + (entry and entry.seconds or 0)
  end
  return seconds
end

function Analysis.PlayTimePerDay(characterKey)
  local dailyStats = ns.Daily.GetStats(characterKey)
  local today = ns.Daily.StartOfDay(time())
  local items = {}
  for index = 1, PLAYTIME_DAYS do
    local day = today - (PLAYTIME_DAYS - index) * SECONDS_PER_DAY
    table.insert(items, playTimeItem(date(L.DAY_FORMAT, day), sumPlayTime(dailyStats, day, 1), index == PLAYTIME_DAYS))
  end
  return items
end

-- Wochen beginnen am Montag; Beschriftung = Datum des Montags
function Analysis.PlayTimePerWeek(characterKey)
  local dailyStats = ns.Daily.GetStats(characterKey)
  local today = ns.Daily.StartOfDay(time())
  local daysSinceMonday = (date("*t", today).wday + 5) % DAYS_PER_WEEK  -- wday: 1 = Sonntag
  local thisWeek = today - daysSinceMonday * SECONDS_PER_DAY
  local items = {}
  for index = 1, PLAYTIME_WEEKS do
    local week = thisWeek - (PLAYTIME_WEEKS - index) * DAYS_PER_WEEK * SECONDS_PER_DAY
    local seconds = sumPlayTime(dailyStats, week, DAYS_PER_WEEK)
    table.insert(items, playTimeItem(date(L.DAY_FORMAT, week), seconds, index == PLAYTIME_WEEKS))
  end
  return items
end

---------------------------------------------------------------------------
-- XP-Verlauf der laufenden (bei anderen Charakteren: letzten) Session in Abschnitten
---------------------------------------------------------------------------
local MAX_TIMELINE_STEPS = 36  -- 3 Stunden bei 5-Minuten-Abschnitten

-- Beschriftung "h:mm" für den Beginn eines Abschnitts
local function sessionClock(seconds)
  return string.format("%d:%02d", math.floor(seconds / 3600), math.floor(seconds / 60) % 60)
end

function Analysis.SessionXpTimeline(characterKey)
  local session = History.GetCharacter(characterKey).currentSession
  local timeline = session.xpTimeline or {}
  local step = ns.Session.TIMELINE_STEP

  local lastStep = 0
  if characterKey == ns.characterKey and session.startedAt then
    lastStep = math.floor(ns.Session.GetSeconds() / step) + 1
  else
    for index in pairs(timeline) do
      lastStep = math.max(lastStep, index)
    end
  end
  if next(timeline) == nil then return {} end

  local items = {}
  for index = math.max(1, lastStep - MAX_TIMELINE_STEPS + 1), lastStep do
    local xp = timeline[index] or 0
    table.insert(items, {
      label = sessionClock((index - 1) * step),
      value = xp,
      text = Format.Number(xp),
      highlight = index == lastStep and characterKey == ns.characterKey,
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
