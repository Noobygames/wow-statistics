-- Hinweis auf fehlendes "Satt": nur eingeschaltet, beim Leveln, außerhalb von Kampf und Ruhegebiet,
-- mit Pause zwischen zwei Hinweisen.
local BuffReminder = addon.BuffReminder
local L = addon.L

local function reminders()
  local count = 0
  for _, line in ipairs(wow.printed) do
    if line:find(L.REMIND_FOOD, 1, true) then count = count + 1 end
  end
  return count
end

wow.login({ level = 10 })
expect("ohne Satt fehlt es", BuffReminder.IsFoodMissing(), true)
BuffReminder.Check()
expect("aus: kein Hinweis", reminders(), 0)

addon.Set("remindFood", true)
BuffReminder.Check()
expect("Hinweis", reminders(), 1)
expect("als Einblendung", LevelTimerAlert.text:GetText(), L.REMIND_FOOD)

BuffReminder.Check()
expect("Pause zwischen Hinweisen", reminders(), 1)

-- Nicht im Kampf, nicht im Ruhegebiet
wow.advance(301)
wow.state.inCombat = true
BuffReminder.Check()
expect("im Kampf still", reminders(), 1)
wow.state.inCombat = false
wow.state.resting = true
BuffReminder.Check()
expect("im Ruhegebiet still", reminders(), 1)
wow.state.resting = false

-- Mit Satt kein Hinweis (Name aus dem Client, hier deutsch)
wow.state.buffs = { "Seelenstärke", "Satt" }
expect("Satt erkannt", BuffReminder.IsFoodMissing(), false)
BuffReminder.Check()
expect("satt: still", reminders(), 1)

-- Buff abgelaufen: nach der Pause wieder
wow.state.buffs = {}
BuffReminder.Check()
expect("wieder hungrig", reminders(), 2)

-- Auf Max-Level kein Hinweis
wow.advance(301)
wow.state.level, addon.level = 60, 60
BuffReminder.Check()
expect("Max-Level still", reminders(), 2)

-- Unbekannter Zauber (anderer Client): nichts behaupten
wow.state.spellNames = {}
expect("ohne Namen unbekannt", BuffReminder.IsFoodMissing(), nil)

---------------------------------------------------------------------------
-- Camp-Buff "Lagervorteile" (Spell 1229741): Erkennung über die Spell-ID
---------------------------------------------------------------------------
-- Retail kennt kein Camp-System
expect("Retail: kein Camp", BuffReminder.IsCampMissing(), nil)
wow.state.interface = 16001  -- WoW Forever
wow.state.spellNames = { [19705] = "Satt", [1229741] = "Lagervorteile" }
wow.state.level, addon.level = 20, 20
wow.advance(301)
wow.state.buffs = { "Satt" }
expect("Camp fehlt", BuffReminder.IsCampMissing(), true)
addon.Set("remindCamp", true)
BuffReminder.Check()
expect("Camp-Hinweis", LevelTimerAlert.text:GetText(), L.REMIND_CAMP)

-- Aktiver Camp-Buff wird an der Spell-ID erkannt
wow.state.buffs = { "Satt", { name = "Lagervorteile", spellId = 1229741 } }
expect("Camp erkannt", BuffReminder.IsCampMissing(), false)

-- Beide fehlen: beide Hinweise in einer Einblendung
wow.advance(301)
wow.state.buffs = {}
BuffReminder.Check()
expect("beide zusammen", LevelTimerAlert.text:GetText(), L.REMIND_FOOD .. "\n" .. L.REMIND_CAMP)

-- Forever ohne den Zauber (älterer Build): nichts behaupten
wow.state.spellNames = { [19705] = "Satt" }
expect("ohne Camp-Zauber unbekannt", BuffReminder.IsCampMissing(), nil)

---------------------------------------------------------------------------
-- Abstand einstellbar: wiederholt, solange der Buff fehlt
---------------------------------------------------------------------------
wow.state.interface = 120100
wow.state.spellNames = { [19705] = "Satt" }
wow.state.buffs = {}
addon.Set("remindCamp", false)
addon.Set("reminderInterval", 2)
wow.advance(1000)
local count = reminders()
BuffReminder.Check()
expect("sofort nach langer Pause", reminders(), count + 1)
wow.advance(100)
BuffReminder.Check()
expect("vor Ablauf von 2 min still", reminders(), count + 1)
wow.advance(20)
BuffReminder.Check()
expect("nach 2 min wieder", reminders(), count + 2)
wow.advance(120)
BuffReminder.Check()
expect("und wieder", reminders(), count + 3)
