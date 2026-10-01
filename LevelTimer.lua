-- Kern: Einstellungs- und Event-Verteilung, Login-Ablauf. Wird vor allen Modulen geladen.
local _, ns = ...

local PREFIX = "|cfff4c95dLevelTimer:|r "

function ns.Print(msg)
  print(PREFIX .. msg)
end

-- Retail kann Werte als "secret" markieren; die dürfen Addons nicht auswerten
function ns.IsSecret(value)
  return issecretvalue ~= nil and issecretvalue(value)
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
  for _, callback in ipairs(applyCallbacks) do
    callback(ns.db)
  end
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

function ns.RegisterEvent(event, handler)
  if not eventHandlers[event] then
    eventHandlers[event] = {}
    eventFrame:RegisterEvent(event)
  end
  table.insert(eventHandlers[event], handler)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
  for _, handler in ipairs(eventHandlers[event]) do
    handler(...)
  end
end)

-- Login-Callbacks laufen, sobald ns.db, ns.charDB und ns.level bereitstehen
local loginCallbacks = {}

function ns.OnLogin(callback)
  table.insert(loginCallbacks, callback)
end

ns.RegisterEvent("PLAYER_LOGIN", function()
  ns.db, ns.charDB = ns.Database.Load()
  ns.level = UnitLevel("player")

  for _, callback in ipairs(loginCallbacks) do
    callback()
  end
  ns.ApplySettings()
end)

-- Als erster Level-Up-Handler registriert, damit alle Module schon das neue Level sehen
ns.RegisterEvent("PLAYER_LEVEL_UP", function(newLevel)
  ns.level = newLevel
end)
