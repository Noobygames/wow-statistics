-- Hinweise beim Leveln, bevor es Zeit kostet; jeder einzeln schaltbar (Standard aus):
--   warnBagsFull   weniger als BAGS_LOW freie Plätze in normalen Taschen (Beute geht verloren)
--   warnDurability ein ausgerüsteter Gegenstand unter DURABILITY_LOW Haltbarkeit
--   warnAmmo       Jäger mit weniger als AMMO_LOW Schuss im Munitionsplatz (nicht in Retail,
--                  dort gibt es keine Munition; GearWarnings.HasAmmo)
-- Gewarnt wird einmal, wenn der Zustand eintritt (Einblendung + Chat), und erst wieder, nachdem er
-- vorbei war. Geprüft wird alle CHECK_INTERVAL Sekunden statt auf viele Einzel-Events zu hören.
-- Freie Plätze: Bags.GetFreeSlots (nur normale Taschen; Köcher und Berufstaschen zählen nicht).
-- APIs in allen Clients: GetInventoryItemDurability(slot) -> aktuell, max (nil bei Gegenständen ohne Haltbarkeit),
-- GetInventoryItemCount("player", INVSLOT_AMMO) wie Blizzards Munitionsplatz im Charakterfenster.
local _, ns = ...
local L = ns.L

local GearWarnings = {}
ns.GearWarnings = GearWarnings

local CHECK_INTERVAL = 5
local BAGS_LOW = 2              -- freie Plätze, ab denen gewarnt wird
local DURABILITY_LOW = 0.2      -- Anteil der Haltbarkeit, ab dem gewarnt wird
local FIRST_EQUIPPED_SLOT = 1
local DEFAULT_LAST_EQUIPPED_SLOT = 19
local AMMO_LOW = 200            -- Schuss, ab denen gewarnt wird
local AMMO_SLOT = INVSLOT_AMMO or 0
local HUNTER = "HUNTER"

-- Niedrigste Haltbarkeit aller ausgerüsteten Gegenstände (0..1); 1 ohne Gegenstände mit Haltbarkeit
function GearWarnings.GetLowestDurability()
  local lowest = 1
  for slot = FIRST_EQUIPPED_SLOT, INVSLOT_LAST_EQUIPPED or DEFAULT_LAST_EQUIPPED_SLOT do
    local current, maximum = GetInventoryItemDurability(slot)
    if current and maximum and maximum > 0 then
      lowest = math.min(lowest, current / maximum)
    end
  end
  return lowest
end

function GearWarnings.HasAmmo()
  return not ns.Client.IsRetail()
end

-- WoW Forever sagt selbst, ob der Charakter Munition nutzt (UnitUsesAmmo, wie Blizzards Munitionsplatz
-- im Charakterfenster); sonst alle Jäger
local function usesAmmo()
  if UnitUsesAmmo then return UnitUsesAmmo("player") end
  return select(2, UnitClass("player")) == HUNTER
end

local function isAmmoLow()
  if not GearWarnings.HasAmmo() or not usesAmmo() then return false end
  return GetInventoryItemCount("player", AMMO_SLOT) < AMMO_LOW
end

-- Je Hinweis: Einstellung, Prüfung (true = warnen), Text; active = Zustand bei der letzten Prüfung
local WARNINGS = {
  { setting = "warnBagsFull", message = "WARN_BAGS_FULL",
    isDue = function() return ns.Bags.GetFreeSlots() < BAGS_LOW end },
  { setting = "warnDurability", message = "WARN_DURABILITY",
    isDue = function() return GearWarnings.GetLowestDurability() < DURABILITY_LOW end },
  { setting = "warnAmmo", message = "WARN_AMMO", isDue = isAmmoLow },
}

function GearWarnings.Check()
  if not ns.db then return end
  for _, warning in ipairs(WARNINGS) do
    local due = ns.db[warning.setting] and warning.isDue() or false
    if due and not warning.active then
      ns.Debug("warnings", "%s", warning.setting)
      ns.Alerts.Notify(L[warning.message], ns.Alerts.WARNING_COLOR)
    end
    warning.active = due
  end
end

ns.Every(CHECK_INTERVAL, GearWarnings.Check)

ns.OnLogin(function()
  for _, warning in ipairs(WARNINGS) do
    warning.active = false
  end
end)
