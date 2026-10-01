-- Historie und Auswertung: Level-, Session-, Kill- und Tod-Einträge aller Charaktere.
--
-- Kill- und Tod-Einträge: siehe Journal.lua
-- Level-Eintrag:   { level, seconds, xp, counters, completedAt, totalPlayed }
-- Session-Eintrag: { startedAt, endedAt, seconds, startLevel, endLevel, xp, counters }
-- isCurrent markiert das noch laufende Level bzw. die laufende Session.
-- Für den eingeloggten Charakter sind das Live-Werte, für andere der Stand ihres letzten Logouts.
local _, ns = ...
local L = ns.L
local Stats = ns.Stats

local History = {}
ns.History = History

local function isLoggedIn(characterKey)
  return characterKey == ns.characterKey
end

-- Einträge einer Liste (älteste zuerst gespeichert), neueste zuerst
local function newestFirst(list)
  local records = {}
  for i = #list, 1, -1 do
    table.insert(records, list[i])
  end
  return records
end

function History.GetCharacter(characterKey)
  return ns.Database.GetCharacters()[characterKey]
end

-- Eingeloggter Charakter zuerst, danach alphabetisch
function History.GetCharacterKeys()
  local keys = {}
  for key in pairs(ns.Database.GetCharacters()) do
    if not isLoggedIn(key) then table.insert(keys, key) end
  end
  table.sort(keys)
  table.insert(keys, 1, ns.characterKey)
  return keys
end

local function currentLevelRecord(characterKey)
  if isLoggedIn(characterKey) then
    return {
      level = ns.level,
      seconds = Stats.GetSeconds(Stats.LEVEL),
      xp = Stats.GetXp(Stats.LEVEL),
      counters = Stats.Snapshot(Stats.LEVEL),
      isCurrent = true,
    }
  end
  local saved = History.GetCharacter(characterKey).currentLevel
  return { level = saved.level, seconds = saved.seconds, xp = saved.xp, counters = saved.counters, isCurrent = true }
end

local function currentSessionRecord(characterKey)
  local session = History.GetCharacter(characterKey).currentSession
  if not session.startedAt then return nil end
  local record = ns.Session.ToRecord(session)
  if isLoggedIn(characterKey) then
    record.seconds = ns.Session.GetSeconds()
    record.endLevel = ns.level
    record.xp = Stats.GetXp(Stats.SESSION)
    record.counters = Stats.Snapshot(Stats.SESSION)
    record.isCurrent = true
  end
  return record
end

-- Neueste zuerst, laufendes Level vorne
function History.GetLevelRecords(characterKey)
  local records = {}
  for _, record in pairs(History.GetCharacter(characterKey).levelHistory) do
    table.insert(records, record)
  end
  table.sort(records, function(a, b) return a.level > b.level end)
  table.insert(records, 1, currentLevelRecord(characterKey))
  return records
end

-- Neueste zuerst, laufende (bzw. letzte) Session vorne
function History.GetSessionRecords(characterKey)
  local records = newestFirst(History.GetCharacter(characterKey).sessionHistory)
  local current = currentSessionRecord(characterKey)
  if current then table.insert(records, 1, current) end
  return records
end

-- Timeline: nur abgeschlossene Level, neueste zuerst. reachedLevel = das damit erreichte Level.
function History.GetMilestones(characterKey)
  local milestones = {}
  for _, record in ipairs(History.GetLevelRecords(characterKey)) do
    if not record.isCurrent then
      table.insert(milestones, {
        reachedLevel = record.level + 1,
        reachedAt = record.completedAt,
        totalPlayed = record.totalPlayed,
        seconds = record.seconds,
      })
    end
  end
  return milestones
end

-- Kills und Tode einzeln (Form siehe Journal.lua), neueste zuerst
function History.GetKillLog(characterKey)
  return newestFirst(History.GetCharacter(characterKey).killLog)
end

function History.GetDeathLog(characterKey)
  return newestFirst(History.GetCharacter(characterKey).deathLog)
end

-- Todesursache als Text: Umgebung (z.B. "Sturz"), "Verursacher (Zauber)" oder "Unbekannt"
function History.DeathCauseText(entry)
  if entry.environment then
    local key = "CAUSE_" .. string.upper(entry.environment)
    local text = L[key]
    return text ~= key and text or entry.environment  -- L liefert bei fehlendem Text den Schlüssel
  end
  if entry.killer and entry.spell then
    return string.format("%s (%s)", entry.killer, entry.spell)
  end
  return entry.killer or entry.spell or L.CAUSE_UNKNOWN
end

-- Auswertung: Summe über Einträge (Zeit, XP und alle Zähler)
function History.Summarize(records)
  local summary = { seconds = 0, xp = 0, counters = {}, count = #records }
  for _, record in ipairs(records) do
    summary.seconds = summary.seconds + (record.seconds or 0)
    summary.xp = summary.xp + (record.xp or 0)
    for counter, value in pairs(record.counters) do
      summary.counters[counter] = (summary.counters[counter] or 0) + value
    end
  end
  return summary
end

-- Läuft vor dem Zurücksetzen der Zähler. UnitXPMax liefert hier noch den Bedarf des alten Levels.
-- seconds/totalPlayed sind nil, falls /played noch nicht geantwortet hatte.
ns.OnLevelCompleted(function(completedLevel)
  ns.character.levelHistory[completedLevel] = {
    level = completedLevel,
    seconds = Stats.GetSeconds(Stats.LEVEL),
    xp = UnitXPMax("player"),
    counters = Stats.Snapshot(Stats.LEVEL),
    completedAt = time(),                           -- Zeitpunkt, an dem das nächste Level erreicht wurde
    totalPlayed = ns.PlayedTime.GetTotalSeconds(),  -- /played gesamt in diesem Moment
  }
end)
