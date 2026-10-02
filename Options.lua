-- Einstellungsfenster mit Reitern: Allgemein (Fenster, Sprache), Statistiken, Hinweise, Stream, Speedrun, Profile.
-- Darunter auf allen Reitern: Neue Session, Zusammenfassung, Historie.
-- Jedes Steuerelement registriert eine refresh(db)-Funktion; nach jeder Änderung
-- (ns.Set/ns.ApplySettings) zeigen alle den aktuellen Stand und die gewählte Sprache.
-- Schalter mit available() == false (z.B. nur in WoW Forever) werden gar nicht angelegt.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local TimerWindow = ns.TimerWindow

local MIN_WIDTH = 320
local MARGIN = 16
local TABS_TOP = -42
local TAB_GAP = 12
local CONTENT_TOP = -70
local FOOTER_GAP = 8         -- Abstand zwischen Reiterinhalt und den Buttons unten
local MIN_COLUMN_WIDTH = 144
local COLUMN_GAP = 12        -- Mindestabstand zwischen einer Beschriftung und der rechten Spalte
local ROW_SECTION = 24
local ROW_CHECKBOX = 26
local ROW_SLIDER = 44
local ROW_BUTTON = 30
local ROW_CHOOSER = 26
local ROW_HINT = 30
local SECTION_GAP = 8
local BUTTON_HEIGHT = 22
local CHOOSER_TAB_GAP = 10
local MAX_PROFILE_ROWS = 6     -- so viele Profile listet der Reiter "Profile"
local ROW_PROFILE = 20
local PROFILE_NAME_WIDTH = 160
local PROFILE_SAVE_WIDTH = 120
local DELETE_PROFILE_POPUP = "LEVELTIMER_DELETE_PROFILE"

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

local refreshers = {}
local toggleCells = {}    -- { checkbox, column, y } aller Schalter; Spaltenbreite setzt fitWidth
local chooserRows = {}    -- { label, tabs } je Auswahlzeile (Sprache, Hintergrund, ...); Breite prüft fitWidth

local function onRefresh(refresh)
  table.insert(refreshers, refresh)
end

---------------------------------------------------------------------------
-- Reiter: je Reiter eine Seite über das ganze Fenster; Steuerelemente hängen an ihrer Seite
---------------------------------------------------------------------------
local pages = {}          -- { key, tabButton, frame, bottom } in Reihenfolge
local page                -- Seite, auf der die Bausteine gerade anlegen
local nextRowY = CONTENT_TOP

local function showPage(selected)
  for _, entry in ipairs(pages) do
    entry.frame:SetShown(entry == selected)
    entry.tabButton:SetActive(entry == selected)
  end
end

