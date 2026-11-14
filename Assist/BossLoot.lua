-- Boss-Beute-Vorschau (LT-35, Einstellung bossLoot, Standard an; nur mit ns.DungeonDB, also Classic Era und Forever):
-- Tooltip-Zeilen mit den bekannten Drops ab Qualität rar eines Bosses (ns.DungeonDB.loot je NPC-ID) bzw. aller Bosse
-- einer Instanz (Bossliste über ns.BossNpcs und Rang 3 = Boss in ns.DungeonDB.npcs). Episch/legendär zuerst, Chance
-- falls bekannt, höchstens MAX_LINES Zeilen plus "+X weitere". Nutzer: Bosstabelle in UI/InstanceRunWindow.lua,
-- Tooltip der Dungeon-Eingänge (Assist/DungeonEntrances.lua). Zeilen in einem Tooltip lassen sich nicht überfahren,
-- deshalb zusätzlich IconLinks: Symbol-Links mit eigenem Item-Tooltip (Bosszeilen im Run-Fenster, Live-Karte
-- UI/InstanceRunTracker.lua für den nächsten Boss).
-- Nicht geladene Items: Platzhalter in Qualitätsfarbe, Laden über den Item-Mixin (Item:CreateFromItemID +
-- ContinueOnItemLoad, Blizzard_ObjectAPI); danach ruft onLoaded jeden wartenden Aufrufer, der den Tooltip neu aufbaut. Items, die der
-- Client nicht kennt (IsItemEmpty, z. B. Forever-Items in Classic Era), fallen weg. Ohne Mixin (nicht in jedem Client
-- belegt) stößt C_Item.GetItemInfo das Laden an und das nächste Überfahren zeigt den Link.
local _, ns = ...
local L = ns.L
local Items = ns.Items

ns.RegisterDefaults({
  settings = {
    bossLoot = true,
  },
})

local BossLoot = {}
ns.BossLoot = BossLoot

BossLoot.MAX_LINES = 6
local ITEM_ID, QUALITY, CHANCE = 1, 2, 3
local BOSS_RANK = 3
local RANK_INDEX = 3  -- Spalte Rang in ns.DungeonDB.npcs
local TITLE_COLOR = { 1, 0.82, 0 }
local HINT_COLOR = { 0.7, 0.7, 0.7 }

local sortedByNpc = {}   -- Cache: NPC-ID -> sortierte Drops (nicht verändern)
local sortedByMap = {}   -- Cache: Karten-ID -> sortierte Drops aller Bosse
local loading = {}       -- itemID -> { [onLoaded] = true }, solange ein Ladeauftrag läuft

function BossLoot.IsAvailable()
  return ns.DungeonDB ~= nil and ns.DungeonDB.loot ~= nil
end

local function isEnabled()
  return BossLoot.IsAvailable() and ns.db ~= nil and ns.db.bossLoot
end

-- Höhere Qualität zuerst, dann höhere (bekannte) Chance, dann itemID für eine feste Reihenfolge
local function better(a, b)
  if a[QUALITY] ~= b[QUALITY] then return a[QUALITY] > b[QUALITY] end
  local chanceA, chanceB = a[CHANCE] or -1, b[CHANCE] or -1
  if chanceA ~= chanceB then return chanceA > chanceB end
  return a[ITEM_ID] < b[ITEM_ID]
end

-- Sortierte Drops eines Bosses (leere Liste ohne Daten); zwischengespeichert, nicht verändern
function BossLoot.Items(npcID)
  if not (npcID and BossLoot.IsAvailable()) then return {} end
  local cached = sortedByNpc[npcID]
  if cached then return cached end
  cached = {}
  for index, drop in ipairs(ns.DungeonDB.loot[npcID] or {}) do cached[index] = drop end
  table.sort(cached, better)
  sortedByNpc[npcID] = cached
  return cached
end

-- NPC-IDs der Bosse einer Instanz: Bossliste (Encounter -> NPC, ns.BossNpcs) und Rang 3 aus ns.DungeonDB.npcs
-- (QuestieDB führt manche Endbosse wie Edwin van Cleef nur als Rar-Elite, deshalb beides)
local function bossNpcs(mapID)
  local npcs = {}
  for _, encounterID in ipairs(ns.InstanceBosses.List(mapID) or {}) do
    local npcID = ns.InstanceBosses.NpcID(encounterID)
    if npcID then npcs[npcID] = true end
  end
  for npcID, info in pairs(ns.DungeonDB.npcs[mapID] or {}) do
    if info[RANK_INDEX] == BOSS_RANK then npcs[npcID] = true end
  end
  return npcs
end

