-- Anzeigefenster: Reiter "Level | Session", Spielzeit im gewählten Bereich und darunter die abschaltbaren Stat-Zeilen.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Format = ns.Format
local Stats = ns.Stats

local UPDATE_INTERVAL = 0.25          -- Sekunden zwischen zwei Anzeige-Updates
local PADDING_X = 20
local PADDING_Y = 8
local LINE_GAP = 3
local TAB_GAP = 10                    -- Abstand zwischen den Reitern
local MIN_WIDTH = 160
local WIDEST_TIME = "00d 00h 00m 00s" -- für die Fensterbreite
local DEFAULT_POSITION = { "TOP", "TOP", 0, -120 }

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
timeText:SetPoint("TOP", window, "TOP", 0, -PADDING_Y)  -- endgültige Position setzt updateLayout
timeText:SetTextColor(unpack(Widgets.COLORS.highlight))

-- Eine FontString pro Stat-Zeile, gleiche Reihenfolge wie ns.STAT_LINES
local statTexts = {}
for i in ipairs(ns.STAT_LINES) do
  statTexts[i] = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
end

local function fontSize(fontString)
  local _, size = fontString:GetFont()
  return size
end

-- Fenster verbreitern, falls eine Stat-Zeile durch wachsende Zahlen zu lang wird
local function growToFitStatLines()
  for _, statText in ipairs(statTexts) do
    local needed = statText:GetStringWidth() + 2 * PADDING_X
    if statText:IsShown() and needed > window:GetWidth() then
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
  for i, line in ipairs(ns.STAT_LINES) do
    if statTexts[i]:IsShown() then
      statTexts[i]:SetText(line.text(scope))
    end
  end
  growToFitStatLines()
end

-- Sichtbare Stat-Zeilen untereinander unter die Zeit hängen, Fenstergröße aus Schriftgrößen berechnen
local function updateLayout(db)
  local font, _, flags = GameFontNormalLarge:GetFont()
  timeText:SetFont(font, db.fontSize, flags)

  timeText:SetText(WIDEST_TIME)
  local width = math.max(MIN_WIDTH, timeText:GetStringWidth() + 2 * PADDING_X)
  local tabHeight = fontSize(levelTab.label) + 4
  timeText:ClearAllPoints()
  timeText:SetPoint("TOP", window, "TOP", 0, -(PADDING_Y + tabHeight + LINE_GAP))
  local height = 2 * PADDING_Y + tabHeight + LINE_GAP + db.fontSize

  local anchor = timeText
  for i, line in ipairs(ns.STAT_LINES) do
    local statText = statTexts[i]
    local visible = db[line.setting]
    statText:SetShown(visible)
    if visible then
      statText:ClearAllPoints()
      statText:SetPoint("TOP", anchor, "BOTTOM", 0, -LINE_GAP)
      anchor = statText
      height = height + LINE_GAP + fontSize(statText)
    end
  end

  window:SetSize(width, height)
end

local function savePosition()
  local point, _, relativePoint, x, y = window:GetPoint()
  ns.db.pos = { point, relativePoint, x, y }
end

local function restorePosition()
  local pos = ns.db.pos or DEFAULT_POSITION
  window:ClearAllPoints()
  window:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
end

window:SetScript("OnDragStart", function(self)
  if not ns.db.locked then self:StartMoving() end
end)
window:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  savePosition()
end)

local sinceUpdate = 0
window:SetScript("OnUpdate", function(_, elapsed)
  sinceUpdate = sinceUpdate + elapsed
  if sinceUpdate < UPDATE_INTERVAL then return end
  sinceUpdate = 0
  refreshTexts()
end)

ns.OnLogin(restorePosition)

ns.RegisterApply(function(db)
  updateLayout(db)
  refreshTexts()
  Widgets.SetBackgroundAlpha(window, db.bgAlpha)
  window:SetShown(db.showTimer)
end)
