-- Beinahe-Tode: Das Leben fällt unter LOW_HEALTH, man stirbt aber nicht. Gezählt wird, sobald das Leben
-- wieder über RECOVERED_HEALTH steigt (Abstand verhindert Mehrfachzählung bei schwankendem Leben).
-- Stirbt man vorher, ist es ein Tod und kein Beinahe-Tod.
local _, ns = ...
local Stats = ns.Stats
local Journal = ns.Journal
local DeathCounter = ns.DeathCounter

local LOW_HEALTH = 0.10
local RECOVERED_HEALTH = 0.30

local episode  -- { lowest, cause } solange das Leben kritisch ist

local NearDeath = {}
ns.NearDeath = NearDeath

-- In Retail und WoW Forever liefert UnitHealth laut generierter Doku immer geheime Werte
-- (SecretReturns = true, ohne Bedingung); Beinahe-Tode lassen sich dort nicht erkennen, Zeile,
-- Schalter und Einblendung entfallen. Classic Era und TBC kennen das nicht.
function NearDeath.IsAvailable()
  return not (ns.Client.IsRetail() or ns.Client.IsForever())
end

-- Anteil des Lebens oder nil, wenn der Client den Wert verbirgt
local function healthFraction()
  local health, maxHealth = UnitHealth("player"), UnitHealthMax("player")
  if ns.IsSecret(health) or ns.IsSecret(maxHealth) or not maxHealth or maxHealth == 0 then return nil end
  return health / maxHealth
end

local function onHealthChanged(unit)
  if unit ~= "player" then return end
  if UnitIsDeadOrGhost("player") then
    episode = nil
    return
  end
  local fraction = healthFraction()
  if not fraction then return end

  if not episode then
    if fraction <= LOW_HEALTH then
      episode = { lowest = fraction, cause = DeathCounter.PeekLastHit() }
    end
    return
  end

  episode.lowest = math.min(episode.lowest, fraction)
  if fraction >= RECOVERED_HEALTH then
    Stats.Increment(Stats.NEAR_DEATHS)
    Journal.AddNearDeath(math.floor(episode.lowest * 100 + 0.5), episode.cause)
    episode = nil
  end
end

ns.RegisterEvent("UNIT_HEALTH", onHealthChanged)
ns.RegisterEvent("UNIT_HEALTH_FREQUENT", onHealthChanged)  -- ältere Clients melden Änderungen hierüber
ns.RegisterEvent("PLAYER_DEAD", function() episode = nil end)
