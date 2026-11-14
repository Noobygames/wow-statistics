-- Testdaten: Auszug im Format von QuestieDB src/corrections/Forever/legacy/classicQuestFixes.lua
local QuestieQuestFixes = QuestieLoader:CreateModule("QuestieQuestFixes")
local QuestieDB = QuestieLoader:ImportModule("QuestieDB")

function QuestieQuestFixes:Load()
  return {}
end

function QuestieQuestFixes:LoadFactionFixes()
    local questKeys = QuestieDB.questKeys
    local raceIDs = QuestieDB.raceKeys
    local playerClass = UnitClassBase("player")

    local questFixesHorde = {
        [53] = { -- Alias-Zone
            [questKeys.startedBy] = {{999}},
        },
        [50] = { -- Draußen töten
            [questKeys.nextQuestInChain] = ({
                ["WARRIOR"] = 100,
            })[playerClass],
            [questKeys.requiredRaces] = raceIDs.NONE,
        },
    }

    local questFixesAlliance = {
        [53] = { -- Alias-Zone
            [questKeys.startedBy] = {{14387}},
        },
        [50] = { -- Draußen töten
            [questKeys.requiredRaces] = raceIDs.NONE,
        },
    }

    if UnitFactionGroup("Player") == "Horde" then
        return questFixesHorde
    else
        return questFixesAlliance
    end
end
