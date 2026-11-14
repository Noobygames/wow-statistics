-- Testdaten: Auszug im Format von QuestieDB support/Forever/Zones/subZoneToParentZone.lua
ZoneDB.private.subZoneToParentZoneOverride = [[return {
    [10098] = 2717, -- Unterzone der Instanz
}]]
ZoneDB.private.subZoneToParentZone = [[return {
    [10099] = 46, -- Alias, der zu einer Außenzone gehört
    [10098] = 46, -- vom Override überschrieben
}]]
