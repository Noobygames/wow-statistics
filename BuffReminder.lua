-- Hinweis auf fehlende Buffs beim Leveln (Einstellung remindFood). In WoW Forever gibt "Satt"
-- (Well Fed) 5 % mehr XP aus Kills. Erinnert wird nur, wenn es sich lohnt: beim Leveln, außerhalb
-- von Kampf und Ruhegebiet, lebendig, und höchstens alle REPEAT_SECONDS.
-- Erkennung über den Namen, den der Client für den Zauber "Satt" (WELL_FED_SPELL_ID) in seiner
-- Sprache liefert; die vielen Essens-Buffs heißen alle so, haben aber verschiedene Spell-IDs.
local _, ns = ...
local L = ns.L

local BuffReminder = {}
ns.BuffReminder = BuffReminder

local WELL_FED_SPELL_ID = 19705  -- "Well Fed" (Classic), liefert den übersetzten Buff-Namen
local CHECK_INTERVAL = 5         -- Sekunden zwischen zwei Prüfungen
local REPEAT_SECONDS = 300       -- Abstand zwischen zwei Hinweisen
local MAX_AURAS = 40
local REMINDER_COLOR = { 1, 0.6, 0.2 }

local function wellFedName()
  return C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(WELL_FED_SPELL_ID)
end

-- true/false, ob ein Buff mit diesem Namen aktiv ist; nil, wenn der Client Auren verbirgt
local function hasBuffNamed(name)
  if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then return nil end
  for index = 1, MAX_AURAS do
    local aura = C_UnitAuras.GetAuraDataByIndex("player", index, "HELPFUL")
    if not aura then return false end
    if ns.IsSecret(aura.name) then return nil end
    if aura.name == name then return true end
  end
  return false
end

-- true, wenn "Satt" fehlt; nil, wenn sich das nicht feststellen lässt
function BuffReminder.IsFoodMissing()
  local name = wellFedName()
  if not name then return nil end
  local active = hasBuffNamed(name)
  if active == nil then return nil end
  return not active
end

local function worthReminding()
  return ns.Experience.IsLeveling()
    and not UnitAffectingCombat("player")
    and not UnitIsDeadOrGhost("player")
    and not IsResting()
end

local lastReminder  -- GetTime() des letzten Hinweises

function BuffReminder.Check()
  if not ns.db or not ns.db.remindFood or not worthReminding() then return end
  if lastReminder and GetTime() - lastReminder < REPEAT_SECONDS then return end
  if BuffReminder.IsFoodMissing() then
    lastReminder = GetTime()
    ns.Alerts.Show(L.REMIND_FOOD, REMINDER_COLOR)
    ns.Print(L.REMIND_FOOD)
  end
end

-- Regelmäßig prüfen statt auf UNIT_AURA zu hören: Ablauf, Kampfende und Ruhegebiet ändern sich
-- auch ohne Aura-Event, und die Prüfung ist billig
local ticker = CreateFrame("Frame")
local sinceCheck = 0
ticker:SetScript("OnUpdate", function(_, elapsed)
  sinceCheck = sinceCheck + elapsed
  if sinceCheck < CHECK_INTERVAL then return end
  sinceCheck = 0
  BuffReminder.Check()
end)

-- Neuer Login: sofort erinnern dürfen
ns.OnLogin(function() lastReminder = nil end)
