-- Geld: Einnahmen (Beute, Quests, Verkäufe, Post) und Ausgaben nach Art.
-- Ausgaben werden über das gerade offene Fenster zugeordnet: Händler, Flugmeister, Lehrer
-- (MERCHANT_*, TAXIMAP_*, TRAINER_*); eine Reparatur erkennt der Hook auf RepairAllItems (unser
-- Merchant.lua und Blizzards Button). Der Flug wird erst nach dem Schließen der Karte bezahlt,
-- daher gilt die Art noch CLOSE_GRACE Sekunden nach dem Schließen. Alles andere (Post,
-- Auktionshaus, Gilde, ...) zählt als Sonstiges. Einnahmen werden nicht mit Ausgaben verrechnet.
local _, ns = ...
local Stats = ns.Stats

local CLOSE_GRACE = 2  -- Sekunden, die eine Art nach dem Schließen ihres Fensters noch gilt

local lastMoney
local context        -- Zähler der Ausgaben-Art des offenen Fensters
local contextUntil   -- GetTime(), bis zu der context nach dem Schließen gilt; nil = offen
local repairPending  -- RepairAllItems wurde aufgerufen, die Abbuchung steht noch aus

local function openContext(counter)
  context, contextUntil = counter, nil
end

local function closeContext(counter)
  if context == counter then contextUntil = GetTime() + CLOSE_GRACE end
end

local function currentContext()
  if context and (not contextUntil or GetTime() <= contextUntil) then return context end
  return nil
end

local function spendingKind()
  if repairPending then
    repairPending = false
    return Stats.SPENT_REPAIR
  end
  return currentContext() or Stats.SPENT_OTHER
end

ns.OnLogin(function()
  lastMoney = GetMoney()
  context, contextUntil, repairPending = nil, nil, false
end)

ns.RegisterEvent("PLAYER_MONEY", function()
  local current = GetMoney()
  if lastMoney and current > lastMoney then
    Stats.Increment(Stats.MONEY_EARNED, current - lastMoney)
  elseif lastMoney and current < lastMoney then
    Stats.Increment(spendingKind(), lastMoney - current)
  end
  lastMoney = current
end)

-- Gildenbank-Reparaturen kosten den Charakter nichts
hooksecurefunc("RepairAllItems", function(useGuildBank)
  if not useGuildBank then repairPending = true end
end)

for counter, events in pairs({
  [Stats.SPENT_MERCHANT] = { "MERCHANT_SHOW", "MERCHANT_CLOSED" },
  [Stats.SPENT_TAXI] = { "TAXIMAP_OPENED", "TAXIMAP_CLOSED" },
  [Stats.SPENT_TRAINER] = { "TRAINER_SHOW", "TRAINER_CLOSED" },
}) do
  ns.RegisterEvent(events[1], function() openContext(counter) end)
  ns.RegisterEvent(events[2], function() closeContext(counter) end)
end
