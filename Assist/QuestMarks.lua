-- Quest-Markierung: ein Symbol links vom Lebensbalken der Namensplakette von Gegnern und NPCs, die zu einer aktiven Quest gehören
-- (Einstellung questMarks im Reiter "Komfort", aus; Größe questMarkScale).
-- Zwei Quellen:
--  1. C_QuestLog.UnitIsRelatedToActiveQuest (in WoW Forever im Spiel geprüft: true für Questmobs, false nach
--     erfülltem Ziel). Bei Zielen vom Typ "Gegenstand" (z.B. "Flatterfliegenstaub: 2/5", Item auf den Mob
--     anwenden) kennt das Spiel keine Beziehung zum Mob und liefert false, auch der Tooltip nennt nichts.
--  2. Deshalb zusätzlich: steht der Name des Gegners in einem unerfüllten Questziel (C_QuestLog.GetQuestObjectives),
--     wird er markiert. Das ist ein Textvergleich und kann daneben liegen (zu kurze Namen werden ignoriert).
-- Werte können in eingeschränkten Situationen geheim sein; dann gibt es keine Markierung durch diese Quelle.
-- Welt-Objekte (Kisten, Hebel) haben keine Einheit und keine Namensplakette und lassen sich so nicht markieren.
local _, ns = ...

local QuestMarks = {}
ns.QuestMarks = QuestMarks

QuestMarks.MIN_SCALE = 0.5  -- Grenzen des Reglers in den Einstellungen
QuestMarks.MAX_SCALE = 2

local ICON = "Interface\\GossipFrame\\AvailableQuestIcon"
local FALLBACK_SIZE = 16  -- ohne erkennbaren Lebensbalken (andere Plakettenaddons)
local GAP = 2               -- Abstand zum Lebensbalken
local MIN_NAME_LENGTH = 4   -- kürzere Namen kämen zu leicht zufällig im Zieltext vor
local REFRESH_SECONDS = 1

local marks = {}  -- [Namensplakette] = Markierungs-Frame
local objectiveTexts = {}      -- Texte der unerfüllten Questziele aller Quests im Log
local objectivesDirty = true  -- QUEST_LOG_UPDATE: vor der nächsten Prüfung neu lesen
local units = {}  -- sichtbare Namensplaketten: [Einheit] = Plakette (beim Entfernen liefert das Spiel sie evtl. nicht mehr)

function QuestMarks.IsAvailable()
  return C_QuestLog ~= nil and C_QuestLog.UnitIsRelatedToActiveQuest ~= nil
    and C_NamePlate ~= nil and C_NamePlate.GetNamePlateForUnit ~= nil
end

-- Nach erfülltem Ziel meldet das Spiel selbst false (im Spiel geprüft)
local function rebuildObjectives()
  objectivesDirty = false
  objectiveTexts = {}
  local log = C_QuestLog
  if not (log.GetNumQuestLogEntries and log.GetQuestIDForLogIndex and log.GetQuestObjectives) then return end
  for index = 1, log.GetNumQuestLogEntries() do
    local questID = log.GetQuestIDForLogIndex(index)
    if not ns.IsSecret(questID) and (questID or 0) > 0 then
      for _, objective in ipairs(log.GetQuestObjectives(questID) or {}) do
        if not objective.finished and type(objective.text) == "string" and not ns.IsSecret(objective.text) then
          table.insert(objectiveTexts, objective.text)
        end
      end
    end
  end
end

local function nameInObjectives(unit)
  if objectivesDirty then rebuildObjectives() end
  if #objectiveTexts == 0 then return false end
  local name = UnitName(unit)
  if ns.IsSecret(name) or type(name) ~= "string" or #name < MIN_NAME_LENGTH then return false end
  for _, text in ipairs(objectiveTexts) do
    if string.find(text, name, 1, true) then return true end
  end
  return false
end

-- Spieler und tote Gegner bekommen keine Markierung (geheime Werte: lieber keine)
local function isUnmarkable(unit)
  local isPlayer = UnitIsPlayer(unit)
  local isDead = UnitIsDead and UnitIsDead(unit)
  if ns.IsSecret(isPlayer) or ns.IsSecret(isDead) then return true end
  return isPlayer or isDead
end

local function isQuestUnit(unit)
  if isUnmarkable(unit) then return false end
  local related = C_QuestLog.UnitIsRelatedToActiveQuest(unit)
  if not ns.IsSecret(related) and related == true then return true end
  return nameInObjectives(unit)
end

function QuestMarks.CurrentScale()
  local scale = ns.db and ns.db.questMarkScale or 1
  return math.max(QuestMarks.MIN_SCALE, math.min(QuestMarks.MAX_SCALE, scale))
end

-- Lebensbalken der Blizzard-Plakette (Retail/Forever: im Container, ältere Clients: direkt am UnitFrame)
local function healthBarOf(plate)
  local unitFrame = plate.UnitFrame
  if not unitFrame then return nil end
  local container = unitFrame.HealthBarsContainer
  return container and container.healthBar or unitFrame.healthBar
end

-- Symbol direkt links vom Lebensbalken, so hoch wie dieser (Größe-Regler skaliert darüber hinaus);
-- ohne Balken über der Plakette. Läuft bei jedem Update, weil sich der Balken ändert (z.B. Ziel größer).
local function layout(mark, plate)
  local bar = healthBarOf(plate)
  local height = bar and bar:GetHeight()
  mark:ClearAllPoints()
  if type(height) == "number" and not ns.IsSecret(height) and height > 0 then
    mark:SetSize(height, height)
    mark:SetPoint("RIGHT", bar, "LEFT", -GAP, 0)
  else
    mark:SetSize(FALLBACK_SIZE, FALLBACK_SIZE)
    mark:SetPoint("BOTTOM", plate, "TOP", 0, GAP)
  end
end

local function markFor(plate)
  if marks[plate] then return marks[plate] end
  local mark = CreateFrame("Frame", nil, plate)
  mark.icon = mark:CreateTexture(nil, "OVERLAY")
  mark.icon:SetAllPoints()
  mark.icon:SetTexture(ICON)
  mark:SetScale(QuestMarks.CurrentScale())
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
    local mark = markFor(plate)
    layout(mark, plate)
    mark:Show()
  elseif marks[plate] then
    marks[plate]:Hide()
  end
end

local function refreshAll()
  if not (ns.db and ns.db.questMarks) or not QuestMarks.IsAvailable() then return end
  for unit in pairs(units) do update(unit) end
end

ns.RegisterEvent("NAME_PLATE_UNIT_ADDED", function(unit)
  if not unit or not QuestMarks.IsAvailable() then return end
  units[unit] = plateOf(unit)
  update(unit)
end)

ns.RegisterEvent("QUEST_LOG_UPDATE", function() objectivesDirty = true end)

ns.RegisterEvent("NAME_PLATE_UNIT_REMOVED", function(unit)
  if not unit then return end
  local plate = units[unit]
  units[unit] = nil
  if plate and marks[plate] then marks[plate]:Hide() end
end)

-- Questziele ändern sich beim Spielen (Ziel erfüllt, Quest abgegeben): regelmäßig nachsehen
ns.Every(REFRESH_SECONDS, refreshAll)

ns.RegisterApply(function(db)
  for _, mark in pairs(marks) do mark:SetScale(QuestMarks.CurrentScale()) end
  for _, mark in pairs(marks) do if not db.questMarks then mark:Hide() end end
  refreshAll()
end)
