-- Kills/Quests bis Level-Up aus der durchschnittlichen XP je Kill bzw. Quest.
local Experience = addon.Experience
local Stats = addon.Stats

wow.login({ level = 10, xp = 0, xpMax = 1000 })
expect("ohne Kills keine Schätzung", Experience.CountToLevel(Stats.XP_KILLS, Stats.PVE_KILLS), nil)

-- 4 Kills à 50 XP, 1 Quest mit 300 XP: 500 XP fehlen
Stats.Increment(Stats.PVE_KILLS, 4)
Stats.Increment(Stats.XP_KILLS, 200)
Stats.Increment(Stats.QUESTS, 1)
Stats.Increment(Stats.XP_QUESTS, 300)
wow.state.xp = 500
expect("10 Kills", Experience.CountToLevel(Stats.XP_KILLS, Stats.PVE_KILLS), 10)
expect("2 Quests (aufgerundet)", Experience.CountToLevel(Stats.XP_QUESTS, Stats.QUESTS), 2)

-- Neues Level ohne Kills: Durchschnitt der Session
wow.levelUp(11, 1000)
expect("neues Level: Session", Experience.CountToLevel(Stats.XP_KILLS, Stats.PVE_KILLS), 20)

addon.Set("showCountToLevel", true)
local line
for _, entry in ipairs(addon.STAT_LINES) do
  if entry.setting == "showCountToLevel" then line = entry end
end
expect("Zeile", line.rows[1].value(Stats.LEVEL), "~20")

-- Verbleibende Erholt-XP
local restedLine
for _, entry in ipairs(addon.STAT_LINES) do
  if entry.setting == "showRestedLeft" then restedLine = entry end
end
wow.state.rested = 1500
expect("Erholt übrig", restedLine.rows[1].value(Stats.LEVEL), "1.5k (150%)")
wow.state.rested = 0
expect("nichts übrig", restedLine.rows[1].value(Stats.LEVEL), "0 (0%)")
