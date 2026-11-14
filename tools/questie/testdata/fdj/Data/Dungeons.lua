-- Testdaten im Format von ForeverDungeonJournal (Data/Dungeons.lua)
local ADDON_NAME, FDJ = ...
FDJ = FDJ or _G.ForeverDungeonJournal_NS
local ALBA_FAIRMOON_LOCATION = FDJ.Constants.ALBA_FAIRMOON_LOCATION

FDJ.DB = {
    ["Hall of Thanes"] = {
        bosses = {
            { name = "Faldrim Anvilmar", npcID = 261306, loot = { {270227, "Ephemeral Choker", "Neck", 3} } },
            { name = "Magmatus", loot = { {270230, "Kindlegem Girdle", "Waist, Mail", 3} } },
        },
    },
}

local DB = FDJ.DB
DB["The Deadmines"] = {
    quests = { { id = 214, pickup = ALBA_FAIRMOON_LOCATION } },
    bosses = { {
        name = "Rhahk'Zor",
        loot = {{872, "Rockslicer", "Two-Hand, Axe", 3}, {5187, "Rhahk'Zor's Hammer", "Two-Hand, Mace", 3}, {273289, "Ogre Loincloth", "Legs, Cloth", 3}},
        npcID = 644,
    }, {
        name = "Miner Johnson",
        loot = {{5443, "Gold-plated Buckler", "Off Hand, Shield", 3}},
        npcID = 3586,
        rare = true,
    }, {
        name = "Trash",
        trash = true,
        loot = { {280000, "Pirate Hat", "Head, Cloth", 3, "Defias Pirate / Nobody"} },
    } },
}
