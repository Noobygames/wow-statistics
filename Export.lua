-- Export: Tabellen als CSV in einem Fenster zum Kopieren (Strg+C); Addons dürfen nicht in Dateien schreiben.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets

local Export = {}
ns.Export = Export

local WIDTH = 520
local HEIGHT = 340
local MARGIN = 16
local TEXT_TOP = -44
local WHEEL_STEP = 40  -- Pixel pro Mausrad-Raste

-- Feld für CSV aufbereiten: in Anführungszeichen, wenn es Trennzeichen, Anführungszeichen oder Umbrüche enthält
local function csvField(value, separator)
  local text = tostring(value or "")
  if text:find(separator, 1, true) or text:find('"', 1, true) or text:find("\n", 1, true) then
    text = '"' .. text:gsub('"', '""') .. '"'
  end
  return text
end

-- headers = { "Spalte", ... }, rows = { { "Wert", ... }, ... }
function Export.ToCsv(headers, rows, separator)
  local lines = {}
  local function addLine(fields)
    local escaped = {}
    for i, field in ipairs(fields) do
      escaped[i] = csvField(field, separator)
    end
    table.insert(lines, table.concat(escaped, separator))
  end
  addLine(headers)
  for _, row in ipairs(rows) do
    addLine(row)
  end
  return table.concat(lines, "\n")
end

---------------------------------------------------------------------------
-- Fenster
---------------------------------------------------------------------------
local panel = Widgets.CreatePanel("LevelTimerExport", 0.95)
panel:SetSize(WIDTH, HEIGHT)
panel:SetPoint("CENTER")
panel:SetFrameStrata("FULLSCREEN_DIALOG")  -- über der Historie
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
panel:Hide()
table.insert(UISpecialFrames, "LevelTimerExport")  -- mit ESC schließen

Widgets.CreateCloseButton(panel)

local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -14)

local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
hint:SetPoint("BOTTOMLEFT", MARGIN, MARGIN - 4)

local scrollFrame = CreateFrame("ScrollFrame", nil, panel)
scrollFrame:SetPoint("TOPLEFT", MARGIN, TEXT_TOP)
scrollFrame:SetPoint("BOTTOMRIGHT", -MARGIN, MARGIN + 10)

local editBox = CreateFrame("EditBox", nil, scrollFrame)
editBox:SetMultiLine(true)
editBox:SetAutoFocus(false)
editBox:SetFontObject("ChatFontNormal")
editBox:SetWidth(WIDTH - 2 * MARGIN)
editBox:SetScript("OnEscapePressed", function() panel:Hide() end)
scrollFrame:SetScrollChild(editBox)

scrollFrame:EnableMouseWheel(true)
scrollFrame:SetScript("OnMouseWheel", function(self, delta)
  local offset = self:GetVerticalScroll() - delta * WHEEL_STEP
  self:SetVerticalScroll(math.max(0, math.min(offset, self:GetVerticalScrollRange())))
end)

-- Text anzeigen, markieren und fokussieren, damit Strg+C sofort kopiert
function Export.Show(heading, text)
  title:SetText(heading)
  hint:SetText(L.EXPORT_HINT)
  editBox:SetText(text)
  panel:Show()
  editBox:SetFocus()
  editBox:HighlightText()
end
