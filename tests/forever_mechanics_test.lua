-- Mechaniken auf WoW Forever (LT-56): nur Zeilen für Forever (Classic-only fällt weg, Forever-eigene Dungeons dazu);
-- Zeilen, die nur aus Classic übernommen sind, bekommen eine graue Hinweiszeile, bestätigte nicht.
local L = addon.L
local Tips = addon.MechanicTips

wow.login({ level = 20 })

expectTrue("Forever: verfügbar", Tips.IsAvailable())

local lines = {}
local tooltip = { AddLine = function(_, text) table.insert(lines, text) end }
local function linesFor(npcID)
  lines = {}
  wow.state.units.target = { name = "Gegner", guid = "Creature-0-1-0-1-" .. npcID .. "-0001" }
  Tips.AddUnitLines(tooltip, "target")
  return lines
end

-- Classic-only (Zauber fehlt im Forever-Build): Arkane Aberration (Düsterbruch) hat keine Zeile mehr
expect("Classic-only weg", #linesFor(11480), 0)
for npcID, list in pairs(addon.Mechanics) do
  for _, mechanic in ipairs(list) do
    if mechanic[5] == "c" then expect("Classic-Zeile bei " .. npcID, mechanic[5], "nicht auf Forever") end
  end
end

-- Forever-Dungeon: Atrexis (Stadt Dalaran) mit drei bestätigten Zeilen, kein Hinweis
local atrexis = linesFor(247126)
expect("Forever-Boss", #atrexis, 3)
expectTrue("Forever-Text", atrexis[1]:find("Unheilige Raserei", 1, true) ~= nil)

-- Von foreverchanges bestätigt (korrigierte Zauber-ID 5532): Oggleflint ohne Hinweis
local oggleflint = linesFor(11517)
expect("bestätigt: kein Hinweis", oggleflint[#oggleflint]:find(L.MECHANIC_UNVERIFIED, 1, true), nil)
expectTrue("Forever-Zauber-ID", oggleflint[1]:find("Spell_5532", 1, true) ~= nil)

-- Nur aus Classic übernommen: Defias-Schwarzwache (Todesminen) mit Hinweis als letzte Zeile
local blackguard = linesFor(636)
expect("Hinweiszeile", blackguard[#blackguard], L.MECHANIC_UNVERIFIED)
expect("Zeile + Hinweis", #blackguard, 2)
