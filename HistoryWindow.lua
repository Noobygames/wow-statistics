-- Historie und Auswertung: Charakter wählen, Reiter "Level | Sessions | Kills | Tode",
-- Tabelle (laufender Eintrag oben hervorgehoben) und Summenzeile darunter.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Format = ns.Format
local Experience = ns.Experience
local Stats = ns.Stats
local History = ns.History
local Journal = ns.Journal

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
local WHITE = { 1, 1, 1 }

---------------------------------------------------------------------------
-- Spalten: header = Locale-Key, value(record) = Zellentext
---------------------------------------------------------------------------
local function counter(record, name)
  return record.counters[name] or 0
end

local function dateTime(timestamp)
  return timestamp and date(L.DATE_FORMAT, timestamp) or ""
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

local function levelColumn(width)
  return { header = "HISTORY_LEVEL", width = width, value = function(r) return r.level or "" end }
end

local function zoneColumn(width)
  return { header = "HISTORY_ZONE", width = width, value = function(r) return r.zone or "" end }
end

local function levelRange(r)
  if not r.startLevel then return "" end
  if r.endLevel and r.endLevel ~= r.startLevel then
    return r.startLevel .. "-" .. r.endLevel
  end
  return r.startLevel
end

-- Todesursache als Text: "Verursacher (Zauber)", Umgebung (z.B. Sturz) oder "Unbekannt"
local function deathCause(r)
  if r.environment then
    return L["CAUSE_" .. string.upper(r.environment)] or r.environment
  end
  if r.killer and r.spell then
    return string.format("%s (%s)", r.killer, r.spell)
  end
  return r.killer or r.spell or L.CAUSE_UNKNOWN
end

local LEVEL_COLUMNS = {
  levelColumn(44),
  durationColumn(62),
  xpRateColumn(52),
  counterColumn("HISTORY_PVE", Stats.PVE_KILLS, 40),
  counterColumn("HISTORY_PVP", Stats.PVP_KILLS, 40),
  counterColumn("HISTORY_DEATHS", Stats.DEATHS, 40),
  counterColumn("HISTORY_QUESTS", Stats.QUESTS, 48),
  goldColumn(56),
}

local SESSION_COLUMNS = {
  { header = "HISTORY_START", width = 80, value = function(r) return dateTime(r.startedAt) end },
  durationColumn(56),
  { header = "HISTORY_LEVEL", width = 44, value = levelRange },
  xpRateColumn(48),
  counterColumn("HISTORY_PVE", Stats.PVE_KILLS, 36),
  counterColumn("HISTORY_PVP", Stats.PVP_KILLS, 36),
  counterColumn("HISTORY_DEATHS", Stats.DEATHS, 40),
  counterColumn("HISTORY_QUESTS", Stats.QUESTS, 44),
  goldColumn(52),
}

local KILL_COLUMNS = {
  { header = "HISTORY_WHEN", width = 80, value = function(r) return dateTime(r.time) end },
  { header = "HISTORY_NAME", width = 140, value = function(r) return r.name or L.UNKNOWN_NAME end },
  { header = "HISTORY_KIND", width = 40, value = function(r)
      return r.kind == Journal.PVP and L.KIND_PVP or L.KIND_PVE
    end },
  levelColumn(40),
  zoneColumn(136),
}

local DEATH_COLUMNS = {
  { header = "HISTORY_WHEN", width = 80, value = function(r) return dateTime(r.time) end },
  { header = "HISTORY_CAUSE", width = 180, value = deathCause },
  levelColumn(40),
  zoneColumn(136),
}

-- Summenzeile für Level und Sessions: Spaltenwerte der Summe, vorne "Gesamt"
local function summaryCells(columns, records)
  local summary = History.Summarize(records)
  local cells = {}
  for i, column in ipairs(columns) do
    cells[i] = column.value(summary)
  end
  cells[1] = L.HISTORY_TOTAL
  return cells
end

