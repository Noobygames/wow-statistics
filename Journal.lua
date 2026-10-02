-- Journal: einzelne Kills, Tode, Quests, Beute, Instanz-Läufe und Beinahe-Tode des eingeloggten Charakters mit Zeitpunkt und Umständen.
--
-- Kill-Eintrag: { time, kind = "pve"|"pvp", name, classification, level, zone }
-- Tod-Eintrag:  { time, level, zone, killer, spell, environment }
--   killer/spell: Verursacher und Zauber des letzten Treffers, environment: Umgebungsschaden
--   (z.B. "FALLING"); alle drei nil, wenn die Ursache nicht bekannt ist.
-- Quest-Eintrag: { time, level, zone, questID, name, xp, money }
-- Instanz-Lauf: { time, name, instanceType, seconds, level, xp, counters = { kills, deaths } }
-- Beute:        { time, level, zone, link, name, quality, quantity, source }
-- Beinahe-Tod:  { time, level, zone, lowestPercent, killer, spell, environment }
local _, ns = ...

local Journal = {}
ns.Journal = Journal

Journal.PVE = "pve"
Journal.PVP = "pvp"

Journal.MAX_KILLS = 5000  -- Historie zeigt per Lazy Load alle, gerendert werden nur sichtbare Zeilen
Journal.MAX_DEATHS = 1000
Journal.MAX_QUESTS = 2000
Journal.MAX_INSTANCE_RUNS = 500
Journal.MAX_LOOT = 2000
Journal.MAX_NEAR_DEATHS = 500

-- Neuen Eintrag anhängen und die ältesten über dem Limit verwerfen
local function append(log, entry, limit)
  table.insert(log, entry)
  while #log > limit do
    table.remove(log, 1)
  end
end

local function baseEntry()
  return { time = time(), level = ns.level, zone = GetZoneText and GetZoneText() or nil }
end

-- name darf nil sein (z.B. wenn das Spiel den Namen verbirgt), classification ebenso
function Journal.AddKill(kind, name, classification)
  local entry = baseEntry()
  entry.kind = kind
  entry.name = name
  entry.classification = classification
  append(ns.character.killLog, entry, Journal.MAX_KILLS)
end

-- name darf nil sein, xp und money (Kupfer) ebenfalls
function Journal.AddQuest(questID, name, xp, money)
  local entry = baseEntry()
  entry.questID = questID
  entry.name = name
  entry.xp = xp
  entry.money = money
  append(ns.character.questLog, entry, Journal.MAX_QUESTS)
end

-- lowestPercent = tiefster Lebensstand in Prozent, cause wie bei AddDeath
function Journal.AddNearDeath(lowestPercent, cause)
  local entry = baseEntry()
  entry.lowestPercent = lowestPercent
  entry.killer = cause.killer
  entry.spell = cause.spell
  entry.environment = cause.environment
  append(ns.character.nearDeathLog, entry, Journal.MAX_NEAR_DEATHS)
end

-- item = { link, name, quality, quantity, source }
function Journal.AddLoot(item)
  local entry = baseEntry()
  entry.link = item.link
  entry.name = item.name
  entry.quality = item.quality
  entry.quantity = item.quantity
  entry.source = item.source
  append(ns.character.lootLog, entry, Journal.MAX_LOOT)
end

-- Beendeter Instanz-Lauf (Form siehe Instances.lua); time = Betreten der Instanz
function Journal.AddInstanceRun(run)
  append(ns.character.instanceLog, {
    time = run.startedAt,
    name = run.name,
    instanceType = run.instanceType,
    seconds = run.seconds,
    level = run.level,
    xp = run.xp,
    counters = run.counters,
  }, Journal.MAX_INSTANCE_RUNS)
end

-- cause = { killer, spell, environment }, Felder dürfen fehlen.
-- Gibt den Eintrag zurück, damit eine später bekannte Ursache nachgetragen werden kann.
function Journal.AddDeath(cause)
  local entry = baseEntry()
  Journal.SetDeathCause(entry, cause)
  append(ns.character.deathLog, entry, Journal.MAX_DEATHS)
  return entry
end

function Journal.SetDeathCause(entry, cause)
  entry.killer = cause.killer
  entry.spell = cause.spell
  entry.environment = cause.environment
end
