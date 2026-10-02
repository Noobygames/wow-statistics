-- Zeitaufteilung: Kampf, Flug, AFK als Zähler je Level und Session, Rest aus der Spielzeit.
local TimeBreakdown = addon.TimeBreakdown
local Stats = addon.Stats

wow.login({ level = 10, playedSeconds = 0 })

local function seconds(counter, scope)
  return TimeBreakdown.GetSeconds(scope or Stats.LEVEL, counter)
end

-- Kampf: 30 s, noch nicht gebucht, aber im Getter enthalten
wow.state.inCombat = true
TimeBreakdown.Update(1)       -- Wechsel in den Kampf
for _ = 1, 3 do TimeBreakdown.Update(1) end
expect("Kampf läuft", seconds(Stats.COMBAT_SECONDS), 3)
for _ = 1, 27 do TimeBreakdown.Update(1) end
expect("Kampf 30 s", seconds(Stats.COMBAT_SECONDS), 30)
expectTrue("zwischendurch gebucht", Stats.Get(Stats.LEVEL, Stats.COMBAT_SECONDS) >= 20)

-- Flug: Kampf hat Vorrang, danach Flugroute
wow.state.onTaxi = true
TimeBreakdown.Update(1)
expect("im Kampf auf dem Greif: Kampf", seconds(Stats.COMBAT_SECONDS), 31)
wow.state.inCombat = false
TimeBreakdown.Update(1)       -- Wechsel: letzte Kampfsekunde gebucht
for _ = 1, 60 do TimeBreakdown.Update(1) end
expect("Flug 60 s", seconds(Stats.TAXI_SECONDS), 60)
expect("Kampf gebucht", Stats.Get(Stats.SESSION, Stats.COMBAT_SECONDS), 32)

-- AFK
wow.state.onTaxi = false
wow.state.afk = true
TimeBreakdown.Update(1)
for _ = 1, 10 do TimeBreakdown.Update(1) end
expect("AFK 10 s", seconds(Stats.AFK_SECONDS), 10)
wow.state.afk = false
TimeBreakdown.Update(1)
expect("Session zählt mit", seconds(Stats.AFK_SECONDS, Stats.SESSION), 11)

-- Rest = Spielzeit minus Anteile
wow.fire("TIME_PLAYED_MSG", 1000, 200)
local rest = TimeBreakdown.GetRestSeconds(Stats.LEVEL)
expectNear("Rest", rest, 200 - 32 - 61 - 11, 1)

-- Level-Up: laufende Zeit landet noch im alten Level und in der Historie
wow.state.inCombat = true
TimeBreakdown.Update(1)
for _ = 1, 5 do TimeBreakdown.Update(1) end
wow.levelUp(11)
local record = addon.character.levelHistory[#addon.character.levelHistory]
expect("Historie: Kampf", record.counters.combatSeconds, 32 + 5)
expect("neues Level leer", Stats.Get(Stats.LEVEL, Stats.COMBAT_SECONDS), 0)

-- Anzeige im Fenster
addon.Set("showTimeBreakdown", true)
local row
for _, line in ipairs(addon.STAT_LINES) do
  if line.setting == "showTimeBreakdown" then row = line.rows[1] end
end
expect("Zeile Kampf", row.label, "ROW_TIME_COMBAT")

---------------------------------------------------------------------------
-- XP/h ohne AFK (xpRateWithoutAfk)
---------------------------------------------------------------------------
local Experience = addon.Experience
wow.state.inCombat = false
wow.state.afk = true
TimeBreakdown.Update(1)
for _ = 1, 1800 do TimeBreakdown.Update(1) end
wow.state.afk = false
TimeBreakdown.Update(1)
wow.state.xp = 500
wow.fire("TIME_PLAYED_MSG", 5000, 3600)
expectNear("mit AFK: 500 XP/h", Experience.GetRatePerHour(Stats.LEVEL), 500, 1)
addon.Set("xpRateWithoutAfk", true)
expectNear("ohne AFK: 1000 XP/h", Experience.GetRatePerHour(Stats.LEVEL), 1000, 1)
expect("Historie ohne Zähler: Spielzeit bleibt", Experience.RateSeconds(100, nil), 100)

-- Historie, Vergleich und Graph rechnen XP/h nach denselben Regeln wie das Fenster
local current = addon.History.GetLevelRecords(addon.characterKey)[1]
expectNear("Historie ohne AFK", Experience.RecordRate(current), 1000, 1)
local function compareRate() return addon.History.GetCharacterComparison()[1].xpRate end
local function summaryRate()
  return Experience.RecordRate(addon.History.Summarize(addon.History.GetLevelRecords(addon.characterKey)))
end
local withoutAfk = compareRate()
expectNear("Vergleich ohne AFK wie Summenzeile", withoutAfk, summaryRate(), 0.01)
local items = addon.Analysis.XpRatePerLevel(addon.characterKey)
expectNear("Graph ohne AFK", items[#items].value, 1000, 1)
addon.Set("xpRateWithoutAfk", false)
expectTrue("Vergleich mit AFK langsamer", compareRate() < withoutAfk)
expectNear("Vergleich mit AFK wie Summenzeile", compareRate(), summaryRate(), 0.01)