-- Neue Seite beginnen; folgende add*-Aufrufe landen darauf
local function addPage(labelKey)
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
local function finishPage()
  pages[#pages].bottom = nextRowY
end

---------------------------------------------------------------------------
-- Bausteine: legen Steuerelemente auf der aktuellen Seite von oben nach unten an
---------------------------------------------------------------------------
local function addRow(widget, height, stretch)
  widget:SetPoint("TOPLEFT", MARGIN, nextRowY)
  if stretch then widget:SetPoint("TOPRIGHT", -MARGIN, nextRowY) end
  nextRowY = nextRowY - height
end

local function addSection(labelKey)
  if nextRowY ~= CONTENT_TOP then nextRowY = nextRowY - SECTION_GAP end
  local header = Widgets.CreateSectionHeader(page)
  addRow(header, ROW_SECTION, true)
  onRefresh(function() header:SetText(L[labelKey]) end)
end

-- slider = { label, min, max, step, get(db) -> Wert, set(Wert), format(Wert) -> Anzeigetext }
local function addSlider(slider)
  local control = Widgets.CreateSlider(page, slider.min, slider.max, slider.step, slider.set)
  addRow(control, ROW_SLIDER, true)
  onRefresh(function(db)
    local value = slider.get(db)
    control.label:SetText(L[slider.label])
    control:SetValueSilently(value, slider.format(value))
  end)
end

-- Checkboxen in zwei Spalten; toggle = { label, get(db) -> bool, set(checked), available() optional,
--   text() optional statt L[label], z.B. für Beschriftungen mit Werten }
local function addToggles(allToggles)
  local toggles = {}
  for _, toggle in ipairs(allToggles) do
    if not toggle.available or toggle.available() then table.insert(toggles, toggle) end
  end
  for i, toggle in ipairs(toggles) do
    local column = (i - 1) % 2
    local row = math.floor((i - 1) / 2)
    local checkbox = Widgets.CreateCheckbox(page, toggle.set)
    table.insert(toggleCells, { checkbox = checkbox, column = column, y = nextRowY - row * ROW_CHECKBOX })
    onRefresh(function(db)
      checkbox.label:SetText(toggle.text and toggle.text() or L[toggle.label])
      checkbox:SetChecked(toggle.get(db))
    end)
  end
  nextRowY = nextRowY - math.ceil(#toggles / 2) * ROW_CHECKBOX
end

local function addButton(labelKey, onClick)
  local button = Widgets.CreateButton(page, MIN_WIDTH - 2 * MARGIN, BUTTON_HEIGHT, onClick)
  addRow(button, ROW_BUTTON, true)
  onRefresh(function() button:SetText(L[labelKey]) end)
end

-- Buttons unten auf allen Reitern, von unten nach oben
local footerButtons = 0
local function addFooterButton(labelKey, onClick)
  local button = Widgets.CreateButton(panel, MIN_WIDTH - 2 * MARGIN, BUTTON_HEIGHT, onClick)
  local y = MARGIN + footerButtons * ROW_BUTTON
  button:SetPoint("BOTTOMLEFT", MARGIN, y)
  button:SetPoint("BOTTOMRIGHT", -MARGIN, y)
  footerButtons = footerButtons + 1
  onRefresh(function() button:SetText(L[labelKey]) end)
end

-- Auswahl als Zeile von Reitern: chooser = { label = Locale-Key, setting, choices = { { value, name() }, ... } }
local function addChooser(chooser)
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
    onRefresh(function(db)
      tab:SetLabel(choice.name())
      tab:SetActive(db[chooser.setting] == choice.value)
    end)
  end
  nextRowY = nextRowY - ROW_CHOOSER
  onRefresh(function() label:SetText(L[chooser.label]) end)
end

local function localized(key)
  return function() return L[key] end
end

-- Sprachnamen stehen immer in der eigenen Sprache
local function addLanguageChooser()
  local choices = {}
  for i, language in ipairs(ns.languages) do
    choices[i] = { value = language.code, name = function() return language.name end }
  end
  addChooser({ label = "LANGUAGE", setting = "language", choices = choices })
end

-- Vergleich der Splits; ein fester Charakter wird per /lt compare Name gewählt
local function addSplitComparisonChooser()
  local Splits = ns.Splits
  addChooser({ label = "SPLIT_COMPARISON", setting = "splitComparison", choices = {
    { value = Splits.BEST, name = localized("COMPARE_CHOICE_BEST") },
    { value = Splits.PERSONAL_BEST, name = localized("COMPARE_CHOICE_PB") },
    { value = Splits.RUN, name = localized("COMPARE_CHOICE_RUN") },
  } })
end

-- Speedrun-Rekorde: schnellster Lauf insgesamt oder der eigenen Klasse
local function addWorldRecordScopeChooser()
  local WorldRecords = ns.WorldRecords
  addChooser({ label = "WORLD_RECORD_SCOPE", setting = "worldRecordScope", choices = {
    { value = WorldRecords.CLASS, name = localized("WORLD_RECORD_OWN_CLASS") },
    { value = WorldRecords.OVERALL, name = localized("WORLD_RECORD_ALL_CLASSES") },
  } })
end

-- Level-Up-Ansage: aus, Gruppe oder Gilde
local function addAnnounceChooser()
  local Summary = ns.LevelUpSummary
  addChooser({ label = "LEVEL_UP_ANNOUNCE", setting = "levelUpAnnounce", choices = {
    { value = Summary.ANNOUNCE_OFF, name = localized("ANNOUNCE_OFF") },
    { value = Summary.ANNOUNCE_PARTY, name = localized("ANNOUNCE_PARTY") },
    { value = Summary.ANNOUNCE_GUILD, name = localized("ANNOUNCE_GUILD") },
    { value = Summary.ANNOUNCE_SAY, name = localized("ANNOUNCE_SAY") },
  } })
end

-- Hintergrund des Fensters: Standard oder Chroma-Farbe für Streams
local function addBackgroundChooser()
  addChooser({ label = "WINDOW_BACKGROUND", setting = "windowBackground", choices = {
    { value = TimerWindow.BACKGROUND_DEFAULT, name = localized("BACKGROUND_DEFAULT") },
    { value = "green", name = localized("BACKGROUND_GREEN") },
    { value = "magenta", name = localized("BACKGROUND_MAGENTA") },
  } })
end

local function addHint(labelKey)
  local hint = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetJustifyH("LEFT")
  addRow(hint, ROW_HINT, true)
  onRefresh(function() hint:SetText(L[labelKey]) end)
end

-- Profile: Liste (Klick wechselt, Rechtsklick löscht), Name + Speichern, Export und Import
StaticPopupDialogs[DELETE_PROFILE_POPUP] = {
  button1 = YES or "Yes",
  button2 = NO or "No",
  OnAccept = function(_, name)
    ns.Profiles.Delete(name)
    ns.ApplySettings()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

local function addProfileList()
  local Profiles = ns.Profiles
  for index = 1, MAX_PROFILE_ROWS do
    local tab = Widgets.CreateTab(page, "GameFontHighlight", function(self, mouseButton)
      local name = self.profileName
      if mouseButton == "RightButton" then
        StaticPopupDialogs[DELETE_PROFILE_POPUP].text = L.PROFILE_DELETE_CONFIRM
        StaticPopup_Show(DELETE_PROFILE_POPUP, Profiles.DisplayName(name), nil, name)
      else
        Profiles.Switch(name)
      end
    end)
    tab:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    addRow(tab, ROW_PROFILE)
    onRefresh(function()
      local name = Profiles.GetNames()[index]
      tab.profileName = name
      tab:SetShown(name ~= nil)
      if name then
        tab:SetLabel(Profiles.DisplayName(name))
        tab:SetActive(name == Profiles.GetActive())
      end
    end)
  end
end

-- Import-Fenster für Profile (auch /lt profile import); das neue Profil wird nicht sofort aktiv
function ns.ShowProfileImport()
  ns.Export.ShowImport(L.PROFILE_IMPORT, function(text)
    local name = ns.Profiles.Import(text)
    if not name then return L.PROFILE_IMPORT_INVALID, false end
    ns.ApplySettings()
    return string.format(L.PROFILE_IMPORTED, name), true
  end)
end

local function addProfileSaver()
  local nameBox = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
  nameBox:SetSize(PROFILE_NAME_WIDTH, BUTTON_HEIGHT)
  nameBox:SetAutoFocus(false)
  nameBox:SetPoint("TOPLEFT", MARGIN + 6, nextRowY)  -- Vorlage zeichnet ihren Rand links außerhalb
  local saveButton = Widgets.CreateButton(page, PROFILE_SAVE_WIDTH, BUTTON_HEIGHT, function()
    if ns.Profiles.SaveAs(nameBox:GetText()) then
      ns.Print(string.format(L.PROFILE_SAVED, nameBox:GetText()))
      nameBox:SetText("")
      ns.ApplySettings()
    end
  end)
  saveButton:SetPoint("LEFT", nameBox, "RIGHT", CHOOSER_TAB_GAP, 0)
  nameBox:SetScript("OnEnterPressed", function() saveButton:Click() end)
  nameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  nextRowY = nextRowY - ROW_BUTTON
  onRefresh(function() saveButton:SetText(L.PROFILE_SAVE) end)
end

local function percent(value)
  return value .. "%"
end

local function toPercent(fraction)
  return math.floor(fraction * 100 + 0.5)
end

-- Schalter für eine Einstellung in ns.db; available() optional (z.B. nur in WoW Forever)
local function toggle(label, key, available)
  return {
    label = label,
    get = function(db) return db[key] end,
    set = function(checked) ns.Set(key, checked) end,
    available = available,
  }
end

---------------------------------------------------------------------------
-- Inhalt
---------------------------------------------------------------------------

-- Allgemein: Fenster und grundlegende Einstellungen
addPage("SECTION_GENERAL")
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
  toggle("SHOW_TIMER", "showTimer"),
  toggle("LOCK_FRAME", "locked"),
  toggle("SHOW_XP_BAR", "showXpBar"),
  toggle("COMPACT_MODE", "compactMode"),
  toggle("HORIZONTAL_LAYOUT", "horizontalLayout"),
})
addButton("RESET_WINDOW", function() TimerWindow.ResetLayout() end)
addHint("OPTIONS_HINT")
addSection("SECTION_GENERAL")
addLanguageChooser()
addToggles({
  { label = "SHOW_MINIMAP", get = function(db) return not db.minimap.hide end,
    set = function(checked) ns.SetMinimapHidden(not checked) end },
})
finishPage()

-- Statistiken: ein Schalter je Stat-Zeile, direkt aus ns.STAT_LINES
addPage("STATISTICS")
addSection("STATISTICS")
local statToggles = {}
for i, line in ipairs(ns.STAT_LINES) do
  statToggles[i] = toggle(line.label, line.setting)
end
addToggles(statToggles)
finishPage()

-- Hinweise: Level-Up im Chat und Erinnerungen an Buffs
addPage("OPTIONS_TAB_NOTIFICATIONS")
addSection("SECTION_LEVEL_UP")
addToggles({ toggle("LEVEL_UP_SUMMARY_TOGGLE", "levelUpSummary") })
addAnnounceChooser()
addSection("SECTION_REMINDERS")
addToggles({
  toggle("REMIND_FOOD_TOGGLE", "remindFood"),
  toggle("REMIND_CAMP_TOGGLE", "remindCamp", ns.BuffReminder.HasCampSystem),
})
addSlider({
  label = "REMINDER_INTERVAL",
  min = ns.BuffReminder.MIN_INTERVAL,
  max = ns.BuffReminder.MAX_INTERVAL,
  step = 1,
  get = function(db) return db.reminderInterval end,
  set = function(value) ns.Set("reminderInterval", value) end,
  format = function(value) return string.format(L.MINUTES, value) end,
})
finishPage()

-- Stream: alles, was nur für Streams gedacht ist (Speedrun hat einen eigenen Reiter)
addPage("OPTIONS_TAB_STREAM")
addSection("SECTION_STREAM")
addToggles({
  { label = "STREAM_MODE", get = function() return ns.StreamMode.IsEnabled() end,
    set = function(checked) ns.StreamMode.SetEnabled(checked) end },
  toggle("STREAMER_PRIVACY", "streamerPrivacy"),
  toggle("HIGHLIGHT_DEATHS", "highlightDeaths"),
})
addBackgroundChooser()
addSection("SECTION_ALERTS")
addToggles({
  toggle("ALERT_TOGGLE_LEVEL_UP", "alertLevelUp"),
  toggle("ALERT_TOGGLE_RARE", "alertRareKill"),
  toggle("ALERT_TOGGLE_ELITE", "alertEliteKill"),
  toggle("ALERT_TOGGLE_LOOT", "alertEpicLoot"),
  toggle("ALERT_TOGGLE_NEAR_DEATH", "alertNearDeath"),
})
finishPage()

-- Speedrun: Splits, Split-Liste und Speedrun-Rekorde
addPage("OPTIONS_TAB_SPEEDRUN")
addSection("SECTION_SPLIT_LIST")
addToggles({
  toggle("SHOW_SPLIT_LIST", "showSplitList"),
  toggle("SHOW_SPLIT_TOTAL", "splitListShowTotal"),
  toggle("SHOW_SPLIT_PLAYED", "splitListShowPlayed"),
})
addSplitComparisonChooser()
addSlider({
  label = "SPLIT_LIST_SIZE",
  min = toPercent(TimerWindow.MIN_SCALE),
  max = toPercent(TimerWindow.MAX_SCALE),
  step = 5,
  get = function(db) return toPercent(ns.SplitList.GetScale(db)) end,
  set = function(value) ns.Set("splitListScale", value / 100) end,
  format = percent,
})
addSlider({
  label = "SPLIT_LIST_ROWS",
  min = ns.SplitList.MIN_ROWS,
  max = ns.SplitList.MAX_ROWS,
  step = 1,
  get = function(db) return db.splitListRows end,
  set = function(value) ns.Set("splitListRows", value) end,
  format = tostring,
})
addSection("SECTION_WORLD_RECORDS")
local recordToggles = {
  toggle("SHOW_WORLD_RECORDS", "showWorldRecords"),
  toggle("SHOW_RECORDS_AGE", "showRecordsAge"),
}
-- Ein Schalter je Abschnitt der Rekord-Daten (1-10, 1-20, ...)
for _, label in ipairs(ns.WorldRecords.GetBracketLabels()) do
  table.insert(recordToggles, {
    text = function() return string.format(L.WORLD_RECORD_ROW, label) end,
    get = function(db) return db.recordBrackets[label] ~= false end,
    set = function(checked)
      ns.db.recordBrackets[label] = checked
      ns.ApplySettings()
    end,
  })
end
addToggles(recordToggles)
addWorldRecordScopeChooser()
finishPage()

-- Profile: Einstellungen benannt speichern, je Charakter wählen, als Text teilen
addPage("OPTIONS_TAB_PROFILES")
addSection("SECTION_PROFILES")
addProfileList()
addProfileSaver()
addButton("PROFILE_EXPORT", function()
  local Profiles = ns.Profiles
  ns.Export.Show(Profiles.DisplayName(Profiles.GetActive()), Profiles.Export(Profiles.GetActive()))
end)
addButton("PROFILE_IMPORT", function() ns.ShowProfileImport() end)
addHint("PROFILE_HINT")
finishPage()

addFooterButton("HISTORY", function() ns.ToggleHistory() end)
addFooterButton("RECAP_TITLE", function() ns.ToggleRecap() end)
addFooterButton("NEW_SESSION", function() ns.StartNewSession() end)

-- Höhe für die längste Seite, damit das Fenster beim Reiterwechsel nicht springt
local lowestBottom = CONTENT_TOP
for _, entry in ipairs(pages) do
  lowestBottom = math.min(lowestBottom, entry.bottom)
end
panel:SetHeight(-lowestBottom + FOOTER_GAP + footerButtons * ROW_BUTTON + MARGIN)
showPage(pages[1])

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

-- Fensterbreite aus den Texten der gewählten Sprache; Abschnitte, Regler und Buttons strecken sich mit
local function fitWidth()
  local column = columnWidth()
  for _, cell in ipairs(toggleCells) do
    cell.checkbox:ClearAllPoints()
    cell.checkbox:SetPoint("TOPLEFT", MARGIN + cell.column * column, cell.y)
  end
  local content = math.max(2 * column, widestChooserRow(), tabRowWidth())
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
