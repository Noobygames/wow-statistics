-- Level-Up: Historie sichert das alte Level, danach starten alle Zähler neu.
local Stats = addon.Stats

wow.login({ level = 10, xp = 0, xpMax = 1000, playedSeconds = 1800 })

wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Wolf stirbt, Ihr bekommt 100 Erfahrung.")
wow.fire("QUEST_TURNED_IN", 1, 200, 0)
wow.state.dead = true
wow.fire("PLAYER_DEAD")
wow.state.dead = false
wow.fire("PLAYER_UNGHOST")
wow.advance(600)

wow.levelUp(11, 1200)

local record = addon.character.levelHistory[10]
expectTrue("Level 10 gesichert", record ~= nil)
expect("Kills gesichert", record.counters.pveKills, 1)
expect("Tode gesichert", record.counters.deaths, 1)
expect("Quests gesichert", record.counters.quests, 1)
expect("XP des Levels = Bedarf", record.xp, 1000)
expectNear("Spielzeit gesichert", record.seconds, 2400)
expectTrue("Zeitpunkt gesetzt", record.completedAt ~= nil)

expect("aktuelles Level", addon.level, 11)
expect("Zähler-Level", addon.character.currentLevel.level, 11)
expect("Kills zurückgesetzt", Stats.Get(Stats.LEVEL, Stats.PVE_KILLS), 0)
expect("Tode zurückgesetzt", Stats.Get(Stats.LEVEL, Stats.DEATHS), 0)
expectNear("Spielzeit zurückgesetzt", addon.PlayedTime.GetLevelSeconds(), 0)

local records = addon.History.GetLevelRecords(addon.characterKey)
expect("laufendes Level vorne", records[1].level, 11)
expect("laufendes Level markiert", records[1].isCurrent, true)
expect("danach abgeschlossenes Level", records[2].level, 10)

-- Level-Up ohne laufendes Addon: beim Login neu starten, aber keinen Eintrag erfinden
addon.character.currentLevel.counters.pveKills = 7
wow.logout()
wow.login({ level = 13 })
expect("Offline-Level-Up setzt zurück", Stats.Get(Stats.LEVEL, Stats.PVE_KILLS), 0)
expect("kein Eintrag für übersprungenes Level", addon.character.levelHistory[12], nil)

-- Summe: XP von Einträgen ohne Dauer (/played fehlte) zählt nicht in die XP/h
local summary = addon.History.Summarize({
  { seconds = 3600, xp = 1000, counters = {} },
  { xp = 5000, counters = {} },
})
expect("Gesamt-XP", summary.xp, 6000)
expectNear("XP/h nur aus Einträgen mit Dauer", addon.Experience.RecordRate(summary), 1000)
