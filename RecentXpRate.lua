-- Aktuelle XP/h: Rate über die letzten WINDOW Sekunden statt über das ganze Level bzw. die Session,
-- damit Einbrüche (Laufwege, Flugrouten, Pausen) sofort sichtbar sind.
-- Alle SAMPLE_INTERVAL Sekunden wird der XP-Stand der Session (Zähler xpGained, steigt auch über
-- Level-Ups hinweg) mit der Zeit gemerkt; die Rate ergibt sich aus dem ältesten Stand im Fenster.
-- Nach Login oder /reload beginnt das Fenster neu.
local _, ns = ...
local Stats = ns.Stats

local RecentXpRate = {}
ns.RecentXpRate = RecentXpRate

RecentXpRate.WINDOW = 15 * 60    -- Sekunden
local SAMPLE_INTERVAL = 30       -- Sekunden zwischen zwei Messpunkten
local MIN_SPAN = 60              -- darunter schwankt die Rate zu stark
local SECONDS_PER_HOUR = 3600

local samples = {}  -- { at = GetTime(), xp = xpGained der Session }, älteste zuerst

local function currentXp()
  return Stats.Get(Stats.SESSION, Stats.XP_GAINED)
end

-- Messpunkt merken und alles verwerfen, was älter als das Fenster ist
function RecentXpRate.Sample()
  local now = GetTime()
  table.insert(samples, { at = now, xp = currentXp() })
  while now - samples[1].at > RecentXpRate.WINDOW do
    table.remove(samples, 1)
  end
end

-- XP pro Stunde im Fenster; nil, solange weniger als MIN_SPAN Sekunden gemessen sind
function RecentXpRate.Get()
  local oldest = samples[1]
  if not oldest then return nil end
  local span = GetTime() - oldest.at
  if span < MIN_SPAN then return nil end
  return (currentXp() - oldest.xp) / span * SECONDS_PER_HOUR
end

local ticker = CreateFrame("Frame")
local sinceSample = 0
ticker:SetScript("OnUpdate", function(_, elapsed)
  if not ns.character then return end
  sinceSample = sinceSample + elapsed
  if sinceSample < SAMPLE_INTERVAL then return end
  sinceSample = 0
  RecentXpRate.Sample()
end)

ns.OnLogin(function()
  samples = {}
  sinceSample = 0
  RecentXpRate.Sample()
end)
