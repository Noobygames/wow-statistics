-- Quests ohne Klicks: annehmen (autoAcceptQuests), geteilte Quests und Eskorten bestätigen
-- (autoAcceptShared).
-- Abläufe wie in Blizzards QuestFrame/GossipFrame aller Clients:
--   QUEST_DETAIL          Quest-Text offen: AcceptQuest, bei Quests, die der Client schon selbst
--                         angenommen hat (QuestGetAutoAccept), AcknowledgeAutoAcceptQuest.
--                         PvP-Quests (QuestFlagsPVP) fragen im Spiel nach, die bleiben manuell.
--   QUEST_ACCEPT_CONFIRM  Quest eines anderen Spielers (Eskorte): ConfirmAcceptQuest, Dialog schließen.
--   GOSSIP_SHOW           Gesprächsfenster mit Quest-Liste: C_GossipInfo.SelectAvailableQuest(questID).
--   QUEST_GREETING        alte Quest-Liste ohne Gespräch: SelectAvailableQuest(index).
-- Graue (triviale) und ignorierte Quests werden nicht angenommen: beim Leveln Zeitverschwendung.
local _, ns = ...
local Comfort = ns.Comfort

local QuestAutomation = {}
ns.QuestAutomation = QuestAutomation

local QUEST_ACCEPT_POPUP = "QUEST_ACCEPT"  -- Blizzards Dialog zu QUEST_ACCEPT_CONFIRM

local function isWorthTaking(quest)
  return not quest.isTrivial and not quest.isIgnored
end

-- Erste lohnende Quest aus einer Liste von C_GossipInfo (GossipQuestUIInfo)
local function firstWorthTaking(quests)
  for _, quest in ipairs(quests) do
    if isWorthTaking(quest) then return quest end
  end
end

ns.RegisterEvent("QUEST_DETAIL", function()
  if not Comfort.IsActive("autoAcceptQuests") then return end
  if QuestFlagsPVP and QuestFlagsPVP() then return end
  if QuestGetAutoAccept and QuestGetAutoAccept() then
    ns.Debug("quests", "acknowledging auto-accepted quest")
    AcknowledgeAutoAcceptQuest()
  else
    ns.Debug("quests", "accepting quest")
    AcceptQuest()
  end
end)

ns.RegisterEvent("QUEST_ACCEPT_CONFIRM", function()
  if not Comfort.IsActive("autoAcceptShared") then return end
  ns.Debug("quests", "confirming shared quest")
  ConfirmAcceptQuest()
  StaticPopup_Hide(QUEST_ACCEPT_POPUP)
end)

-- Gesprächsfenster: nächste lohnende Quest öffnen; QUEST_DETAIL nimmt sie dann an
function QuestAutomation.HandleGossip()
  if not Comfort.IsActive("autoAcceptQuests") then return false end
  local quest = firstWorthTaking(C_GossipInfo.GetAvailableQuests())
  if not quest then return false end
  ns.Debug("quests", "gossip: opening quest %s", quest.questID)
  C_GossipInfo.SelectAvailableQuest(quest.questID)
  return true
end

function QuestAutomation.HandleGreeting()
  if not Comfort.IsActive("autoAcceptQuests") then return false end
  for index = 1, GetNumAvailableQuests() do
    local isTrivial = GetAvailableQuestInfo(index)
    if not isTrivial then
      ns.Debug("quests", "greeting: opening quest %s", index)
      SelectAvailableQuest(index)
      return true
    end
  end
  return false
end

ns.RegisterEvent("GOSSIP_SHOW", function()
  QuestAutomation.HandleGossip()
end)

ns.RegisterEvent("QUEST_GREETING", function()
  QuestAutomation.HandleGreeting()
end)
