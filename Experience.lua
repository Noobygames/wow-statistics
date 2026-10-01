-- Erfahrung auf dem aktuellen Level: XP pro Stunde, Zeit bis Level-Up, XP-Quellen und Erholungs-XP.
-- UnitXP("player") ist die XP seit Levelbeginn, daher braucht die Rate keinen eigenen Zähler.
local _, ns = ...
local LevelStats = ns.LevelStats

local Experience = {}
ns.Experience = Experience

local SECONDS_PER_HOUR = 3600
local MIN_SECONDS_FOR_RATE = 60  -- darunter schwankt die Rate zu stark

-- false auf Max-Level oder bei abgeschalteter XP
function Experience.IsLeveling()
  if IsXPUserDisabled and IsXPUserDisabled() then return false end
  if GetMaxPlayerLevel and ns.level >= GetMaxPlayerLevel() then return false end
  return UnitXPMax("player") > 0
end

-- XP pro Stunde aus XP und Spielzeit, nil wenn noch nicht aussagekräftig
function Experience.CalculateRate(xp, seconds)
  if not seconds or seconds < MIN_SECONDS_FOR_RATE or xp <= 0 then return nil end
  return xp / seconds * SECONDS_PER_HOUR
end

function Experience.GetRatePerHour()
  return Experience.CalculateRate(UnitXP("player"), ns.PlayedTime.GetLevelSeconds())
end

-- Geschätzte Spielzeit bis zum Level-Up bei gleichbleibender Rate
function Experience.GetSecondsToLevel()
  local rate = Experience.GetRatePerHour()
  if not rate then return nil end
  local remainingXp = UnitXPMax("player") - UnitXP("player")
  return remainingXp / rate * SECONDS_PER_HOUR
end

-- XP-Quellen auf diesem Level. "Sonstige" ist der Rest (Entdecken, Berufe, ...).
function Experience.GetSources()
  local fromKills = LevelStats.Get(LevelStats.XP_KILLS)
  local fromQuests = LevelStats.Get(LevelStats.XP_QUESTS)
  local total = UnitXP("player")
  local other = math.max(0, total - fromKills - fromQuests)
  return fromKills, fromQuests, other, math.max(total, fromKills + fromQuests)
end

---------------------------------------------------------------------------
-- Erholungs-XP: Der Bonus wird aus dem Erholungs-Pool bezahlt. Jede Abnahme
-- des Pools entspricht verbrauchtem Bonus; Zunahmen (Ausruhen) setzen nur die Basis neu.
---------------------------------------------------------------------------
local lastRestedPool

local function restedPool()
  return GetXPExhaustion() or 0
end

local function trackRestedXp()
  local current = restedPool()
  if lastRestedPool and current < lastRestedPool then
    LevelStats.Increment(LevelStats.XP_RESTED, lastRestedPool - current)
  end
  lastRestedPool = current
end

ns.OnLogin(function()
  lastRestedPool = restedPool()
end)

ns.RegisterEvent("PLAYER_XP_UPDATE", trackRestedXp)
ns.RegisterEvent("UPDATE_EXHAUSTION", trackRestedXp)
