-- Zähler des eingeloggten Charakters in zwei Bereichen (Scopes):
--   LEVEL    aktuelles Level, beginnt beim Level-Up neu
--   SESSION  aktuelle Session, beginnt beim Login neu (siehe Session.lua)
-- Jedes Increment zählt in beiden Bereichen.
local _, ns = ...

local Stats = {}
ns.Stats = Stats

Stats.LEVEL = "level"
Stats.SESSION = "session"

-- Zähler-Schlüssel (Defaults in Database.lua)
Stats.PVE_KILLS = "pveKills"
Stats.PVP_KILLS = "pvpKills"
Stats.DEATHS = "deaths"
Stats.DEAD_SECONDS = "deadSeconds"
Stats.QUESTS = "quests"
Stats.XP_GAINED = "xpGained"
Stats.XP_KILLS = "xpKills"
Stats.XP_QUESTS = "xpQuests"
Stats.XP_RESTED = "xpRested"
Stats.MONEY_EARNED = "moneyEarned"

local function countersOf(scope)
  if scope == Stats.SESSION then
    return ns.character.currentSession.counters
  end
  return ns.character.currentLevel.counters
end

function Stats.Get(scope, counter)
  return countersOf(scope)[counter] or 0
end

function Stats.Increment(counter, amount)
  amount = amount or 1
  for _, scope in ipairs({ Stats.LEVEL, Stats.SESSION }) do
    local counters = countersOf(scope)
    counters[counter] = (counters[counter] or 0) + amount
  end
end

function Stats.GetTotalKills(scope)
  return Stats.Get(scope, Stats.PVE_KILLS) + Stats.Get(scope, Stats.PVP_KILLS)
end

-- Kopie aller Zähler eines Bereichs, z.B. für die Historie
function Stats.Snapshot(scope)
  local copy = {}
  for counter, value in pairs(countersOf(scope)) do
    copy[counter] = value
  end
  return copy
end

-- Gespielte Sekunden im Bereich (Level: vom Server, nil bis zur ersten Antwort)
function Stats.GetSeconds(scope)
  if scope == Stats.SESSION then
    return ns.Session.GetSeconds()
  end
  return ns.PlayedTime.GetLevelSeconds()
end

-- Gewonnene XP im Bereich. Für das Level ist UnitXP exakt (zählt ab Levelbeginn,
-- auch wenn das Addon erst später installiert wurde); Sessions zählen selbst mit.
function Stats.GetXp(scope)
  if scope == Stats.SESSION then
    return Stats.Get(Stats.SESSION, Stats.XP_GAINED)
  end
  return UnitXP("player")
end

local function startLevel(level)
  local currentLevel = ns.character.currentLevel
  currentLevel.level = level
  currentLevel.seconds = 0
  currentLevel.xp = 0
  currentLevel.counters = ns.Database.NewCounters()
end

-- Level hat sich geändert, während das Addon nicht lief (oder erster Start)
ns.OnLogin(function()
  if ns.character.currentLevel.level ~= ns.level then
    startLevel(ns.level)
  end
end)

ns.OnLevelStarted(startLevel)

-- Letzte bekannte Werte sichern, damit die Historie sie auch für ausgeloggte Charaktere zeigen kann
ns.OnLogout(function()
  local currentLevel = ns.character.currentLevel
  currentLevel.seconds = Stats.GetSeconds(Stats.LEVEL) or currentLevel.seconds
  currentLevel.xp = UnitXP("player")
end)
