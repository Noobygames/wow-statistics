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

---------------------------------------------------------------------------
-- Haltbarkeit
---------------------------------------------------------------------------
wow.state.freeSlots[0] = { 10, 0 }
wow.state.durability = { [1] = { 50, 60 }, [5] = { 10, 100 } }
expectNear("niedrigste", GearWarnings.GetLowestDurability(), 0.1, 0.001)
addon.Set("warnDurability", true)
GearWarnings.Check()
expect("Haltbarkeit-Warnung", count(L.WARN_DURABILITY), 1)
GearWarnings.Check()
expect("nur einmal", count(L.WARN_DURABILITY), 1)
wow.state.durability = { [5] = { 100, 100 } }
GearWarnings.Check()
expect("repariert: still", count(L.WARN_DURABILITY), 1)

---------------------------------------------------------------------------
-- Lehrer besuchen: gerade Level, nicht in Retail
---------------------------------------------------------------------------
local function trainerReminders()
  local found = 0
  for _, line in ipairs(wow.printed) do
    if line:find("neue Zauber beim Lehrer", 1, true) then found = found + 1 end
  end
  return found
end

addon.Set("remindTrainer", true)
expect("Retail: nicht verfügbar", addon.TrainerReminder.IsAvailable(), false)
wow.levelUp(12)
expect("Retail: still", trainerReminders(), 0)

wow.state.interface = 11509
wow.levelUp(13)
expect("ungerade: still", trainerReminders(), 0)
wow.levelUp(14)
expect("gerade: Hinweis", trainerReminders(), 1)
expect("mit Level", LevelTimerAlert.text:GetText(), string.format(L.REMIND_TRAINER, 14))

wow.state.interface = 16001
expect("Forever: verfügbar", addon.TrainerReminder.IsAvailable(), true)
