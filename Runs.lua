-- Läufe für Speedrun-Vergleiche: Level-Zeiten eines Charakters oder eines importierten Laufs.
-- Lauf: { id, name, realm, class, times = { [level] = Sekunden }, reachedLevel, imported, favorite }
--   id = Charakter-Schlüssel ("Name-Realm") oder "import:<n>" für importierte Läufe
-- Importierte Läufe liegen in LevelTimerStatsDB.importedRuns, Favoriten in LevelTimerStatsDB.runFavorites.
local _, ns = ...
local History = ns.History

local Runs = {}
ns.Runs = Runs

local IMPORT_PREFIX = "import:"

local function store()
  LevelTimerStatsDB.importedRuns = LevelTimerStatsDB.importedRuns or {}
  LevelTimerStatsDB.runFavorites = LevelTimerStatsDB.runFavorites or {}
  return LevelTimerStatsDB
end

-- Abgeschlossene Level-Zeiten eines Charakters: level -> Sekunden
function Runs.LevelTimes(characterKey)
  local times = {}
  for _, record in ipairs(History.GetLevelRecords(characterKey)) do
    if not record.isCurrent and record.seconds then times[record.level] = record.seconds end
  end
  return times
end

local function fromCharacter(characterKey)
  local character = History.GetCharacter(characterKey)
  return {
    id = characterKey,
    name = character.name,
    realm = character.realm,
    class = character.class,
    times = Runs.LevelTimes(characterKey),
    reachedLevel = character.currentLevel.level,
  }
end

local function fromImport(index, run)
  return {
    id = IMPORT_PREFIX .. index,
    name = run.name,
    realm = run.realm,
    class = run.class,
    times = run.times,
    reachedLevel = run.reachedLevel,
    imported = true,
  }
end

-- Alle Läufe: eigene Charaktere (eingeloggter zuerst), dann importierte
function Runs.GetAll()
  local favorites = store().runFavorites
  local runs = {}
  for _, key in ipairs(History.GetCharacterKeys()) do
    table.insert(runs, fromCharacter(key))
  end
  for index, run in ipairs(store().importedRuns) do
    table.insert(runs, fromImport(index, run))
  end
  for _, run in ipairs(runs) do
    run.favorite = favorites[run.id] == true
  end
  return runs
end

function Runs.Get(id)
  for _, run in ipairs(Runs.GetAll()) do
    if run.id == id then return run end
  end
end

-- Erster Lauf mit diesem Namen (Groß-/Kleinschreibung egal), außer dem eingeloggten Charakter
function Runs.FindByName(name)
  local wanted = name:lower()
  for _, run in ipairs(Runs.GetAll()) do
    if run.id ~= ns.characterKey and (run.name or ""):lower() == wanted then return run end
  end
end

function Runs.ToggleFavorite(id)
  local favorites = store().runFavorites
  favorites[id] = not favorites[id] or nil
end

-- Summe der Zeiten von Level from bis to; nil, wenn eines davon fehlt
function Runs.SumOfLevels(times, from, to)
  local sum = 0
  for level = from, to do
    if not times[level] then return nil end
    sum = sum + times[level]
  end
  return sum
end
