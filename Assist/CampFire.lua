-- Lagerfeuer in WoW Forever (nur dort; Spell-IDs im Spiel per Aura-Liste ermittelt):
--   1283391 "Lagerfeuer in der Nähe"   ohne Dauer, solange man bei einem Feuer steht
--   1229739 "Einladendes Lagerfeuer"   60 s, beginnt beim Sitzen am Feuer; danach kommen
--   1229741 "Lagervorteile"            1 h (wird bei jedem Durchlauf erneuert)
-- Zwei Anzeigen (UI/CampDisplay.lua), je einzeln schaltbar:
--   campCountdown  Countdown mit der Restzeit des einladenden Lagerfeuers, danach kurz "Lagervorteile aktiv"
--   campHint       Hinweis, wenn ein Feuer in der Nähe ist und die Lagervorteile fehlen: hinsetzen
-- Geprüft wird alle CHECK_INTERVAL Sekunden; bei gesperrten Auren (Kampf, Bosskampf) passiert nichts.
local _, ns = ...
local Auras = ns.Auras

local CampFire = {}
ns.CampFire = CampFire

CampFire.NEARBY_SPELL_ID = 1283391
CampFire.INVITING_SPELL_ID = 1229739
CampFire.BENEFITS_SPELL_ID = 1229741
local CHECK_INTERVAL = 0.5

function CampFire.IsAvailable()
  return ns.Client.IsForever()
end

-- Zustand aus den Buffs: nil oder
--   { kind = "countdown", remaining, duration, spellId }  einladendes Lagerfeuer läuft
--   { kind = "hint", spellId }                            Feuer in der Nähe, keine Lagervorteile
-- Zweiter Rückgabewert: der Buff "Lagervorteile" (oder nil)
function CampFire.GetState()
  if not CampFire.IsAvailable() or UnitIsDeadOrGhost("player") then return nil end
  local found = Auras.FindBySpellIds({ CampFire.NEARBY_SPELL_ID, CampFire.INVITING_SPELL_ID, CampFire.BENEFITS_SPELL_ID })
  if not found then return nil end
  local benefits = found[CampFire.BENEFITS_SPELL_ID]
  local inviting = found[CampFire.INVITING_SPELL_ID]
  if inviting then
    local remaining, duration = Auras.RemainingSeconds(inviting)
    if remaining then
      return { kind = "countdown", remaining = remaining, duration = duration, spellId = CampFire.INVITING_SPELL_ID }, benefits
    end
  end
  if found[CampFire.NEARBY_SPELL_ID] and not benefits then
    return { kind = "hint", spellId = CampFire.NEARBY_SPELL_ID }, nil
  end
  return nil, benefits
end

-- Ablaufzeit der Lagervorteile; nur zum Erkennen, ob ein Durchlauf sie erneuert hat
local function benefitsExpiration(benefits)
  local expiration = benefits and benefits.expirationTime
  if ns.IsSecret(expiration) or type(expiration) ~= "number" then return nil end
  return expiration
end

local GRANT_WINDOW = 3      -- Sekunden nach dem Ende des Countdowns, in denen die Lagervorteile eintreffen dürfen
local previousKind          -- Art des letzten Zustands
local NO_BENEFITS, UNKNOWN_EXPIRATION = false, "unknown"
local benefitsAtStart = NO_BENEFITS  -- Lagervorteile beim Start des Countdowns: keine, Ablaufzeit oder unbekannt
local countdownEndedAt      -- GetTime(), seit der Countdown nicht mehr läuft, bis das Ergebnis feststeht

-- Hat der Countdown die Lagervorteile gebracht? Sie sind neu oder wurden erneuert (spätere Ablaufzeit).
-- Wer vorher aufsteht, hat sie nicht bekommen.
local function benefitsGranted(benefits)
  if not benefits then return false end
  if benefitsAtStart == NO_BENEFITS then return true end
  if benefitsAtStart == UNKNOWN_EXPIRATION then return false end  -- nicht feststellbar: lieber keine Meldung
  local expiration = benefitsExpiration(benefits)
  return expiration ~= nil and expiration > benefitsAtStart + 1
end

function CampFire.Check()
  if not ns.db then return end
  local state, benefits = CampFire.GetState()
  local kind = state and state.kind or nil

  if kind == "countdown" and previousKind ~= "countdown" then
    benefitsAtStart = not benefits and NO_BENEFITS or benefitsExpiration(benefits) or UNKNOWN_EXPIRATION
    countdownEndedAt = nil
  elseif kind ~= "countdown" and previousKind == "countdown" then
    countdownEndedAt = GetTime()
  end
  previousKind = kind

  local finished = false
  if countdownEndedAt then
    if benefitsGranted(benefits) then
      finished, countdownEndedAt = true, nil
    elseif GetTime() - countdownEndedAt > GRANT_WINDOW then
      countdownEndedAt = nil  -- aufgestanden, bevor es fertig war
    end
  end

  if kind == "countdown" and not ns.db.campCountdown then state = nil end
  if kind == "hint" and not ns.db.campHint then state = nil end
  ns.CampDisplay.Show(state)
  if finished and ns.db.campCountdown then
    ns.Debug("camp", "campfire benefits granted")
    ns.CampDisplay.ShowDone()
  end
end

-- Regelmäßig prüfen statt auf UNIT_AURA zu hören: der Countdown läuft in der Anzeige selbst weiter,
-- und die Prüfung ist billig
if CampFire.IsAvailable() then
  ns.Every(CHECK_INTERVAL, CampFire.Check)
end

ns.OnLogin(function()
  previousKind, benefitsAtStart, countdownEndedAt = nil, NO_BENEFITS, nil
end)
