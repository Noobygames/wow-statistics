-- Historie "Speedrun": Läufe mit Favoriten, Klick wählt den Vergleich.
local L = addon.L

local function otherCharacter(name, class, levels)
  LevelTimerStatsDB.characters[name .. "-Testrealm"] = {
    name = name, realm = "Testrealm", class = class, currentLevel = { level = 30, counters = {} },
    levelHistory = levels, sessionHistory = {}, killLog = {}, deathLog = {},
  }
end

wow.login({ name = "Neu", level = 12, playedSeconds = 0 })
addon.character.levelHistory[10] = { level = 10, seconds = 3000, counters = {} }
addon.character.levelHistory[11] = { level = 11, seconds = 2000, counters = {} }
otherCharacter("Rekord", "MAGE", { [10] = { level = 10, seconds = 2500 }, [11] = { level = 11, seconds = 2500 } })
otherCharacter("Lahm", "ROGUE", { [10] = { level = 10, seconds = 9000 } })

SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Speedrun", wow.click(L.HISTORY_GROUP_SPEEDRUN))
local view = wow.shownTable()
local runs = view:GetVisibleRecords()
expect("alle Läufe", #runs, 3)
expect("eingeloggter zuerst", runs[1].id, "Neu-Testrealm")

local function runByName(name)
  for _, run in ipairs(view:GetVisibleRecords()) do
    if run.name == name then return run end
  end
end
expect("Zeit bis zum aktuellen Level", runByName("Rekord").timeToLevel, 5000)
expect("Lauf ohne alle Level: keine Zeit", runByName("Lahm").timeToLevel, nil)

-- Zeile per Name finden (Zelle 2 = Name) und anklicken
local function clickRow(name, mouseButton)
  local row = wow.findFrame(function(frame)
    local cells = rawget(frame, "cells")
    return cells and cells[2]._text:find(name, 1, true) == 1 and frame._scripts.OnMouseUp ~= nil and frame:IsShown()
  end)
  row._scripts.OnMouseUp(row, mouseButton)
end

clickRow("Rekord", "LeftButton")
expect("Klick wählt Vergleich", LevelTimerDB.splitReference.id, "Rekord-Testrealm")
expect("Vergleich als Lauf", LevelTimerDB.splitComparison, "run")

clickRow("Lahm", "RightButton")
expect("Favorit oben", view:GetVisibleRecords()[1].name, "Lahm")
clickRow("Lahm", "RightButton")
expect("Favorit wieder weg", view:GetVisibleRecords()[1].name, "Neu")

-- Eigener Lauf ist kein Vergleich
clickRow("Neu", "LeftButton")
expect("eigener Lauf nicht wählbar", LevelTimerDB.splitReference.id, "Rekord-Testrealm")

-- Suche nach Klasse
view:SetFilter("rogue")
local filtered = view:GetVisibleRecords()
expect("Filter nach Klasse", #filtered == 1 and filtered[1].name, "Lahm")

-- Status-Spalte zeigt den gewählten Vergleich
view:SetFilter("")
expectTrue("Status im Export", view:BuildCsv():find(L.RUN_REFERENCE, 1, true) ~= nil)

-- Rekorde: schnellste Zeit je Level, eigene Zeit und Abweichung
expectTrue("Unterreiter Rekorde", wow.click(L.HISTORY_TAB_RECORDS))
local records = wow.shownTable():GetVisibleRecords()
expect("ein Rekord je Level", #records, 2)
expect("höchstes Level zuerst", records[1].level, 11)
expect("Rekord Level 11", records[1].seconds, 2000)
expect("hält der eingeloggte", records[1].run.name, "Neu")
expect("Rekord Level 10", records[2].seconds, 2500)
expect("hält Rekord", records[2].run.name, "Rekord")
expect("eigene Zeit", records[2].ownSeconds, 3000)

-- Noch kein eigenes Level abgeschlossen: keine Zeit bis zum aktuellen Level statt "0s"
expect("leere Spanne", addon.Runs.SumOfLevels({ [10] = 100 }, 12, 11), nil)
