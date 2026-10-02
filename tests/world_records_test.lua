-- Speedrun-Rekorde: Vergleich der /played-Zeit beim Erreichen eines Levels mit dem Rekord je Abschnitt.
local L = addon.L
local WorldRecords = addon.WorldRecords

-- Feste Testdaten statt der erzeugten Datei (die ändert sich mit jedem "make records")
addon.SpeedrunRecordsData = {
  source = "test",
  fetched = "2026-10-02",
  brackets = {
    { label = "1-10", level = 10,
      best = { seconds = 3331, runner = "Schnell", class = "PALADIN", date = "2025-11-20" },
      classes = {
        PALADIN = { seconds = 3331, runner = "Schnell", class = "PALADIN", date = "2025-11-20" },
        WARRIOR = { seconds = 3635, runner = "Krieger", class = "WARRIOR", date = "2025-04-26" },
      } },
    { label = "1-20", level = 20,
      best = { seconds = 18369, runner = "Jäger", class = "HUNTER", date = "2026-08-31" },
      classes = {} },
  },
}

wow.login({ level = 12, class = "WARRIOR" })
wow.fire("TIME_PLAYED_MSG", 5000, 100)  -- /played gesamt 5000 s
addon.character.levelHistory[9] = { level = 9, seconds = 400, totalPlayed = 3000, counters = {} }

-- Standard: Rekord der eigenen Klasse, ohne Klassenrekord der Gesamtrekord
local comparisons = WorldRecords.GetComparisons()
expect("1-10 Klassenrekord", comparisons[1].record.runner, "Krieger")
expect("1-10 erreicht", comparisons[1].reached, true)
expect("1-10 eigene Zeit beim Erreichen", comparisons[1].ownSeconds, 3000)
expect("1-10 schneller", comparisons[1].delta, 3000 - 3635)
expect("1-20 ohne Klassenrekord: gesamt", comparisons[2].record.runner, "Jäger")
expect("1-20 noch nicht erreicht", comparisons[2].reached, false)
expect("1-20 laufende /played-Zeit", comparisons[2].ownSeconds, 5000)

addon.Set("worldRecordScope", "overall")
expect("Gesamtrekord", WorldRecords.GetComparisons()[1].record.runner, "Schnell")

-- Split-Liste zeigt die Rekorde als eigene Zeilen
addon.Set("showSplitList", true)
LevelTimerSplits._scripts.OnUpdate(LevelTimerSplits, 1)
local row = wow.findFrame(function(frame) return frame._text == string.format(L.WORLD_RECORD_ROW, "1-10") end)
expectTrue("Rekord-Zeile", row ~= nil and row:IsShown())
addon.Set("showWorldRecords", false)
LevelTimerSplits._scripts.OnUpdate(LevelTimerSplits, 1)
expect("abschaltbar", row:IsShown(), false)

-- Historie: alle Rekorde, eigene Klasse hervorgehoben
SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Speedrun", wow.click(L.HISTORY_GROUP_SPEEDRUN))
expectTrue("Unterreiter Rekorde", wow.click(L.HISTORY_TAB_WORLD_RECORDS))
local rows = wow.shownTable():GetVisibleRecords()
expect("gesamt und je Klasse", #rows, 4)
expect("eigene Klasse markiert", rows[3].isCurrent, true)
expect("Abweichung zum Klassenrekord", rows[3].delta, 3000 - 3635)
