-- Dungeonquest-Hinweise (Classic Era, DungeonDB): Fenster beim Betreten einer Zone mit Gebern.
-- Wilder Klippenschmied 656 steht auf Karte 1453 (70, 41) und bietet 167/168 (Allianz, ab 15/14).
local L = addon.L
local Hint = addon.DungeonQuestHint
local Hints = addon.DungeonQuestHints

local completed = {}
C_QuestLog = C_QuestLog or {}
C_QuestLog.IsQuestFlaggedCompleted = function(questID) return completed[questID] == true end
function GetRealZoneText(mapID) return mapID == 36 and "Die Todesminen" or ("Instanz " .. tostring(mapID)) end
wow.state.questTitles[167] = "Die Bruderschaft"
wow.state.questTitles[168] = "Gesammelte Erinnerungen"

local MAPS = {
  [1415] = { name = "Östliche Königreiche", mapType = 2 },
  [1453] = { name = "Sturmwind", mapType = 3, parentMapID = 1415 },
  [9999] = { name = "Testzone", mapType = 3, parentMapID = 1415 },
}
local playerMap = { id = 9999 }
C_Map = {
  GetBestMapForUnit = function() return playerMap.id end,
  GetMapInfo = function(mapID) return MAPS[mapID] end,
}

wow.state.class = "WARRIOR"
wow.login({ level = 15 })
wow.fire("QUEST_LOG_UPDATE")
expect("Standard an", addon.db.dungeonQuestZoneHint, true)

-- Zone ohne Geber: kein Fenster
wow.fire("PLAYER_ENTERING_WORLD")
expectTrue("ohne Geber: kein Fenster", not Hint.IsShown())

-- Ausgeschaltet: nichts
playerMap.id = 1453
addon.Set("dungeonQuestZoneHint", false)
wow.fire("ZONE_CHANGED_NEW_AREA")
expectTrue("aus", not Hint.IsShown())

-- Sturmwind: zwei Angebote, Titel mit Zonenname, Zeile mit Instanz, Geber und Ort
addon.Set("dungeonQuestZoneHint", true)
wow.fire("ZONE_CHANGED_NEW_AREA")
expectTrue("Sturmwind: Fenster", Hint.IsShown())
local entries = Hints.ZoneEntries(1453)
expectTrue("mindestens 167 und 168", #entries >= 2)
local texts = {}
for _, entry in ipairs(entries) do texts[entry.text] = entry end
local first = texts[string.format(L.DUNGEON_QUEST_HINT_ROW, "Die Bruderschaft", "Die Todesminen")]
expectTrue("Zeile mit Instanz", first ~= nil)
expect("Geber und Ort", first and first.detail,
  string.format(L.DUNGEON_QUEST_HINT_DETAIL, L.DUNGEON_QUEST_GIVER_NPC, "Sturmwind (70, 41)"))

-- Gelernter Gebername ersetzt "Questgeber"
LevelTimerStatsDB.questNpcs = { [167] = { giver = { name = "Wilder Klippenschmied" }, spots = {} } }
expect("gelernter Name", Hints.GiverName(167), "Wilder Klippenschmied")

-- Schließt nach der Anzeigedauer von selbst
wow.advance(Hint.DISPLAY_SECONDS + 1)
wow.update(0.1)
expectTrue("schließt von selbst", not Hint.IsShown())

-- Einmal je Zone und Sitzung
wow.fire("ZONE_CHANGED_NEW_AREA")
expectTrue("nicht zweimal", not Hint.IsShown())

