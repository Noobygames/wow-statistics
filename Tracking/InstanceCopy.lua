-- Instanz-Kopien: in welcher Kopie eines Dungeons, Raids oder Szenarios man ist. Die API liefert für
-- 5er-Dungeons keine Instanz-ID; erkennbar ist die Kopie an der zoneUID in den GUIDs ihrer Gegner
-- (Creature-0-Server-InstanzID-zoneUID-NpcID-SpawnUID, siehe warcraft.wiki.gg/wiki/GUID), so wie es
-- auch Nova Instance Tracker macht. Beim Betreten wird deshalb zuerst geschätzt, später bestätigt:
--   Schätzung    neue Kopie, wenn der Charakter die Instanz nicht kennt, sie seitdem zurückgesetzt wurde
--                oder er sie vor mehr als REUSE_SECONDS verlassen hat; sonst dieselbe
--   Bestätigung  sobald CONFIRM_SIGHTINGS verschiedene Gegner (Ziel, Maus, Namensplakette) dieselbe
--                zoneUID zeigen. Weicht sie von der gemerkten ab, war es eine andere Kopie (Reset, den
--                man nicht gesehen hat, oder Kopie eines anderen Gruppenleiters).
-- In Retail und WoW Forever kann UnitGUID geheim sein (SecretWhenUnitIdentityRestricted); dann bleibt
-- es bei der Schätzung.
-- Reset: INSTANCE_RESET_SUCCESS oder INSTANCE_RESET_FAILED im Systemchat. Beide bekommt nur der
-- Gruppenleiter; FAILED ("noch Spieler drin") setzt die Instanz für alle draußen trotzdem zurück.
-- Je Charakter gemerkt: character.instanceVisits[Name] = { zoneUID, leftAt }.
--
-- Abonnenten (Instances.lua, InstanceLimit.lua):
--   OnEnter(fn(name, instanceType, isNew))                     isNew = Schätzung
--   OnLeave(fn(name))
--   OnCorrected(fn(name, instanceType, isNew, enteredAt))     die zoneUID widerspricht der Schätzung
--   OnConfirmed(fn(name, zoneUID))                            Kopie steht fest
--   OnReset(fn(name))                                         alte Kopie ist weg
local _, ns = ...
local ChatPatterns = ns.ChatPatterns

local InstanceCopy = {}
ns.InstanceCopy = InstanceCopy

local TRACKED_TYPES = { party = true, raid = true, scenario = true }
local REUSE_SECONDS = 30 * 60  -- so lange nach dem Verlassen gilt die Instanz als dieselbe Kopie
local CONFIRM_SIGHTINGS = 2    -- so viele verschiedene Gegner müssen dieselbe zoneUID zeigen

local resetPatterns = ChatPatterns.CompileGlobals({ "INSTANCE_RESET_SUCCESS", "INSTANCE_RESET_FAILED" })

-- Aktueller Aufenthalt: { name, instanceType, enteredAt, guessNew, expectedZoneUID,
-- candidate, sightings, lastGuid, confirmed }; nil draußen
local inside

local listeners = { enter = {}, leave = {}, corrected = {}, confirmed = {}, reset = {} }

local function notify(kind, ...)
  for _, listener in ipairs(listeners[kind]) do
    listener(...)
  end
end

function InstanceCopy.OnEnter(fn) table.insert(listeners.enter, fn) end
function InstanceCopy.OnLeave(fn) table.insert(listeners.leave, fn) end
function InstanceCopy.OnCorrected(fn) table.insert(listeners.corrected, fn) end
function InstanceCopy.OnConfirmed(fn) table.insert(listeners.confirmed, fn) end
function InstanceCopy.OnReset(fn) table.insert(listeners.reset, fn) end

-- Name der Instanz, in der man gerade ist; nil draußen
function InstanceCopy.GetInsideName()
  return inside and inside.name
end

-- zoneUID aus der GUID eines Gegners; nil für Spieler, Begleiter, geheime oder unbekannte GUIDs
function InstanceCopy.ZoneUIDOf(guid)
  if not guid or ns.IsSecret(guid) then return nil end
  local digits = guid:match("^Creature%-%d+%-%d+%-%d+%-(%d+)%-")
  local zoneUID = digits and tonumber(digits)
  return zoneUID and zoneUID > 0 and zoneUID or nil
