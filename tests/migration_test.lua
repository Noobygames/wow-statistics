-- Alte Speicherstände werden beim Login migriert, Einstellungen bleiben erhalten.
local LevelStats = addon.LevelStats

LevelTimerCharDB = { level = 10, kills = 4 }  -- Schema 1: nur PvE-Kills als "kills"
LevelTimerDB = { locked = true, showKills = false }

wow.login({ level = 10 })

expect("kills wird zu pveKills", LevelStats.Get(LevelStats.PVE_KILLS), 4)
expect("altes Feld entfernt", LevelTimerCharDB.kills, nil)
expect("Schema-Version aktuell", LevelTimerCharDB.schemaVersion, 2)
expect("neuer Zähler bekommt Default", LevelStats.Get(LevelStats.QUESTS), 0)
expectTrue("Historie angelegt", type(LevelTimerCharDB.history) == "table")

expect("Einstellung bleibt", LevelTimerDB.locked, true)
expect("abgeschaltete Zeile bleibt aus", LevelTimerDB.showKills, false)
expect("neue Einstellung bekommt Default", LevelTimerDB.showDeaths, true)

-- Zweiter Lauf darf nicht erneut migrieren
LevelTimerCharDB.counters.pveKills = 20
addon.Database.Load()
expect("keine Doppelmigration", LevelTimerCharDB.counters.pveKills, 20)
