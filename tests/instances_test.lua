-- Instanz-Läufe: Dauer, XP, Kills und Tode je Lauf; /reload setzt den Lauf fort.
local History = addon.History

local function enter(name, instanceType)
  wow.state.instance = name and { name = name, type = instanceType or "party" } or nil
  wow.fire("PLAYER_ENTERING_WORLD")
end

local function gainXp(amount)
  wow.state.xp = wow.state.xp + amount
  wow.fire("PLAYER_XP_UPDATE", "player")
end

wow.login({ level = 20, xp = 0, xpMax = 100000 })
enter(nil)
expect("offene Welt: kein Lauf", addon.character.currentRun, nil)

-- Die Todesminen: 30 min, 2 Kills, 1 Tod, 5000 XP; mittendrin /reload
enter("Die Todesminen")
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Defias-Schurke stirbt, Ihr bekommt 100 Erfahrung.")
gainXp(3000)
wow.advance(900)
wow.logout()
wow.advance(20)
wow.login()
enter("Die Todesminen")
expect("Reload setzt Lauf fort", #addon.character.instanceLog, 0)
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Edwin VanCleef stirbt, Ihr bekommt 500 Erfahrung.")
gainXp(2000)
wow.state.dead = true
wow.fire("PLAYER_DEAD")
wow.state.dead = false
wow.advance(900)

local current = History.GetInstanceLog(addon.characterKey)[1]
expect("laufender Lauf vorne", current.isCurrent, true)
expectNear("laufende Dauer ohne Reload-Pause", current.seconds, 1800)

-- Verlassen beendet den Lauf
enter(nil)
local run = addon.character.instanceLog[1]
expect("Lauf beendet", addon.character.currentRun, nil)
expect("Name", run.name, "Die Todesminen")
expectNear("Dauer", run.seconds, 1800)
expect("XP", run.xp, 5000)
expect("Kills", run.counters.kills, 2)
expect("Tode", run.counters.deaths, 1)
expect("Level beim Betreten", run.level, 20)

-- Kills in der offenen Welt zählen nicht zum Lauf; Raid wird ebenfalls erfasst
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Wolf stirbt, Ihr bekommt 10 Erfahrung.")
expect("Welt-Kill nicht im Lauf", run.counters.kills, 2)
enter("Geschmolzener Kern", "raid")
expect("Raid erfasst", addon.character.currentRun.instanceType, "raid")

-- Logout im Raid und langer Abstand: alter Lauf wird beim nächsten Login abgeschlossen
wow.advance(600)
wow.logout()
wow.advance(3600)
wow.login()
expect("alter Raid-Lauf abgeschlossen", #addon.character.instanceLog, 2)
expectNear("Dauer bis Logout", addon.character.instanceLog[2].seconds, 600)

SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Instanzen", wow.click("Instanzen"))
