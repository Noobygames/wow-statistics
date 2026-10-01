-- Zählt Kills, getrennt nach PvE und PvP, und schreibt jeden Kill mit Namen ins Journal.
local _, ns = ...
local L = ns.L
local Stats = ns.Stats
local Journal = ns.Journal
local ChatPatterns = ns.ChatPatterns

-- Fehlersuche (/lt debug): jede XP-Meldung mit ihrer Wertung in den Chat schreiben
local function debugXpMessage(verdictKey, message)
  if not ns.debug then return end
  if message then
    ns.Print(L[verdictKey] .. ": " .. message)
  else
    ns.Print(L[verdictKey])
  end
end

---------------------------------------------------------------------------
-- PvE: Kills, die Erfahrung gegeben haben (Chatmeldung "X stirbt, Ihr bekommt Y Erfahrung").
-- Gruppen-Kills zählen mit; graue Gegner ohne XP und Kills auf Max-Level nicht.
-- Die XP-Menge aus der Meldung fließt in die XP-Quellen ein.
---------------------------------------------------------------------------
if COMBATLOG_XPGAIN_FIRSTPERSON then
  local killFormat = ChatPatterns.Compile(COMBATLOG_XPGAIN_FIRSTPERSON)

  ns.RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN", function(message)
    if ns.IsSecret(message) then
      debugXpMessage("DEBUG_XP_SECRET")  -- Inhalt nicht lesbar, daher auch nicht ausgeben
      return
    end
    local args = ChatPatterns.Match(message, killFormat)
    if args then
      local name, xp = args[1], tonumber(args[2])
      Stats.Increment(Stats.PVE_KILLS)
      Stats.Increment(Stats.XP_KILLS, xp or 0)
      Journal.AddKill(Journal.PVE, name)
      debugXpMessage("DEBUG_XP_KILL", message)
    else
      debugXpMessage("DEBUG_XP_OTHER", message)
    end
  end)
end

---------------------------------------------------------------------------
-- PvP-Zähler: ehrenhafte Siege. Der Client liefert nur die Summe seit Login bzw.
-- Tagesbeginn, daher wird die Differenz zum zuletzt gesehenen Wert gezählt.
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

---------------------------------------------------------------------------
-- PvP-Namen: Ehre-Meldung "X stirbt, ehrenhafter Sieg ...". Liefert nur den Namen fürs
-- Journal; gezählt wird oben, weil die Summe zuverlässiger ist als Chatmeldungen.
---------------------------------------------------------------------------
local honorFormats = ChatPatterns.CompileGlobals({ "COMBATLOG_HONORGAIN", "COMBATLOG_HONORGAIN_NO_RANK" })

if #honorFormats > 0 then
  ns.RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN", function(message)
    if ns.IsSecret(message) then return end
    local args = ChatPatterns.MatchAny(message, honorFormats)
    if args then
      Journal.AddKill(Journal.PVP, args[1])
    end
  end)
end
