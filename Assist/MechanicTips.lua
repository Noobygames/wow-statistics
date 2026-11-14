-- Boss- und Trash-Mechaniken im Einheiten-Tooltip (LT-10/LT-11, Einstellung tooltipMechanics im Reiter "Komfort",
-- Standard an; nur mit ns.Mechanics, also Classic Era und Forever): Gegner, deren NPC-ID in den Guide-Daten
-- (Assist/InstanceData/mechanics.lua) steht, bekommen bis zu MAX_LINES Zeilen "Symbol Typ: Text". Typ in eigener Farbe,
-- Symbol = Zaubersymbol (Widgets.SpellTexture), ohne Zauber-ID das Fragezeichen. Gilt überall, wo der NPC auftaucht
-- (reine Tabellen-Abfrage per NPC-ID). Angehängt von Assist/Tooltip.lua.
-- NPC-ID aus UnitGUID; ist die GUID geheim (Forever in Instanzen möglich), fehlen die Zeilen (Debug-Check
-- LT10.mechanics.mouseover).
-- Text: deDE-Clients den deutschen, alle anderen den englischen (frFR/esES haben keine eigenen Guide-Texte).
local _, ns = ...
local L = ns.L

ns.RegisterDefaults({
  settings = {
    tooltipMechanics = true,
  },
})

local MechanicTips = {}
ns.MechanicTips = MechanicTips

MechanicTips.MAX_LINES = 3
local SPELL_ID, KIND, TEXT_DE, TEXT_EN = 1, 2, 3, 4
local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local TEXT_COLOR = { 0.9, 0.9, 0.9 }

-- Farbe je Typ (Typen wie in tools/mechanics)
MechanicTips.COLORS = {
  avoid = { 1, 0.5, 0.1 },
  interrupt = { 0.35, 0.75, 1 },
  dispel = { 0.75, 0.5, 1 },
  tank = { 0.8, 0.65, 0.45 },
  survive = { 1, 0.3, 0.3 },
  adds = { 1, 0.85, 0.2 },
  positioning = { 0.4, 1, 0.4 },
}

function MechanicTips.IsAvailable()
  return ns.Mechanics ~= nil
end

-- Mechaniken einer NPC-ID (nicht verändern), nil ohne Eintrag
function MechanicTips.ForNpc(npcID)
  return ns.Mechanics and npcID and ns.Mechanics[npcID]
end

function MechanicTips.NpcOf(unit)
  return ns.QuestBlocklist.NpcId(UnitGUID(unit))
end

-- Tooltip-Text einer Mechanik: "|T...|t Typ: Text", Typ farbig
function MechanicTips.LineText(mechanic)
  local color = MechanicTips.COLORS[mechanic[KIND]] or TEXT_COLOR
  local icon = mechanic[SPELL_ID] > 0 and ns.Widgets.SpellTexture(mechanic[SPELL_ID]) or FALLBACK_ICON
  local text = GetLocale() == "deDE" and mechanic[TEXT_DE] or mechanic[TEXT_EN]
  return string.format("|T%s:0|t |cff%02x%02x%02x%s:|r %s", icon, math.floor(color[1] * 255),
    math.floor(color[2] * 255), math.floor(color[3] * 255), L["MECHANIC_" .. mechanic[KIND]:upper()], text)
end

function MechanicTips.AddUnitLines(tooltip, unit)
  local npcID = MechanicTips.NpcOf(unit)
  local mechanics = MechanicTips.ForNpc(npcID)
  ns.Debug("mechanics", "unit tooltip npc %s: %s lines", npcID, mechanics and #mechanics or 0)
  if not mechanics then return end
  for index = 1, math.min(#mechanics, MechanicTips.MAX_LINES) do
    tooltip:AddLine(MechanicTips.LineText(mechanics[index]), TEXT_COLOR[1], TEXT_COLOR[2], TEXT_COLOR[3], true)
  end
end