-- Summenzeile für Kills und Tode: nur die Anzahl
local function countCells(_, records)
  return { string.format(L.HISTORY_COUNT, #records) }
end

-- Reiter in Anzeigereihenfolge
local VIEWS = {
  { tab = "HISTORY_TAB_LEVELS", columns = LEVEL_COLUMNS, records = History.GetLevelRecords, footer = summaryCells },
  { tab = "HISTORY_TAB_SESSIONS", columns = SESSION_COLUMNS, records = History.GetSessionRecords, footer = summaryCells },
  { tab = "HISTORY_TAB_KILLS", columns = KILL_COLUMNS, records = History.GetKillLog, footer = countCells },
  { tab = "HISTORY_TAB_DEATHS", columns = DEATH_COLUMNS, records = History.GetDeathLog, footer = countCells },
}

local function tableWidth(columns)
  local width = 0
  for _, column in ipairs(columns) do
    width = width + column.width
  end
  return width
end

local widestTable = 0
for _, view in ipairs(VIEWS) do
  widestTable = math.max(widestTable, tableWidth(view.columns))
end

---------------------------------------------------------------------------
-- Fenster
---------------------------------------------------------------------------
local panel = Widgets.CreatePanel("LevelTimerHistory", 0.95)
panel:SetSize(widestTable + 2 * MARGIN + SCROLLBAR_SPACE, -TABLE_TOP + ROW_HEIGHT * (VISIBLE_ROWS + 3) + MARGIN)
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
local selectedView = VIEWS[1]
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
    cell:SetWordWrap(false)
    row.cells[i] = cell
    x = x + column.width
  end
  return row
end

local function fillRow(row, cells, color)
  for i, cell in ipairs(row.cells) do
    cell:SetText(cells[i] or "")
    cell:SetTextColor(unpack(color))
  end
  row:Show()
end

local function recordCells(columns, record)
  local cells = {}
  for i, column in ipairs(columns) do
    cells[i] = column.value(record)
  end
  return cells
end

local function createTable(view)
  local columns = view.columns
  local frame = CreateFrame("Frame", nil, panel)
  frame:SetPoint("TOPLEFT", MARGIN, TABLE_TOP)
  frame:SetPoint("BOTTOMRIGHT", -MARGIN, MARGIN)

  local headerRow = createRow(frame, columns, "GameFontNormalSmall")
  headerRow:SetPoint("TOPLEFT")

  local footerRow = createRow(frame, columns, "GameFontNormalSmall")
  footerRow:SetPoint("BOTTOMLEFT")

  local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
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

  function frame:Render(records)
    for i, column in ipairs(columns) do
      headerRow.cells[i]:SetText(L[column.header])
    end

    for i, record in ipairs(records) do
      local color = record.isCurrent and Widgets.COLORS.highlight or WHITE
      fillRow(getRow(i), recordCells(columns, record), color)
    end
    for i = #records + 1, #rows do
      rows[i]:Hide()
    end
    content:SetHeight(math.max(1, #records) * ROW_HEIGHT)

    fillRow(footerRow, view.footer(columns, records), Widgets.COLORS.highlight)
    self:Show()
  end

  frame:Hide()
  return frame
end

for _, view in ipairs(VIEWS) do
  view.table = createTable(view)
end

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
-- Reiter: einer pro Ansicht, nebeneinander von links
---------------------------------------------------------------------------
local previousTab
for _, view in ipairs(VIEWS) do
  view.tabButton = Widgets.CreateTab(panel, "GameFontNormal", function()
    selectedView = view
    refresh()
  end)
  if previousTab then
    view.tabButton:SetPoint("LEFT", previousTab, "RIGHT", TAB_GAP, 0)
  else
    view.tabButton:SetPoint("TOPLEFT", MARGIN, TABS_TOP)
  end
  previousTab = view.tabButton
end

---------------------------------------------------------------------------
-- Aufbau
---------------------------------------------------------------------------
function refresh()
  if not History.GetCharacter(selectedCharacter or "") then
    selectedCharacter = ns.characterKey
  end

  header:SetText(L.HISTORY)
  showCharacterName(History.GetCharacter(selectedCharacter))

  for _, view in ipairs(VIEWS) do
    view.tabButton:SetLabel(L[view.tab])
    view.tabButton:SetActive(view == selectedView)
    if view == selectedView then
      view.table:Render(view.records(selectedCharacter))
    else
      view.table:Hide()
    end
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
