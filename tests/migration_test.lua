-- Alte Speicherstände (pro Charakter, Schema 1/2) werden beim Login in die
-- account-weite Datei übernommen und migriert. Einstellungen bleiben erhalten.
local Stats = addon.Stats

LevelTimerCharDB = {  -- Schema 1: flach, nur PvE-Kills als "kills"
  level = 10,
  kills = 4,
  history = { [9] = { level = 9, seconds = 3000, xp = 900, counters = { pveKills = 30 } } },
}
LevelTimerDB = { locked = true, showKills = false, showDeaths = true, fontSize = 24 }

wow.login({ level = 10 })

local character = LevelTimerStatsDB.characters["Testchar-Testrealm"]
expectTrue("Charakter unter Name-Realm angelegt", character ~= nil)
expect("alte Datei geleert", LevelTimerCharDB, nil)
expect("Schema-Version aktuell", character.schemaVersion, 3)
expect("Name gespeichert", character.name, "Testchar")
expect("Klasse gespeichert", character.class, "WARRIOR")

expect("kills wird zu pveKills", Stats.Get(Stats.LEVEL, Stats.PVE_KILLS), 4)
expect("Level übernommen", character.currentLevel.level, 10)
expect("Historie übernommen", character.levelHistory[9].counters.pveKills, 30)
expect("alte Felder entfernt", character.kills or character.level or character.history, nil)
expect("neuer Zähler bekommt Default", Stats.Get(Stats.LEVEL, Stats.XP_GAINED), 0)
expectTrue("Session gestartet", character.currentSession.startedAt ~= nil)

expect("Einstellung bleibt", LevelTimerDB.locked, true)
expect("Kills aus -> PvE aus", LevelTimerDB.showPveKills, false)
expect("Kills aus -> PvP aus", LevelTimerDB.showPvpKills, false)
expect("alter Kills-Schalter entfernt", LevelTimerDB.showKills, nil)
expect("Tode an -> Kills pro Tod an", LevelTimerDB.showKillsPerDeath, true)
expect("neue Einstellung bekommt Default", LevelTimerDB.windowScope, "level")
expect("Schriftgröße wird zu Fenstergröße", LevelTimerDB.scale, 1.5)
expect("alte Schriftgröße entfernt", LevelTimerDB.fontSize, nil)

-- Zweiter Login darf nicht erneut migrieren
character.currentLevel.counters.pveKills = 20
wow.logout()
wow.login()
expect("keine Doppelmigration", Stats.Get(Stats.LEVEL, Stats.PVE_KILLS), 20)
