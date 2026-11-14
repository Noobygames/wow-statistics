-- Testdaten: Auszug im Format von QuestieDB src/corrections/Forever/legacy/classicItemFixes.lua
local QuestieItemFixes = QuestieLoader:CreateModule("QuestieItemFixes")
local QuestieDB = QuestieLoader:ImportModule("QuestieDB");

function QuestieItemFixes:LoadFactionFixes()
    local itemKeys = QuestieDB.itemKeys

    local itemFixesHorde = {
        [17204] = { -- Eye of Sulfuras
            [itemKeys.npcDrops] = {12056},
            [itemKeys.objectDrops] = {},
        },
    }

    local itemFixesAlliance = {
        [17204] = { -- Eye of Sulfuras
            [itemKeys.name] = "Eye of Sulfuras",
            [itemKeys.npcDrops] = {12056},
        },
    }

    if UnitFactionGroup("Player") == "Horde" then
        return itemFixesHorde
    else
        return itemFixesAlliance
    end
end
