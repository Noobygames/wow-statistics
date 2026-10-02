-- Aktuelle XP/h: Rate über die letzten 15 Minuten.
local RecentXpRate = addon.RecentXpRate
local Stats = addon.Stats

wow.login({ level = 10 })
expect("direkt nach Login: noch keine Rate", RecentXpRate.Get(), nil)

-- 10 min lang 100 XP/min = 6000 XP/h
for _ = 1, 20 do
  wow.advance(30)
  Stats.Increment(Stats.XP_GAINED, 50)
  RecentXpRate.Sample()
end
expectNear("gleichmäßig", RecentXpRate.Get(), 6000, 1)

-- Danach 15 min nichts (Flugroute): Fenster enthält nur noch die Pause
for _ = 1, 30 do
  wow.advance(30)
  RecentXpRate.Sample()
end
expectNear("nach Pause: 0", RecentXpRate.Get(), 0, 1)
local average = addon.Experience.CalculateRate(Stats.Get(Stats.SESSION, Stats.XP_GAINED), 25 * 60)
expectTrue("Durchschnitt reagiert langsamer", average > 2000)

-- Wieder 5 min leveln: Rate steigt sofort
for _ = 1, 10 do
  wow.advance(30)
  Stats.Increment(Stats.XP_GAINED, 100)
  RecentXpRate.Sample()
end
expectNear("Erholung sichtbar", RecentXpRate.Get(), 1000 / 900 * 3600, 50)
