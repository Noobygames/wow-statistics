-- Twink mit Daten aus v1.x (Schema 3, ohne Journale, Zonen- und Tageswerte): Historie und
-- Graphen funktionieren, obwohl er nicht eingeloggt ist.
LevelTimerStatsDB = { characters = { ["Alt-Realm"] = {
  schemaVersion = 3, name = "Alt", realm = "Realm", class = "MAGE",
  currentLevel = { level = 12, counters = { pveKills = 3 } },
  levelHistory = { [11] = { level = 11, seconds = 900, xp = 8800, counters = { pveKills = 20 } } },
  sessionHistory = {},
} } }
wow.login({ name = "Main", realm = "Realm" })

local History, Analysis = addon.History, addon.Analysis
local key = "Alt-Realm"
for _, getter in ipairs({ "GetLevelRecords", "GetSessionRecords", "GetMilestones", "GetKillLog", "GetDeathLog",
    "GetQuestLog", "GetLootLog", "GetNearDeathLog", "GetInstanceLog" }) do
  expectTrue("History." .. getter, pcall(History[getter], key))
end
for _, getter in ipairs({ "TimePerLevel", "XpRatePerLevel", "KillsPerDay", "PlayTimePerDay", "PlayTimePerWeek",
    "SessionXpTimeline", "XpRatePerZone", "TopKills", "DeathCauses" }) do
  expectTrue("Analysis." .. getter, pcall(Analysis[getter], key))
end
expectTrue("Zonen", pcall(addon.Zones.GetRecords, key))
expectTrue("Vergleich", pcall(History.GetCharacterComparison))
expect("Twink auf aktuellem Schema", LevelTimerStatsDB.characters[key].schemaVersion,
  addon.Database.CHARACTER_SCHEMA_VERSION)
