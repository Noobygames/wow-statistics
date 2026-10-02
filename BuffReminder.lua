-- Hinweise auf fehlende Buffs beim Leveln, jeder einzeln schaltbar:
--   remindFood  "Satt" (Well Fed); in WoW Forever 5 % mehr XP aus Kills
--   remindCamp  "Lagervorteile" (Camp-Buff, nur WoW Forever, Spell 1229741)
-- Erinnert wird nur, wenn es sich lohnt: beim Leveln, außerhalb von Kampf und Ruhegebiet, lebendig,
-- und je Buff höchstens alle REPEAT_SECONDS.
-- "Satt" wird über den Namen erkannt, den der Client für Zauber WELL_FED_SPELL_ID in seiner Sprache
-- liefert: Die vielen Essens-Buffs heißen alle so, haben aber verschiedene Spell-IDs.
-- Der Camp-Buff hat eine feste Spell-ID und gibt es nur in WoW Forever (BuffReminder.HasCampSystem);
-- in anderen Clients gibt es weder Hinweis noch Einstellung.
local _, ns = ...
local L = ns.L

local BuffReminder = {}
ns.BuffReminder = BuffReminder

local WELL_FED_SPELL_ID = 19705    -- "Well Fed" (Classic), liefert den übersetzten Buff-Namen
local CAMP_SPELL_ID = 1229741      -- "Lagervorteile" (WoW Forever), im Spiel per /dump ermittelt
local CHECK_INTERVAL = 5           -- Sekunden zwischen zwei Prüfungen
local REPEAT_SECONDS = 300         -- Abstand zwischen zwei Hinweisen je Buff
local MAX_AURAS = 40
local REMINDER_COLOR = { 1, 0.6, 0.2 }

local function spellName(spellID)
  return C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)
end

-- true/false, ob ein Buff mit matches(aura) aktiv ist; nil, wenn der Client Auren verbirgt
local function hasBuff(matches)
  if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then return nil end
  for index = 1, MAX_AURAS do
    local aura = C_UnitAuras.GetAuraDataByIndex("player", index, "HELPFUL")
    if not aura then return false end
    if ns.IsSecret(aura.name) or ns.IsSecret(aura.spellId) then return nil end
    if matches(aura) then return true end
  end
  return false
end

-- true, wenn der Buff fehlt; nil, wenn sich das nicht feststellen lässt
local function missing(matches)
  local active = hasBuff(matches)
  if active == nil then return nil end
  return not active
end

function BuffReminder.IsFoodMissing()
  local name = spellName(WELL_FED_SPELL_ID)
  if not name then return nil end
  return missing(function(aura) return aura.name == name end)
end

function BuffReminder.HasCampSystem()
  return ns.Client.IsForever()
end

function BuffReminder.IsCampMissing()
  if not BuffReminder.HasCampSystem() or not spellName(CAMP_SPELL_ID) then return nil end
  return missing(function(aura) return aura.spellId == CAMP_SPELL_ID end)
end

-- Je Hinweis: Einstellung, Prüfung, Text und Zeitpunkt des letzten Hinweises
local REMINDERS = {
  { setting = "remindFood", isMissing = BuffReminder.IsFoodMissing, message = "REMIND_FOOD" },
  { setting = "remindCamp", isMissing = BuffReminder.IsCampMissing, message = "REMIND_CAMP" },
}

local function worthReminding()
  return ns.Experience.IsLeveling()
    and not UnitAffectingCombat("player")
    and not UnitIsDeadOrGhost("player")
    and not IsResting()
end

local function isDue(reminder)
  return ns.db[reminder.setting]
    and (not reminder.lastShown or GetTime() - reminder.lastShown >= REPEAT_SECONDS)
    and reminder.isMissing()
end

-- Fällige Hinweise als Chatzeilen und gemeinsam in einer Einblendung
function BuffReminder.Check()
  if not ns.db or not worthReminding() then return end
  local messages = {}
  for _, reminder in ipairs(REMINDERS) do
    if isDue(reminder) then
      reminder.lastShown = GetTime()
      table.insert(messages, L[reminder.message])
      ns.Print(L[reminder.message])
    end
  end
  if #messages > 0 then
    ns.Alerts.Show(table.concat(messages, "\n"), REMINDER_COLOR)
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
ns.OnLogin(function()
  for _, reminder in ipairs(REMINDERS) do
    reminder.lastShown = nil
  end
end)
