-- Anzeigefenster: Reiter "Level | Session", Spielzeit im gewählten Bereich und darunter
-- eine Tabelle der eingeschalteten Stats (Bezeichnung links, Wert rechts).
-- Größe: Ziehgriff unten rechts (erscheint bei Mauskontakt) oder Einstellung "scale" skaliert das ganze Fenster.
-- Rechtsklick öffnet die Einstellungen.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Format = ns.Format
local Stats = ns.Stats

local TimerWindow = {
  MIN_SCALE = 0.5,
  MAX_SCALE = 2,
}
ns.TimerWindow = TimerWindow

local UPDATE_INTERVAL = 0.25          -- Sekunden zwischen zwei Anzeige-Updates
local PADDING_X = 20
local PADDING_Y = 8
local LINE_GAP = 3
local TAB_GAP = 10                    -- Abstand zwischen den Reitern
local MIN_WIDTH = 160
local GRIP_SIZE = 14
local COLUMN_GAP = 16                 -- Mindestabstand zwischen Bezeichnung und Wert
local TABLE_GAP = 4                   -- Abstand zwischen Zeitanzeige und Tabelle
local WIDEST_TIME = "00d 00h 00m 00s" -- für die Fensterbreite
local DEFAULT_POSITION = { "TOP", "TOP", 0, -120 }
local DEFAULT_SCALE = 1

local window = Widgets.CreatePanel("LevelTimerFrame", 0.8)
window:Hide()  -- erst nach Login anzeigen, wenn Daten und Einstellungen bereitstehen

-- Reiter wählen den Bereich (Einstellung windowScope)
local levelTab = Widgets.CreateTab(window, "GameFontNormalSmall", function()
  ns.Set("windowScope", Stats.LEVEL)
end)
levelTab:SetPoint("TOPRIGHT", window, "TOP", -TAB_GAP / 2, -PADDING_Y)

local sessionTab = Widgets.CreateTab(window, "GameFontNormalSmall", function()
  ns.Set("windowScope", Stats.SESSION)
end)
sessionTab:SetPoint("TOPLEFT", window, "TOP", TAB_GAP / 2, -PADDING_Y)

local timeText = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
timeText:SetTextColor(unpack(Widgets.COLORS.highlight))

-- Tabellenzeilen: Bezeichnung links, Wert rechtsbündig. Je Stat aus ns.STAT_LINES
-- so viele Zeilen wie sie rows hat; stat.setting entscheidet über die Sichtbarkeit.
local rows = {}
for _, stat in ipairs(ns.STAT_LINES) do
  for _, rowDefinition in ipairs(stat.rows) do
    table.insert(rows, {
      setting = stat.setting,
      definition = rowDefinition,
      label = window:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"),
      value = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"),
    })
  end
end

local function fontSize(fontString)
  local _, size = fontString:GetFont()
  return size
end

---------------------------------------------------------------------------
-- Inhalt
---------------------------------------------------------------------------

-- Fenster verbreitern, falls Bezeichnung und Wert einer Zeile nicht mehr nebeneinander passen
local function growToFitRows()
  for _, row in ipairs(rows) do
    local needed = row.label:GetStringWidth() + COLUMN_GAP + row.value:GetStringWidth() + 2 * PADDING_X
    if row.label:IsShown() and needed > window:GetWidth() then
      window:SetWidth(needed)
    end
  end
end

local function refreshTexts()
  local scope = ns.db.windowScope
  levelTab:SetLabel(string.format(L.TAB_LEVEL, ns.level))
  levelTab:SetActive(scope == Stats.LEVEL)
  sessionTab:SetLabel(L.TAB_SESSION)
  sessionTab:SetActive(scope == Stats.SESSION)

  local seconds = Stats.GetSeconds(scope)
  timeText:SetText(seconds and Format.Clock(seconds) or "...")
  for _, row in ipairs(rows) do
    if row.label:IsShown() then
      row.label:SetText(L[row.definition.label])
      row.value:SetText(row.definition.value(scope))
    end
  end
  growToFitRows()
end

-- Sichtbare Zeilen untereinander unter die Zeit setzen, Fenstergröße aus Schriftgrößen berechnen.
-- Alle Maße gelten bei Skalierung 1; SetScale vergrößert das Ergebnis gleichmäßig.
local function updateLayout(db)
  timeText:SetText(WIDEST_TIME)
  local width = math.max(MIN_WIDTH, timeText:GetStringWidth() + 2 * PADDING_X)

  local tabHeight = fontSize(levelTab.label) + 4
  local y = PADDING_Y + tabHeight + LINE_GAP
  timeText:ClearAllPoints()
  timeText:SetPoint("TOP", window, "TOP", 0, -y)
  y = y + fontSize(timeText) + TABLE_GAP

  for _, row in ipairs(rows) do
    local visible = db[row.setting]
    row.label:SetShown(visible)
    row.value:SetShown(visible)
    if visible then
      row.label:ClearAllPoints()
      row.label:SetPoint("TOPLEFT", window, "TOPLEFT", PADDING_X, -y)
      row.value:ClearAllPoints()
      row.value:SetPoint("TOPRIGHT", window, "TOPRIGHT", -PADDING_X, -y)
      y = y + fontSize(row.label) + LINE_GAP
    end
  end

  window:SetSize(width, y + PADDING_Y)
