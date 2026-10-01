-- Zählt Kills, getrennt nach PvE und PvP.
local _, ns = ...
local Stats = ns.Stats

---------------------------------------------------------------------------
-- PvE: Kills, die Erfahrung gegeben haben (Chatmeldung "X stirbt, Ihr bekommt Y Erfahrung").
-- Gruppen-Kills zählen mit; graue Gegner ohne XP und Kills auf Max-Level nicht.
-- Die XP-Menge aus der Meldung fließt in die XP-Quellen ein.
---------------------------------------------------------------------------

-- Wandelt einen WoW-Formatstring ("%s dies, you gain %d experience.") in ein Lua-Pattern,
-- das die Zahl (%d) als Capture liefert. Nur am Anfang verankert, damit auch Varianten
-- mit Bonus-Zusatz ("... (+10 exp Rested bonus)") passen.
local function formatToPattern(format)
  local pattern = format:gsub("[%(%)%.%+%-%*%?%[%]]", "%%%0")  -- Pattern-Sonderzeichen escapen
  pattern = pattern:gsub("%%%d?%$?s", ".-")                   -- %s und %1$s
  pattern = pattern:gsub("%%%d?%$?d", "(%%d+)")               -- %d und %2$d
  return "^" .. pattern
end

if COMBATLOG_XPGAIN_FIRSTPERSON then
  local killPattern = formatToPattern(COMBATLOG_XPGAIN_FIRSTPERSON)

  ns.RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN", function(message)
    if ns.IsSecret(message) then return end
    local xp = message:match(killPattern)
    if xp then
      Stats.Increment(Stats.PVE_KILLS)
      Stats.Increment(Stats.XP_KILLS, tonumber(xp))
    end
  end)
end

---------------------------------------------------------------------------
-- PvP: ehrenhafte Siege. Der Client liefert nur die Summe seit Login bzw. Tagesbeginn,
-- daher wird die Differenz zum zuletzt gesehenen Wert gezählt.
---------------------------------------------------------------------------
if GetPVPSessionStats then
  local lastHonorableKills = 0

  local function sessionHonorableKills()
    local honorableKills = GetPVPSessionStats()
    if ns.IsSecret(honorableKills) then return nil end
    return honorableKills or 0
  end

  ns.OnLogin(function()
    lastHonorableKills = sessionHonorableKills() or 0
  end)

  ns.RegisterEvent("PLAYER_PVP_KILLS_CHANGED", function()
    local current = sessionHonorableKills()
    if not current then return end
    if current < lastHonorableKills then
      lastHonorableKills = 0  -- Tageswechsel hat die Summe zurückgesetzt
    end
    Stats.Increment(Stats.PVP_KILLS, current - lastHonorableKills)
    lastHonorableKills = current
  end)
end
