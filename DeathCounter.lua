-- Zählt eigene Tode und die Zeit, die man tot bzw. als Geist verbringt.
-- Totstellen (Jäger) löst PLAYER_DEAD nicht aus.
local _, ns = ...
local Stats = ns.Stats

local DeathCounter = {}
ns.DeathCounter = DeathCounter

local deadSince  -- GetTime() beim Tod, nil solange lebendig

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

local function finishDeadTime()
  if not deadSince then return end
  Stats.Increment(Stats.DEAD_SECONDS, GetTime() - deadSince)
  deadSince = nil
end

ns.RegisterEvent("PLAYER_DEAD", function()
  if deadSince then return end  -- schon tot (z.B. Login als Geist), nicht doppelt zählen
  Stats.Increment(Stats.DEATHS)
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

-- Als Geist eingeloggt: Zeit seit Login weiterzählen (Offline-Zeit zählt nicht)
ns.OnLogin(function()
  if UnitIsDeadOrGhost("player") then
    deadSince = GetTime()
  end
end)

-- Laufende Zeit vor dem Speichern verbuchen; nach dem Login zählt sie neu weiter
ns.OnLogout(finishDeadTime)
