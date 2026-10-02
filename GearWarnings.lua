-- Hinweise beim Leveln, bevor es Zeit kostet; jeder einzeln schaltbar (Standard aus):
--   warnBagsFull   weniger als BAGS_LOW freie Plätze in normalen Taschen (Beute geht verloren)
--   warnDurability ein ausgerüsteter Gegenstand unter DURABILITY_LOW Haltbarkeit
--   warnAmmo       Jäger mit weniger als AMMO_LOW Schuss im Munitionsplatz (nicht in Retail,
--                  dort gibt es keine Munition; GearWarnings.HasAmmo)
-- Gewarnt wird einmal, wenn der Zustand eintritt (Einblendung + Chat), und erst wieder, nachdem er
-- vorbei war. Geprüft wird alle CHECK_INTERVAL Sekunden statt auf viele Einzel-Events zu hören.
-- APIs in allen Clients: C_Container.GetContainerNumFreeSlots(bag) -> frei, bagFamily
-- (0 = normale Tasche; Köcher, Munitions- und Berufstaschen zählen nicht),
-- GetInventoryItemDurability(slot) -> aktuell, max (nil bei Gegenständen ohne Haltbarkeit),
-- GetInventoryItemCount("player", INVSLOT_AMMO) wie Blizzards Munitionsplatz im Charakterfenster.
local _, ns = ...
local L = ns.L

local GearWarnings = {}
ns.GearWarnings = GearWarnings

local CHECK_INTERVAL = 5
local BAGS_LOW = 2              -- freie Plätze, ab denen gewarnt wird
local GENERAL_BAG_FAMILY = 0
local BACKPACK = 0
local DEFAULT_BAG_SLOTS = 4     -- ausgerüstete Taschen, falls der Client die Konstante nicht kennt
local DURABILITY_LOW = 0.2      -- Anteil der Haltbarkeit, ab dem gewarnt wird
local FIRST_EQUIPPED_SLOT = 1
local DEFAULT_LAST_EQUIPPED_SLOT = 19
local AMMO_LOW = 200            -- Schuss, ab denen gewarnt wird
local AMMO_SLOT = INVSLOT_AMMO or 0
local HUNTER = "HUNTER"
local WARNING_COLOR = { 1, 0.6, 0.2 }

local function lastBag()
  return NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or DEFAULT_BAG_SLOTS
end

-- Freie Plätze in normalen Taschen
function GearWarnings.GetFreeBagSlots()
  local free = 0
  for bag = BACKPACK, lastBag() do
    local slots, family = C_Container.GetContainerNumFreeSlots(bag)
    if family == GENERAL_BAG_FAMILY then free = free + (slots or 0) end
  end
  return free
end

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

local function isAmmoLow()
  if not GearWarnings.HasAmmo() or select(2, UnitClass("player")) ~= HUNTER then return false end
  return GetInventoryItemCount("player", AMMO_SLOT) < AMMO_LOW
end

-- Je Hinweis: Einstellung, Prüfung (true = warnen), Text; active = Zustand bei der letzten Prüfung
local WARNINGS = {
  { setting = "warnBagsFull", message = "WARN_BAGS_FULL",
    isDue = function() return GearWarnings.GetFreeBagSlots() < BAGS_LOW end },
  { setting = "warnDurability", message = "WARN_DURABILITY",
    isDue = function() return GearWarnings.GetLowestDurability() < DURABILITY_LOW end },
  { setting = "warnAmmo", message = "WARN_AMMO", isDue = isAmmoLow },
}

local function warn(message)
  ns.Print(message)
  ns.Alerts.Show(message, WARNING_COLOR)
end

function GearWarnings.Check()
  if not ns.db then return end
  for _, warning in ipairs(WARNINGS) do
    local due = ns.db[warning.setting] and warning.isDue() or false
    if due and not warning.active then
      ns.Debug("warnings", "%s", warning.setting)
      warn(L[warning.message])
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
