-- Level-Historie: sichert beim Level-Up Spielzeit, XP und alle Zähler des abgeschlossenen Levels.
-- Gespeichert in ns.charDB.history[level].
local _, ns = ...
local LevelStats = ns.LevelStats

local LevelHistory = {}
ns.LevelHistory = LevelHistory

-- Ein Eintrag hat dieselbe Form für abgeschlossene Level und das laufende Level
local function buildRecord(level, xp)
  return {
    level = level,
    seconds = ns.PlayedTime.GetLevelSeconds(),  -- nil, falls /played noch nicht geantwortet hatte
    xp = xp,
    counters = LevelStats.Snapshot(),
  }
end

-- Neueste zuerst; das laufende Level steht vorne und ist mit isCurrent markiert
function LevelHistory.GetRecords()
  local records = {}
  for _, record in pairs(ns.charDB.history) do
    table.insert(records, record)
  end
  table.sort(records, function(a, b) return a.level > b.level end)

  local current = buildRecord(ns.level, UnitXP("player"))
  current.isCurrent = true
  table.insert(records, 1, current)
  return records
end

-- Läuft vor dem Zurücksetzen der Zähler. UnitXPMax liefert hier noch den Bedarf des alten Levels.
ns.OnLevelCompleted(function(completedLevel)
  local record = buildRecord(completedLevel, UnitXPMax("player"))
  record.completedAt = time()
  ns.charDB.history[completedLevel] = record
end)
