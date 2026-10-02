-- Prognose bis zum Max-Level: Rest des aktuellen Levels plus geschätzte Zeit je weiteres Level.
-- Schätzung je Level = Durchschnitt der letzten SAMPLE_SIZE abgeschlossenen Level, ohne solche die
-- hochgerechnete Dauer des aktuellen. Höhere Level dauern meist länger, die Prognose ist daher eher knapp.
local _, ns = ...
local Stats = ns.Stats
local Experience = ns.Experience
local History = ns.History

local Forecast = {}
ns.Forecast = Forecast

local SAMPLE_SIZE = 5

local function averageRecentLevelSeconds()
  local sum, count = 0, 0
  for _, record in ipairs(History.GetLevelRecords(ns.characterKey)) do
    if not record.isCurrent and record.seconds then
      sum = sum + Experience.RateSeconds(record.seconds, record.counters[Stats.AFK_SECONDS])
      count = count + 1
      if count == SAMPLE_SIZE then break end
    end
  end
  if count == 0 then return nil end
  return sum / count
end

-- Geschätzte Spielzeit bis zum Erreichen von targetLevel; nil, solange keine Schätzung möglich ist
function Forecast.SecondsToLevel(targetLevel)
  if not Experience.IsLeveling() then return nil end
  if targetLevel <= ns.level then return 0 end
  local remaining = Experience.GetSecondsToLevel(Stats.LEVEL)
  if not remaining then return nil end

  local levelsAfterThis = targetLevel - ns.level - 1
  if levelsAfterThis <= 0 then return remaining end

  local levelSeconds = Experience.RateSeconds(Stats.GetSeconds(Stats.LEVEL),
    ns.TimeBreakdown.GetSeconds(Stats.LEVEL, Stats.AFK_SECONDS))
  local perLevel = averageRecentLevelSeconds() or (levelSeconds + remaining)
  return remaining + levelsAfterThis * perLevel
end

function Forecast.SecondsToMaxLevel()
  if not GetMaxPlayerLevel then return nil end
  return Forecast.SecondsToLevel(GetMaxPlayerLevel())
end
