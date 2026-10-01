-- Zählt eigene Tode auf dem aktuellen Level. Totstellen (Jäger) löst PLAYER_DEAD nicht aus.
local _, ns = ...
local LevelStats = ns.LevelStats

ns.RegisterEvent("PLAYER_DEAD", function()
  LevelStats.Increment(LevelStats.DEATHS)
end)
