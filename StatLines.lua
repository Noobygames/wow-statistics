-- Stat-Zeilen unter der Spielzeit. Einzige Stelle, an der festgelegt wird, welche Stats es gibt:
-- TimerWindow zeigt sie an, Options baut daraus die Schalter.
-- setting = Schalter in ns.db (Default in Database.lua), label = Locale-Key für den Schalter,
-- text(scope) = Inhalt für den gewählten Bereich (Stats.LEVEL oder Stats.SESSION).
local _, ns = ...
local L = ns.L
local Format = ns.Format
local Stats = ns.Stats
local Experience = ns.Experience
local DeathCounter = ns.DeathCounter

local function xpRateText(scope)
  if not Experience.IsLeveling() then return L.XP_MAX_LEVEL end
  local rate = Experience.GetRatePerHour(scope)
  if not rate then return L.XP_RATE_PENDING end
  return string.format(L.XP_RATE, Format.Number(rate), Format.Duration(Experience.GetSecondsToLevel(scope)))
end

local function killsText(scope)
  return string.format(L.KILLS, Stats.Get(scope, Stats.PVE_KILLS), Stats.Get(scope, Stats.PVP_KILLS))
end

local function deathsText(scope)
  local deaths = Stats.Get(scope, Stats.DEATHS)
  local killsPerDeath = DeathCounter.GetKillsPerDeath(scope)
  if not killsPerDeath then
    return string.format(L.DEATHS, deaths)
  end
  return string.format(L.DEATHS_DETAIL, deaths,
    Format.Duration(DeathCounter.GetDeadSeconds(scope)),
    string.format("%.1f", killsPerDeath))
end

local function xpSourcesText(scope)
  local fromKills, fromQuests, other, total = Experience.GetSources(scope)
  if total <= 0 then return L.XP_SOURCES_NONE end
  return string.format(L.XP_SOURCES,
    Format.Percent(fromKills, total),
    Format.Percent(fromQuests, total),
    Format.Percent(other, total))
end

local function restedText(scope)
  local restedXp = Stats.Get(scope, Stats.XP_RESTED)
  return string.format(L.RESTED_XP, Format.Number(restedXp), Format.Percent(restedXp, Stats.GetXp(scope)))
end

local function questsText(scope)
  return string.format(L.QUESTS, Stats.Get(scope, Stats.QUESTS))
end

local function moneyText(scope)
  return string.format(L.MONEY, Format.Money(Stats.Get(scope, Stats.MONEY_EARNED)))
end

ns.STAT_LINES = {
  { setting = "showXpRate", label = "STAT_XP_RATE", text = xpRateText },
  { setting = "showKills", label = "STAT_KILLS", text = killsText },
  { setting = "showDeaths", label = "STAT_DEATHS", text = deathsText },
  { setting = "showXpSources", label = "STAT_XP_SOURCES", text = xpSourcesText },
  { setting = "showRested", label = "STAT_RESTED", text = restedText },
  { setting = "showQuests", label = "STAT_QUESTS", text = questsText },
  { setting = "showMoney", label = "STAT_MONEY", text = moneyText },
}
