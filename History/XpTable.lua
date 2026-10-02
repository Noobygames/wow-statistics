-- XP, die man auf einem Level bis zum nächsten braucht, je Client. Quelle: warcraft.wiki.gg,
-- "Experience to level" (Abschnitte "Vanilla / Classic table" und "pre-Wrath").
--   Classic Era, Anniversary-Realms (Classic) und WoW Forever: Werte von Patch 1.12 (vor TBC)
--   Burning Crusade (Classic, Anniversary): Werte ab Patch 2.3.0 (20-60 um ca. 10 % gesenkt)
--   Retail: keine Tabelle (Werte ändern sich mit jeder Erweiterung)
-- Stimmt der Wert für das aktuelle Level nicht mit UnitXPMax überein (Client mit anderen Werten),
-- gilt die Tabelle für diesen Client als unbekannt.
local _, ns = ...

local XpTable = {}
ns.XpTable = XpTable

-- Index = Level, Wert = XP bis zum nächsten Level
local CLASSIC = {
  400, 900, 1400, 2100, 2800, 3600, 4500, 5400, 6500, 7600,                                   -- 1-10
  8800, 10100, 11400, 12900, 14400, 16000, 17700, 19400, 21300, 23200,                        -- 11-20
  25200, 27300, 29400, 31700, 34000, 36400, 38900, 41400, 44300, 47400,                       -- 21-30
  50800, 54500, 58600, 62800, 67100, 71600, 76100, 80800, 85700, 90700,                       -- 31-40
  95800, 101000, 106300, 111800, 117500, 123200, 129100, 135100, 141200, 147500,              -- 41-50
  153900, 160400, 167100, 173900, 180800, 187900, 195000, 202300, 209800,                     -- 51-59
}

local BURNING_CRUSADE = {
  400, 900, 1400, 2100, 2800, 3600, 4500, 5400, 6500, 7600,                                   -- 1-10
  8700, 9800, 11000, 12300, 13600, 15000, 16400, 17800, 19300, 20800,                         -- 11-20
  22400, 24000, 25500, 27200, 28900, 30500, 32200, 33900, 36300, 38800,                       -- 21-30
  41600, 44600, 48000, 51400, 55000, 58700, 62400, 66200, 70200, 74300,                       -- 31-40
  78500, 82800, 87100, 91600, 96300, 101000, 105800, 110700, 115700, 120900,                  -- 41-50
  126100, 131500, 137000, 142500, 148200, 154000, 159900, 165800, 172000, 494000,             -- 51-60
  574700, 614400, 650300, 682300, 710200, 734100, 753700, 768900, 779700,                     -- 61-69
}

local function tableForClient()
  local Client = ns.Client
  if Client.IsClassicEra() or Client.IsForever() then return CLASSIC end
  if Client.IsBurningCrusade() then return BURNING_CRUSADE end
  return nil
end

-- Tabelle des Clients, nur wenn sie zum aktuellen Level passt; sonst nil
local function trustedTable()
  local values = tableForClient()
  if not values or values[ns.level] ~= UnitXPMax("player") then return nil end
  return values
end

-- XP für die ganzen Level von fromLevel bis vor toLevel; nil, wenn ein Wert fehlt
function XpTable.XpBetween(fromLevel, toLevel)
  local values = trustedTable()
  if not values then return nil end
  local sum = 0
  for level = fromLevel, toLevel - 1 do
    if not values[level] then return nil end
    sum = sum + values[level]
  end
  return sum
end
