-- XP/h, Level-ETA und Prognose ohne AFK-Zeit (xpRateWithoutAfk): Randfälle um Level-Up und ungebuchte AFK-Zeit.
local TimeBreakdown = addon.TimeBreakdown
local Stats = addon.Stats
local Experience = addon.Experience
local History = addon.History

wow.login({ level = 10, xp = 0, xpMax = 1000, playedSeconds = 0 })
addon.Set("xpRateWithoutAfk", true)

local function afk(seconds)
  wow.state.afk = true
  TimeBreakdown.Update(1)               -- Wechsel in AFK
  for _ = 1, seconds do TimeBreakdown.Update(1) end
end

-- 1) ETA: 600 s im Level, davon 300 s AFK, 300 von 1000 XP -> 3600 XP/h, Rest 700 XP = 700 s
afk(300)
wow.state.afk = false
TimeBreakdown.Update(1)
wow.state.xp = 300
wow.fire("TIME_PLAYED_MSG", 100000, 600)
local afkSeconds = TimeBreakdown.GetSeconds(Stats.LEVEL, Stats.AFK_SECONDS)
expectNear("ETA ohne AFK", Experience.GetSecondsToLevel(Stats.LEVEL), (1000 - 300) / (300 / (600 - afkSeconds)), 1)

-- 2) Ungebuchte AFK-Zeit: Historie-Eintrag des laufenden Levels muss sie enthalten wie das Fenster
afk(5)
local current = History.GetLevelRecords(addon.characterKey)[1]
expect("laufendes Level: AFK wie im Fenster", current.counters[Stats.AFK_SECONDS],
  TimeBreakdown.GetSeconds(Stats.LEVEL, Stats.AFK_SECONDS))
wow.state.afk = false
TimeBreakdown.Update(1)

-- 3) Level-Up mitten im AFK: Historie hat die ganze AFK-Zeit, XP/h der Historie = XP/h ohne AFK
afk(20)
wow.state.xp = 900
wow.fire("TIME_PLAYED_MSG", 100000, 700)
local expectedAfk = TimeBreakdown.GetSeconds(Stats.LEVEL, Stats.AFK_SECONDS)
wow.levelUp(11, 1500)
local record = addon.character.levelHistory[#addon.character.levelHistory]
expect("Level-Up: AFK komplett gebucht", record.counters[Stats.AFK_SECONDS], expectedAfk)
expectNear("Level-Up: Historie-Rate", Experience.RecordRate(record), 1000 / (record.seconds - expectedAfk) * 3600, 1)
wow.state.afk = false
TimeBreakdown.Update(1)

-- 4) Neues Level: kurz nach dem Level-Up (weniger als 60 s Nicht-AFK-Zeit) ist die Rate unbekannt,
-- aber die Prognose bleibt nicht dauerhaft leer, sobald genug Zeit da ist
wow.fire("TIME_PLAYED_MSG", 100000, 90)
wow.state.xp = 100
expectTrue("neues Level: AFK-Zähler (fast) leer", Stats.Get(Stats.LEVEL, Stats.AFK_SECONDS) <= 1)
expectTrue("90 s ohne AFK: Rate da", Experience.GetRatePerHour(Stats.LEVEL) ~= nil)
afk(60)
wow.fire("TIME_PLAYED_MSG", 100000, 100)
-- 100 s Spielzeit, 61 s AFK -> 39 s: unter der Mindestzeit, keine Rate; kein Fehler, keine negative Zahl
local rate = Experience.GetRatePerHour(Stats.LEVEL)
expectTrue("wenig Nicht-AFK-Zeit: nil oder positiv", rate == nil or rate > 0)

-- 5) AFK-Zähler größer als Spielzeit (Server-/Lokal-Versatz) ergibt nie negative Zeiten
wow.fire("TIME_PLAYED_MSG", 100000, 10)
expect("Rate bei AFK > Spielzeit", Experience.GetRatePerHour(Stats.LEVEL), nil)
expect("ETA bei AFK > Spielzeit", Experience.GetSecondsToLevel(Stats.LEVEL), nil)
expectTrue("Prognose ohne Fehler", addon.Forecast.SecondsToLevel(13) == nil or addon.Forecast.SecondsToLevel(13) >= 0)
