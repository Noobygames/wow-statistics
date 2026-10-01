-- PvE-Kills aus XP-Meldungen, PvP-Kills aus der Summe ehrenhafter Siege.
local Stats = addon.Stats

wow.login({ honorableKills = 3 })  -- 3 Siege vor dem Login zählen nicht

-- PvE
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Wolf stirbt, Ihr bekommt 100 Erfahrung.")
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Wolf (Elite) stirbt, Ihr bekommt 80 Erfahrung. (+40 Erholt-Bonus)")
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Ihr bekommt 250 Erfahrung.")  -- Quest/Entdecken, kein Kill

expect("PvE-Kills inkl. Bonus-Variante", Stats.Get(Stats.LEVEL, Stats.PVE_KILLS), 2)
expect("Kill-XP aus Meldung", Stats.Get(Stats.LEVEL, Stats.XP_KILLS), 180)

-- PvP: Differenz zur letzten Summe
wow.state.honorableKills = 5
wow.fire("PLAYER_PVP_KILLS_CHANGED")
expect("PvP-Kills seit Login", Stats.Get(Stats.LEVEL, Stats.PVP_KILLS), 2)

wow.state.honorableKills = 1  -- Tageswechsel: Summe beginnt neu
wow.fire("PLAYER_PVP_KILLS_CHANGED")
expect("PvP nach Tageswechsel", Stats.Get(Stats.LEVEL, Stats.PVP_KILLS), 3)

expect("Kills gesamt", Stats.GetTotalKills(Stats.LEVEL), 5)
