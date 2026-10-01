-- Stat-Zeilen unter der Spielzeit. Einzige Stelle, an der festgelegt wird, welche Stats es gibt:
-- TimerWindow zeigt sie an, Options baut daraus die Schalter.
-- setting = Schalter in ns.db (Default in Database.lua), label = Locale-Key für den Schalter.
local _, ns = ...
local L = ns.L
local Format = ns.Format
local LevelStats = ns.LevelStats
local Experience = ns.Experience
local DeathCounter = ns.DeathCounter

local function xpRateText()
  if not Experience.IsLeveling() then return L.XP_MAX_LEVEL end
  local rate = Experience.GetRatePerHour()
  if not rate then return L.XP_RATE_PENDING end
  return string.format(L.XP_RATE, Format.Number(rate), Format.Duration(Experience.GetSecondsToLevel()))
end

local function killsText()
  return string.format(L.KILLS, LevelStats.Get(LevelStats.PVE_KILLS), LevelStats.Get(LevelStats.PVP_KILLS))
end

local function deathsText()
  local deaths = LevelStats.Get(LevelStats.DEATHS)
  local killsPerDeath = DeathCounter.GetKillsPerDeath()
  if not killsPerDeath then
    return string.format(L.DEATHS, deaths)
  end
  return string.format(L.DEATHS_DETAIL, deaths,
    Format.Duration(DeathCounter.GetDeadSeconds()),
    string.format("%.1f", killsPerDeath))
end

local function xpSourcesText()
  local fromKills, fromQuests, other, total = Experience.GetSources()
  if total <= 0 then return L.XP_SOURCES_NONE end
  return string.format(L.XP_SOURCES,
    Format.Percent(fromKills, total),
    Format.Percent(fromQuests, total),
    Format.Percent(other, total))
end

local function restedText()
  local restedXp = LevelStats.Get(LevelStats.XP_RESTED)
  return string.format(L.RESTED_XP, Format.Number(restedXp), Format.Percent(restedXp, UnitXP("player")))
end

local function questsText()
  return string.format(L.QUESTS, LevelStats.Get(LevelStats.QUESTS))
end

local function moneyText()
  return string.format(L.MONEY, Format.Money(LevelStats.Get(LevelStats.MONEY_EARNED)))
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
