-- PvE-Kills aus XP-Meldungen, PvP-Kills aus der Summe ehrenhafter Siege.
local LevelStats = addon.LevelStats

wow.login({ honorableKills = 3 })  -- 3 Siege vor dem Login zählen nicht

-- PvE
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Wolf stirbt, Ihr bekommt 100 Erfahrung.")
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Wolf (Elite) stirbt, Ihr bekommt 80 Erfahrung. (+40 Erholt-Bonus)")
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Ihr bekommt 250 Erfahrung.")  -- Quest/Entdecken, kein Kill

expect("PvE-Kills inkl. Bonus-Variante", LevelStats.Get(LevelStats.PVE_KILLS), 2)
expect("Kill-XP aus Meldung", LevelStats.Get(LevelStats.XP_KILLS), 180)

-- PvP: Differenz zur letzten Summe
wow.state.honorableKills = 5
wow.fire("PLAYER_PVP_KILLS_CHANGED")
expect("PvP-Kills seit Login", LevelStats.Get(LevelStats.PVP_KILLS), 2)

wow.state.honorableKills = 1  -- Tageswechsel: Summe beginnt neu
wow.fire("PLAYER_PVP_KILLS_CHANGED")
expect("PvP nach Tageswechsel", LevelStats.Get(LevelStats.PVP_KILLS), 3)

expect("Kills gesamt", LevelStats.GetTotalKills(), 5)
