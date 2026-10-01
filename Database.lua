-- Gespeicherte Daten: Defaults und Migrationen für LevelTimerDB (Account) und LevelTimerCharDB (Charakter).
local _, ns = ...

local Database = {}
ns.Database = Database

local SETTINGS_DEFAULTS = {
  language = ns.DefaultLanguage(),
  fontSize = 16,
  bgAlpha = 0.8,
  locked = false,
  showTimer = true,
  -- Stat-Zeilen im Fenster (siehe StatLines.lua)
  showXpRate = true,
  showKills = true,
  showDeaths = true,
  showXpSources = true,
  showRested = true,
  showQuests = true,
  showMoney = true,
  minimap = { hide = false, angle = 225 },
}

local CHARACTER_DEFAULTS = {
  level = 0,  -- Level, auf das sich die Zähler beziehen
  counters = {  -- Schlüssel siehe LevelStats.lua
    pveKills = 0,
    pvpKills = 0,
    deaths = 0,
    deadSeconds = 0,
    quests = 0,
    xpKills = 0,
    xpQuests = 0,
    xpRested = 0,
    moneyEarned = 0,
  },
  history = {},  -- abgeschlossene Level, Schlüssel = Level (siehe LevelHistory.lua)
}

-- Migrationen für LevelTimerCharDB, Schlüssel = Zielversion.
-- Laufen auch für frische (leere) Daten und müssen daher fehlende Felder vertragen.
local CHARACTER_SCHEMA_VERSION = 2
local characterMigrations = {
  [2] = function(db)  -- kills (nur PvE) -> counters.pveKills
    db.counters = db.counters or {}
    db.counters.pveKills = db.kills
    db.kills = nil
  end,
}

local function migrate(db, migrations, targetVersion)
  local version = db.schemaVersion or 1
  for nextVersion = version + 1, targetVersion do
    if migrations[nextVersion] then
      migrations[nextVersion](db)
    end
  end
  db.schemaVersion = targetVersion
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

-- Erst ab PLAYER_LOGIN aufrufen, vorher hat der Client die SavedVariables nicht geladen
function Database.Load()
  LevelTimerDB = applyDefaults(LevelTimerDB or {}, SETTINGS_DEFAULTS)

  LevelTimerCharDB = LevelTimerCharDB or {}
  migrate(LevelTimerCharDB, characterMigrations, CHARACTER_SCHEMA_VERSION)
  applyDefaults(LevelTimerCharDB, CHARACTER_DEFAULTS)

  return LevelTimerDB, LevelTimerCharDB
end
