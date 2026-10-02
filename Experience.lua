-- Erfahrung je Bereich (Level/Session): XP pro Stunde, Zeit bis Level-Up, XP-Quellen.
-- Zählt außerdem gewonnene XP (für Sessions) und verbrauchte Erholungs-XP.
local _, ns = ...
local Stats = ns.Stats

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
  if not seconds or seconds < MIN_SECONDS_FOR_RATE or not xp or xp <= 0 then return nil end
  return xp / seconds * SECONDS_PER_HOUR
end

-- Spielzeit, auf die sich Raten und Prognosen beziehen: ohne AFK-Zeit, wenn eingestellt
-- (xpRateWithoutAfk, AFK-Zeit aus TimeBreakdown.lua). Auch für Historie-Einträge.
function Experience.RateSeconds(seconds, afkSeconds)
  if not seconds or not ns.db or not ns.db.xpRateWithoutAfk then return seconds end
  return math.max(0, seconds - (afkSeconds or 0))
end

function Experience.GetRatePerHour(scope)
  local afkSeconds = ns.TimeBreakdown.GetSeconds(scope, Stats.AFK_SECONDS)
  return Experience.CalculateRate(Stats.GetXp(scope), Experience.RateSeconds(Stats.GetSeconds(scope), afkSeconds))
end

-- Geschätzte Spielzeit bis zum Level-Up bei der Rate des Bereichs
function Experience.GetSecondsToLevel(scope)
  local rate = Experience.GetRatePerHour(scope)
  if not rate then return nil end
  local remainingXp = UnitXPMax("player") - UnitXP("player")
  return remainingXp / rate * SECONDS_PER_HOUR
end

-- Wie viele Kills bzw. Quests noch bis zum Level-Up fehlen, bei der durchschnittlichen XP je
-- Kill/Quest auf diesem Level (sonst der Session); nil ohne Grundlage
function Experience.CountToLevel(xpCounter, countCounter)
  for _, scope in ipairs({ Stats.LEVEL, Stats.SESSION }) do
    local count = Stats.Get(scope, countCounter)
    local xp = Stats.Get(scope, xpCounter)
    if count > 0 and xp > 0 then
      local remainingXp = UnitXPMax("player") - UnitXP("player")
      return math.ceil(remainingXp / (xp / count))
    end
  end
  return nil
end

-- XP-Quellen im Bereich. "Sonstige" ist der Rest (Entdecken, Berufe, ...).
function Experience.GetSources(scope)
  local fromKills = Stats.Get(scope, Stats.XP_KILLS)
  local fromQuests = Stats.Get(scope, Stats.XP_QUESTS)
  local total = math.max(Stats.GetXp(scope), fromKills + fromQuests)
  return fromKills, fromQuests, total - fromKills - fromQuests, total
end

---------------------------------------------------------------------------
-- Gewonnene XP: Differenz zum letzten Stand. Liegt ein Level-Up dazwischen,
-- zählt der Rest des alten Levels plus die XP auf dem neuen.
---------------------------------------------------------------------------
local lastXp, lastXpMax

local function trackXpGained()
  local xp, xpMax = UnitXP("player"), UnitXPMax("player")
  if lastXp then
    local gained = xp - lastXp
    if gained < 0 then
      gained = (lastXpMax - lastXp) + xp
    end
    if gained > 0 then
      Stats.Increment(Stats.XP_GAINED, gained)
    end
  end
  lastXp, lastXpMax = xp, xpMax
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
    Stats.Increment(Stats.XP_RESTED, lastRestedPool - current)
  end
  lastRestedPool = current
end

ns.OnLogin(function()
  lastXp, lastXpMax = UnitXP("player"), UnitXPMax("player")
  lastRestedPool = restedPool()
end)

ns.RegisterEvent("PLAYER_XP_UPDATE", function()
  trackXpGained()
  trackRestedXp()
end)
ns.RegisterEvent("UPDATE_EXHAUSTION", trackRestedXp)
