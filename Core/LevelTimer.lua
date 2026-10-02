-- Kern: Einstellungs- und Event-Verteilung, Login-, Logout- und Level-Up-Ablauf. Wird vor allen Modulen geladen.
local _, ns = ...

-- Name, den Spieler sehen (CurseForge-Projekt, Addon-Liste, Fenster, Chat). Technische Namen
-- (Ordner, .toc, SavedVariables, Frame-Namen, /lt) bleiben LevelTimer, sonst gingen Daten verloren.
ns.DISPLAY_NAME = "Level Time"

local PREFIX = "|cfff4c95d" .. ns.DISPLAY_NAME .. ":|r "

function ns.Print(msg)
  print(PREFIX .. msg)
end

-- Erweitertes Logging für /lt debug (ns.debug, bis /reload). Technische Zeilen für die
-- Fehlersuche, daher englisch und nicht übersetzt. Werte werden zu Text, daher nur %s:
-- ns.Debug("stats", "%s +%s", counter, amount)
local DEBUG_PREFIX = "|cff888888[debug] %s:|r "

-- Technische Zeile immer ausgeben (Ergebnisse der /lt debug-Befehle)
function ns.DebugPrint(area, format, ...)
  local args = { ... }
  for i = 1, select("#", ...) do
    args[i] = ns.IsSecret(args[i]) and "<secret>" or tostring(args[i])
  end
  print(PREFIX .. string.format(DEBUG_PREFIX, area) .. string.format(format, unpack(args, 1, select("#", ...))))
end

-- Nur bei eingeschaltetem Logging
function ns.Debug(area, format, ...)
  if ns.debug then ns.DebugPrint(area, format, ...) end
end

-- Retail kann Werte als "secret" markieren; die dürfen Addons nicht auswerten
function ns.IsSecret(value)
  return issecretvalue ~= nil and issecretvalue(value)
end

local function runAll(callbacks, ...)
  for _, callback in ipairs(callbacks) do
    callback(...)
  end
end

---------------------------------------------------------------------------
-- Einstellungen: Module registrieren Apply-Callbacks, die bei jeder Änderung
-- ihren Zustand aus ns.db neu aufbauen.
---------------------------------------------------------------------------
local applyCallbacks = {}

function ns.RegisterApply(callback)
  table.insert(applyCallbacks, callback)
end

function ns.ApplySettings()
  runAll(applyCallbacks, ns.db)
end

function ns.Set(key, value)
  ns.db[key] = value
  ns.ApplySettings()
end

---------------------------------------------------------------------------
-- Events: mehrere Module können dasselbe Event abonnieren.
-- Handler laufen in Registrierungsreihenfolge (= Ladereihenfolge der .toc).
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
local eventHandlers = {}

-- Gibt false zurück, wenn der Client das Event nicht kennt (andere Spielversion).
-- Das zugehörige Feature bleibt dann still aus, statt einen Fehler zu werfen.
function ns.RegisterEvent(event, handler)
  if not eventHandlers[event] then
    if not pcall(eventFrame.RegisterEvent, eventFrame, event) then
      return false
    end
    eventHandlers[event] = {}
  end
  table.insert(eventHandlers[event], handler)
  return true
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
  runAll(eventHandlers[event], ...)
end)

---------------------------------------------------------------------------
-- Wiederkehrende Aufgaben: fn(elapsed) etwa alle seconds Sekunden, erst nach dem Login (vorher
-- gibt es weder ns.db noch ns.character). elapsed = tatsächlich vergangene Zeit seit dem letzten Lauf.
-- Ein gemeinsamer Frame statt eines OnUpdate-Frames je Modul.
---------------------------------------------------------------------------
local repeatingTasks = {}
local taskFrame = CreateFrame("Frame")

function ns.Every(seconds, fn)
  table.insert(repeatingTasks, { interval = seconds, fn = fn, elapsed = 0 })
end

taskFrame:SetScript("OnUpdate", function(_, elapsed)
  if not ns.character then return end
  for _, task in ipairs(repeatingTasks) do
    task.elapsed = task.elapsed + elapsed
    if task.elapsed >= task.interval then
      local due = task.elapsed
      task.elapsed = 0
      task.fn(due)
    end
  end
end)

---------------------------------------------------------------------------
-- Login/Logout. Nach dem Login stehen bereit:
--   ns.db            Einstellungen (Account)
--   ns.characterKey  "Name-Realm" des eingeloggten Charakters
--   ns.character     Statistiken des eingeloggten Charakters
--   ns.level         aktuelles Level
-- Logout kommt auch bei /reload; danach schreibt der Client die SavedVariables.
---------------------------------------------------------------------------
local loginCallbacks = {}
local logoutCallbacks = {}

function ns.OnLogin(callback)
  table.insert(loginCallbacks, callback)
end

function ns.OnLogout(callback)
  table.insert(logoutCallbacks, callback)
end

local function startTracking()
  ns.db, ns.characterKey, ns.character = ns.Database.Load()
  ns.level = UnitLevel("player")
  ns.Debug("core", "login %s level %s", ns.characterKey, ns.level)
  runAll(loginCallbacks)
  ns.ApplySettings()
end

ns.RegisterEvent("PLAYER_LOGIN", startTracking)

-- Statistiken eines Charakters löschen. Beim eingeloggten Charakter beginnt die Aufzeichnung
-- sofort neu (wie bei einem frischen Login); alle Module initialisieren sich über OnLogin.
function ns.DeleteCharacter(characterKey)
  ns.Database.DeleteCharacter(characterKey)
  if characterKey == ns.characterKey then
    startTracking()
  end
end

ns.RegisterEvent("PLAYER_LOGOUT", function()
  ns.Debug("core", "logout")
  runAll(logoutCallbacks)
end)

---------------------------------------------------------------------------
-- Level-Up in zwei Phasen, damit die Reihenfolge nicht von der Ladereihenfolge abhängt:
-- 1. OnLevelCompleted(oldLevel): Werte des alten Levels sind noch vollständig (z.B. Historie sichern)
-- 2. OnLevelStarted(newLevel): Zähler für das neue Level zurücksetzen
---------------------------------------------------------------------------
local levelCompletedCallbacks = {}
local levelStartedCallbacks = {}

function ns.OnLevelCompleted(callback)
  table.insert(levelCompletedCallbacks, callback)
end

function ns.OnLevelStarted(callback)
  table.insert(levelStartedCallbacks, callback)
end

ns.RegisterEvent("PLAYER_LEVEL_UP", function(newLevel)
  ns.Debug("core", "level up %s -> %s", ns.level, newLevel)
  runAll(levelCompletedCallbacks, ns.level)
  ns.level = newLevel
  runAll(levelStartedCallbacks, newLevel)
end)
