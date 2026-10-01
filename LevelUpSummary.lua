-- Chatzeile beim Level-Up mit den Werten des abgeschlossenen Levels (Einstellung levelUpSummary).
-- Läuft in OnLevelCompleted, also bevor die Zähler für das neue Level zurückgesetzt werden.
local _, ns = ...
local L = ns.L
local Format = ns.Format
local Stats = ns.Stats
local Experience = ns.Experience

ns.OnLevelCompleted(function(completedLevel)
  if not ns.db.levelUpSummary then return end

  local seconds = Stats.GetSeconds(Stats.LEVEL)
  local rate = Experience.CalculateRate(UnitXPMax("player"), seconds)  -- UnitXPMax: Bedarf des alten Levels
  ns.Print(string.format(L.LEVEL_UP_SUMMARY,
    completedLevel + 1,
    completedLevel,
    seconds and Format.Duration(seconds) or "?",
    Stats.GetTotalKills(Stats.LEVEL),
    Stats.Get(Stats.LEVEL, Stats.DEATHS),
    rate and Format.Number(rate) or "-"))
end)
