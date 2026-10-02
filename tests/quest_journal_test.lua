-- Quest-Journal: Name, XP und Gold jeder abgegebenen Quest.
local Stats = addon.Stats

wow.login({ level = 15, zone = "Westfall" })

-- Name aus C_QuestLog
wow.state.questTitles[101] = "Die Verteidigung von Westfall"
wow.fire("QUEST_TURNED_IN", 101, 1200, 2500)

-- Name aus dem Abgabe-Dialog, wenn C_QuestLog nichts liefert
wow.state.questTitle = "Gnollplage"
wow.fire("QUEST_COMPLETE")
wow.fire("QUEST_TURNED_IN", 102, 800, 0)

-- Weder noch: Name unbekannt, Client ohne XP-Angabe
wow.fire("QUEST_TURNED_IN", 103, nil, nil)

local quests = addon.character.questLog
expect("drei Quests", #quests, 3)
expect("Name aus C_QuestLog", quests[1].name, "Die Verteidigung von Westfall")
expect("XP", quests[1].xp, 1200)
expect("Gold in Kupfer", quests[1].money, 2500)
expect("Zone", quests[1].zone, "Westfall")
expect("Name aus Abgabe-Dialog", quests[2].name, "Gnollplage")
expect("Dialog-Titel nur für eine Quest", quests[3].name, nil)
expect("ID gespeichert", quests[3].questID, 103)
expect("Zähler weiterhin", Stats.Get(Stats.LEVEL, Stats.QUESTS), 3)

local log = addon.History.GetQuestLog(addon.characterKey)
expect("neueste zuerst", log[1].questID, 103)

SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Quests", wow.click("Quests"))
