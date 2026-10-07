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

-- Sortieren nach Name (Spalte 2, Text): erst aufsteigend (A-Z), dann absteigend
killTable:SortBy(2)
expect("Name aufsteigend", shownNames(), "Defias,Ghul,Wolf")
killTable:SortBy(2)
expect("Name absteigend", shownNames(), "Wolf,Ghul,Defias")

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

-- Sessions nach Level: numerisch, auch bei Spannen wie "9-10"
local sessions = addon.character.sessionHistory
for _, levels in ipairs({ { 10, 10 }, { 9, 10 }, { 2, 3 } }) do
  table.insert(sessions, { startedAt = 1000, endedAt = 2000, seconds = 600, startLevel = levels[1],
    endLevel = levels[2], xp = 0, counters = {} })
end
wow.click("Sessions")
local sessionTable = wow.shownTable()
local function sessionLevels()
  local levels = {}
  for _, record in ipairs(sessionTable:GetVisibleRecords()) do
    if record.startLevel and not record.isCurrent then table.insert(levels, record.startLevel) end
  end
  return table.concat(levels, ",")
end
sessionTable:SortBy(3)
expect("absteigend nach Start-Level", sessionLevels(), "10,9,2")
sessionTable:SortBy(3)
expect("aufsteigend nach Start-Level", sessionLevels(), "2,9,10")
