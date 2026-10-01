-- Kern: Datenbanken, Einstellungen, Event-Verteilung. Wird vor allen Modulen geladen.
local _, ns = ...

local PREFIX = "|cfff4c95dLevelTimer:|r "

-- Account-weit (LevelTimerDB)
local settingsDefaults = {
  language = ns.DefaultLanguage(),
  fontSize = 16,
  bgAlpha = 0.8,
  locked = false,
  showTimer = true,
  showKills = true,
  minimap = { hide = false, angle = 225 },
}

-- Pro Charakter (LevelTimerCharDB)
local characterDefaults = {
  level = 0,  -- Level, auf das sich kills bezieht
  kills = 0,
}

function ns.Print(msg)
  print(PREFIX .. msg)
end

-- Fehlende Werte aus den Defaults ergänzen (auch verschachtelt)
local function applyDefaults(db, defaults)
  for key, value in pairs(defaults) do
    if type(value) == "table" then
      if type(db[key]) ~= "table" then db[key] = {} end
      applyDefaults(db[key], value)
    elseif db[key] == nil then
      db[key] = value
    end
  end
  return db
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
  LevelTimerDB = applyDefaults(LevelTimerDB or {}, settingsDefaults)
  LevelTimerCharDB = applyDefaults(LevelTimerCharDB or {}, characterDefaults)
  ns.db = LevelTimerDB
  ns.charDB = LevelTimerCharDB
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
