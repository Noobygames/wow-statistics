-- Kern: Einstellungs- und Event-Verteilung, Login-, Logout- und Level-Up-Ablauf. Wird vor allen Modulen geladen.
local _, ns = ...

local PREFIX = "|cfff4c95dLevelTimer:|r "

function ns.Print(msg)
  print(PREFIX .. msg)
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

ns.RegisterEvent("PLAYER_LOGIN", function()
  ns.db, ns.characterKey, ns.character = ns.Database.Load()
  ns.level = UnitLevel("player")
  runAll(loginCallbacks)
  ns.ApplySettings()
end)

ns.RegisterEvent("PLAYER_LOGOUT", function()
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
  runAll(levelCompletedCallbacks, ns.level)
  ns.level = newLevel
  runAll(levelStartedCallbacks, newLevel)
end)
