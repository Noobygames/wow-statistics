-- Tageswerte: Spielzeit pro Tag (über Mitternacht aufgeteilt) und pro Woche.
local Analysis = addon.Analysis
local DAY = 86400

-- Alter Stand mit einer archivierten Session: wird ihrem Starttag zugeordnet
local mondayNoon = os.time({ year = 2026, month = 10, day = 12, hour = 12 })  -- Montag
LevelTimerCharDB = {
  schemaVersion = 3,
  currentLevel = { level = 10, counters = {} },
  sessionHistory = { { startedAt = mondayNoon - 2 * DAY, seconds = 5400, counters = {} } },  -- Samstag
}
wow.login({ level = 10, clock = mondayNoon + 11 * 3600 })  -- Montag 23:00

local saturday = addon.character.dailyStats["2026-10-10"]
expectTrue("Session-Spielzeit übernommen", saturday ~= nil and saturday.seconds == 5400)

-- 2 h spielen: 1 h Montag, 1 h Dienstag
wow.advance(2 * 3600)
local perDay = Analysis.PlayTimePerDay(addon.characterKey)
expect("14 Tage", #perDay, 14)
expect("heute (Dienstag) hervorgehoben", perDay[14].highlight, true)
expect("Dienstag 1 h", perDay[14].value, 3600)
expect("Montag 1 h", perDay[13].value, 3600)
expect("Samstag aus alter Session", perDay[11].value, 5400)
expect("Beschriftung", perDay[14].label, "13.10.")

-- Woche ab Montag: diese Woche 2 h, Vorwoche (mit Samstag) 1,5 h
local perWeek = Analysis.PlayTimePerWeek(addon.characterKey)
expect("8 Wochen", #perWeek, 8)
expect("diese Woche", perWeek[8].value, 7200)
expect("Vorwoche", perWeek[7].value, 5400)
expect("Wochenbeschriftung = Montag", perWeek[8].label, "12.10.")

-- Mehrfaches Lesen verbucht nicht doppelt
Analysis.PlayTimePerDay(addon.characterKey)
expect("kein Doppelzählen", addon.character.dailyStats["2026-10-13"].seconds, 3600)

-- Ende der Sommerzeit (25-Stunden-Tag in Europa): Buchung über 23 Uhr und Mitternacht hängt nicht
-- und teilt korrekt auf. Ohne Zeitumstellung in der lokalen Zeitzone ist es ein normaler Tag.
wow.state.clock = os.time({ year = 2026, month = 10, day = 25, hour = 22, min = 30 })
addon.Daily.BookPlayTime()
local stats = addon.character.dailyStats
local before25 = stats["2026-10-25"] and stats["2026-10-25"].seconds or 0
wow.advance(2 * 3600)
addon.Daily.BookPlayTime()
local nextMidnight = os.time({ year = 2026, month = 10, day = 26, hour = 0 })
local endOfDay = nextMidnight - os.time({ year = 2026, month = 10, day = 25, hour = 22, min = 30 })
expect("Rest des 25. Oktober", stats["2026-10-25"].seconds - before25, endOfDay)
expect("Rest am 26. Oktober", stats["2026-10-26"].seconds, 2 * 3600 - endOfDay)
expect("AddDays über den Kalender", addon.Daily.AddDays(nextMidnight - 3600, 1), nextMidnight)

-- Graphen über die Frühjahrs-Umstellung (23-Stunden-Tag): jeder Tag genau einmal, Wochen ab Montag
wow.state.clock = os.time({ year = 2026, month = 4, day = 2, hour = 12 })  -- Donnerstag nach dem 29. März
local days = Analysis.PlayTimePerDay(addon.characterKey)
local seen = {}
for _, item in ipairs(days) do
  expectTrue("Tag nur einmal: " .. item.label, not seen[item.label])
  seen[item.label] = true
end
expect("29.03. dabei", seen["29.03."], true)
local weeks = Analysis.PlayTimePerWeek(addon.characterKey)
expect("Woche vor der Umstellung beginnt Montag", weeks[7].label, "23.03.")
