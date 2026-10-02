-- Hinweise beim Leveln, bevor es Zeit kostet; jeder einzeln schaltbar (Standard aus):
--   warnBagsFull  weniger als BAGS_LOW freie Plätze in normalen Taschen (Beute geht verloren)
-- Gewarnt wird einmal, wenn der Zustand eintritt (Einblendung + Chat), und erst wieder, nachdem er
-- vorbei war. Geprüft wird alle CHECK_INTERVAL Sekunden statt auf viele Einzel-Events zu hören.
-- APIs in allen Clients: C_Container.GetContainerNumFreeSlots(bag) -> frei, bagFamily
-- (0 = normale Tasche; Köcher, Munitions- und Berufstaschen zählen nicht).
local _, ns = ...
local L = ns.L

local GearWarnings = {}
ns.GearWarnings = GearWarnings

local CHECK_INTERVAL = 5
local BAGS_LOW = 2              -- freie Plätze, ab denen gewarnt wird
local GENERAL_BAG_FAMILY = 0
local BACKPACK = 0
local DEFAULT_BAG_SLOTS = 4     -- ausgerüstete Taschen, falls der Client die Konstante nicht kennt
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

-- Je Hinweis: Einstellung, Prüfung (true = warnen), Text; active = Zustand bei der letzten Prüfung
local WARNINGS = {
  { setting = "warnBagsFull", message = "WARN_BAGS_FULL",
    isDue = function() return GearWarnings.GetFreeBagSlots() < BAGS_LOW end },
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

local ticker = CreateFrame("Frame")
local sinceCheck = 0
ticker:SetScript("OnUpdate", function(_, elapsed)
  sinceCheck = sinceCheck + elapsed
  if sinceCheck < CHECK_INTERVAL then return end
  sinceCheck = 0
  GearWarnings.Check()
end)

ns.OnLogin(function()
  for _, warning in ipairs(WARNINGS) do
    warning.active = false
  end
end)
