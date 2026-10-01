-- Journal: einzelne Kills und Tode des eingeloggten Charakters mit Zeitpunkt und Umständen.
--
-- Kill-Eintrag: { time, kind = "pve"|"pvp", name, level, zone }
-- Tod-Eintrag:  { time, level, zone, killer, spell, environment }
--   killer/spell: Verursacher und Zauber des letzten Treffers, environment: Umgebungsschaden
--   (z.B. "FALLING"); alle drei nil, wenn die Ursache nicht bekannt ist.
local _, ns = ...

local Journal = {}
ns.Journal = Journal

Journal.PVE = "pve"
Journal.PVP = "pvp"

Journal.MAX_KILLS = 5000  -- Historie zeigt per Lazy Load alle, gerendert werden nur sichtbare Zeilen
Journal.MAX_DEATHS = 1000

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

-- name darf nil sein (z.B. wenn das Spiel den Namen verbirgt)
function Journal.AddKill(kind, name)
  local entry = baseEntry()
  entry.kind = kind
  entry.name = name
  append(ns.character.killLog, entry, Journal.MAX_KILLS)
end

-- cause = { killer, spell, environment }, Felder dürfen fehlen
function Journal.AddDeath(cause)
  local entry = baseEntry()
  entry.killer = cause.killer
  entry.spell = cause.spell
  entry.environment = cause.environment
  append(ns.character.deathLog, entry, Journal.MAX_DEATHS)
end
