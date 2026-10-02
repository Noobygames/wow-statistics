-- Split-Liste wie bei LiveSplit: eigene kleine Anzeige mit dem laufenden Level und den zuletzt
-- abgeschlossenen Leveln (Level, Zeit, Abweichung zum Vergleich aus Splits.lua), darunter die Summe.
-- Einstellungen: showSplitList (an/aus, /lt splits), splitListRows (Zahl der Level), Position splitListPos.
-- Größe, Hintergrund und Fixieren folgen dem Hauptfenster.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Format = ns.Format
local Stats = ns.Stats
local Splits = ns.Splits
local TimerWindow = ns.TimerWindow

local SplitList = {
  MIN_ROWS = 3,
  MAX_ROWS = 15,
}
ns.SplitList = SplitList

local UPDATE_INTERVAL = 0.5
local PADDING_X = 12
local PADDING_Y = 8
local ROW_HEIGHT = 14
local COLUMN_GAP = 12
local MIN_WIDTH = 140
local DEFAULT_POSITION = { "TOPLEFT", "TOPLEFT", 20, -200 }

local panel = Widgets.CreatePanel("LevelTimerSplits", 0.8)
panel:Hide()

local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
title:SetPoint("TOPLEFT", PADDING_X, -PADDING_Y)

-- Zeilen: Level links, Zeit und Abweichung rechtsbündig in eigenen Spalten
local rows = {}

local function getRow(index)
  if rows[index] then return rows[index] end
  local function cell(font) return panel:CreateFontString(nil, "OVERLAY", font) end
  rows[index] = {
    level = cell("GameFontNormalSmall"),
    time = cell("GameFontHighlightSmall"),
    delta = cell("GameFontHighlightSmall"),
  }
  return rows[index]
end

---------------------------------------------------------------------------
-- Inhalt
---------------------------------------------------------------------------

-- { level, seconds, delta } für das laufende Level und die zuletzt abgeschlossenen, neueste zuerst
function SplitList.BuildLines()
  local lines = {
    { level = ns.level, seconds = Stats.GetSeconds(Stats.LEVEL), delta = Splits.GetCurrentDelta() },
  }
  local level = ns.level - 1
  while #lines < ns.db.splitListRows and level >= 1 do
    local record = ns.character.levelHistory[level]
    if record then
      table.insert(lines, { level = level, seconds = record.seconds, delta = Splits.GetLevelDelta(level) })
    end
    level = level - 1
  end
  return lines
end

local function setCells(row, levelText, timeText, deltaText)
  row.level:SetText(levelText)
  row.time:SetText(timeText)
  row.delta:SetText(deltaText)
  for _, fontString in pairs(row) do fontString:Show() end
end

-- Spalten so breit wie ihr breitester Text, Fenster entsprechend
local function layout(count)
  local levelWidth, timeWidth, deltaWidth = 0, 0, 0
  for i = 1, count do
    levelWidth = math.max(levelWidth, rows[i].level:GetStringWidth())
    timeWidth = math.max(timeWidth, rows[i].time:GetStringWidth())
    deltaWidth = math.max(deltaWidth, rows[i].delta:GetStringWidth())
  end
  local timeRight = PADDING_X + levelWidth + COLUMN_GAP + timeWidth
  for i = 1, count do
    local y = -PADDING_Y - i * ROW_HEIGHT
    local row = rows[i]
    row.level:ClearAllPoints()
    row.level:SetPoint("TOPLEFT", PADDING_X, y)
    row.time:ClearAllPoints()
    row.time:SetPoint("TOPRIGHT", panel, "TOPLEFT", timeRight, y)
    row.delta:ClearAllPoints()
    row.delta:SetPoint("TOPRIGHT", -PADDING_X, y)
  end
  local width = timeRight + COLUMN_GAP + deltaWidth + PADDING_X
  panel:SetSize(math.max(MIN_WIDTH, width, title:GetStringWidth() + 2 * PADDING_X),
    2 * PADDING_Y + (count + 1) * ROW_HEIGHT)
end

local function render()
  title:SetText(L.SPLIT_LIST_TITLE)
  local lines = SplitList.BuildLines()
  for i, line in ipairs(lines) do
    setCells(getRow(i), tostring(line.level),
      line.seconds and Format.Duration(line.seconds) or "...", Format.SplitDelta(line.delta))
  end
  local totalRow = getRow(#lines + 1)
  setCells(totalRow, L.SPLIT_LIST_TOTAL, "", Format.SplitDelta(Splits.GetTotalDelta()))
  for i = #lines + 2, #rows do
    for _, fontString in pairs(rows[i]) do fontString:Hide() end
  end
  layout(#lines + 1)
end

---------------------------------------------------------------------------
-- Position, Ablauf
---------------------------------------------------------------------------
panel:SetScript("OnDragStart", function(self)
  if not ns.db.locked then self:StartMoving() end
end)
panel:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  local point, _, relativePoint, x, y = self:GetPoint()
  ns.db.splitListPos = { point, relativePoint, x, y }
end)
panel:SetScript("OnMouseUp", function(_, mouseButton)
  if mouseButton == "RightButton" then ns.ToggleOptions() end
end)

local sinceUpdate = 0
panel:SetScript("OnUpdate", function(_, elapsed)
  sinceUpdate = sinceUpdate + elapsed
  if sinceUpdate < UPDATE_INTERVAL then return end
  sinceUpdate = 0
  render()
end)

-- Abstände gelten in der Skalierung der Anzeige, daher vor dem Positionieren skalieren
local function restorePosition(db)
  local pos = db.splitListPos or DEFAULT_POSITION
  panel:SetScale(db.scale)
  panel:ClearAllPoints()
  panel:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
end

ns.RegisterApply(function(db)
  restorePosition(db)
  TimerWindow.ApplyBackground(panel, db)
  panel:SetShown(db.showSplitList)
  if db.showSplitList then render() end
end)
