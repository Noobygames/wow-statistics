-- Zählt eigene Tode, die Zeit tot bzw. als Geist und schreibt jeden Tod mit Ursache ins Journal.
-- Ursache = letzter Treffer vor dem Tod aus dem Kampflog. Wo der Client das Kampflog
-- nicht an Addons gibt (Retail), bleibt sie unbekannt.
-- Totstellen (Jäger) löst PLAYER_DEAD nicht aus.
local _, ns = ...
local Stats = ns.Stats
local Journal = ns.Journal

local DeathCounter = {}
ns.DeathCounter = DeathCounter

local LAST_HIT_MAX_AGE = 10  -- Sekunden; ältere Treffer gelten nicht mehr als Todesursache

local deadSince   -- GetTime() beim Tod, nil solange lebendig
local lastHit     -- { killer, spell, environment, at } des letzten Schadens am Spieler
local playerGUID  -- einmal beim Login gemerkt; das Kampflog feuert sehr oft

-- Inklusive der laufenden Zeit, falls man gerade tot ist
function DeathCounter.GetDeadSeconds(scope)
  local running = deadSince and (GetTime() - deadSince) or 0
  return Stats.Get(scope, Stats.DEAD_SECONDS) + running
end

-- Kills pro Tod, nil solange man im Bereich nicht gestorben ist
function DeathCounter.GetKillsPerDeath(scope)
  local deaths = Stats.Get(scope, Stats.DEATHS)
  if deaths == 0 then return nil end
  return Stats.GetTotalKills(scope) / deaths
end

---------------------------------------------------------------------------
-- Letzter Treffer: Schadens-Events aus dem Kampflog, deren Ziel der Spieler ist
---------------------------------------------------------------------------
local SPELL_DAMAGE_EVENTS = {
  RANGE_DAMAGE = true,
  SPELL_DAMAGE = true,
  SPELL_PERIODIC_DAMAGE = true,
}

local function readable(value)
  if ns.IsSecret(value) then return nil end
  return value
end

-- Feldreihenfolge von CombatLogGetCurrentEventInfo: 2 = Event, 5 = Verursacher, 8 = Ziel-GUID,
-- ab 12 je nach Event (Zauber: 12 = ID, 13 = Name; Umgebung: 12 = Art)
local function onCombatLogEvent()
  local ok, _, subevent, _, _, sourceName, _, _, destGUID, _, _, _, extra1, extra2 =
    pcall(CombatLogGetCurrentEventInfo)
  if not ok or not playerGUID or readable(destGUID) ~= playerGUID then return end

  if subevent == "ENVIRONMENTAL_DAMAGE" then
    lastHit = { environment = readable(extra1) }
  elseif subevent == "SWING_DAMAGE" then
    lastHit = { killer = readable(sourceName) }
  elseif SPELL_DAMAGE_EVENTS[subevent] then
    lastHit = { killer = readable(sourceName), spell = readable(extra2) }
  else
    return
  end
  lastHit.at = GetTime()
end

if CombatLogGetCurrentEventInfo then
  ns.RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", onCombatLogEvent)
end

local function takeDeathCause()
  local cause = {}
  if lastHit and GetTime() - lastHit.at <= LAST_HIT_MAX_AGE then
    cause = lastHit
  end
  lastHit = nil
  return cause
end

---------------------------------------------------------------------------
-- Tod und Wiederbelebung
---------------------------------------------------------------------------
local function finishDeadTime()
  if not deadSince then return end
  Stats.Increment(Stats.DEAD_SECONDS, GetTime() - deadSince)
  deadSince = nil
end

ns.RegisterEvent("PLAYER_DEAD", function()
  if deadSince then return end  -- schon tot (z.B. Login als Geist), nicht doppelt zählen
  Stats.Increment(Stats.DEATHS)
  Journal.AddDeath(takeDeathCause())
  deadSince = GetTime()
end)

-- PLAYER_ALIVE kommt auch beim Freilassen des Geistes, daher prüfen, ob man wirklich lebt
local function onPossiblyAlive()
  if not UnitIsDeadOrGhost("player") then
    finishDeadTime()
  end
end

ns.RegisterEvent("PLAYER_ALIVE", onPossiblyAlive)
ns.RegisterEvent("PLAYER_UNGHOST", onPossiblyAlive)

-- Spieler-GUID merken. Als Geist eingeloggt: Zeit seit Login weiterzählen (Offline-Zeit zählt nicht)
ns.OnLogin(function()
  playerGUID = UnitGUID("player")
  if UnitIsDeadOrGhost("player") then
    deadSince = GetTime()
  end
end)

-- Laufende Zeit vor dem Speichern verbuchen; nach dem Login zählt sie neu weiter
ns.OnLogout(finishDeadTime)
