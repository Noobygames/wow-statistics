-- Historie und Auswertung: Charakter wählen, Reiter "Level | Sessions",
-- Tabelle (laufender Eintrag oben hervorgehoben) und Summenzeile darunter.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Format = ns.Format
local Experience = ns.Experience
local Stats = ns.Stats
local History = ns.History

local MARGIN = 16
local HEADER_TOP = -14
local CHARACTER_ROW_TOP = -40
local TABS_TOP = -66
local TABLE_TOP = -90
local ROW_HEIGHT = 16
local CELL_GAP = 6
local VISIBLE_ROWS = 14
local SCROLLBAR_SPACE = 26
local ARROW_SIZE = 22
local TAB_GAP = 12
local UPDATE_INTERVAL = 1  -- Sekunden; hält laufende Einträge aktuell

local LEVEL_VIEW = "level"
local SESSION_VIEW = "session"

---------------------------------------------------------------------------
-- Spalten. value(record) bekommt einen Historien-Eintrag oder die Summe aus
-- History.Summarize (ohne Level/Datum, daher "or ''").
---------------------------------------------------------------------------
local function counter(record, name)
  return record.counters[name] or 0
end

local function durationColumn(width)
  return { header = "HISTORY_TIME", width = width, value = function(r)
    return r.seconds and Format.Duration(r.seconds) or "?"
  end }
end

local function xpRateColumn(width)
  return { header = "HISTORY_XP_RATE", width = width, value = function(r)
    local rate = Experience.CalculateRate(r.xp, r.seconds)
    return rate and Format.Number(rate) or "-"
  end }
end

local function counterColumn(header, name, width)
  return { header = header, width = width, value = function(r) return counter(r, name) end }
end

local function goldColumn(width)
  return { header = "HISTORY_GOLD", width = width, value = function(r)
    return Format.Gold(counter(r, Stats.MONEY_EARNED))
  end }
end

local LEVEL_COLUMNS = {
  { header = "HISTORY_LEVEL", width = 44, value = function(r) return r.level or "" end },
  durationColumn(62),
  xpRateColumn(52),
  counterColumn("HISTORY_PVE", Stats.PVE_KILLS, 40),
  counterColumn("HISTORY_PVP", Stats.PVP_KILLS, 40),
  counterColumn("HISTORY_DEATHS", Stats.DEATHS, 40),
  counterColumn("HISTORY_QUESTS", Stats.QUESTS, 48),
  goldColumn(56),
}

local function levelRange(r)
  if not r.startLevel then return "" end
  if r.endLevel and r.endLevel ~= r.startLevel then
    return r.startLevel .. "-" .. r.endLevel
  end
  return r.startLevel
end

local SESSION_COLUMNS = {
  { header = "HISTORY_START", width = 80, value = function(r)
      return r.startedAt and date(L.DATE_FORMAT, r.startedAt) or ""
    end },
  durationColumn(56),
  { header = "HISTORY_LEVEL", width = 44, value = levelRange },
  xpRateColumn(48),
  counterColumn("HISTORY_PVE", Stats.PVE_KILLS, 36),
  counterColumn("HISTORY_PVP", Stats.PVP_KILLS, 36),
  counterColumn("HISTORY_DEATHS", Stats.DEATHS, 40),
  counterColumn("HISTORY_QUESTS", Stats.QUESTS, 44),
  goldColumn(52),
}

local function tableWidth(columns)
  local width = 0
  for _, column in ipairs(columns) do
    width = width + column.width
  end
  return width
end

local PANEL_WIDTH = math.max(tableWidth(LEVEL_COLUMNS), tableWidth(SESSION_COLUMNS)) + 2 * MARGIN + SCROLLBAR_SPACE
local PANEL_HEIGHT = -TABLE_TOP + ROW_HEIGHT * (VISIBLE_ROWS + 3) + MARGIN

---------------------------------------------------------------------------
-- Fenster
---------------------------------------------------------------------------
local panel = Widgets.CreatePanel("LevelTimerHistory", 0.95)
panel:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
panel:SetPoint("CENTER")
panel:SetFrameStrata("DIALOG")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
panel:Hide()
table.insert(UISpecialFrames, "LevelTimerHistory")  -- mit ESC schließen

local closeButton = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -2, -2)

local header = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
header:SetPoint("TOP", 0, HEADER_TOP)

local selectedCharacter  -- Schlüssel "Name-Realm"; nil = eingeloggter Charakter
local selectedView = LEVEL_VIEW
local refresh            -- unten definiert

---------------------------------------------------------------------------
-- Tabelle: Kopfzeile, scrollbare Zeilen, Summenzeile
---------------------------------------------------------------------------
local function createRow(parent, columns, fontObject)
  local row = CreateFrame("Frame", nil, parent)
  row:SetSize(tableWidth(columns), ROW_HEIGHT)
  row.cells = {}
  local x = 0
  for i, column in ipairs(columns) do
    local cell = row:CreateFontString(nil, "OVERLAY", fontObject)
    cell:SetPoint("LEFT", x, 0)
    cell:SetWidth(column.width - CELL_GAP)
    cell:SetJustifyH(i == 1 and "LEFT" or "RIGHT")
    row.cells[i] = cell
    x = x + column.width
  end
  return row
end

local function fillRow(row, columns, record, color)
  for i, column in ipairs(columns) do
    row.cells[i]:SetText(column.value(record))
    row.cells[i]:SetTextColor(unpack(color))
  end
  row:Show()
end

