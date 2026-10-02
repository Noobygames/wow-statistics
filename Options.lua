-- Einstellungsfenster in drei Abschnitten: Fenster, Statistiken, Allgemein.
-- Jedes Steuerelement registriert eine refresh(db)-Funktion; nach jeder Änderung
-- (ns.Set/ns.ApplySettings) zeigen alle den aktuellen Stand und die gewählte Sprache.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local TimerWindow = ns.TimerWindow

local MIN_WIDTH = 320
local MARGIN = 16
local CONTENT_TOP = -42
local MIN_COLUMN_WIDTH = 144
local COLUMN_GAP = 12        -- Mindestabstand zwischen einer Beschriftung und der rechten Spalte
local ROW_SECTION = 24
local ROW_CHECKBOX = 26
local ROW_SLIDER = 44
local ROW_BUTTON = 30
local ROW_LANGUAGE = 26
local ROW_HINT = 30
local SECTION_GAP = 8
local BUTTON_HEIGHT = 22
local LANGUAGE_TAB_GAP = 10

local panel = Widgets.CreatePanel("LevelTimerOptions", 0.95)
panel:SetWidth(MIN_WIDTH)  -- wächst mit den Texten der gewählten Sprache (fitWidth)
panel:SetPoint("CENTER")
panel:SetFrameStrata("DIALOG")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
panel:Hide()
table.insert(UISpecialFrames, "LevelTimerOptions")  -- mit ESC schließen

Widgets.CreateCloseButton(panel)

local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -14)

---------------------------------------------------------------------------
-- Bausteine: legen Steuerelemente von oben nach unten an
---------------------------------------------------------------------------
local refreshers = {}
local nextRowY = CONTENT_TOP
local toggleCells = {}    -- { checkbox, column, y } aller Schalter; Spaltenbreite setzt fitWidth
local languageRow         -- { label, tabs } der Sprachwahl

local function onRefresh(refresh)
  table.insert(refreshers, refresh)
end

local function addRow(widget, height, stretch)
  widget:SetPoint("TOPLEFT", MARGIN, nextRowY)
  if stretch then widget:SetPoint("TOPRIGHT", -MARGIN, nextRowY) end
  nextRowY = nextRowY - height
end

local function addSection(labelKey)
  if nextRowY ~= CONTENT_TOP then nextRowY = nextRowY - SECTION_GAP end
  local header = Widgets.CreateSectionHeader(panel)
  addRow(header, ROW_SECTION, true)
  onRefresh(function() header:SetText(L[labelKey]) end)
end

-- slider = { label, min, max, step, get(db) -> Wert, set(Wert), format(Wert) -> Anzeigetext }
local function addSlider(slider)
  local control = Widgets.CreateSlider(panel, slider.min, slider.max, slider.step, slider.set)
  addRow(control, ROW_SLIDER, true)
  onRefresh(function(db)
    local value = slider.get(db)
    control.label:SetText(L[slider.label])
    control:SetValueSilently(value, slider.format(value))
  end)
end

