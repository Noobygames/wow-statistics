-- Zählt eigene Tode auf dem aktuellen Level und die Zeit, die man tot bzw. als Geist verbringt.
-- Totstellen (Jäger) löst PLAYER_DEAD nicht aus.
local _, ns = ...
local LevelStats = ns.LevelStats

local DeathCounter = {}
ns.DeathCounter = DeathCounter

local deadSince  -- GetTime() beim Tod, nil solange lebendig

-- Inklusive der laufenden Zeit, falls man gerade tot ist
function DeathCounter.GetDeadSeconds()
  local running = deadSince and (GetTime() - deadSince) or 0
  return LevelStats.Get(LevelStats.DEAD_SECONDS) + running
end

-- Kills pro Tod, nil solange man auf diesem Level nicht gestorben ist
function DeathCounter.GetKillsPerDeath()
  local deaths = LevelStats.Get(LevelStats.DEATHS)
  if deaths == 0 then return nil end
  return LevelStats.GetTotalKills() / deaths
end

local function finishDeadTime()
  if not deadSince then return end
  LevelStats.Increment(LevelStats.DEAD_SECONDS, GetTime() - deadSince)
  deadSince = nil
end

ns.RegisterEvent("PLAYER_DEAD", function()
  if deadSince then return end  -- schon tot (z.B. Login als Geist), nicht doppelt zählen
  LevelStats.Increment(LevelStats.DEATHS)
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
