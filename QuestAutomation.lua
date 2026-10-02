-- Quests ohne Klicks: annehmen (autoAcceptQuests), geteilte Quests und Eskorten bestätigen
-- (autoAcceptShared), abgeben (autoTurnIn) und bei mehreren Belohnungen die wertvollste wählen
-- (autoChooseReward); Gespräche mit nur einer Option überspringen (skipGossip).
-- Abläufe wie in Blizzards QuestFrame/GossipFrame aller Clients:
--   QUEST_DETAIL          Quest-Text offen: AcceptQuest, bei Quests, die der Client schon selbst
--                         angenommen hat (QuestGetAutoAccept), AcknowledgeAutoAcceptQuest.
--                         PvP-Quests (QuestFlagsPVP) fragen im Spiel nach, die bleiben manuell.
--   QUEST_ACCEPT_CONFIRM  Quest eines anderen Spielers (Eskorte): ConfirmAcceptQuest, Dialog schließen.
--   QUEST_PROGRESS        Abgabe, Gegenstände prüfen: CompleteQuest, wenn IsQuestCompletable.
--   QUEST_COMPLETE        Belohnung: GetQuestReward(Wahl); Wahl = 1 bei einer Belohnung zur Auswahl,
--                         sonst 0 (wie QuestInfoFrame.itemChoice). Quests, die Geld kosten
--                         (GetQuestMoneyToGet), fragen im Spiel nach und bleiben manuell.
--   GOSSIP_SHOW           Gesprächsfenster mit Quest-Listen: zuerst fertige Quests
--                         (C_GossipInfo.SelectActiveQuest), dann neue (SelectAvailableQuest), je questID.
--   QUEST_GREETING        alte Quest-Liste ohne Gespräch: dasselbe mit SelectActiveQuest/
--                         SelectAvailableQuest(index), fertig laut GetActiveTitle.
-- Graue (triviale) und ignorierte Quests werden nicht angenommen: beim Leveln Zeitverschwendung.
-- Gespräch überspringen wie Blizzards GossipFrame bei selectOptionWhenOnlyOption: keine Quests,
-- genau eine verfügbare Option (GossipOptionStatus Available), kein ForceGossip; gewählt mit
-- C_GossipInfo.SelectOptionByIndex(orderIndex). Optionen mit Bestätigung fragt das Spiel weiter nach.
local _, ns = ...
local Comfort = ns.Comfort

local QuestAutomation = {}
ns.QuestAutomation = QuestAutomation

local QUEST_ACCEPT_POPUP = "QUEST_ACCEPT"  -- Blizzards Dialog zu QUEST_ACCEPT_CONFIRM
local NO_CHOICE = 0           -- GetQuestReward ohne Belohnung zur Auswahl
local OPTION_AVAILABLE = 0    -- Enum.GossipOptionStatus.Available
local SELL_PRICE_INDEX = 11   -- Rückgabewert sellPrice von GetItemInfo

local getItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo

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

local function firstComplete(quests)
  for _, quest in ipairs(quests) do
    if quest.isComplete then return quest end
  end
end

ns.RegisterEvent("QUEST_PROGRESS", function()
  if not Comfort.IsActive("autoTurnIn") or not IsQuestCompletable() then return end
  ns.Debug("quests", "completing quest")
  CompleteQuest()
end)

-- Verkaufswert einer Belohnung zur Auswahl; nil, solange der Client das Item nicht kennt
local function choiceValue(index)
  local link = GetQuestItemLink("choice", index)
  return link and select(SELL_PRICE_INDEX, getItemInfo(link))
end

-- Belohnung mit dem höchsten Verkaufswert; nil, wenn ein Wert noch unbekannt ist
local function mostValuableChoice(count)
  local best, bestValue
  for index = 1, count do
    local value = choiceValue(index)
    if not value then return nil end
    if not bestValue or value > bestValue then best, bestValue = index, value end
  end
  return best
end

-- Welche Belohnung genommen wird; nil = Spieler wählt selbst
function QuestAutomation.RewardChoice()
  local count = GetNumQuestChoices()
  if count == 0 then return NO_CHOICE end
  if count == 1 then return 1 end
  if ns.db.autoChooseReward then return mostValuableChoice(count) end
  return nil
end

ns.RegisterEvent("QUEST_COMPLETE", function()
  if not Comfort.IsActive("autoTurnIn") or GetQuestMoneyToGet() > 0 then return end
  local choice = QuestAutomation.RewardChoice()
  ns.Debug("quests", "reward choice %s", choice)
  if choice then GetQuestReward(choice) end
end)

-- Die einzige Gesprächsoption, wenn es sonst nichts zu tun gibt (z.B. Flugmeister, Händler)
local function onlyOption()
  if C_GossipInfo.GetNumAvailableQuests() > 0 or C_GossipInfo.GetNumActiveQuests() > 0 then return nil end
  if C_GossipInfo.ForceGossip() then return nil end
  local options = C_GossipInfo.GetOptions()
  if #options ~= 1 or options[1].status ~= OPTION_AVAILABLE then return nil end
  return options[1]
end

-- Gesprächsfenster: erst fertige Quests abgeben, dann die nächste lohnende öffnen
-- (QUEST_PROGRESS/QUEST_DETAIL übernehmen den Rest), sonst die einzige Option wählen
function QuestAutomation.HandleGossip()
  if Comfort.IsActive("autoTurnIn") then
    local quest = firstComplete(C_GossipInfo.GetActiveQuests())
    if quest then
      ns.Debug("quests", "gossip: turning in quest %s", quest.questID)
      C_GossipInfo.SelectActiveQuest(quest.questID)
      return true
    end
  end
  if Comfort.IsActive("autoAcceptQuests") then
    local quest = firstWorthTaking(C_GossipInfo.GetAvailableQuests())
    if quest then
      ns.Debug("quests", "gossip: opening quest %s", quest.questID)
      C_GossipInfo.SelectAvailableQuest(quest.questID)
      return true
    end
  end
  if Comfort.IsActive("skipGossip") then
    local option = onlyOption()
    if option then
      ns.Debug("quests", "gossip: skipping to option %s", option.orderIndex)
      C_GossipInfo.SelectOptionByIndex(option.orderIndex)
      return true
    end
  end
  return false
end

function QuestAutomation.HandleGreeting()
  if Comfort.IsActive("autoTurnIn") then
    for index = 1, GetNumActiveQuests() do
      local _, isComplete = GetActiveTitle(index)
      if isComplete then
        ns.Debug("quests", "greeting: turning in quest %s", index)
        SelectActiveQuest(index)
        return true
      end
    end
  end
  if Comfort.IsActive("autoAcceptQuests") then
    for index = 1, GetNumAvailableQuests() do
      local isTrivial = GetAvailableQuestInfo(index)
      if not isTrivial then
        ns.Debug("quests", "greeting: opening quest %s", index)
        SelectAvailableQuest(index)
        return true
      end
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
