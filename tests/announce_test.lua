-- Level-Up-Ansage an Gruppe oder Gilde: nur wenn eingestellt, Mitglied und keine Chat-Sperre.
local L = addon.L

wow.login({ level = 10, playedSeconds = 0 })

-- Standard: keine Ansage
wow.levelUp(11)
expect("aus: nichts gesendet", #wow.sentChat, 0)

-- Gilde eingestellt, aber nicht in einer Gilde
SlashCmdList.LEVELTIMER("config")
expectTrue("Auswahl Gilde", wow.click(L.ANNOUNCE_GUILD))
expect("Einstellung Gilde", LevelTimerDB.levelUpAnnounce, "guild")
wow.levelUp(12)
expect("ohne Gilde nichts gesendet", #wow.sentChat, 0)

wow.state.inGuild = true
wow.levelUp(13)
expect("an die Gilde", wow.sentChat[1].chatType, "GUILD")
local message = wow.sentChat[1].message
expectTrue("mit Präfix", message:find("LevelTimer: ", 1, true) == 1)
expectTrue("Text der Zusammenfassung", message:find("13", 1, true) ~= nil)
expectTrue("ohne Farbcodes", message:find("|c", 1, true) == nil)

-- Chat-Sperre (z.B. Bosskampf in Retail): nichts senden
wow.state.chatLockdown = true
wow.levelUp(14)
expect("gesperrt: nichts gesendet", #wow.sentChat, 1)
wow.state.chatLockdown = false

-- Gruppe
addon.Set("levelUpAnnounce", "party")
wow.levelUp(15)
expect("nicht in Gruppe: nichts", #wow.sentChat, 1)
wow.state.inGroup = true
wow.levelUp(16)
expect("an die Gruppe", wow.sentChat[2].chatType, "PARTY")

-- Eigene Chatzeile unabhängig davon abschaltbar
addon.Set("levelUpSummary", false)
local printed = #wow.printed
wow.levelUp(17)
expect("Ansage ohne eigene Zeile", #wow.sentChat, 3)
expect("keine eigene Zeile", #wow.printed, printed)

-- /sagen: erst der Klick auf den Button sendet (Hardware-Eingabe)
addon.Set("levelUpAnnounce", "say")
local sent = #wow.sentChat
wow.levelUp(18)
expect("ohne Klick nichts gesendet", #wow.sentChat, sent)
expectTrue("Klick auf den Button", wow.click(L.ANNOUNCE_SAY_BUTTON))
expect("nach Klick gesendet", #wow.sentChat, sent + 1)
expect("in /sagen", wow.sentChat[#wow.sentChat].chatType, "SAY")
expectTrue("Text vom Level-Up", wow.sentChat[#wow.sentChat].message:find("18", 1, true) ~= nil)

-- Button verschwindet nach Ablauf
local button = wow.findFrame(function(frame) return frame._text == L.ANNOUNCE_SAY_BUTTON end)
wow.levelUp(19)
expect("Button sichtbar", button:IsShown(), true)
wow.runTimers()
expect("nach Ablauf versteckt", button:IsShown(), false)

-- Chat-Sperre beim Klick: nichts senden
wow.levelUp(20)
wow.state.chatLockdown = true
wow.click(L.ANNOUNCE_SAY_BUTTON)
expect("gesperrt: nichts gesendet", #wow.sentChat, sent + 1)
wow.state.chatLockdown = false
