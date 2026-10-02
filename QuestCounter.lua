-- Zählt abgegebene Quests und die XP daraus und schreibt jede Quest ins Journal.
-- Name: C_QuestLog.GetTitleForQuestID, wo vorhanden; sonst der Titel aus dem Quest-Fenster,
-- der bei QUEST_COMPLETE (Abgabe-Dialog offen) gemerkt wird.
local _, ns = ...
local Stats = ns.Stats
local Journal = ns.Journal

local pendingTitle  -- Titel der Quest im offenen Abgabe-Dialog

local function readable(value)
  if value == nil or ns.IsSecret(value) then return nil end
  return value
end

local function questName(questID)
  local title = C_QuestLog and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID)
  return readable(title) or pendingTitle
end

ns.RegisterEvent("QUEST_COMPLETE", function()
  pendingTitle = GetTitleText and readable(GetTitleText()) or nil
end)

ns.RegisterEvent("QUEST_TURNED_IN", function(questID, xpReward, moneyReward)
  xpReward, moneyReward = readable(xpReward), readable(moneyReward)
  Stats.Increment(Stats.QUESTS)
  if xpReward then
    Stats.Increment(Stats.XP_QUESTS, xpReward)
  end
  Journal.AddQuest(questID, questName(questID), xpReward, moneyReward)
  pendingTitle = nil
end)
