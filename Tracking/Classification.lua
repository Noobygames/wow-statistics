-- Einstufung von Gegnern nach Namen (normal, elite, rare, rareelite, worldboss), gemerkt sobald man sie
-- anvisiert, mit der Maus berührt oder ihre Namensplakette sieht. KillCounter schlägt beim Kill den
-- Namen aus der XP-Meldung nach; so geht es ohne Kampflog und damit in allen Clients.
local _, ns = ...

local Classification = {}
ns.Classification = Classification

local MAX_NAMES = 5000  -- danach wird neu begonnen, damit die Tabelle nicht endlos wächst

local byName = {}
local nameCount = 0

local function remember(unit)
  if not unit or not UnitExists(unit) or UnitIsPlayer(unit) then return end
  local name, classification = UnitName(unit), UnitClassification(unit)
  if not name or ns.IsSecret(name) or ns.IsSecret(classification) then return end
  if not byName[name] then
    nameCount = nameCount + 1
    if nameCount > MAX_NAMES then
      byName, nameCount = {}, 1
    end
  end
  byName[name] = classification
end

-- Zuletzt gesehene Einstufung eines Gegners oder nil
function Classification.Of(name)
  return name and byName[name]
end

function Classification.IsElite(classification)
  return classification == "elite" or classification == "rareelite" or classification == "worldboss"
end

function Classification.IsRare(classification)
  return classification == "rare" or classification == "rareelite"
end

ns.RegisterEvent("PLAYER_TARGET_CHANGED", function() remember("target") end)
ns.RegisterEvent("UPDATE_MOUSEOVER_UNIT", function() remember("mouseover") end)
ns.RegisterEvent("NAME_PLATE_UNIT_ADDED", remember)
