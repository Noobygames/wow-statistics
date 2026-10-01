-- Tode, Zeit tot/als Geist und Kills pro Tod.
local LevelStats = addon.LevelStats
local DeathCounter = addon.DeathCounter

wow.login()
expect("Kills/Tod ohne Tod", DeathCounter.GetKillsPerDeath(), nil)

wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Wolf stirbt, Ihr bekommt 100 Erfahrung.")
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Wolf stirbt, Ihr bekommt 100 Erfahrung.")

wow.state.dead = true
wow.fire("PLAYER_DEAD")
wow.advance(30)
wow.fire("PLAYER_ALIVE")  -- Geist freigelassen, noch nicht lebendig
wow.fire("PLAYER_DEAD")   -- doppeltes Event
expectNear("laufende Zeit tot", DeathCounter.GetDeadSeconds(), 30)

wow.advance(60)
wow.state.dead = false
wow.fire("PLAYER_UNGHOST")

expect("ein Tod", LevelStats.Get(LevelStats.DEATHS), 1)
expectNear("Zeit tot gesamt", DeathCounter.GetDeadSeconds(), 90)
expect("Kills pro Tod", DeathCounter.GetKillsPerDeath(), 2)

wow.advance(100)
expectNear("lebendig: Zeit läuft nicht weiter", DeathCounter.GetDeadSeconds(), 90)