end

---------------------------------------------------------------------------
-- Position und Größe
---------------------------------------------------------------------------
local function clampScale(scale)
  return math.max(TimerWindow.MIN_SCALE, math.min(TimerWindow.MAX_SCALE, scale))
end

local function savePosition()
  local point, _, relativePoint, x, y = window:GetPoint()
  ns.db.pos = { point, relativePoint, x, y }
end

-- Gespeicherte Abstände gelten in der Skalierung des Fensters, daher zuerst skalieren
local function restorePosition()
  local pos = ns.db.pos or DEFAULT_POSITION
  window:SetScale(clampScale(ns.db.scale))
  window:ClearAllPoints()
  window:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
end

-- Skaliert das Fenster und hält dabei die linke obere Ecke auf dem Bildschirm fest.
-- Ankerabstände werden in der Skalierung des Fensters gemessen und müssen umgerechnet werden.
local function setScaleKeepingTopLeft(scale)
  local oldScale = window:GetScale()
  local left, top = window:GetLeft(), window:GetTop()
  window:SetScale(scale)
  if left and top then
    window:ClearAllPoints()
    window:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left * oldScale / scale, top * oldScale / scale)
  end
end

function TimerWindow.ResetLayout()
  ns.db.pos = nil
  ns.db.scale = DEFAULT_SCALE
  restorePosition()
  ns.ApplySettings()
end

window:SetScript("OnDragStart", function(self)
  if not ns.db.locked then self:StartMoving() end
end)
window:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  savePosition()
end)

window:SetScript("OnMouseUp", function(_, mouseButton)
  if mouseButton == "RightButton" then ns.ToggleOptions() end
end)

---------------------------------------------------------------------------
-- Ziehgriff: Abstand der Maus zum Start bestimmt die neue Skalierung
---------------------------------------------------------------------------
local grip = CreateFrame("Button", nil, window)
grip:SetSize(GRIP_SIZE, GRIP_SIZE)
grip:SetPoint("BOTTOMRIGHT", -3, 3)
grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

local resizeStart  -- Zustand beim Drücken: Mausposition, Fenstergröße auf dem Bildschirm, Skalierung

local function cursorPosition()
  local x, y = GetCursorPosition()
  local uiScale = UIParent:GetEffectiveScale()
  return x / uiScale, y / uiScale
end

-- Mittel aus horizontaler und vertikaler Vergrößerung, damit diagonales Ziehen natürlich wirkt
local function onResizeUpdate()
  local x, y = cursorPosition()
  local widthFactor = (resizeStart.width + x - resizeStart.x) / resizeStart.width
  local heightFactor = (resizeStart.height + resizeStart.y - y) / resizeStart.height
  setScaleKeepingTopLeft(clampScale(resizeStart.scale * (widthFactor + heightFactor) / 2))
end

grip:SetScript("OnMouseDown", function(self)
  local x, y = cursorPosition()
  local scale = window:GetScale()
  resizeStart = {
    x = x,
    y = y,
    width = window:GetWidth() * scale,
    height = window:GetHeight() * scale,
    scale = scale,
  }
  self:SetScript("OnUpdate", onResizeUpdate)
end)

grip:SetScript("OnMouseUp", function(self)
  self:SetScript("OnUpdate", nil)
  resizeStart = nil
  savePosition()
  ns.Set("scale", window:GetScale())
end)

---------------------------------------------------------------------------
-- Ablauf
---------------------------------------------------------------------------
local sinceUpdate = 0
window:SetScript("OnUpdate", function(_, elapsed)
  sinceUpdate = sinceUpdate + elapsed
  if sinceUpdate < UPDATE_INTERVAL then return end
  sinceUpdate = 0
  refreshTexts()
  -- Ziehgriff nur zeigen, wenn die Maus über dem Fenster ist (oder gerade gezogen wird)
  grip:SetAlpha((window:IsMouseOver() or resizeStart) and 1 or 0)
end)

ns.OnLogin(restorePosition)

ns.RegisterApply(function(db)
  updateLayout(db)
  refreshTexts()
  Widgets.SetBackgroundAlpha(window, db.bgAlpha)

  -- Größe aus den Einstellungen (Regler); beim Login ist sie schon gesetzt
  local scale = clampScale(db.scale)
  if math.abs(window:GetScale() - scale) > 0.001 then
    setScaleKeepingTopLeft(scale)
    savePosition()
  end

  grip:SetShown(not db.locked)
  window:SetShown(db.showTimer)
end)
