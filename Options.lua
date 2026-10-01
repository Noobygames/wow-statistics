-- Einstellungsfenster. Jede Änderung geht über ns.Set/ns.ApplySettings,
-- refresh() spiegelt danach den aktuellen Stand in die Widgets.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets

local WIDTH = 300
local MARGIN = 16
local CONTENT_TOP = -50
local LANGUAGE_COLUMN_WIDTH = 130
local ROW_LABEL = 18
local ROW_CHECKBOX = 28
local ROW_SLIDER = 50
local ROW_SECTION_GAP = 10

local panel = Widgets.CreatePanel("LevelTimerOptions", 0.95)
panel:SetWidth(WIDTH)
panel:SetPoint("CENTER")
panel:SetFrameStrata("DIALOG")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
panel:Hide()
table.insert(UISpecialFrames, "LevelTimerOptions")  -- mit ESC schließen

local closeButton = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -2, -2)

local header = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
header:SetPoint("TOP", 0, -14)

-- Einfaches Zeilenlayout von oben nach unten
local nextRowY = CONTENT_TOP

local function addRow(widget, height, stretch)
  widget:SetPoint("TOPLEFT", MARGIN, nextRowY)
  if stretch then widget:SetPoint("TOPRIGHT", -MARGIN, nextRowY) end
  nextRowY = nextRowY - height
end

-- Sprache
local languageLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
addRow(languageLabel, ROW_LABEL)

local languageButtons = {}
for i, language in ipairs(ns.languages) do
  local checkbox = Widgets.CreateCheckbox(panel, function()
    ns.Set("language", language.code)
  end)
  checkbox:SetPoint("TOPLEFT", MARGIN + (i - 1) * LANGUAGE_COLUMN_WIDTH, nextRowY)
  checkbox.label:SetText(language.name)
  checkbox.languageCode = language.code
  languageButtons[i] = checkbox
end
nextRowY = nextRowY - ROW_CHECKBOX - ROW_SECTION_GAP

-- Darstellung
local fontSizeSlider = Widgets.CreateSlider(panel, 10, 32, 1, function(size)
  ns.Set("fontSize", size)
end)
addRow(fontSizeSlider, ROW_SLIDER, true)

local opacitySlider = Widgets.CreateSlider(panel, 0, 100, 5, function(percent)
  ns.Set("bgAlpha", percent / 100)
end)
addRow(opacitySlider, ROW_SLIDER, true)

-- Schalter
local function addToggle(onToggle)
  local checkbox = Widgets.CreateCheckbox(panel, onToggle)
  addRow(checkbox, ROW_CHECKBOX)
  return checkbox
end

local lockToggle = addToggle(function(checked) ns.Set("locked", checked) end)
local timerToggle = addToggle(function(checked) ns.Set("showTimer", checked) end)
local killsToggle = addToggle(function(checked) ns.Set("showKills", checked) end)
local deathsToggle = addToggle(function(checked) ns.Set("showDeaths", checked) end)
local minimapToggle = addToggle(function(checked) ns.SetMinimapHidden(not checked) end)

panel:SetHeight(-nextRowY + MARGIN)

local function refresh(db)
  header:SetText("LevelTimer - " .. L.SETTINGS)

  languageLabel:SetText(L.LANGUAGE)
  for _, checkbox in ipairs(languageButtons) do
    checkbox:SetChecked(db.language == checkbox.languageCode)
  end

  fontSizeSlider.label:SetText(L.FONT_SIZE)
  fontSizeSlider:SetValueSilently(db.fontSize)

  local opacityPercent = math.floor(db.bgAlpha * 100 + 0.5)
  opacitySlider.label:SetText(L.BG_OPACITY)
  opacitySlider:SetValueSilently(opacityPercent, opacityPercent .. "%")

  lockToggle.label:SetText(L.LOCK_FRAME)
  lockToggle:SetChecked(db.locked)
  timerToggle.label:SetText(L.SHOW_TIMER)
  timerToggle:SetChecked(db.showTimer)
  killsToggle.label:SetText(L.SHOW_KILLS)
  killsToggle:SetChecked(db.showKills)
  deathsToggle.label:SetText(L.SHOW_DEATHS)
  deathsToggle:SetChecked(db.showDeaths)
  minimapToggle.label:SetText(L.SHOW_MINIMAP)
  minimapToggle:SetChecked(not db.minimap.hide)
end

ns.RegisterApply(refresh)

function ns.ToggleOptions()
  if not ns.db then return end
  if panel:IsShown() then
    panel:Hide()
  else
    refresh(ns.db)
    panel:Show()
  end
end
