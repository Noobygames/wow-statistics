-- Zähler, die für das aktuelle Level gelten und beim Level-Up auf 0 gehen.
-- Gespeichert pro Charakter in ns.charDB.counters.
local _, ns = ...

local LevelStats = {}
ns.LevelStats = LevelStats

LevelStats.PVE_KILLS = "pveKills"
LevelStats.PVP_KILLS = "pvpKills"
LevelStats.DEATHS = "deaths"

function LevelStats.Get(counter)
  return ns.charDB.counters[counter] or 0
end

function LevelStats.Increment(counter, amount)
  local counters = ns.charDB.counters
  counters[counter] = (counters[counter] or 0) + (amount or 1)
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

ns.RegisterEvent("PLAYER_LEVEL_UP", function(newLevel)
  resetForLevel(newLevel)
end)
