-- Zählt Kills, getrennt nach PvE und PvP, und schreibt jeden Kill mit Namen ins Journal.
local _, ns = ...
local L = ns.L
local Stats = ns.Stats
local Journal = ns.Journal

-- Fehlersuche (/lt debug): jede XP-Meldung mit ihrer Wertung in den Chat schreiben
local function debugXpMessage(verdictKey, message)
  if not ns.debug then return end
  if message then
    ns.Print(L[verdictKey] .. ": " .. message)
  else
    ns.Print(L[verdictKey])
  end
end

-- Wandelt einen WoW-Formatstring ("%s dies, you gain %d experience.") in ein Lua-Pattern.
-- Jeder Platzhalter wird zum Capture; positions[i] ist die Argument-Nummer des i-ten Captures,
-- damit auch umgestellte Platzhalter ("%2$d ... %1$s") richtig zugeordnet werden.
-- Nur am Anfang verankert, damit auch Varianten mit Zusatz ("... (+10 exp Rested bonus)") passen.
local function formatToPattern(format)
  local positions = {}
  local pattern = format:gsub("[%(%)%.%+%-%*%?%[%]]", "%%%0")  -- Pattern-Sonderzeichen escapen
  pattern = pattern:gsub("%%(%d?)%$?([sd])", function(position, kind)
    table.insert(positions, tonumber(position) or #positions + 1)
    return kind == "s" and "(.-)" or "(%d+)"
  end)
  return "^" .. pattern, positions
end

-- Meldung gegen ein Format prüfen; Rückgabe: Argumente in Format-Reihenfolge oder nil
local function matchFormat(message, pattern, positions)
  local captures = { message:match(pattern) }
  if #captures == 0 then return nil end
  local args = {}
  for i, position in ipairs(positions) do
    args[position] = captures[i]
  end
  return args
end

---------------------------------------------------------------------------
-- PvE: Kills, die Erfahrung gegeben haben (Chatmeldung "X stirbt, Ihr bekommt Y Erfahrung").
-- Gruppen-Kills zählen mit; graue Gegner ohne XP und Kills auf Max-Level nicht.
-- Die XP-Menge aus der Meldung fließt in die XP-Quellen ein.
---------------------------------------------------------------------------
if COMBATLOG_XPGAIN_FIRSTPERSON then
  local killPattern, killPositions = formatToPattern(COMBATLOG_XPGAIN_FIRSTPERSON)

  ns.RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN", function(message)
    if ns.IsSecret(message) then
      debugXpMessage("DEBUG_XP_SECRET")  -- Inhalt nicht lesbar, daher auch nicht ausgeben
      return
    end
    local args = matchFormat(message, killPattern, killPositions)
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
local HONOR_FORMAT_GLOBALS = { "COMBATLOG_HONORGAIN", "COMBATLOG_HONORGAIN_NO_RANK" }

local honorFormats = {}
for _, globalName in ipairs(HONOR_FORMAT_GLOBALS) do
  local format = _G[globalName]  -- nicht jeder Client kennt beide Varianten
  if format then
    local pattern, positions = formatToPattern(format)
    table.insert(honorFormats, { pattern = pattern, positions = positions })
  end
end

if #honorFormats > 0 then
  ns.RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN", function(message)
    if ns.IsSecret(message) then return end
    for _, format in ipairs(honorFormats) do
      local args = matchFormat(message, format.pattern, format.positions)
      if args then
        Journal.AddKill(Journal.PVP, args[1])
        return
      end
    end
  end)
end
