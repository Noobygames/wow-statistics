-- Historie-Fenster: Lazy Load in langen Listen und Graphen rendern ohne Fehler.
local Journal = addon.Journal

wow.login({ level = 20, playedSeconds = 600 })

for i = 1, 1000 do
  Journal.AddKill(Journal.PVE, "Gegner " .. i)
end

SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Kills", wow.click("Kills"))

-- Tabelle mit Mausrad: nur die Kill-Tabelle ist sichtbar und scrollbar
local killTable = wow.findFrame(function(frame)
  return frame._scripts.OnMouseWheel ~= nil and frame:IsShown()
end)
expectTrue("Kill-Tabelle gefunden", killTable ~= nil)
expect("startet oben", killTable.offset, 0)

killTable._scripts.OnMouseWheel(killTable, -1)
expect("Mausrad scrollt drei Zeilen", killTable.offset, 3)
killTable._scripts.OnMouseWheel(killTable, 10)
expect("nicht über den Anfang hinaus", killTable.offset, 0)
for _ = 1, 1000 do
  killTable._scripts.OnMouseWheel(killTable, -1)
end
expectTrue("bis zum Ende scrollbar, nicht darüber hinaus", killTable.offset > 900 and killTable.offset < 1000)

-- Wechsel der Ansicht setzt den Bildlauf zurück
expectTrue("Reiter Tode", wow.click("Tode"))
expectTrue("zurück zu Kills", wow.click("Kills"))
expect("Bildlauf zurückgesetzt", killTable.offset, 0)

-- Graphen: alle Diagramme anklickbar
expectTrue("Reiter Graphen", wow.click("Graphen"))
for _, chart in ipairs({ "Zeit je Level", "XP/h je Level", "Kills je Tag", "Top-Gegner", "Todesursachen" }) do
  expectTrue("Diagramm " .. chart, wow.click(chart))
end

-- Leere Daten: anderer Charakter ohne Einträge
wow.logout()
wow.login({ name = "Neuling", level = 1 })
SlashCmdList.LEVELTIMER("history")
SlashCmdList.LEVELTIMER("history")
expectTrue("leere Rangliste", wow.click("Todesursachen"))