-- Sortierte Drops aller Bosse einer Instanz (jedes Item einmal, mit dem besten Eintrag); nicht verändern
function BossLoot.ForInstance(mapID)
  if not (mapID and BossLoot.IsAvailable()) then return {} end
  local cached = sortedByMap[mapID]
  if cached then return cached end
  cached = {}
  local seen = {}
  for npcID in pairs(bossNpcs(mapID)) do
    for _, drop in ipairs(BossLoot.Items(npcID)) do
      local index = seen[drop[ITEM_ID]]
      if not index then
        cached[#cached + 1] = drop
        seen[drop[ITEM_ID]] = #cached
      elseif better(drop, cached[index]) then
        cached[index] = drop
      end
    end
  end
  table.sort(cached, better)
  sortedByMap[mapID] = cached
  return cached
end

-- Item-Mixin des Clients oder nil (Blizzard_ObjectAPI; nicht in jeder Client-Doku belegt)
local function itemMixin(itemID)
  if not (Item and Item.CreateFromItemID) then return nil end
  return Item:CreateFromItemID(itemID)
end

-- Kennt der Client das Item? Ohne Mixin unbekannt, dann zählt es mit
local function exists(item)
  return not (item and item:IsItemEmpty())
end

-- Ladeauftrag für ein nicht zwischengespeichertes Item (ohne Mixin hat Items.GetLink das Laden schon angestoßen). Ein
-- Auftrag je Item; jeder Wartende (Tooltip, Bosszeile) wird nach dem Laden einmal gerufen.
local function requestLoad(itemID, item, onLoaded)
  if not item then return end
  local waiting = loading[itemID]
  if not waiting then
    waiting = {}
    loading[itemID] = waiting
    item:ContinueOnItemLoad(function()
      loading[itemID] = nil
      ns.Debug("bossloot", "item %s loaded", itemID)
      for callback in pairs(waiting) do ns.SafeCall(callback) end
    end)
  end
  if onLoaded then waiting[onLoaded] = true end
end

-- Platzhalter in der Qualitätsfarbe des Items, solange sein Link fehlt
local function placeholder(quality)
  local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
  local text = L.BOSS_LOOT_LOADING
  return color and color.hex and (color.hex .. text .. "|r") or text
end

-- Zeilentext eines bekannten Drops; nil, wenn der Client das Item nicht kennt
local function lineText(drop, onLoaded)
  local itemID = drop[ITEM_ID]
  local link = Items.GetLink(itemID)
  if not link then
    local item = itemMixin(itemID)
    if not exists(item) then return nil end
    requestLoad(itemID, item, onLoaded)
  end
  local text = link or placeholder(drop[QUALITY])
  if drop[CHANCE] then text = string.format(L.BOSS_LOOT_CHANCE, text, tostring(drop[CHANCE])) end
  return text
end

-- Überschrift und Drop-Zeilen an einen Tooltip anhängen; onLoaded() baut den Tooltip neu auf, wenn ein Item geladen
-- ist. Nur die sichtbaren Zeilen laden nach, der Rest zählt in "+X weitere". Rückgabe: true, wenn Zeilen dazukamen
-- (Einstellung aus oder keine Daten: nichts).
function BossLoot.AddLines(tooltip, drops, onLoaded)
  if not isEnabled() or #drops == 0 then return false end
  local lines, more = {}, 0
  for _, drop in ipairs(drops) do
    if #lines < BossLoot.MAX_LINES then
      lines[#lines + 1] = lineText(drop, onLoaded)
    elseif Items.GetLink(drop[ITEM_ID]) or exists(itemMixin(drop[ITEM_ID])) then
      more = more + 1
    end
  end
  if #lines == 0 then return false end
  tooltip:AddLine(L.BOSS_LOOT_TITLE, unpack(TITLE_COLOR))
  for _, text in ipairs(lines) do tooltip:AddLine(text) end
  if more > 0 then tooltip:AddLine(string.format(L.BOSS_LOOT_MORE, more), unpack(HINT_COLOR)) end
  return true
end

-- Kompakte Symbolzeile der ersten MAX_LINES Drops, jedes Symbol ein Item-Link (Tooltip über
-- Widgets.EnableItemLinks am Frame des Texts); kein Laden nötig. nil, wenn aus oder nichts bekannt.
function BossLoot.IconLinks(drops, size)
  if not isEnabled() then return nil end
  local icons = {}
  for _, drop in ipairs(drops) do
    if #icons >= BossLoot.MAX_LINES then break end
    local itemID = drop[ITEM_ID]
    local link = exists(itemMixin(itemID)) and Items.IconLink(itemID, drop[QUALITY], size)
    if link then icons[#icons + 1] = link end
  end
  return #icons > 0 and table.concat(icons, " ") or nil
end
