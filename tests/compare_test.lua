-- Vergleich aller Charaktere: Summen je Charakter, schnellster Leveler zuerst.
local History = addon.History

-- Langsamer Charakter: zwei Level à 2 h
wow.login({ name = "Langsam", level = 12, playedSeconds = 0 })
addon.character.levelHistory[10] = { level = 10, seconds = 7200, xp = 900, counters = { pveKills = 40, deaths = 2 } }
addon.character.levelHistory[11] = { level = 11, seconds = 7200, xp = 1000, counters = { pveKills = 50 } }
wow.logout()

-- Schneller Charakter (eingeloggt): ein Level à 1 h, plus laufendes Level mit einem Kill
wow.login({ name = "Flink", level = 8, playedSeconds = 0 })
addon.character.levelHistory[7] = { level = 7, seconds = 3600, xp = 800, counters = { pveKills = 30, pvpKills = 2 } }
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Wolf stirbt, Ihr bekommt 100 Erfahrung.")

local ohneDaten = "Neu-Testrealm"
LevelTimerStatsDB.characters[ohneDaten] = {
  name = "Neu", realm = "Testrealm", currentLevel = { level = 1, counters = {} },
  levelHistory = {}, sessionHistory = {}, killLog = {}, deathLog = {},
}

local rows = History.GetCharacterComparison()
expect("drei Charaktere", #rows, 3)
expect("schnellster zuerst", rows[1].name, "Flink")
expect("dann langsamer", rows[2].name, "Langsam")
expect("ohne abgeschlossene Level zuletzt", rows[3].name, "Neu")

expect("Ø Zeit je Level", rows[2].averageLevelSeconds, 7200)
expect("gelevelte Level", rows[2].levelsCompleted, 2)
expect("Kills summiert inkl. laufendem Level", rows[1].counters.pveKills, 31)
expect("PvP summiert", rows[1].counters.pvpKills, 2)
expect("Tode summiert", rows[2].counters.deaths, 2)
expect("eingeloggter Charakter markiert", rows[1].isCurrent, true)
expect("kein Durchschnitt ohne Daten", rows[3].averageLevelSeconds, nil)

SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Vergleich", wow.click("Vergleich"))
