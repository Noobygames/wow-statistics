-- Hinweise zu Dungeonquests im Fenster UI/DungeonQuestHint.lua (nur mit ns.DungeonDB, also Classic Era und Forever).
-- Zone (Einstellung dungeonQuestZoneHint, an): beim Betreten einer Zone (ZONE_CHANGED_NEW_AREA, nach dem Login
-- PLAYER_ENTERING_WORLD) die jetzt annehmbaren Dungeonquests und Kettenschritte, deren Geber in dieser Zone steht
-- (DungeonQuests.OffersOnMap), einmal je Zone und Sitzung. Zone = C_Map.GetBestMapForUnit("player"), Kleinstkarten
-- über QuestLog.ZoneMapOf auf Zonenebene.
-- Gebername: in der DungeonDB gibt es keine Namen; NPC = gelernter Name aus QuestNpcs (Annahme-Dialog), sonst
-- "Questgeber"; Gegenstand = C_Item.GetItemNameByID (Classic Era laut Blizzard-Doku, sonst geschützt); Objekt = "Objekt".
-- Ort "Zone (x, y)" über DungeonEntrances.StartText (C_Map.GetMapInfo).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    dungeonQuestZoneHint = true,
  },
})
local L = ns.L
local DungeonQuests = ns.DungeonQuests

local DungeonQuestHints = {}
ns.DungeonQuestHints = DungeonQuestHints

local GIVER_FALLBACK = { npc = "DUNGEON_QUEST_GIVER_NPC", object = "DUNGEON_QUEST_GIVER_OBJECT",
  item = "DUNGEON_QUEST_GIVER_ITEM" }

local shownZones = {}  -- [uiMapID] = true: in dieser Sitzung schon gezeigt

local function readable(value)
  if value == nil or ns.IsSecret(value) then return nil end
  return value
end

-- Name des Gebers einer Quest; nil, wenn die Art unbekannt ist
function DungeonQuestHints.GiverName(questID)
  local kind, giverID = DungeonQuests.Giver(questID)
  if not kind then return nil end
  local name
  if kind == "npc" then
    local learned = ns.QuestNpcs.Get(questID)
    name = learned and learned.giver and learned.giver.name
  elseif kind == "item" and C_Item and C_Item.GetItemNameByID then
    name = readable(C_Item.GetItemNameByID(giverID))
  end
  if type(name) == "string" and name ~= "" then return name end
  return L[GIVER_FALLBACK[kind]]
end

-- Zweite Zeile eines Eintrags: "Geber – Zone (x, y)", nur der Geber oder nur der Ort; nil ohne beides
function DungeonQuestHints.Detail(questID, place)
  local giver = DungeonQuestHints.GiverName(questID)
  local where = place and ns.DungeonEntrances.StartText(place)
  if giver and where then return string.format(L.DUNGEON_QUEST_HINT_DETAIL, giver, where) end
  return giver or where
end

-- Zeile eines Angebots: "Titel (Instanz)" bzw. "Titel (Instanz, Schritt 2/7)"
local function offerText(offer)
  local questTitle, instance = DungeonQuests.Title(offer.questID), ns.InstanceInfo.MapName(offer.mapID)
  if offer.step then return string.format(L.DUNGEON_QUEST_HINT_CHAIN_ROW, questTitle, instance, offer.step, offer.total) end
  return string.format(L.DUNGEON_QUEST_HINT_ROW, questTitle, instance)
end

-- Einträge für die Geber auf einer Zonenkarte
function DungeonQuestHints.ZoneEntries(uiMapID)
  local entries = {}
  for _, point in ipairs(DungeonQuests.OffersOnMap(uiMapID)) do
    local place = { uiMapID = uiMapID, x = point.x, y = point.y }
    for _, offer in ipairs(point.offers) do
      table.insert(entries, { text = offerText(offer), detail = DungeonQuestHints.Detail(offer.questID, place),
        place = place, questID = offer.questID })
    end
  end
  return entries
end

local function currentZone()
  local mapID = C_Map and C_Map.GetBestMapForUnit and readable(C_Map.GetBestMapForUnit("player"))
  return mapID and ns.QuestLog.ZoneMapOf(mapID)
end

local function zoneName(uiMapID)
  local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(uiMapID)
  return info and readable(info.name) or ""
end

local function onZoneEntered()
  if not (ns.db and ns.db.dungeonQuestZoneHint and DungeonQuests.IsAvailable()) then return end
  local zone = currentZone()
  if not zone or shownZones[zone] then return end
  local entries = DungeonQuestHints.ZoneEntries(zone)
  ns.Debug("dungeonquests", "zone %s: %s offers", zone, #entries)
  if #entries == 0 then return end
  shownZones[zone] = true
  ns.DungeonQuestHint.Show(string.format(L.DUNGEON_QUEST_ZONE_HINT_TITLE, zoneName(zone)), entries)
end

ns.RegisterEvent("ZONE_CHANGED_NEW_AREA", onZoneEntered)
ns.RegisterEvent("PLAYER_ENTERING_WORLD", onZoneEntered)
