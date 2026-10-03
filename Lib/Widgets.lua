-- Gemeinsame UI-Bausteine, damit alle Fenster gleich aussehen und sich gleich verhalten.
local addonName, ns = ...

local Widgets = {}
ns.Widgets = Widgets

-- Eigenes Addon-Icon (Media/Icon.tga, erzeugt mit "make artwork"); auch als IconTexture in der .toc
Widgets.ICON = "Interface\\AddOns\\" .. addonName .. "\\Media\\Icon"

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
local SECTION_HEADER_HEIGHT = 18
local CLOSE_BUTTON_SIZE = 24
local SCROLLBAR_WIDTH = 8
local SCROLLBAR_THUMB_HEIGHT = 30
local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8x8"

local CHECKBOX_SIZE = 26
Widgets.CHECKBOX_LABEL_GAP = 2  -- Abstand Kästchen zu Beschriftung (Options.lua rechnet damit)
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

-- Skaliert einen Frame und hält dabei seine linke obere Ecke auf dem Bildschirm fest.
-- Ankerabstände werden in der Skalierung des Frames gemessen und müssen umgerechnet werden.
function Widgets.SetScaleKeepingTopLeft(frame, scale)
  local oldScale = frame:GetScale()
  local left, top = frame:GetLeft(), frame:GetTop()
  frame:SetScale(scale)
  if left and top then
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left * oldScale / scale, top * oldScale / scale)
  end
end

function Widgets.SetBackgroundAlpha(panel, alpha)
  local r, g, b = unpack(Widgets.COLORS.background)
  panel:SetBackdropColor(r, g, b, alpha)
end

-- Vollfarbiger Hintergrund ohne Rahmen (z.B. Chroma-Key für Streams); color = { r, g, b }
function Widgets.SetSolidBackground(panel, color)
  local r, g, b = unpack(color)
  panel:SetBackdropColor(r, g, b, 1)
  panel:SetBackdropBorderColor(0, 0, 0, 0)
end

function Widgets.SetDefaultBackground(panel, alpha)
  Widgets.SetBackgroundAlpha(panel, alpha)
  panel:SetBackdropBorderColor(unpack(Widgets.COLORS.border))
end

-- Tooltip bei Mauskontakt. title() und text() liefern die Texte in der aktuellen Sprache;
-- liefert text() nil, erscheint kein Tooltip. HookScript, damit vorhandene Handler bleiben.
function Widgets.AttachTooltip(frame, title, text)
  frame:HookScript("OnEnter", function(self)
    local body = text()
    if not body then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(title(), unpack(Widgets.COLORS.highlight))
    GameTooltip:AddLine(body, 1, 1, 1, true)  -- true = umbrechen
    GameTooltip:Show()
  end)
  frame:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Checkbox mit eigenem Label, da die Template-Textfelder je nach Client anders heißen
function Widgets.CreateCheckbox(parent, onToggle)
  local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  checkbox:SetSize(CHECKBOX_SIZE, CHECKBOX_SIZE)
  checkbox.label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  checkbox.label:SetPoint("LEFT", checkbox, "RIGHT", Widgets.CHECKBOX_LABEL_GAP, 0)
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
  container.slider = slider  -- z.B. für einen Tooltip

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

-- Abschnitts-Überschrift: Text mit feiner Linie bis zum rechten Rand
function Widgets.CreateSectionHeader(parent)
  local header = CreateFrame("Frame", nil, parent)
  header:SetHeight(SECTION_HEADER_HEIGHT)

  header.label = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  header.label:SetPoint("LEFT")

  local line = header:CreateTexture(nil, "ARTWORK")
  line:SetHeight(1)
  line:SetPoint("LEFT", header.label, "RIGHT", 6, 0)
  line:SetPoint("RIGHT")
  local r, g, b = unpack(Widgets.COLORS.border)
  line:SetColorTexture(r, g, b, 0.6)

  function header:SetText(text)
    self.label:SetText(text)
  end

  return header
end

-- Schließen-Knopf oben rechts, kleiner als die Vorlage, damit er nicht über den Rand ragt
function Widgets.CreateCloseButton(panel)
  local button = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
  button:SetSize(CLOSE_BUTTON_SIZE, CLOSE_BUTTON_SIZE)
  button:SetPoint("TOPRIGHT", -4, -4)
  return button
end

-- Schmale senkrechte Bildlaufleiste im Addon-Stil (die Vorlage sieht je nach Client anders aus).
-- onScroll(offset) wird nur bei Benutzereingabe aufgerufen, Werte sind ganze Zeilen.
function Widgets.CreateScrollBar(parent, onScroll)
  local bar = CreateFrame("Slider", nil, parent, "BackdropTemplate")
  bar:SetOrientation("VERTICAL")
  bar:SetWidth(SCROLLBAR_WIDTH)
  bar:SetBackdrop({ bgFile = WHITE_TEXTURE })
  bar:SetBackdropColor(1, 1, 1, 0.08)

  local thumb = bar:CreateTexture(nil, "OVERLAY")
  local r, g, b = unpack(Widgets.COLORS.border)
  thumb:SetColorTexture(r, g, b, 0.9)
  thumb:SetSize(SCROLLBAR_WIDTH, SCROLLBAR_THUMB_HEIGHT)
  bar:SetThumbTexture(thumb)

  bar:SetMinMaxValues(0, 0)
  bar:SetValueStep(1)
  if bar.SetObeyStepOnDrag then bar:SetObeyStepOnDrag(true) end

  local silent = false
  bar:SetScript("OnValueChanged", function(_, value)
    if not silent then onScroll(math.floor(value + 0.5)) end
  end)

  -- Bereich 0..maxOffset; ohne etwas zu scrollen wird die Leiste ausgeblendet
  function bar:SetRange(maxOffset)
    silent = true
    self:SetMinMaxValues(0, maxOffset)
    silent = false
    self:SetShown(maxOffset > 0)
  end

  function bar:SetOffsetSilently(offset)
    silent = true
    self:SetValue(offset)
    silent = false
  end

  return bar
end
