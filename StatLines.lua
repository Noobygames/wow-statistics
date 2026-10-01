-- Stats im Fenster. Einzige Stelle, an der festgelegt wird, welche Stats es gibt:
-- TimerWindow zeigt die Zeilen (rows) als Tabelle an, Options baut aus setting/label die Schalter.
-- Eintrag: setting = Schalter in ns.db (Default in Database.lua), label = Locale-Key des Schalters,
-- rows = feste Liste von Zeilen mit label (Locale-Key) und value(scope) -> Text für den Bereich.
local _, ns = ...
local Format = ns.Format
local Stats = ns.Stats
local Experience = ns.Experience
local DeathCounter = ns.DeathCounter

local NO_VALUE = "-"
local PENDING = "..."  -- noch nicht aussagekräftig (z.B. /played hat noch nicht geantwortet)

local function counter(name)
  return function(scope) return tostring(Stats.Get(scope, name)) end
end

local function xpRate(scope)
  if not Experience.IsLeveling() then return NO_VALUE end
  local rate = Experience.GetRatePerHour(scope)
  return rate and Format.Number(rate) or PENDING
end

local function timeToLevel(scope)
  if not Experience.IsLeveling() then return NO_VALUE end
  local seconds = Experience.GetSecondsToLevel(scope)
  return seconds and Format.Duration(seconds) or PENDING
end

local function deaths(scope)
  local count = Stats.Get(scope, Stats.DEATHS)
  local deadSeconds = DeathCounter.GetDeadSeconds(scope)
  if deadSeconds < 1 then return tostring(count) end
  return string.format("%d (%s)", count, Format.Duration(deadSeconds))
end

local function killsPerDeath(scope)
  local ratio = DeathCounter.GetKillsPerDeath(scope)
  return ratio and string.format("%.1f", ratio) or NO_VALUE
end

-- Anteil einer XP-Quelle; index 1 = Kills, 2 = Quests, 3 = Sonstige (Reihenfolge von GetSources)
local function xpShare(index)
  return function(scope)
    local sources = { Experience.GetSources(scope) }
    local total = sources[4]
    if total <= 0 then return NO_VALUE end
    return Format.Percent(sources[index], total)
  end
end

local function restedXp(scope)
  local rested = Stats.Get(scope, Stats.XP_RESTED)
  return string.format("%s (%s)", Format.Number(rested), Format.Percent(rested, Stats.GetXp(scope)))
end

local function income(scope)
  return Format.Money(Stats.Get(scope, Stats.MONEY_EARNED))
end

ns.STAT_LINES = {
  { setting = "showXpRate", label = "STAT_XP_RATE", rows = { { label = "ROW_XP_RATE", value = xpRate } } },
  { setting = "showLevelEta", label = "STAT_LEVEL_ETA", rows = { { label = "ROW_LEVEL_ETA", value = timeToLevel } } },
  { setting = "showPveKills", label = "STAT_PVE_KILLS",
    rows = { { label = "ROW_PVE_KILLS", value = counter(Stats.PVE_KILLS) } } },
  { setting = "showPvpKills", label = "STAT_PVP_KILLS",
    rows = { { label = "ROW_PVP_KILLS", value = counter(Stats.PVP_KILLS) } } },
  { setting = "showDeaths", label = "STAT_DEATHS", rows = { { label = "ROW_DEATHS", value = deaths } } },
  { setting = "showKillsPerDeath", label = "STAT_KILLS_PER_DEATH",
    rows = { { label = "ROW_KILLS_PER_DEATH", value = killsPerDeath } } },
  { setting = "showXpSources", label = "STAT_XP_SOURCES", rows = {
    { label = "ROW_XP_KILLS", value = xpShare(1) },
    { label = "ROW_XP_QUESTS", value = xpShare(2) },
    { label = "ROW_XP_OTHER", value = xpShare(3) },
  } },
  { setting = "showRested", label = "STAT_RESTED", rows = { { label = "ROW_RESTED", value = restedXp } } },
  { setting = "showQuests", label = "STAT_QUESTS", rows = { { label = "ROW_QUESTS", value = counter(Stats.QUESTS) } } },
  { setting = "showMoney", label = "STAT_MONEY", rows = { { label = "ROW_MONEY", value = income } } },
}
