-- Zählt getötete Gegner auf dem aktuellen Level.
-- Gezählt werden Kills, die Erfahrung gegeben haben (Chatmeldung "X stirbt, Ihr bekommt Y Erfahrung").
-- Dadurch zählen auch Gruppen-Kills mit; graue Gegner ohne XP zählen nicht.
local _, ns = ...

local KillCounter = {}
ns.KillCounter = KillCounter

function KillCounter.GetKills()
  return ns.charDB.kills
end

local function resetForLevel(level)
  ns.charDB.level = level
  ns.charDB.kills = 0
end

-- Wandelt einen WoW-Formatstring ("%s dies, you gain %d experience.") in ein Lua-Pattern.
-- Nur am Anfang verankert, damit auch Varianten mit Bonus-Zusatz ("... (+10 exp bonus)") passen.
local function formatToPattern(format)
  local pattern = format:gsub("[%(%)%.%+%-%*%?%[%]]", "%%%0")  -- Pattern-Sonderzeichen escapen
  pattern = pattern:gsub("%%%d?%$?s", ".-")                   -- %s und %1$s
  pattern = pattern:gsub("%%%d?%$?d", "%%d+")                 -- %d und %2$d
  return "^" .. pattern
end

local function isKillMessage(message, killPattern)
  -- Retail kann Inhalte als "secret" markieren; die lassen sich nicht auswerten
  if issecretvalue and issecretvalue(message) then return false end
  return message:match(killPattern) ~= nil
end

-- Level hat sich geändert, während das Addon nicht lief (oder erster Start)
ns.OnLogin(function()
  if ns.charDB.level ~= ns.level then
    resetForLevel(ns.level)
  end
end)

ns.RegisterEvent("PLAYER_LEVEL_UP", function(newLevel)
  resetForLevel(newLevel)
end)

if COMBATLOG_XPGAIN_FIRSTPERSON then
  local killPattern = formatToPattern(COMBATLOG_XPGAIN_FIRSTPERSON)
  ns.RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN", function(message)
    if isKillMessage(message, killPattern) then
      ns.charDB.kills = ns.charDB.kills + 1
    end
  end)
end
