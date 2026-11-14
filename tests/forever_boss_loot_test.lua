-- LT-57: Boss-Beute in Forever: Drops nur aus Classic-Daten (viertes Feld) bekommen ein Sternchen in Tooltip-Zeile und
-- Symbolzeile, der Tooltip eine Hinweiszeile; bestätigte Drops bleiben unmarkiert
local BossLoot = addon.BossLoot
local L = addon.L

expectTrue("Beutedaten in Forever", BossLoot.IsAvailable())
-- echte Daten: Rhahk'Zor mit Classic-Hammer (FDJ) und Forever-Items
local hammer = false
for _, drop in ipairs(addon.DungeonDB.loot[644] or {}) do hammer = hammer or drop[1] == 5187 end
expectTrue("Rhahk'Zors Hammer aus ForeverDungeonJournal", hammer)

wow.login({ level = 20, xp = 0, xpMax = 100000 })
wow.state.itemLinks = { [100] = "[Classic]", [101] = "[Forever]" }
wow.state.itemIcons = { [100] = 1, [101] = 2 }
addon.DungeonDB.loot[990002] = { { 100, 3, nil, 1 }, { 101, 3 } }
local drops = BossLoot.Items(990002)

GameTooltip:ClearLines()
expectTrue("Zeilen", BossLoot.AddLines(GameTooltip, drops))
local lines = GameTooltip._lines
expectTrue("Classic-Drop mit Sternchen", lines[2]:find("[Classic] ", 1, true) == 1 and lines[2]:find("*", 1, true) ~= nil)
expect("bestätigter Drop ohne Sternchen", lines[3], "[Forever]")
expect("Hinweiszeile", lines[4], "* " .. L.LOOT_UNVERIFIED)

local icons = BossLoot.IconLinks(drops, 16) or ""
local _, marks = icons:gsub("%*", "")
expect("ein Sternchen in der Symbolzeile", marks, 1)

-- nur bestätigte Drops: kein Hinweis
addon.DungeonDB.loot[990003] = { { 101, 3 } }
GameTooltip:ClearLines()
BossLoot.AddLines(GameTooltip, BossLoot.Items(990003))
expect("ohne Hinweis", #GameTooltip._lines, 2)
expect("keine Lua-Fehler", #wow.errors, 0)
