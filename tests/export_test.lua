-- Export: CSV aus den angezeigten Tabellenzeilen, mit Escaping und ohne Farbcodes.
local Export = addon.Export
local Journal = addon.Journal

expect("einfache Felder", Export.ToCsv({ "A", "B" }, { { "1", "2" } }, ";"), "A;B\n1;2")
expect("Trennzeichen im Feld wird gequotet", Export.ToCsv({ "A" }, { { "x;y" } }, ";"), 'A\n"x;y"')
expect("Anführungszeichen werden verdoppelt", Export.ToCsv({ "A" }, { { 'sag "hi"' } }, ","), 'A\n"sag ""hi"""')

wow.login({ level = 20, zone = "Westfall" })
Journal.AddKill(Journal.PVE, "Wolf")
Journal.AddKill(Journal.PVE, "Defias; Schurke")
wow.state.zone = "Dämmerwald"
Journal.AddKill(Journal.PVE, "Ghul")

SlashCmdList.LEVELTIMER("history")
wow.click("Kills")
local killTable = wow.shownTable()

killTable:SetFilter("westfall")
local csv = killTable:BuildCsv()
local lines = {}
for line in (csv .. "\n"):gmatch("(.-)\n") do
  table.insert(lines, line)
end
expect("Kopfzeile + gefilterte Zeilen", #lines, 3)
expectTrue("Kopfzeile in Deutsch", lines[1]:find("Name", 1, true) ~= nil and lines[1]:find("Zone", 1, true) ~= nil)
expectTrue("Semikolon für Deutsch", lines[1]:find(";", 1, true) ~= nil)
expectTrue("Feld mit Semikolon gequotet", csv:find('"Defias; Schurke"', 1, true) ~= nil)
expect("Ghul weggefiltert", csv:find("Ghul", 1, true), nil)

-- Knopf öffnet das Export-Fenster
expectTrue("Export-Knopf", wow.click("Export"))
expect("Export-Fenster offen", LevelTimerExport:IsShown(), true)
