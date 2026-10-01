-- Spielzeit gesamt und auf dem aktuellen Level. Quelle ist der Server (/played),
-- zwischen zwei Abfragen wird lokal hochgezählt.
local _, ns = ...

local PlayedTime = {}
ns.PlayedTime = PlayedTime

local LOGIN_SYNC_DELAY = 3     -- Sekunden nach Login bis zur ersten Abfrage
local LEVEL_UP_SYNC_DELAY = 5  -- Sekunden nach Level-Up bis zum Abgleich

-- Stand beim letzten Abgleich (nil bis zur ersten Antwort des Servers)
local totalSeconds
local levelSeconds
local syncedAt  -- GetTime() beim letzten Abgleich
local silentRequest = false

local function sinceSync()
  return GetTime() - syncedAt
end

-- Sekunden auf aktuellem Level oder nil, solange der Server noch nicht geantwortet hat
function PlayedTime.GetLevelSeconds()
  if not levelSeconds then return nil end
  return levelSeconds + sinceSync()
end

-- Gesamte Spielzeit des Charakters oder nil, solange der Server noch nicht geantwortet hat
function PlayedTime.GetTotalSeconds()
  if not totalSeconds then return nil end
  return totalSeconds + sinceSync()
end

function PlayedTime.Sync()
  silentRequest = true
  RequestTimePlayed()
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

ns.RegisterEvent("TIME_PLAYED_MSG", function(total, thisLevel)
  totalSeconds = total
  levelSeconds = thisLevel
  syncedAt = GetTime()
end)

-- Neues Level beginnt bei 0; die Gesamtzeit läuft weiter
ns.OnLevelStarted(function()
  if totalSeconds then
    totalSeconds = totalSeconds + sinceSync()
  end
  levelSeconds = 0
  syncedAt = GetTime()
  C_Timer.After(LEVEL_UP_SYNC_DELAY, PlayedTime.Sync)
end)

ns.OnLogin(function()
  C_Timer.After(LOGIN_SYNC_DELAY, PlayedTime.Sync)
end)
