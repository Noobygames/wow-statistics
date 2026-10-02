-- Historie-Tabellen: Spalten sortieren und Zeilen filtern; Summen gelten für die gefilterten Zeilen.
local Journal = addon.Journal

wow.login({ level = 20 })
local zones = { "Westfall", "Dämmerwald", "Westfall" }
local names = { "Wolf", "Ghul", "Defias" }
for i = 1, 3 do
  wow.state.zone = zones[i]
  wow.state.clock = wow.state.clock + 60
  Journal.AddKill(Journal.PVE, names[i])
end

SlashCmdList.LEVELTIMER("history")
wow.click("Kills")

local killTable = wow.shownTable()

local function shownNames()
  local result = {}
  for _, record in ipairs(killTable:GetVisibleRecords()) do
    table.insert(result, record.name)
  end
  return table.concat(result, ",")
end

expect("Standard: neueste zuerst", shownNames(), "Defias,Ghul,Wolf")

-- Sortieren nach Name (Spalte 2): erst absteigend, dann aufsteigend
killTable:SortBy(2)
expect("Name absteigend", shownNames(), "Wolf,Ghul,Defias")
killTable:SortBy(2)
expect("Name aufsteigend", shownNames(), "Defias,Ghul,Wolf")

-- Sortieren nach Zeitpunkt nutzt den Zeitstempel, nicht den Text
killTable:SortBy(1)
expect("Zeit absteigend", shownNames(), "Defias,Ghul,Wolf")

-- Filter: Groß-/Kleinschreibung egal, durchsucht alle Spalten
killTable:SetFilter("westFALL")
expect("Filter nach Zone", shownNames(), "Defias,Wolf")
killTable:SetFilter("ghul")
expect("Filter nach Name", shownNames(), "Ghul")
killTable:SetFilter("")
expect("leerer Filter zeigt alles", #killTable:GetVisibleRecords(), 3)

-- Formatierter Text wird für Suche bereinigt
expect("Item-Link ohne Markup", addon.Format.PlainText("|cff0070dd|Hitem:1::|h[Klinge]|h|r"), "[Klinge]")
