-- Quest-Markierung: ein Symbol über der Namensplakette von Gegnern und NPCs, die zu einer aktiven Quest gehören
-- (Einstellung questMarks im Reiter "Komfort", aus; Größe questMarkScale).
-- Quelle ist C_QuestLog.UnitIsRelatedToActiveQuest (in WoW Forever im Spiel geprüft: true für Questmobs).
-- Der Tooltip der Einheit (C_TooltipInfo.GetUnit) verfeinert das: stehen dort Questziele und sind alle erfüllt,
-- entfällt die Markierung. Alle Werte können in eingeschränkten Situationen geheim sein; dann gilt "unbekannt"
-- und die Quest-Beziehung entscheidet allein. Welt-Objekte (Kisten, Hebel) haben keine Einheit und keine
-- Namensplakette und lassen sich so nicht markieren.
local _, ns = ...

local QuestMarks = {}
ns.QuestMarks = QuestMarks

QuestMarks.MIN_SCALE = 0.5  -- Grenzen des Reglers in den Einstellungen
QuestMarks.MAX_SCALE = 2

local ICON = "Interface\\GossipFrame\\AvailableQuestIcon"
local BASE_SIZE = 28
local OFFSET_Y = 2
local REFRESH_SECONDS = 1
local QUEST_OBJECTIVE_LINE = Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.QuestObjective or 8

local marks = {}  -- [Namensplakette] = Markierungs-Frame
local units = {}  -- sichtbare Namensplaketten: [Einheit] = true

function QuestMarks.IsAvailable()
  return C_QuestLog ~= nil and C_QuestLog.UnitIsRelatedToActiveQuest ~= nil
    and C_NamePlate ~= nil and C_NamePlate.GetNamePlateForUnit ~= nil
end

-- true, wenn der Tooltip Questziele nennt und alle erfüllt sind; false bei offenen oder unlesbaren Zielen
local function objectivesDone(unit)
  if not C_TooltipInfo or not C_TooltipInfo.GetUnit then return false end
  local ok, data = pcall(C_TooltipInfo.GetUnit, unit)
  if not ok or ns.IsSecret(data) or type(data) ~= "table" or type(data.lines) ~= "table" then return false end
  local found = false
  for _, line in ipairs(data.lines) do
    if ns.IsSecret(line.type) then return false end
    if line.type == QUEST_OBJECTIVE_LINE then
      if ns.IsSecret(line.completed) or not line.completed then return false end
      found = true
    end
  end
  return found
end

local function isQuestUnit(unit)
  local related = C_QuestLog.UnitIsRelatedToActiveQuest(unit)
  if ns.IsSecret(related) or not related then return false end
  return not objectivesDone(unit)
end

local function markFor(plate)
  if marks[plate] then return marks[plate] end
  local mark = CreateFrame("Frame", nil, plate)
  mark:SetSize(BASE_SIZE, BASE_SIZE)
  mark:SetPoint("BOTTOM", plate, "TOP", 0, OFFSET_Y)
  mark.icon = mark:CreateTexture(nil, "OVERLAY")
  mark.icon:SetAllPoints()
  mark.icon:SetTexture(ICON)
  mark:SetScale(ns.db and ns.db.questMarkScale or 1)
  marks[plate] = mark
  return mark
end

local function plateOf(unit)
  local plate = C_NamePlate.GetNamePlateForUnit(unit)
  if not plate or (plate.IsForbidden and plate:IsForbidden()) then return nil end
  return plate
end

local function update(unit)
  local plate = plateOf(unit)
  if not plate then return end
  local show = ns.db and ns.db.questMarks and isQuestUnit(unit)
  if show then
    markFor(plate):Show()
  elseif marks[plate] then
    marks[plate]:Hide()
  end
end

local function refreshAll()
  if not QuestMarks.IsAvailable() then return end
  for unit in pairs(units) do update(unit) end
end

ns.RegisterEvent("NAME_PLATE_UNIT_ADDED", function(unit)
  if not unit or not QuestMarks.IsAvailable() then return end
  units[unit] = true
  update(unit)
end)

ns.RegisterEvent("NAME_PLATE_UNIT_REMOVED", function(unit)
  if not unit then return end
  units[unit] = nil
  if QuestMarks.IsAvailable() then
    local plate = plateOf(unit)
    if plate and marks[plate] then marks[plate]:Hide() end
  end
end)

-- Questziele ändern sich beim Spielen (Ziel erfüllt, Quest abgegeben): regelmäßig nachsehen
ns.Every(REFRESH_SECONDS, refreshAll)

ns.RegisterApply(function(db)
  local scale = math.max(QuestMarks.MIN_SCALE, math.min(QuestMarks.MAX_SCALE, db.questMarkScale))
  for _, mark in pairs(marks) do mark:SetScale(scale) end
  refreshAll()
end)