-- Checkboxen in zwei Spalten; toggle = { label, get(db) -> bool, set(checked) }
local function addToggles(toggles)
  for i, toggle in ipairs(toggles) do
    local column = (i - 1) % 2
    local row = math.floor((i - 1) / 2)
    local checkbox = Widgets.CreateCheckbox(panel, toggle.set)
    table.insert(toggleCells, { checkbox = checkbox, column = column, y = nextRowY - row * ROW_CHECKBOX })
    onRefresh(function(db)
      checkbox.label:SetText(L[toggle.label])
      checkbox:SetChecked(toggle.get(db))
    end)
  end
  nextRowY = nextRowY - math.ceil(#toggles / 2) * ROW_CHECKBOX
end

local function addButton(labelKey, onClick)
  local button = Widgets.CreateButton(panel, MIN_WIDTH - 2 * MARGIN, BUTTON_HEIGHT, onClick)
  addRow(button, ROW_BUTTON, true)
  onRefresh(function() button:SetText(L[labelKey]) end)
end

-- Sprache: Beschriftung und ein Reiter je Sprache
local function addLanguageChooser()
  local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  addRow(label, 0)
  languageRow = { label = label, tabs = {} }
  local anchor = label
  for _, language in ipairs(ns.languages) do
    local tab = Widgets.CreateTab(panel, "GameFontHighlight", function()
      ns.Set("language", language.code)
    end)
    tab:SetPoint("LEFT", anchor, "RIGHT", LANGUAGE_TAB_GAP, 0)
    anchor = tab
    table.insert(languageRow.tabs, tab)
    onRefresh(function(db)
      tab:SetLabel(language.name)
      tab:SetActive(db.language == language.code)
    end)
  end
  nextRowY = nextRowY - ROW_LANGUAGE
  onRefresh(function() label:SetText(L.LANGUAGE) end)
end

local function addHint(labelKey)
  local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetJustifyH("LEFT")
  addRow(hint, ROW_HINT, true)
  onRefresh(function() hint:SetText(L[labelKey]) end)
end

local function percent(value)
  return value .. "%"
end

local function toPercent(fraction)
  return math.floor(fraction * 100 + 0.5)
end

---------------------------------------------------------------------------
-- Inhalt
---------------------------------------------------------------------------
addSection("SECTION_WINDOW")
addSlider({
  label = "WINDOW_SIZE",
  min = toPercent(TimerWindow.MIN_SCALE),
  max = toPercent(TimerWindow.MAX_SCALE),
  step = 5,
  get = function(db) return toPercent(db.scale) end,
  set = function(value) ns.Set("scale", value / 100) end,
  format = percent,
})
addSlider({
  label = "BG_OPACITY",
  min = 0,
  max = 100,
  step = 5,
  get = function(db) return toPercent(db.bgAlpha) end,
  set = function(value) ns.Set("bgAlpha", value / 100) end,
  format = percent,
})
addToggles({
  { label = "SHOW_TIMER", get = function(db) return db.showTimer end,
    set = function(checked) ns.Set("showTimer", checked) end },
  { label = "LOCK_FRAME", get = function(db) return db.locked end,
    set = function(checked) ns.Set("locked", checked) end },
  { label = "SHOW_XP_BAR", get = function(db) return db.showXpBar end,
    set = function(checked) ns.Set("showXpBar", checked) end },
  { label = "COMPACT_MODE", get = function(db) return db.compactMode end,
    set = function(checked) ns.Set("compactMode", checked) end },
  { label = "HORIZONTAL_LAYOUT", get = function(db) return db.horizontalLayout end,
    set = function(checked) ns.Set("horizontalLayout", checked) end },
})
addButton("RESET_WINDOW", function() TimerWindow.ResetLayout() end)
addHint("OPTIONS_HINT")

-- Ein Schalter je Stat-Zeile, direkt aus ns.STAT_LINES
addSection("STATISTICS")
local statToggles = {}
for i, line in ipairs(ns.STAT_LINES) do
  statToggles[i] = {
    label = line.label,
    get = function(db) return db[line.setting] end,
    set = function(checked) ns.Set(line.setting, checked) end,
  }
end
addToggles(statToggles)

addSection("SECTION_GENERAL")
addLanguageChooser()
addToggles({
  { label = "SHOW_MINIMAP", get = function(db) return not db.minimap.hide end,
    set = function(checked) ns.SetMinimapHidden(not checked) end },
  { label = "LEVEL_UP_SUMMARY_TOGGLE", get = function(db) return db.levelUpSummary end,
    set = function(checked) ns.Set("levelUpSummary", checked) end },
})
nextRowY = nextRowY - SECTION_GAP
addButton("NEW_SESSION", function() ns.StartNewSession() end)
addButton("HISTORY", function() ns.ToggleHistory() end)

panel:SetHeight(-nextRowY + MARGIN)

---------------------------------------------------------------------------
-- Aktualisierung
---------------------------------------------------------------------------

-- Zwei Schalter-Spalten so breit wie die längste Beschriftung, damit sich nichts überlappt
local function columnWidth()
  local width = MIN_COLUMN_WIDTH
  for _, cell in ipairs(toggleCells) do
    local checkbox = cell.checkbox
    width = math.max(width, checkbox:GetWidth() + Widgets.CHECKBOX_LABEL_GAP + checkbox.label:GetStringWidth() + COLUMN_GAP)
  end
  return width
end

local function languageRowWidth()
  local width = languageRow.label:GetStringWidth()
  for _, tab in ipairs(languageRow.tabs) do
    width = width + LANGUAGE_TAB_GAP + tab:GetWidth()
  end
  return width
end

-- Fensterbreite aus den Texten der gewählten Sprache; Abschnitte, Regler und Buttons strecken sich mit
local function fitWidth()
  local column = columnWidth()
  for _, cell in ipairs(toggleCells) do
    cell.checkbox:ClearAllPoints()
    cell.checkbox:SetPoint("TOPLEFT", MARGIN + cell.column * column, cell.y)
  end
  local content = math.max(2 * column, languageRowWidth())
  panel:SetWidth(math.max(MIN_WIDTH, content + 2 * MARGIN))
end

local function refresh(db)
  title:SetText("LevelTimer - " .. L.SETTINGS)
  for _, refreshControl in ipairs(refreshers) do
    refreshControl(db)
  end
  fitWidth()
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
