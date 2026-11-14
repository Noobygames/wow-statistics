-- Dungeonquests hervorheben (Einstellung dungeonQuestTags im Reiter "Komfort", an; nur mit ns.DungeonDB, also
-- Classic Era und Forever): Questnamen in Questlog, Gespräch, Gruß und (Classic) Tracker bekommen den farbigen
-- Kurznamen der Instanz angehängt ("Arugal muss sterben [BS]", Lib/QuestListHooks.lua), Quest-Tooltips eine Zeile
-- "Dungeon: Burg Schattenfang". Schritte einer Vorquest-Kette (DungeonQuests.Chain) bekommen den Kurznamen mit Schritt
-- ("[BS 2/7]", leiser gefärbt) und die Zeile "Führt zu Burg Schattenfang (Schritt 2/7)".
-- Gruß-Knöpfe tragen keine questID: Zuordnung über den Titel, zuerst im Questlog, dann unter den Quests, die der
-- Gesprächspartner laut DungeonDB vergibt (UnitGUID("npc")).
-- Quest-Tooltips: Post-Hook auf SetHyperlink von GameTooltip und ItemRefTooltip (Chat-Links "quest:<id>:...", alle
-- Clients) und in Forever auf QuestMapLogTitleButton_OnEnter (Questlog-Tooltip; Gethe/wow-ui-source, Zweig forever,
-- Blizzard_UIPanels_Game/Mainline/QuestMapFrame.lua: self.info.questID). Classic Era zeigt im Questlog keinen Tooltip.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    dungeonQuestTags = true,
  },
})
local L = ns.L
local DungeonQuests = ns.DungeonQuests

local DungeonQuestTags = {}
ns.DungeonQuestTags = DungeonQuestTags

local TAG_COLOR = "info"  -- Theme-Farbe des Kurznamens und der Tooltipzeile
local CHAIN_COLOR = "muted"  -- Vorquests: leiser als die Dungeonquest selbst
local NPC_UNIT = "npc"
local QUEST_LINK_PATTERN = "quest:(%d+)"
local TOOLTIPS = { "GameTooltip", "ItemRefTooltip" }

local hooked = {}

function DungeonQuestTags.IsAvailable()
  return DungeonQuests.IsAvailable()
end

local function isEnabled(db)
  return db and db.dungeonQuestTags and DungeonQuestTags.IsAvailable()
end

local function endsWith(text, suffix)
  return suffix ~= "" and text:sub(-#suffix) == suffix
end

-- Farbiger Kurzname der Instanz einer Dungeonquest ("[BS]"), bei Vorquests mit Schritt ("[BS 2/7]"); nil ohne Bezug
function DungeonQuestTags.Tag(questID)
  local mapID = DungeonQuests.Instance(questID)
  if mapID then return string.format("%s[%s]|r", ns.Theme.Hex(TAG_COLOR), DungeonQuests.ShortName(mapID)) end
  local chainMap, _, step, total = DungeonQuests.Chain(questID)
  if not chainMap then return nil end
  return string.format("%s[%s %d/%d]|r", ns.Theme.Hex(CHAIN_COLOR), DungeonQuests.ShortName(chainMap), step, total)
end

-- Quest-ID zu einem Gruß-Knopf über den Titel (Text kann schon "[12] " vorn tragen)
local function questByTitle(text)
  for _, entry in ipairs(ns.QuestLog.Entries()) do
    if entry.questID and entry.title and text:find(entry.title, 1, true) then return entry.questID end
  end
  local npcID = ns.QuestBlocklist.NpcId(UnitGUID(NPC_UNIT))
  local quests = npcID and ns.DungeonDB.givers.npc[npcID]
  for _, questID in ipairs(quests or {}) do
    if text:find(DungeonQuests.Title(questID), 1, true) then return questID end
  end
end

-- Questname mit angehängtem Kurznamen; nil ohne Dungeonquest oder schon ergänzt
function DungeonQuestTags.Decorate(text, quest)
  local tag = DungeonQuestTags.Tag(quest.questID or questByTitle(text))
  if not tag or endsWith(text, tag) then return nil end
  return text .. " " .. tag
end

-- Tooltipzeile "Dungeon: Burg Schattenfang" bzw. "Führt zu Burg Schattenfang (Schritt 2/7)"; nil ohne Bezug
function DungeonQuestTags.TooltipLine(questID)
  local mapID = DungeonQuests.Instance(questID)
  if mapID then return string.format(L.DUNGEON_QUEST_LINE, ns.InstanceInfo.MapName(mapID)) end
  local chainMap, _, step, total = DungeonQuests.Chain(questID)
  if not chainMap then return nil end
  return string.format(L.DUNGEON_QUEST_CHAIN_LINE, ns.InstanceInfo.MapName(chainMap), step, total)
end

local function addTooltipLine(tooltip, questID)
  if not isEnabled(ns.db) or type(questID) ~= "number" or ns.IsSecret(questID) then return end
  local line = DungeonQuestTags.TooltipLine(questID)
  if not line then return end
  tooltip:AddLine(line, ns.Theme.RGB(TAG_COLOR))
  tooltip:Show()  -- Größe nach der neuen Zeile anpassen
end

local function onHyperlink(tooltip, link)
  if type(link) ~= "string" or ns.IsSecret(link) then return end
  local id = link:match(QUEST_LINK_PATTERN)
  if id then addTooltipLine(tooltip, tonumber(id)) end
end

local function onQuestLogTitleEnter(button)
  local info = type(button) == "table" and button.info
  addTooltipLine(GameTooltip, type(info) == "table" and info.questID or button.questID)
end

ns.QuestListHooks.Register({ enabled = isEnabled, decorate = DungeonQuestTags.Decorate })

local function hookAll()
  if not DungeonQuestTags.IsAvailable() then return end
  for _, name in ipairs(TOOLTIPS) do
    local tooltip = _G[name]
    if not hooked[name] and tooltip and tooltip.SetHyperlink then
      hooked[name] = true
      hooksecurefunc(tooltip, "SetHyperlink", function(...) ns.SafeCall(onHyperlink, ...) end)
    end
  end
  if not hooked.questLog and type(QuestMapLogTitleButton_OnEnter) == "function" then
    hooked.questLog = true
    hooksecurefunc("QuestMapLogTitleButton_OnEnter", function(...) ns.SafeCall(onQuestLogTitleEnter, ...) end)
  end
end

ns.OnLogin(hookAll)
ns.RegisterEvent("ADDON_LOADED", hookAll)
