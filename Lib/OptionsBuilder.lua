-- Baukasten für Einstellungsfenster mit Reitern: legt Steuerelemente von oben nach unten auf der
-- aktuellen Seite an und hält sie aktuell.
-- Jedes Steuerelement registriert eine refresh(db)-Funktion; Refresh(db) (nach jeder Änderung über
-- ns.Set/ns.ApplySettings) zeigt den aktuellen Stand und die gewählte Sprache.
-- Schalter mit available() == false (z.B. nur in WoW Forever) werden gar nicht angelegt.
-- Tooltips: Text aus L["<LABEL>_TIP"] (fehlt er, gibt es keinen Tooltip), Titel = Beschriftung.
-- Breite: die zwei Schalter-Spalten, Auswahlzeilen und die Reiterzeile bestimmen sie (fitWidth),
-- damit längere Sprachen (fr/es) passen; Höhe: längste Seite plus Buttons unten (Finish).
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets

local OptionsBuilder = {}
ns.OptionsBuilder = OptionsBuilder

local MIN_WIDTH = 320
local MARGIN = 16
local TABS_TOP = -42
local TAB_GAP = 12
local CONTENT_TOP = -70
local FOOTER_GAP = 8         -- Abstand zwischen Reiterinhalt und den Buttons unten
local MIN_COLUMN_WIDTH = 144
local FOOTER_COLUMN_GAP = 8     -- Abstand zwischen den beiden Button-Spalten unten
local FOOTER_TEXT_PADDING = 24  -- Rand im Button links und rechts zusammen
local COLUMN_GAP = 12        -- Mindestabstand zwischen einer Beschriftung und der rechten Spalte
local ROW_SECTION = 24
local ROW_CHECKBOX = 26
local ROW_SLIDER = 44
local ROW_CHOOSER = 26
local ROW_HINT = 30
local SECTION_GAP = 8

-- Für eigene Bausteine des Fensters (z.B. Profil-Liste)
OptionsBuilder.MARGIN = MARGIN
OptionsBuilder.ROW_BUTTON = 30
OptionsBuilder.BUTTON_HEIGHT = 22
OptionsBuilder.CHOOSER_TAB_GAP = 10
local ROW_BUTTON = OptionsBuilder.ROW_BUTTON
local BUTTON_HEIGHT = OptionsBuilder.BUTTON_HEIGHT
local CHOOSER_TAB_GAP = OptionsBuilder.CHOOSER_TAB_GAP

-- Schalter für eine Einstellung in ns.db; available() optional (z.B. nur in WoW Forever)
function OptionsBuilder.Toggle(label, key, available)
  return {
    label = label,
    get = function(db) return db[key] end,
    set = function(checked) ns.Set(key, checked) end,
    available = available,
  }
end

-- Text aus den Locales zum Zeitpunkt der Anzeige (Sprachwechsel live)
function OptionsBuilder.Localized(key)
  return function() return L[key] end
end

