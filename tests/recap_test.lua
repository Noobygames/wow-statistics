-- Session-Abschlusskarte: Werte der laufenden Session, beste Beute, gefährlichster Gegner.
local L = addon.L
local Journal = addon.Journal
local RecapWindow = addon.RecapWindow

local function row(label)
  for _, line in ipairs(RecapWindow.BuildRows()) do
    if line[1] == label then return line[2] end
  end
end

wow.login({ level = 10, xp = 0, xpMax = 1000 })

-- Beute und Tode aus einer früheren Session zählen nicht
Journal.AddLoot({ link = "[Altes Episches]", quality = 4 })
Journal.AddDeath({ killer = "Alter Feind" })
wow.advance(10)
SlashCmdList.LEVELTIMER("newsession")
wow.advance(1)

expect("ohne Beute", row(L.RECAP_BEST_LOOT), "-")
expect("ohne Gegner", row(L.RECAP_DANGER), "-")

wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Wolf stirbt, Ihr bekommt 100 Erfahrung.")
Journal.AddLoot({ link = "[Blauer Ring]", quality = 3 })
Journal.AddLoot({ link = "[Lila Schwert]", quality = 4 })
Journal.AddLoot({ link = "[Grüner Gürtel]", quality = 3 })
Journal.AddDeath({ killer = "Hogger" })
Journal.AddNearDeath(5, { killer = "Hogger" })
Journal.AddNearDeath(8, { killer = "Wolf" })
wow.levelUp(11)
wow.advance(3600)

expect("Charakter", row(L.RECAP_CHARACTER), "Testchar - Testrealm")
expect("Level-Spanne", row(L.RECAP_LEVELS), "10 > 11")
expect("Kills", row(L.RECAP_KILLS), "1")
expect("beste Beute = höchste Qualität", row(L.RECAP_BEST_LOOT), "[Lila Schwert]")
expect("gefährlichster Gegner", row(L.RECAP_DANGER), "Hogger (2)")
expect("Spielzeit", row(L.RECAP_TIME), addon.Format.Duration(3601))

-- Fenster per Befehl und Button, Datenschutz gilt auch hier
SlashCmdList.LEVELTIMER("recap")
expect("Fenster offen", LevelTimerRecap:IsShown(), true)
addon.Set("streamerPrivacy", true)
expect("ohne Realm", row(L.RECAP_CHARACTER), "Testchar")
SlashCmdList.LEVELTIMER("recap")
expect("Fenster zu", LevelTimerRecap:IsShown(), false)
SlashCmdList.LEVELTIMER("config")
expectTrue("Button in den Einstellungen", wow.click(L.RECAP_TITLE))
expect("Fenster per Button", LevelTimerRecap:IsShown(), true)
