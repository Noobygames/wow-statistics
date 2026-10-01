-- Spielzeit auf dem aktuellen Level. Quelle ist der Server (/played),
-- zwischen zwei Abfragen wird lokal hochgezählt.
local _, ns = ...

local PlayedTime = {}
ns.PlayedTime = PlayedTime

local LOGIN_SYNC_DELAY = 3     -- Sekunden nach Login bis zur ersten Abfrage
local LEVEL_UP_SYNC_DELAY = 5  -- Sekunden nach Level-Up bis zum Abgleich

local levelSeconds   -- Spielzeit auf aktuellem Level, Stand bei syncedAt (nil bis zur ersten Antwort)
local syncedAt       -- GetTime() beim letzten Abgleich
local silentRequest = false

-- Sekunden auf aktuellem Level oder nil, solange der Server noch nicht geantwortet hat
function PlayedTime.GetLevelSeconds()
  if not levelSeconds then return nil end
  return levelSeconds + GetTime() - syncedAt
end

function PlayedTime.Sync()
  silentRequest = true
  RequestTimePlayed()
end

local function setLevelSeconds(seconds)
  levelSeconds = seconds
  syncedAt = GetTime()
end

-- Chat-Ausgabe von /played unterdrücken, wenn das Addon selbst fragt
if ChatFrame_DisplayTimePlayed then
  local original = ChatFrame_DisplayTimePlayed
  ChatFrame_DisplayTimePlayed = function(...)
    if silentRequest then
      silentRequest = false
      return
    end
    return original(...)
  end
end

ns.RegisterEvent("TIME_PLAYED_MSG", function(_, secondsThisLevel)
  setLevelSeconds(secondsThisLevel)
end)

ns.RegisterEvent("PLAYER_LEVEL_UP", function()
  setLevelSeconds(0)
  C_Timer.After(LEVEL_UP_SYNC_DELAY, PlayedTime.Sync)
end)

ns.OnLogin(function()
  C_Timer.After(LOGIN_SYNC_DELAY, PlayedTime.Sync)
end)
