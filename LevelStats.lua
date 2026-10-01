-- Zähler, die für das aktuelle Level gelten und beim Level-Up auf 0 gehen.
-- Gespeichert pro Charakter in ns.charDB.counters (Defaults in Database.lua).
local _, ns = ...

local LevelStats = {}
ns.LevelStats = LevelStats

LevelStats.PVE_KILLS = "pveKills"
LevelStats.PVP_KILLS = "pvpKills"
LevelStats.DEATHS = "deaths"
LevelStats.DEAD_SECONDS = "deadSeconds"
LevelStats.QUESTS = "quests"
LevelStats.XP_KILLS = "xpKills"
LevelStats.XP_QUESTS = "xpQuests"
LevelStats.XP_RESTED = "xpRested"
LevelStats.MONEY_EARNED = "moneyEarned"

function LevelStats.Get(counter)
  return ns.charDB.counters[counter] or 0
end

function LevelStats.Increment(counter, amount)
  local counters = ns.charDB.counters
  counters[counter] = (counters[counter] or 0) + (amount or 1)
end

function LevelStats.GetTotalKills()
  return LevelStats.Get(LevelStats.PVE_KILLS) + LevelStats.Get(LevelStats.PVP_KILLS)
end

-- Kopie aller Zähler, z.B. für die Level-Historie
function LevelStats.Snapshot()
  local copy = {}
  for counter, value in pairs(ns.charDB.counters) do
    copy[counter] = value
  end
  return copy
end

local function resetForLevel(level)
  ns.charDB.level = level
  for counter in pairs(ns.charDB.counters) do
    ns.charDB.counters[counter] = 0
  end
end

-- Level hat sich geändert, während das Addon nicht lief (oder erster Start)
ns.OnLogin(function()
  if ns.charDB.level ~= ns.level then
    resetForLevel(ns.level)
  end
end)

ns.OnLevelStarted(resetForLevel)
