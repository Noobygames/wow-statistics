-- Summiert Einnahmen (Beute, Quests, Verkäufe, Post).
-- Ausgaben werden nicht abgezogen.
local _, ns = ...
local Stats = ns.Stats

local lastMoney

ns.OnLogin(function()
  lastMoney = GetMoney()
end)

ns.RegisterEvent("PLAYER_MONEY", function()
  local current = GetMoney()
  if lastMoney and current > lastMoney then
    Stats.Increment(Stats.MONEY_EARNED, current - lastMoney)
  end
  lastMoney = current
end)
