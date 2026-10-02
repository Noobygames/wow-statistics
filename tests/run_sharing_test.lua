-- Läufe teilen: Export als Text, Import als eigener Lauf, Doppelte und Ungültiges abgelehnt.
local L = addon.L
local Runs = addon.Runs

wow.login({ name = "Neu", level = 12, playedSeconds = 0 })
LevelTimerStatsDB.characters["Rekord-Testrealm"] = {
  name = "Rekord", realm = "Testrealm", class = "MAGE", currentLevel = { level = 30, counters = {} },
  levelHistory = { [10] = { level = 10, seconds = 2500 }, [11] = { level = 11, seconds = 2500 } },
  sessionHistory = {}, killLog = {}, deathLog = {},
}

local text = Runs.Export(Runs.Get("Rekord-Testrealm"))
expect("eigener Charakter ist schon bekannt", Runs.Import(text), 0)

-- In einem anderen Client: Charakter gibt es nicht, Lauf wird importiert
LevelTimerStatsDB.characters["Rekord-Testrealm"] = nil
expect("ein Lauf importiert", Runs.Import(text), 1)
expect("doppelt nicht", Runs.Import(text), 0)
local imported = Runs.Get("import:1")
expect("importierter Name", imported.name, "Rekord")
expect("importierte Zeiten", imported.times[11], 2500)
expect("als importiert markiert", imported.imported, true)

-- Als Vergleich wählbar
addon.Splits.SetReferenceRun(imported)
expect("Vergleich aus Import", addon.Splits.GetReference(10), 2500)

-- Ungültige Texte
expect("Müll", Runs.Import("hallo"), nil)
local broken = addon.Serializer.Encode("run", { name = "X", times = { [10] = "viel" } })
expect("Zeiten keine Zahlen", Runs.Import(broken), nil)

-- Sicherung aller Läufe enthält eigene und importierte
local backup = Runs.ExportAll()
expectTrue("Sicherung", backup:find("LT1:runs:", 1, true) == 1)

-- Import über das Fenster
LevelTimerStatsDB.importedRuns = {}
SlashCmdList.LEVELTIMER("runs import")
expect("Fenster offen", LevelTimerExport:IsShown(), true)
local editBox = wow.findFrame(function(frame) return frame._scripts.OnEscapePressed ~= nil and rawget(frame, "label") == nil and frame._text == "" end)
editBox:SetText(text)
expectTrue("Button Importieren", wow.click(L.IMPORT))
expect("über Fenster importiert", #LevelTimerStatsDB.importedRuns, 1)
expect("Fenster zu", LevelTimerExport:IsShown(), false)
