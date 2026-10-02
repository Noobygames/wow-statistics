-- Warnungen beim Leveln: einmal beim Eintreten, wieder erst, nachdem der Zustand vorbei war.
local GearWarnings = addon.GearWarnings
local L = addon.L

local function count(message)
  local found = 0
  for _, line in ipairs(wow.printed) do
    if line:find(message, 1, true) then found = found + 1 end
  end
  return found
end

wow.login()

---------------------------------------------------------------------------
-- Taschen fast voll
---------------------------------------------------------------------------
wow.state.freeSlots = { [0] = { 1, 0 }, [1] = { 20, 4 } }  -- Tasche 1 = Köcher o.ä., zählt nicht
expect("freie Plätze", GearWarnings.GetFreeBagSlots(), 1)
GearWarnings.Check()
expect("aus: still", count(L.WARN_BAGS_FULL), 0)

addon.Set("warnBagsFull", true)
GearWarnings.Check()
expect("Warnung", count(L.WARN_BAGS_FULL), 1)
expect("Einblendung", LevelTimerAlert.text:GetText(), L.WARN_BAGS_FULL)
GearWarnings.Check()
expect("nur einmal", count(L.WARN_BAGS_FULL), 1)

wow.state.freeSlots[0] = { 10, 0 }
GearWarnings.Check()
wow.state.freeSlots[0] = { 0, 0 }
GearWarnings.Check()
expect("nach Platz wieder", count(L.WARN_BAGS_FULL), 2)
