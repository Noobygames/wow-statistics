-- Gemeinsame UI-Bausteine, damit alle Fenster gleich aussehen und sich gleich verhalten.
local _, ns = ...

local Widgets = {}
ns.Widgets = Widgets

Widgets.COLORS = {
  background = { 0.04, 0.05, 0.1 },
  border = { 0.72, 0.53, 0.17 },
  highlight = { 0.96, 0.79, 0.36 },
}

local PANEL_BACKDROP = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  edgeSize = 14,
  insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local SLIDER_BACKDROP = {
  bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
  edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
  tile = true, tileSize = 8, edgeSize = 8,
  insets = { left = 3, right = 3, top = 6, bottom = 6 },
}

local INACTIVE_TAB_COLOR = { 0.55, 0.55, 0.55 }
local TAB_PADDING = 8

local CHECKBOX_SIZE = 26
local SLIDER_HEIGHT = 17
local SLIDER_LABEL_HEIGHT = 18

-- Verschiebbares Fenster im Addon-Stil (Ziehen muss der Aufrufer per OnDragStart regeln)
function Widgets.CreatePanel(name, backgroundAlpha)
  local panel = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
  panel:SetBackdrop(PANEL_BACKDROP)
  panel:SetBackdropBorderColor(unpack(Widgets.COLORS.border))
  Widgets.SetBackgroundAlpha(panel, backgroundAlpha)
  panel:SetMovable(true)
  panel:EnableMouse(true)
  panel:SetClampedToScreen(true)
  panel:RegisterForDrag("LeftButton")
  return panel
end

function Widgets.SetBackgroundAlpha(panel, alpha)
  local r, g, b = unpack(Widgets.COLORS.background)
  panel:SetBackdropColor(r, g, b, alpha)
end

-- Checkbox mit eigenem Label, da die Template-Textfelder je nach Client anders heißen
function Widgets.CreateCheckbox(parent, onToggle)
  local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  checkbox:SetSize(CHECKBOX_SIZE, CHECKBOX_SIZE)
  checkbox.label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  checkbox.label:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
  checkbox:SetScript("OnClick", function(self)
    onToggle(self:GetChecked() and true or false)
  end)
  return checkbox
end

-- Slider mit Label (links) und Wertanzeige (rechts). Selbst gebaut, weil
-- OptionsSliderTemplate nicht in allen Clients existiert.
-- Rückgabe ist ein Container; Breite bestimmt der Aufrufer über seine Anker.
function Widgets.CreateSlider(parent, minValue, maxValue, step, onChange)
  local container = CreateFrame("Frame", nil, parent)
  container:SetHeight(SLIDER_LABEL_HEIGHT + SLIDER_HEIGHT)

  container.label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  container.label:SetPoint("TOPLEFT")
  container.valueText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  container.valueText:SetPoint("TOPRIGHT")

  local slider = CreateFrame("Slider", nil, container, "BackdropTemplate")
  slider:SetOrientation("HORIZONTAL")
  slider:SetPoint("BOTTOMLEFT")
  slider:SetPoint("BOTTOMRIGHT")
  slider:SetHeight(SLIDER_HEIGHT)
  slider:SetHitRectInsets(0, 0, -6, -6)
  slider:SetBackdrop(SLIDER_BACKDROP)
  slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
  slider:SetMinMaxValues(minValue, maxValue)
  slider:SetValueStep(step)
  if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end

  local silent = false
  slider:SetScript("OnValueChanged", function(_, value)
    if silent then return end
    onChange(math.floor(value / step + 0.5) * step)
  end)

  -- Wert setzen, ohne onChange auszulösen (für Anzeige-Updates)
  function container:SetValueSilently(value, displayText)
    silent = true
    slider:SetValue(value)
    silent = false
    self.valueText:SetText(displayText or value)
  end

  return container
end

-- Reiter als schlichter Text-Button; der aktive Reiter ist hervorgehoben
function Widgets.CreateTab(parent, fontObject, onClick)
  local tab = CreateFrame("Button", nil, parent)
  tab.label = tab:CreateFontString(nil, "OVERLAY", fontObject)
  tab.label:SetPoint("CENTER")
  tab:SetScript("OnClick", onClick)

  function tab:SetLabel(text)
    self.label:SetText(text)
    local _, fontHeight = self.label:GetFont()
    self:SetSize(self.label:GetStringWidth() + TAB_PADDING, fontHeight + 4)
  end

  function tab:SetActive(active)
    local color = active and Widgets.COLORS.highlight or INACTIVE_TAB_COLOR
    self.label:SetTextColor(unpack(color))
  end

  return tab
end

-- Kleiner Button mit Text, z.B. Pfeile zum Blättern
function Widgets.CreateButton(parent, width, height, onClick)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(width, height)
  button:SetScript("OnClick", onClick)
  return button
end
