-- Instanz-Läufe: Dungeons, Raids und Szenarien vom Betreten bis zum lebendigen Verlassen.
-- Wer stirbt und als Geist zum Friedhof außerhalb läuft, ist noch im selben Lauf; er endet erst,
-- wenn man lebend draußen ist (z.B. Wiederbelebung beim Geistheiler).
-- Laufender Lauf: ns.character.currentRun = { name, instanceType, startedAt, seconds, level, xp, counters,
-- lastSeen }. Beendete Läufe landen im Journal (instanceLog). /reload und kurze Unterbrechungen setzen
-- den Lauf fort, wie bei Sessions.
local _, ns = ...
local Stats = ns.Stats
local Journal = ns.Journal

local Instances = {}
ns.Instances = Instances

local TRACKED_TYPES = { party = true, raid = true, scenario = true }
local RESUME_GAP_SECONDS = 300

-- Welche Zähler in den Lauf fließen
local RUN_FIELDS = {
  [Stats.PVE_KILLS] = "kills",
  [Stats.PVP_KILLS] = "kills",
  [Stats.DEATHS] = "deaths",
}

local runningSince  -- GetTime() seit dem die laufende Zeit gezählt wird (nil = kein laufender Lauf)

local function currentRun()
  return ns.character and ns.character.currentRun
end

-- Name und Art der Instanz, in der man gerade ist; nil in der offenen Welt
local function trackedInstance()
  local inInstance, instanceType = IsInInstance()
  if not inInstance or not TRACKED_TYPES[instanceType] then return nil end
  local name = GetInstanceInfo()
  if ns.IsSecret(name) then return nil end
  return name, instanceType
end

-- Laufender Lauf des eingeloggten Charakters oder nil
function Instances.GetCurrentRun()
  return runningSince and currentRun() or nil
end

function Instances.GetRunSeconds(run)
  local running = (run == currentRun() and runningSince) and (GetTime() - runningSince) or 0
  return run.seconds + running
end

local function start(name, instanceType)
  ns.character.currentRun = {
    name = name,
    instanceType = instanceType,
    startedAt = time(),
    seconds = 0,
    level = ns.level,
    xp = 0,
    counters = { kills = 0, deaths = 0 },
  }
  runningSince = GetTime()
end

local function finish()
  local run = currentRun()
  run.seconds = Instances.GetRunSeconds(run)
  run.lastSeen = nil
  Journal.AddInstanceRun(run)
  ns.character.currentRun = nil
  runningSince = nil
end

local function onWorldChanged()
  local run = currentRun()
  local name, instanceType = trackedInstance()
  if run and run.name ~= name then
    if UnitIsDeadOrGhost("player") then
      ns.Debug("instances", "left %s as ghost, run continues", run.name)
      return
    end
    finish()
  end
  if name and not currentRun() then
    start(name, instanceType)
  end
end

-- Lauf vom letzten Login fortsetzen oder (nach langer Pause) abschließen
ns.OnLogin(function()
  runningSince = nil
  local run = currentRun()
  if not run then return end
  if run.lastSeen and time() - run.lastSeen <= RESUME_GAP_SECONDS then
    runningSince = GetTime()
  else
    finish()
  end
end)

ns.OnLogout(function()
  local run = currentRun()
  if not run then return end
  run.seconds = Instances.GetRunSeconds(run)
  run.lastSeen = time()
  runningSince = GetTime()
end)

ns.RegisterEvent("PLAYER_ENTERING_WORLD", onWorldChanged)
ns.RegisterEvent("ZONE_CHANGED_NEW_AREA", onWorldChanged)
-- Wiederbelebt außerhalb der Instanz (Geistheiler): Lauf endet jetzt
ns.RegisterEvent("PLAYER_ALIVE", onWorldChanged)
ns.RegisterEvent("PLAYER_UNGHOST", onWorldChanged)

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
