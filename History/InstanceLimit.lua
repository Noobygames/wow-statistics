-- Instanzlimit: Der Server lässt pro Stunde nur LIMIT neue Instanzen (Dungeons und Raids) zu, für alle
-- Charaktere eines Accounts auf einem Realm (Classic Era, Anniversary, WoW Forever: 5; Retail: 10).
-- Die Stunde gleitet: ein Platz wird eine Stunde nach dem Betreten der jeweiligen Instanz wieder frei.
--
-- Betretene Instanzen: LevelTimerStatsDB.instanceEntries[Realm] = { { time, name, character }, ... },
-- älteste zuerst, nur die letzten 24 Stunden. Accountweit, damit alle Charaktere zählen, die das Addon
-- in diesem Client schon gesehen hat.
--
-- Ob es eine neue Instanz ist, liefert die API für 5er-Dungeons nicht (keine Instanz-ID). Geschätzt wird
-- je Charakter (character.instanceVisits[Name] = { leftAt }):
--   gleiche Instanz  derselbe Dungeon, noch drin (/reload) oder vor höchstens REUSE_SECONDS verlassen
--   neue Instanz     sonst, oder nach der Reset-Meldung (INSTANCE_RESET_SUCCESS im Systemchat)
-- Wechsel der Gruppe (andere Instanz des Gruppenleiters) erkennt die Schätzung nicht.
local _, ns = ...
local L = ns.L
local Format = ns.Format

local InstanceLimit = {}
ns.InstanceLimit = InstanceLimit

InstanceLimit.WINDOW = 3600               -- Sekunden, für die eine Instanz zählt
local LIMIT_CLASSIC = 5
local LIMIT_RETAIL = 10
local KEEP_SECONDS = 24 * 3600            -- so lange bleiben Einträge gespeichert (Info "heute")
local REUSE_SECONDS = 30 * 60             -- so lange nach dem Verlassen gilt derselbe Dungeon als gleiche Instanz
local COUNTED_TYPES = { party = true, raid = true }  -- Schlachtfelder und Szenarien zählen nicht

local resetPattern = INSTANCE_RESET_SUCCESS and ns.ChatPatterns.Compile(INSTANCE_RESET_SUCCESS)
local insideName  -- Instanz, in der der Charakter gerade ist (nil = draußen)

function InstanceLimit.GetLimit()
  return ns.Client.IsRetail() and LIMIT_RETAIL or LIMIT_CLASSIC
end

local function realmEntries()
  LevelTimerStatsDB.instanceEntries = LevelTimerStatsDB.instanceEntries or {}
  local realm = ns.character.realm
  LevelTimerStatsDB.instanceEntries[realm] = LevelTimerStatsDB.instanceEntries[realm] or {}
  return LevelTimerStatsDB.instanceEntries[realm]
end

local function prune(entries, now)
  while entries[1] and now - entries[1].time > KEEP_SECONDS do
    table.remove(entries, 1)
  end
end

-- Einträge seit since (Zeitstempel), älteste zuerst
local function entriesSince(since)
  local result = {}
  for _, entry in ipairs(realmEntries()) do
    if entry.time > since then table.insert(result, entry) end
  end
  return result
end

-- Neue Instanzen in der laufenden Stunde
function InstanceLimit.GetHourCount()
  return #entriesSince(time() - InstanceLimit.WINDOW)
end

-- Sekunden, bis der nächste Platz frei wird (die älteste Instanz der Stunde fällt heraus); nil ohne Einträge
function InstanceLimit.GetSecondsUntilNextFree()
  local oldest = entriesSince(time() - InstanceLimit.WINDOW)[1]
  if not oldest then return nil end
  return oldest.time + InstanceLimit.WINDOW - time()
end

-- Neue Instanzen seit Mitternacht (nur Info, kein Limit)
function InstanceLimit.GetTodayCount()
  return #entriesSince(ns.Daily.StartOfDay(time()) - 1)
end

local function visits()
  return ns.character.instanceVisits
end

local function isSameInstance(name, now)
  local visit = visits()[name]
  if not visit then return false end
  return not visit.leftAt or now - visit.leftAt <= REUSE_SECONDS
end

local function warn()
  if not ns.db.warnInstanceLimit then return end
  local count, limit = InstanceLimit.GetHourCount(), InstanceLimit.GetLimit()
  if count < limit - 1 then return end
  local wait = InstanceLimit.GetSecondsUntilNextFree() or 0
  ns.Alerts.Notify(string.format(L.INSTANCE_LIMIT_WARNING, count, limit, Format.Duration(wait)),
    ns.Alerts.WARNING_COLOR)
end

local function enter(name)
  local now = time()
  if isSameInstance(name, now) then
    ns.Debug("instances", "back in %s, same instance", name)
  else
    local entries = realmEntries()
    prune(entries, now)
    table.insert(entries, { time = now, name = name, character = ns.characterKey })
    ns.Debug("instances", "new instance %s, %s in the last hour", name, InstanceLimit.GetHourCount())
    warn()
  end
  visits()[name] = { leftAt = nil }
  insideName = name
end

local function leave()
  visits()[insideName] = { leftAt = time() }
  insideName = nil
end

-- Name der gezählten Instanz, in der man gerade ist; nil draußen
local function countedInstance()
  local inInstance, instanceType = IsInInstance()
  if not inInstance or not COUNTED_TYPES[instanceType] then return nil end
  local name = GetInstanceInfo()
  if ns.IsSecret(name) then return nil end
  return name
end

local function onWorldChanged()
  local name = countedInstance()
  if name == insideName then return end
  if insideName then leave() end
  if name then enter(name) end
end

-- "Die Todesminen wurde zurückgesetzt.": nächstes Betreten ist eine neue Instanz
local function onSystemMessage(message)
  if not resetPattern or ns.IsSecret(message) then return end
  local args = ns.ChatPatterns.Match(message, resetPattern)
  if not args then return end
  ns.Debug("instances", "reset %s", args[1])
  visits()[args[1]] = nil
end

ns.OnLogin(function()
  insideName = nil
end)

-- Logout in der Instanz: gilt ab jetzt als verlassen, damit ein späterer Login die Pause sieht
ns.OnLogout(function()
  if insideName then leave() end
end)

ns.RegisterEvent("PLAYER_ENTERING_WORLD", onWorldChanged)
ns.RegisterEvent("ZONE_CHANGED_NEW_AREA", onWorldChanged)
ns.RegisterEvent("CHAT_MSG_SYSTEM", onSystemMessage)
