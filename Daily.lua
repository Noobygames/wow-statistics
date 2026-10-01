-- Tageswerte pro Charakter: ns.character.dailyStats["JJJJ-MM-TT"] = { seconds, ... }.
-- Spielzeit wird beim Lesen und beim Logout verbucht und dabei an Mitternacht aufgeteilt.
local _, ns = ...

local Daily = {}
ns.Daily = Daily

local SECONDS_PER_DAY = 86400

local bookedUntil  -- time() bis zu dem die Spielzeit verbucht ist (nil = nicht eingeloggt)

-- Mitternacht des Tages, in dem timestamp liegt
function Daily.StartOfDay(timestamp)
  local day = date("*t", timestamp)
  return time({ year = day.year, month = day.month, day = day.day, hour = 0 })
end

function Daily.DayKey(timestamp)
  return date("%Y-%m-%d", timestamp)
end

-- Tageseintrag holen oder anlegen
function Daily.Entry(dailyStats, timestamp)
  local key = Daily.DayKey(timestamp)
  dailyStats[key] = dailyStats[key] or { seconds = 0 }
  return dailyStats[key]
end

-- Spielzeit seit der letzten Verbuchung den jeweiligen Tagen gutschreiben
function Daily.BookPlayTime()
  if not bookedUntil then return end
  local now = time()
  local from = bookedUntil
  while from < now do
    local untilTime = math.min(now, Daily.StartOfDay(from) + SECONDS_PER_DAY)
    local entry = Daily.Entry(ns.character.dailyStats, from)
    entry.seconds = entry.seconds + (untilTime - from)
    from = untilTime
  end
  bookedUntil = now
end

-- Tageswerte eines Charakters; beim eingeloggten inklusive der laufenden Spielzeit
function Daily.GetStats(characterKey)
  if characterKey == ns.characterKey then
    Daily.BookPlayTime()
  end
  return ns.History.GetCharacter(characterKey).dailyStats
end

ns.OnLogin(function()
  bookedUntil = time()
end)

ns.OnLogout(Daily.BookPlayTime)
