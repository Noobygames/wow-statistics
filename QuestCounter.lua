-- Zählt abgegebene Quests und die XP daraus.
local _, ns = ...
local Stats = ns.Stats

ns.RegisterEvent("QUEST_TURNED_IN", function(_, xpReward)
  Stats.Increment(Stats.QUESTS)
  if xpReward and not ns.IsSecret(xpReward) then
    Stats.Increment(Stats.XP_QUESTS, xpReward)
  end
end)
