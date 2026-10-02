-- Instanz-Läufe: ein Lauf ist eine Kopie eines Dungeons, Raids oder Szenarios (siehe InstanceCopy.lua),
-- vom ersten Betreten bis zum Reset oder bis man eine andere Kopie betritt. Raus und wieder rein in
-- dieselbe Kopie (Händler, /reload) setzt den Lauf fort; die Zeit draußen zählt nicht, außer als Geist
-- auf dem Weg zurück zur Leiche. Wiederbelebt draußen (Geistheiler) hält die Uhr an.
-- Offener Lauf: ns.character.currentRun = { name, instanceType, startedAt, seconds, level, xp,
-- counters = { kills, deaths }, zoneUID, unconfirmed }. unconfirmed = Stand vor einem Wiedereintritt,
-- dessen Kopie noch nicht bestätigt ist; zeigt sich eine andere Kopie, wird dort geteilt.
-- Beendete Läufe landen im Journal (instanceLog).
local _, ns = ...
local Stats = ns.Stats
local Journal = ns.Journal
local InstanceCopy = ns.InstanceCopy

local Instances = {}
ns.Instances = Instances

-- Welche Zähler in den Lauf fließen
local RUN_FIELDS = {
  [Stats.PVE_KILLS] = "kills",
  [Stats.PVP_KILLS] = "kills",
  [Stats.DEATHS] = "deaths",
}

local runningSince  -- GetTime(), seit dem die Uhr des offenen Laufs läuft (nil = angehalten)

local function currentRun()
  return ns.character and ns.character.currentRun
end

-- Offener Lauf des eingeloggten Charakters (auch angehalten, solange man draußen ist) oder nil
function Instances.GetCurrentRun()
  return currentRun()
end

function Instances.GetRunSeconds(run)
  local running = (run == currentRun() and runningSince) and (GetTime() - runningSince) or 0
  return run.seconds + running
end

local function pause()
  local run = currentRun()
  if not run or not runningSince then return end
  run.seconds = Instances.GetRunSeconds(run)
  runningSince = nil
end

local function resume()
  runningSince = runningSince or GetTime()
end

local function newRun(name, instanceType, startedAt, level)
  return {
    name = name,
    instanceType = instanceType,
    startedAt = startedAt,
    seconds = 0,
    level = level,
    xp = 0,
    counters = { kills = 0, deaths = 0 },
  }
end

local function finish()
  if not currentRun() then return end
  pause()
  Journal.AddInstanceRun(currentRun())
  ns.character.currentRun = nil
end

-- Stand vor einem Wiedereintritt, dessen Kopie noch nicht feststeht
local function snapshot(run)
  return { seconds = run.seconds, xp = run.xp, kills = run.counters.kills, deaths = run.counters.deaths,
    at = time(), level = ns.level }
end

InstanceCopy.OnEnter(function(name, instanceType, isNew)
  local run = currentRun()
  if run and run.name == name and not isNew then
    -- Als Geist zurück zur Leiche läuft die Uhr schon: sicher dieselbe Kopie
    if not runningSince and run.zoneUID then
      run.unconfirmed = run.unconfirmed or snapshot(run)
    end
  else
    finish()
    ns.character.currentRun = newRun(name, instanceType, time(), ns.level)
  end
  resume()
end)

-- Als Geist auf dem Weg zum Friedhof und zurück läuft die Uhr weiter
InstanceCopy.OnLeave(function()
  if UnitIsDeadOrGhost("player") then return end
  pause()
end)

-- Draußen wiederbelebt (Geistheiler): Uhr anhalten. PLAYER_ALIVE kommt auch beim Freilassen des Geistes.
local function onPossiblyAlive()
  if UnitIsDeadOrGhost("player") or InstanceCopy.GetInsideName() then return end
  pause()
end

-- Andere Kopie als geschätzt: Wiedereintritt war ein neuer Lauf (teilen) bzw. der vermeintlich neue
-- Lauf gehört zum zuletzt beendeten (zusammenführen)
InstanceCopy.OnCorrected(function(name, instanceType, isNew)
  local run = currentRun()
  if not run or run.name ~= name then return end
  if isNew then
    local before = run.unconfirmed
    if not before then return end
    pause()
    local fresh = newRun(name, instanceType, before.at, before.level)
    fresh.seconds = run.seconds - before.seconds
    fresh.xp = run.xp - before.xp
    fresh.counters.kills = run.counters.kills - before.kills
    fresh.counters.deaths = run.counters.deaths - before.deaths
    run.seconds, run.xp = before.seconds, before.xp
    run.counters.kills, run.counters.deaths = before.kills, before.deaths
    run.unconfirmed = nil
    finish()
    ns.character.currentRun = fresh
    resume()
  else
    local previous = Journal.TakeLastInstanceRun(name)
    if not previous then return end
    run.startedAt, run.level = previous.time, previous.level
    run.seconds = run.seconds + previous.seconds
    run.xp = run.xp + previous.xp
    run.counters.kills = run.counters.kills + previous.counters.kills
    run.counters.deaths = run.counters.deaths + previous.counters.deaths
  end
end)

InstanceCopy.OnConfirmed(function(name, zoneUID)
  local run = currentRun()
  if not run or run.name ~= name then return end
  run.zoneUID = zoneUID
  run.unconfirmed = nil
end)

-- Reset: diese Kopie gibt es nicht mehr, der Lauf ist zu Ende
InstanceCopy.OnReset(function(name)
  local run = currentRun()
  if run and run.name == name then finish() end
end)

-- Nach dem Login steht die Uhr; betritt man die Instanz (wieder), läuft sie weiter
ns.OnLogin(function()
  runningSince = nil
end)

ns.OnLogout(pause)

ns.RegisterEvent("PLAYER_ALIVE", onPossiblyAlive)
ns.RegisterEvent("PLAYER_UNGHOST", onPossiblyAlive)

Stats.OnIncrement(function(counter, amount)
  local run = currentRun()
  if not run or not runningSince then return end
  if counter == Stats.XP_GAINED then
    run.xp = run.xp + amount
  elseif RUN_FIELDS[counter] then
    local field = RUN_FIELDS[counter]
    run.counters[field] = run.counters[field] + amount
  end
end)