end

local function visits()
  return ns.character.instanceVisits
end

local function isNewCopy(visit, now)
  return not visit or (visit.leftAt ~= nil and now - visit.leftAt > REUSE_SECONDS)
end

local function enter(name, instanceType)
  local now = time()
  local visit = visits()[name]
  local guessNew = isNewCopy(visit, now)
  inside = {
    name = name,
    instanceType = instanceType,
    enteredAt = now,
    guessNew = guessNew,
    expectedZoneUID = visit and visit.zoneUID,
    sightings = 0,
  }
  -- Bis zur Bestätigung gilt die gemerkte zoneUID nur, wenn es dieselbe Kopie sein dürfte
  visits()[name] = { zoneUID = not guessNew and visit and visit.zoneUID or nil }
  ns.Debug("instances", "enter %s, new copy guessed: %s", name, guessNew)
  notify("enter", name, instanceType, guessNew)
end

local function leave()
  local name = inside.name
  local visit = visits()[name]
  if visit then visit.leftAt = time() end
  inside = nil
  notify("leave", name)
end

local function confirm(zoneUID)
  inside.confirmed = true
  visits()[inside.name].zoneUID = zoneUID
  local expected = inside.expectedZoneUID
  if expected then
    local isNew = zoneUID ~= expected
    if isNew ~= inside.guessNew then
      ns.Debug("instances", "%s: zoneUID %s vs %s, new copy: %s", inside.name, zoneUID, expected, isNew)
      notify("corrected", inside.name, inside.instanceType, isNew, inside.enteredAt)
    end
  end
  notify("confirmed", inside.name, zoneUID)
end

-- Gegner gesehen: zoneUID zählt erst, wenn CONFIRM_SIGHTINGS verschiedene Gegner sie zeigen
local function sighted(unit)
  if not inside or inside.confirmed or not unit then return end
  local guid = UnitGUID(unit)
  local zoneUID = InstanceCopy.ZoneUIDOf(guid)
  if not zoneUID or guid == inside.lastGuid then return end
  inside.lastGuid = guid
  if zoneUID == inside.candidate then
    inside.sightings = inside.sightings + 1
  else
    inside.candidate, inside.sightings = zoneUID, 1
  end
  if inside.sightings >= CONFIRM_SIGHTINGS then
    confirm(zoneUID)
  end
end

-- Name und Art der verfolgten Instanz, in der man gerade ist; nil in der offenen Welt
local function trackedInstance()
  local inInstance, instanceType = IsInInstance()
  if not inInstance or not TRACKED_TYPES[instanceType] then return nil end
  local name = GetInstanceInfo()
  if ns.IsSecret(name) then return nil end
  return name, instanceType
end

local function onWorldChanged()
  local name, instanceType = trackedInstance()
  if name == InstanceCopy.GetInsideName() then return end
  if inside then leave() end
  if name then enter(name, instanceType) end
end

-- "Die Todesminen wurde zurückgesetzt.": die alte Kopie gibt es nicht mehr
local function onSystemMessage(message)
  if ns.IsSecret(message) then return end
  local args = ChatPatterns.MatchAny(message, resetPatterns)
  if not args then return end
  local name = args[1]
  ns.Debug("instances", "reset %s", name)
  visits()[name] = nil
  notify("reset", name)
end

ns.OnLogin(function()
  inside = nil
end)

-- Logout in der Instanz gilt als Verlassen, damit der nächste Login die Pause sieht
ns.OnLogout(function()
  if inside then leave() end
end)

ns.RegisterEvent("PLAYER_ENTERING_WORLD", onWorldChanged)
ns.RegisterEvent("ZONE_CHANGED_NEW_AREA", onWorldChanged)
ns.RegisterEvent("CHAT_MSG_SYSTEM", onSystemMessage)
ns.RegisterEvent("PLAYER_TARGET_CHANGED", function() sighted("target") end)
ns.RegisterEvent("UPDATE_MOUSEOVER_UNIT", function() sighted("mouseover") end)
ns.RegisterEvent("NAME_PLATE_UNIT_ADDED", sighted)
