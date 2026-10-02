-- Stream-Modus (/lt stream oder Einstellungen): schaltet eine Auswahl an Einstellungen für Streams
-- gemeinsam ein und stellt beim Ausschalten den vorherigen Stand wieder her.
-- Der vorherige Stand liegt in db.streamBackup, übersteht also /reload und Logout.
local _, ns = ...
local L = ns.L

local StreamMode = {}
ns.StreamMode = StreamMode

-- Fenster ohne Hintergrund und größer, Einblendungen an, Namen verborgen
StreamMode.PRESET = {
  bgAlpha = 0,
  windowBackground = "default",
  scale = 1.5,
  alertLevelUp = true,
  alertRareKill = true,
  alertEpicLoot = true,
  alertNearDeath = true,
  streamerPrivacy = true,
}

function StreamMode.IsEnabled()
  return ns.db.streamBackup ~= nil
end

function StreamMode.SetEnabled(enabled)
  if enabled == StreamMode.IsEnabled() then return end
  local db = ns.db
  if enabled then
    db.streamBackup = {}
    for key, value in pairs(StreamMode.PRESET) do
      db.streamBackup[key] = db[key]
      db[key] = value
    end
  else
    for key, value in pairs(db.streamBackup) do
      db[key] = value
    end
    db.streamBackup = nil
  end
  ns.ApplySettings()
  ns.Print(enabled and L.STREAM_MODE_ON or L.STREAM_MODE_OFF)
end

function StreamMode.Toggle()
  StreamMode.SetEnabled(not StreamMode.IsEnabled())
end
