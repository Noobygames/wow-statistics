-- Summiert Einnahmen auf dem aktuellen Level (Beute, Quests, Verkäufe, Post).
-- Ausgaben werden nicht abgezogen.
local _, ns = ...
local LevelStats = ns.LevelStats

local lastMoney

ns.OnLogin(function()
  lastMoney = GetMoney()
end)

ns.RegisterEvent("PLAYER_MONEY", function()
  local current = GetMoney()
  if lastMoney and current > lastMoney then
    LevelStats.Increment(LevelStats.MONEY_EARNED, current - lastMoney)
  end
  lastMoney = current
end)
