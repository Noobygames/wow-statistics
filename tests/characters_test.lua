-- Jeder Charakter hat eigene Statistiken; die Historie kennt alle Charaktere.
local Stats = addon.Stats
local History = addon.History

local function kill()
  wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Wolf stirbt, Ihr bekommt 100 Erfahrung.")
end

wow.login({ name = "Alpha", realm = "Realm", level = 10, playedSeconds = 600 })
kill()
wow.advance(600)
wow.logout()

wow.login({ name = "Beta", realm = "Realm", level = 5, playedSeconds = 0 })
expect("neuer Charakter beginnt bei 0", Stats.Get(Stats.LEVEL, Stats.PVE_KILLS), 0)
kill()
kill()
expect("Beta zählt eigene Kills", Stats.Get(Stats.LEVEL, Stats.PVE_KILLS), 2)

local alpha = LevelTimerStatsDB.characters["Alpha-Realm"]
expect("Alpha unverändert", alpha.currentLevel.counters.pveKills, 1)
expectNear("Alpha: Spielzeit beim Logout gesichert", alpha.currentLevel.seconds, 1200)

local keys = History.GetCharacterKeys()
expect("eingeloggter Charakter zuerst", keys[1], "Beta-Realm")
expect("andere Charaktere danach", keys[2], "Alpha-Realm")

local alphaLevel = History.GetLevelRecords("Alpha-Realm")[1]
expect("Alpha: laufendes Level aus Speicher", alphaLevel.level, 10)
expect("Alpha: Kills aus Speicher", alphaLevel.counters.pveKills, 1)

local alphaSession = History.GetSessionRecords("Alpha-Realm")[1]
expect("Alpha: letzte Session nicht live", alphaSession.isCurrent, nil)
expect("Alpha: Session-Kills", alphaSession.counters.pveKills, 1)

wow.logout()
wow.login({ name = "Alpha", realm = "Realm", level = 10 })
expect("zurück bei Alpha: eigene Kills", Stats.Get(Stats.LEVEL, Stats.PVE_KILLS), 1)
