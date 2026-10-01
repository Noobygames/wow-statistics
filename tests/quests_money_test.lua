-- Quests und Einnahmen.
local Stats = addon.Stats

wow.login({ money = 10000 })

wow.fire("QUEST_TURNED_IN", 1, 150, 500)
wow.fire("QUEST_TURNED_IN", 2, nil, 0)  -- Client ohne XP-Angabe
expect("Quests", Stats.Get(Stats.LEVEL, Stats.QUESTS), 2)
expect("Quest-XP", Stats.Get(Stats.LEVEL, Stats.XP_QUESTS), 150)

wow.state.money = 12500
wow.fire("PLAYER_MONEY")
wow.state.money = 11000  -- Ausgabe
wow.fire("PLAYER_MONEY")
wow.state.money = 11200
wow.fire("PLAYER_MONEY")
expect("nur Einnahmen zählen", Stats.Get(Stats.LEVEL, Stats.MONEY_EARNED), 2700)
