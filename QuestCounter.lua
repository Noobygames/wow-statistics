-- Zählt abgegebene Quests auf dem aktuellen Level und die XP daraus.
local _, ns = ...
local LevelStats = ns.LevelStats

ns.RegisterEvent("QUEST_TURNED_IN", function(_, xpReward)
  LevelStats.Increment(LevelStats.QUESTS)
  if xpReward and not ns.IsSecret(xpReward) then
    LevelStats.Increment(LevelStats.XP_QUESTS, xpReward)
  end
end)