local function createTable(columns)
  local view = CreateFrame("Frame", nil, panel)
  view:SetPoint("TOPLEFT", MARGIN, TABLE_TOP)
  view:SetPoint("BOTTOMRIGHT", -MARGIN, MARGIN)

  local headerRow = createRow(view, columns, "GameFontNormalSmall")
  headerRow:SetPoint("TOPLEFT")

  local footerRow = createRow(view, columns, "GameFontNormalSmall")
  footerRow:SetPoint("BOTTOMLEFT")

  local scrollFrame = CreateFrame("ScrollFrame", nil, view, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 0, -ROW_HEIGHT)
  scrollFrame:SetPoint("BOTTOMRIGHT", -SCROLLBAR_SPACE, ROW_HEIGHT + 4)

  local content = CreateFrame("Frame", nil, scrollFrame)
  content:SetSize(tableWidth(columns), ROW_HEIGHT)
  scrollFrame:SetScrollChild(content)

  local rows = {}  -- werden bei Bedarf angelegt und wiederverwendet

  local function getRow(index)
    if not rows[index] then
      rows[index] = createRow(content, columns, "GameFontHighlightSmall")
      rows[index]:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
    end
    return rows[index]
  end

  function view:Render(records)
    for i, column in ipairs(columns) do
      headerRow.cells[i]:SetText(L[column.header])
    end

    for i, record in ipairs(records) do
      local color = record.isCurrent and Widgets.COLORS.highlight or { 1, 1, 1 }
      fillRow(getRow(i), columns, record, color)
    end
    for i = #records + 1, #rows do
      rows[i]:Hide()
    end
    content:SetHeight(math.max(1, #records) * ROW_HEIGHT)

    fillRow(footerRow, columns, History.Summarize(records), Widgets.COLORS.highlight)
    footerRow.cells[1]:SetText(L.HISTORY_TOTAL)
    self:Show()
  end

  view:Hide()
  return view
end

local views = {
  [LEVEL_VIEW] = createTable(LEVEL_COLUMNS),
  [SESSION_VIEW] = createTable(SESSION_COLUMNS),
}

---------------------------------------------------------------------------
-- Charakter-Auswahl: Pfeile blättern durch alle gespeicherten Charaktere
---------------------------------------------------------------------------
local characterName = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
characterName:SetPoint("TOP", 0, CHARACTER_ROW_TOP)

local function stepCharacter(step)
  local keys = History.GetCharacterKeys()
  local index = 1
  for i, key in ipairs(keys) do
    if key == selectedCharacter then index = i end
  end
  selectedCharacter = keys[(index - 1 + step) % #keys + 1]
  refresh()
end

local previousButton = Widgets.CreateButton(panel, ARROW_SIZE, ARROW_SIZE, function() stepCharacter(-1) end)
previousButton:SetText("<")
previousButton:SetPoint("TOPLEFT", MARGIN, CHARACTER_ROW_TOP + 4)

local nextButton = Widgets.CreateButton(panel, ARROW_SIZE, ARROW_SIZE, function() stepCharacter(1) end)
nextButton:SetText(">")
nextButton:SetPoint("TOPRIGHT", -MARGIN, CHARACTER_ROW_TOP + 4)

local function showCharacterName(character)
  characterName:SetText(string.format(L.HISTORY_CHARACTER, character.name or "?", character.realm or "?",
    character.currentLevel.level))
  local classColor = RAID_CLASS_COLORS and character.class and RAID_CLASS_COLORS[character.class]
  if classColor then
    characterName:SetTextColor(classColor.r, classColor.g, classColor.b)
  else
    characterName:SetTextColor(1, 1, 1)
  end
end

---------------------------------------------------------------------------
-- Reiter Level | Sessions
---------------------------------------------------------------------------
local levelTab = Widgets.CreateTab(panel, "GameFontNormal", function()
  selectedView = LEVEL_VIEW
  refresh()
end)
levelTab:SetPoint("TOPRIGHT", panel, "TOP", -TAB_GAP / 2, TABS_TOP)

local sessionTab = Widgets.CreateTab(panel, "GameFontNormal", function()
  selectedView = SESSION_VIEW
  refresh()
end)
sessionTab:SetPoint("TOPLEFT", panel, "TOP", TAB_GAP / 2, TABS_TOP)

---------------------------------------------------------------------------
-- Aufbau
---------------------------------------------------------------------------
function refresh()
  if not History.GetCharacter(selectedCharacter or "") then
    selectedCharacter = ns.characterKey
  end

  header:SetText(L.HISTORY)
  showCharacterName(History.GetCharacter(selectedCharacter))

  levelTab:SetLabel(L.HISTORY_TAB_LEVELS)
  levelTab:SetActive(selectedView == LEVEL_VIEW)
  sessionTab:SetLabel(L.HISTORY_TAB_SESSIONS)
  sessionTab:SetActive(selectedView == SESSION_VIEW)

  local records
  if selectedView == LEVEL_VIEW then
    records = History.GetLevelRecords(selectedCharacter)
  else
    records = History.GetSessionRecords(selectedCharacter)
  end
  for name, view in pairs(views) do
    if name == selectedView then view:Render(records) else view:Hide() end
  end
end

local sinceUpdate = 0
panel:SetScript("OnUpdate", function(_, elapsed)
  sinceUpdate = sinceUpdate + elapsed
  if sinceUpdate < UPDATE_INTERVAL then return end
  sinceUpdate = 0
  refresh()
end)

-- Sprachwechsel bei offenem Fenster
ns.RegisterApply(function()
  if panel:IsShown() then refresh() end
end)

function ns.ToggleHistory()
  if not ns.db then return end
  if panel:IsShown() then
    panel:Hide()
  else
    refresh()
    panel:Show()
  end
end
