-- Gespeicherte Daten:
--   LevelTimerDB       Account: Einstellungen
--   LevelTimerStatsDB  Account: Statistiken, je Charakter ("Name-Realm") getrennt
--   LevelTimerCharDB   veraltet (pro Charakter); wird beim Login in LevelTimerStatsDB übernommen
local _, ns = ...

local Database = {}
ns.Database = Database

local SETTINGS_DEFAULTS = {
  language = ns.DefaultLanguage(),
  fontSize = 16,
  bgAlpha = 0.8,
  locked = false,
  showTimer = true,
  windowScope = "level",  -- "level" oder "session" (siehe Stats.lua)
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

-- Zähler für Level und Session gleichermaßen. Schlüssel siehe Stats.lua.
local COUNTER_DEFAULTS = {
  pveKills = 0,
  pvpKills = 0,
  deaths = 0,
  deadSeconds = 0,
  quests = 0,
  xpGained = 0,
  xpKills = 0,
  xpQuests = 0,
  xpRested = 0,
  moneyEarned = 0,
}

local CHARACTER_DEFAULTS = {
  currentLevel = {
    level = 0,    -- Level, auf das sich die Zähler beziehen
    seconds = 0,  -- letzte bekannte Spielzeit auf dem Level (für die Anzeige anderer Charaktere)
    xp = 0,       -- letzte bekannte XP auf dem Level
    counters = COUNTER_DEFAULTS,
  },
  currentSession = {
    seconds = 0,  -- gespielte Zeit bis zum letzten Logout; startedAt fehlt, solange keine Session lief
    counters = COUNTER_DEFAULTS,
  },
  levelHistory = {},    -- abgeschlossene Level, Schlüssel = Level
  sessionHistory = {},  -- beendete Sessions, älteste zuerst
}

-- Migrationen für die Daten eines Charakters, Schlüssel = Zielversion.
-- Laufen auch für frische (leere) Daten und müssen daher fehlende Felder vertragen.
local CHARACTER_SCHEMA_VERSION = 3
local characterMigrations = {
  [2] = function(data)  -- kills (nur PvE) -> counters.pveKills
    data.counters = data.counters or {}
    data.counters.pveKills = data.kills
    data.kills = nil
  end,
  [3] = function(data)  -- flache Level-Daten -> currentLevel + levelHistory (Sessions sind neu)
    data.currentLevel = { level = data.level, counters = data.counters }
    data.levelHistory = data.history
    data.level, data.counters, data.history = nil, nil, nil
  end,
}

local function migrate(data, migrations, targetVersion)
  local version = data.schemaVersion or 1
  for nextVersion = version + 1, targetVersion do
    if migrations[nextVersion] then
      migrations[nextVersion](data)
    end
  end
  data.schemaVersion = targetVersion
end

-- Fehlende Werte aus den Defaults ergänzen (auch verschachtelt)
local function applyDefaults(data, defaults)
  for key, value in pairs(defaults) do
    if type(value) == "table" then
      if type(data[key]) ~= "table" then data[key] = {} end
      applyDefaults(data[key], value)
    elseif data[key] == nil then
      data[key] = value
    end
  end
  return data
end

function Database.NewCounters()
  return applyDefaults({}, COUNTER_DEFAULTS)
end

function Database.CharacterKey(name, realm)
  return name .. "-" .. realm
end

-- Daten des eingeloggten Charakters holen oder anlegen. Alte Daten aus
-- LevelTimerCharDB werden dabei einmalig übernommen und durchlaufen dieselben Migrationen.
local function loadCharacter(stats)
  local name, realm = UnitName("player"), GetRealmName()
  local key = Database.CharacterKey(name, realm)

  local data = stats.characters[key]
  if not data then
    data = LevelTimerCharDB or {}
    stats.characters[key] = data
  end
  LevelTimerCharDB = nil

  migrate(data, characterMigrations, CHARACTER_SCHEMA_VERSION)
  applyDefaults(data, CHARACTER_DEFAULTS)

  data.name, data.realm = name, realm
  data.class = select(2, UnitClass("player"))
  return key, data
end

-- Erst ab PLAYER_LOGIN aufrufen, vorher hat der Client die SavedVariables nicht geladen.
-- Rückgabe: Einstellungen, Schlüssel und Daten des eingeloggten Charakters.
function Database.Load()
  LevelTimerDB = applyDefaults(LevelTimerDB or {}, SETTINGS_DEFAULTS)
  LevelTimerStatsDB = applyDefaults(LevelTimerStatsDB or {}, { characters = {} })
  local characterKey, character = loadCharacter(LevelTimerStatsDB)
  return LevelTimerDB, characterKey, character
end

function Database.GetCharacters()
  return LevelTimerStatsDB.characters
end
