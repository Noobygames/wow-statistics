-- LT-35: Boss-Beute-Vorschau in Classic Era: sortierte Drops je Boss und Instanz, Tooltip der Bosszeile im
-- Run-Fenster mit Links, Platzhalter für nicht geladene Items, Nachladen, unbekannte Items fallen weg, Einstellung aus
local BossLoot = addon.BossLoot
local L = addon.L

expectTrue("Beutedaten in Classic Era", BossLoot.IsAvailable())
local DEADMINES = { name = "Die Todesminen", type = "party", difficulty = 1, mapID = 36, maxPlayers = 5 }

-- Sortierung: höhere Qualität zuerst, dann bekannte Chance
local loot = addon.DungeonDB.loot
loot[990001] = { { 100, 3 }, { 101, 4, 5 }, { 102, 4, 20 }, { 103, 5 } }
local ids = {}
for index, drop in ipairs(BossLoot.Items(990001)) do ids[index] = drop[1] end
expect("legendär, episch nach Chance, rar", table.concat(ids, ","), "103,102,101,100")
expectTrue("Instanzbeute der Todesminen", #BossLoot.ForInstance(36) > 0)

-- Forever-eigene Items (ab 200000) kennt der Classic-Client nicht
wow.state.unknownItems = setmetatable({}, { __index = function(_, itemID) return itemID > 200000 end })
wow.state.itemLinks = { [5191] = "|cff0070dd[Cruel Barb]|r" }

wow.login({ level = 20, xp = 0, xpMax = 100000 })
wow.state.instance = DEADMINES
wow.fire("PLAYER_ENTERING_WORLD")
wow.advance(60)
wow.fire("ENCOUNTER_END", 2747, "Edwin van Cleef", 1, 5, 1)
SlashCmdList.LEVELTIMER("runs")
local parts = addon.InstanceRunWindow.Parts()
local edwin
for _, row in ipairs(parts.bossRows) do
  if row.npcID == 639 then edwin = row end
end
expectTrue("Bosszeile für Edwin van Cleef (NPC 639)", edwin ~= nil)

-- Überfahren: Name, Überschrift, Link, Platzhalter für die übrigen drei Classic-Items, keine Forever-Items
edwin:GetScript("OnEnter")(edwin)
local lines = GameTooltip._lines
expect("Überschrift", lines[2], L.BOSS_LOOT_TITLE)
expect("Link des geladenen Items", lines[3], "|cff0070dd[Cruel Barb]|r")
expectTrue("Platzhalter für nicht geladene Items", lines[4]:find(L.BOSS_LOOT_LOADING, 1, true) ~= nil)
expect("nur die vier Classic-Items", #lines, 6)
expectTrue("Ladeauftrag für Item 5193", wow.state.itemLoads[5193] ~= nil)

-- Nachgeladen: der Tooltip baut sich mit dem Link neu auf
wow.state.itemLinks[5193] = "|cff0070dd[Smelting Pants]|r"
wow.state.itemLoads[5193]()
expect("Link nach dem Laden", GameTooltip._lines[4], "|cff0070dd[Smelting Pants]|r")

-- Mehr als MAX_LINES Drops: "+X weitere"
wow.state.unknownItems = {}
edwin:GetScript("OnEnter")(edwin)
local total = #BossLoot.Items(639)
expect("Überlaufzeile", GameTooltip._lines[#GameTooltip._lines],
  string.format(L.BOSS_LOOT_MORE, total - BossLoot.MAX_LINES))

-- Einstellung aus: kein Tooltip-Inhalt
addon.Set("bossLoot", false)
expect("aus: keine Zeilen", BossLoot.AddLines(GameTooltip, BossLoot.Items(639)), false)
expect("keine Lua-Fehler", #wow.errors, 0)