-- Neues Fenster: options = { name (globaler Frame-Name), alpha, title() -> Text }
function OptionsBuilder.New(options)
  local builder = {}

  local panel = Widgets.CreatePanel(options.name, options.alpha)
  panel:SetWidth(MIN_WIDTH)  -- wächst mit den Texten der gewählten Sprache (fitWidth)
  panel:SetPoint("CENTER")
  panel:SetFrameStrata("DIALOG")
  panel:SetScript("OnDragStart", panel.StartMoving)
  panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
  panel:Hide()
  table.insert(UISpecialFrames, options.name)  -- mit ESC schließen
  Widgets.CreateCloseButton(panel)
  builder.panel = panel

  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -14)

  local refreshers = {}
  local toggleCells = {}    -- { checkbox, column, y } aller Schalter; Spaltenbreite setzt fitWidth
  local chooserRows = {}    -- { label, tabs } je Auswahlzeile; Breite prüft fitWidth

  function builder.OnRefresh(refresh)
    table.insert(refreshers, refresh)
  end
  local onRefresh = builder.OnRefresh

  -------------------------------------------------------------------------
  -- Reiter: je Reiter eine Seite über das ganze Fenster; Steuerelemente hängen an ihrer Seite
  -------------------------------------------------------------------------
  local pages = {}          -- { key, tabButton, frame, bottom } in Reihenfolge
  local page                -- Seite, auf der die Bausteine gerade anlegen
  local nextRowY = CONTENT_TOP

  local function showPage(selected)
    for _, entry in ipairs(pages) do
      entry.frame:SetShown(entry == selected)
      entry.tabButton:SetActive(entry == selected)
    end
  end

  -- Neue Seite beginnen; folgende Add*-Aufrufe landen darauf
  function builder.AddPage(labelKey)
    local entry = { key = labelKey, frame = CreateFrame("Frame", nil, panel) }
    entry.frame:SetAllPoints(panel)
    entry.tabButton = Widgets.CreateTab(panel, "GameFontNormal", function() showPage(entry) end)
    local previous = pages[#pages]
    if previous then
      entry.tabButton:SetPoint("LEFT", previous.tabButton, "RIGHT", TAB_GAP, 0)
    else
      entry.tabButton:SetPoint("TOPLEFT", MARGIN, TABS_TOP)
    end
    table.insert(pages, entry)
    page = entry.frame
    nextRowY = CONTENT_TOP
    onRefresh(function() entry.tabButton:SetLabel(L[labelKey]) end)
  end

  -- Seite abschließen: wie weit sie nach unten reicht (für die Fensterhöhe)
  function builder.FinishPage()
    pages[#pages].bottom = nextRowY
  end

  -- Für eigene Bausteine: aktuelle Seite, y der nächsten Zeile, Zeile weiterschieben
  function builder.Page() return page end
  function builder.RowY() return nextRowY end
  function builder.Advance(height) nextRowY = nextRowY - height end

  -------------------------------------------------------------------------
  -- Bausteine: legen Steuerelemente auf der aktuellen Seite von oben nach unten an
  -------------------------------------------------------------------------

  -- Tooltip aus L[tipKey]; L liefert bei fehlendem Text den Schlüssel, dann kein Tooltip
  function builder.AddTooltip(frame, tipKey, tooltipTitle)
    Widgets.AttachTooltip(frame, tooltipTitle, function()
      local text = L[tipKey]
      if text == tipKey then return nil end
      return text
    end)
  end
  local addTooltip = builder.AddTooltip
  local localized = OptionsBuilder.Localized

  function builder.AddRow(widget, height, stretch)
    widget:SetPoint("TOPLEFT", MARGIN, nextRowY)
    if stretch then widget:SetPoint("TOPRIGHT", -MARGIN, nextRowY) end
    nextRowY = nextRowY - height
  end
  local addRow = builder.AddRow

  function builder.AddSection(labelKey)
    if nextRowY ~= CONTENT_TOP then nextRowY = nextRowY - SECTION_GAP end
    local header = Widgets.CreateSectionHeader(page)
    addRow(header, ROW_SECTION, true)
    onRefresh(function() header:SetText(L[labelKey]) end)
  end

  -- slider = { label, min, max, step, get(db) -> Wert, set(Wert), format(Wert) -> Anzeigetext }
  function builder.AddSlider(slider)
    local control = Widgets.CreateSlider(page, slider.min, slider.max, slider.step, slider.set)
    addRow(control, ROW_SLIDER, true)
    addTooltip(control.slider, slider.label .. "_TIP", localized(slider.label))
    onRefresh(function(db)
      local value = slider.get(db)
      control.label:SetText(L[slider.label])
      control:SetValueSilently(value, slider.format(value))
    end)
  end

  -- Checkboxen in zwei Spalten; toggle = { label, get(db) -> bool, set(checked), available() optional,
  --   text() optional statt L[label], z.B. für Beschriftungen mit Werten, tip = Locale-Key optional }
  function builder.AddToggles(allToggles)
    local toggles = {}
    for _, toggle in ipairs(allToggles) do
      if not toggle.available or toggle.available() then table.insert(toggles, toggle) end
    end
    for i, toggle in ipairs(toggles) do
      local column = (i - 1) % 2
      local row = math.floor((i - 1) / 2)
      local checkbox = Widgets.CreateCheckbox(page, toggle.set)
      table.insert(toggleCells, { checkbox = checkbox, column = column, y = nextRowY - row * ROW_CHECKBOX })
      addTooltip(checkbox, toggle.tip or (toggle.label .. "_TIP"), function() return checkbox.label:GetText() end)
      onRefresh(function(db)
        checkbox.label:SetText(toggle.text and toggle.text() or L[toggle.label])
        checkbox:SetChecked(toggle.get(db))
        -- Beschriftung gehört zur Klick- und Tooltip-Fläche
        checkbox:SetHitRectInsets(0, -(Widgets.CHECKBOX_LABEL_GAP + checkbox.label:GetStringWidth()), 0, 0)
      end)
    end
    nextRowY = nextRowY - math.ceil(#toggles / 2) * ROW_CHECKBOX
  end

  function builder.AddButton(labelKey, onClick)
    local button = Widgets.CreateButton(page, MIN_WIDTH - 2 * MARGIN, BUTTON_HEIGHT, onClick)
    addRow(button, ROW_BUTTON, true)
    addTooltip(button, labelKey .. "_TIP", localized(labelKey))
    onRefresh(function() button:SetText(L[labelKey]) end)
  end

  -- Buttons unten auf allen Reitern in zwei Spalten, Zeilen von unten nach oben
  local footerButtons = {}
  local function footerRows()
    return math.ceil(#footerButtons / 2)
  end
  function builder.AddFooterButton(labelKey, onClick)
    local button = Widgets.CreateButton(panel, MIN_WIDTH / 2, BUTTON_HEIGHT, onClick)
    local index = #footerButtons
    local y = MARGIN + math.floor(index / 2) * ROW_BUTTON
    if index % 2 == 0 then
      button:SetPoint("BOTTOMLEFT", MARGIN, y)
      button:SetPoint("BOTTOMRIGHT", panel, "BOTTOM", -FOOTER_COLUMN_GAP / 2, y)
    else
      button:SetPoint("BOTTOMLEFT", panel, "BOTTOM", FOOTER_COLUMN_GAP / 2, y)
      button:SetPoint("BOTTOMRIGHT", -MARGIN, y)
    end
    table.insert(footerButtons, button)
    addTooltip(button, labelKey .. "_TIP", localized(labelKey))
    onRefresh(function() button:SetText(L[labelKey]) end)
  end

  -- Auswahl als Zeile von Reitern: chooser = { label = Locale-Key, setting, choices = { { value, name() }, ... } }
  function builder.AddChooser(chooser)
    local label = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    addRow(label, 0)
    local row = { label = label, tabs = {} }
    table.insert(chooserRows, row)
    local anchor = label
    for _, choice in ipairs(chooser.choices) do
      local tab = Widgets.CreateTab(page, "GameFontHighlight", function()
        ns.Set(chooser.setting, choice.value)
      end)
      tab:SetPoint("LEFT", anchor, "RIGHT", CHOOSER_TAB_GAP, 0)
      anchor = tab
      table.insert(row.tabs, tab)
      addTooltip(tab, chooser.label .. "_TIP", localized(chooser.label))
      onRefresh(function(db)
        tab:SetLabel(choice.name())
        tab:SetActive(db[chooser.setting] == choice.value)
      end)
    end
    nextRowY = nextRowY - ROW_CHOOSER
    onRefresh(function() label:SetText(L[chooser.label]) end)
  end

  function builder.AddHint(labelKey)
    local hint = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetJustifyH("LEFT")
    addRow(hint, ROW_HINT, true)
    onRefresh(function() hint:SetText(L[labelKey]) end)
  end

  -- Nach dem letzten Baustein: Höhe für die längste Seite, damit das Fenster beim Reiterwechsel
  -- nicht springt; erste Seite zeigen
  function builder.Finish()
    local lowestBottom = CONTENT_TOP
    for _, entry in ipairs(pages) do
      lowestBottom = math.min(lowestBottom, entry.bottom)
    end
    panel:SetHeight(-lowestBottom + FOOTER_GAP + footerRows() * ROW_BUTTON + MARGIN)
    showPage(pages[1])
  end

  -------------------------------------------------------------------------
  -- Aktualisierung
  -------------------------------------------------------------------------

  -- Zwei Schalter-Spalten so breit wie die längste Beschriftung, damit sich nichts überlappt
  local function columnWidth()
    local width = MIN_COLUMN_WIDTH
    for _, cell in ipairs(toggleCells) do
      local checkbox = cell.checkbox
      width = math.max(width, checkbox:GetWidth() + Widgets.CHECKBOX_LABEL_GAP + checkbox.label:GetStringWidth() + COLUMN_GAP)
    end
    return width
  end

  local function widestChooserRow()
    local widest = 0
    for _, row in ipairs(chooserRows) do
      local width = row.label:GetStringWidth()
      for _, tab in ipairs(row.tabs) do
        width = width + CHOOSER_TAB_GAP + tab:GetWidth()
      end
      widest = math.max(widest, width)
    end
    return widest
  end

  local function tabRowWidth()
    local width = 0
    for i, entry in ipairs(pages) do
      width = width + entry.tabButton:GetWidth() + (i > 1 and TAB_GAP or 0)
    end
    return width
  end

  -- Beide Button-Spalten sind gleich breit: so breit wie der längste Text, doppelt plus Abstand
  local function footerWidth()
    local widest = 0
    for _, button in ipairs(footerButtons) do
      widest = math.max(widest, button:GetTextWidth() + FOOTER_TEXT_PADDING)
    end
    return 2 * widest + FOOTER_COLUMN_GAP
  end

  -- Fensterbreite aus den Texten der gewählten Sprache; Abschnitte, Regler und Buttons strecken sich mit
  local function fitWidth()
    local column = columnWidth()
    for _, cell in ipairs(toggleCells) do
      cell.checkbox:ClearAllPoints()
      cell.checkbox:SetPoint("TOPLEFT", MARGIN + cell.column * column, cell.y)
    end
    local content = math.max(2 * column, widestChooserRow(), tabRowWidth(), footerWidth())
    panel:SetWidth(math.max(MIN_WIDTH, content + 2 * MARGIN))
  end

  function builder.Refresh(db)
    title:SetText(options.title())
    for _, refreshControl in ipairs(refreshers) do
      refreshControl(db)
    end
    fitWidth()
  end

  return builder
end
