-- Tabelle der Level-Historie: laufendes Level oben (hervorgehoben), darunter abgeschlossene Level.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Format = ns.Format
local Experience = ns.Experience
local LevelStats = ns.LevelStats

local MARGIN = 16
local HEADER_TOP = -40
local ROW_HEIGHT = 16
local CELL_GAP = 6
local VISIBLE_ROWS = 15
local SCROLLBAR_SPACE = 26
local UPDATE_INTERVAL = 1  -- Sekunden; hält die Zeile des laufenden Levels aktuell

local function counter(record, name)
  return record.counters[name] or 0
end

-- Spalten: header = Locale-Key, value = Zellentext aus einem Historien-Eintrag
local COLUMNS = {
  { header = "HISTORY_LEVEL", width = 40, value = function(r) return r.level end },
  { header = "HISTORY_TIME", width = 62, value = function(r)
      return r.seconds and Format.Duration(r.seconds) or "?"
    end },
  { header = "HISTORY_XP_RATE", width = 52, value = function(r)
      local rate = Experience.CalculateRate(r.xp, r.seconds)
      return rate and Format.Number(rate) or "-"
    end },
  { header = "HISTORY_PVE", width = 40, value = function(r) return counter(r, LevelStats.PVE_KILLS) end },
  { header = "HISTORY_PVP", width = 40, value = function(r) return counter(r, LevelStats.PVP_KILLS) end },
  { header = "HISTORY_DEATHS", width = 40, value = function(r) return counter(r, LevelStats.DEATHS) end },
  { header = "HISTORY_QUESTS", width = 48, value = function(r) return counter(r, LevelStats.QUESTS) end },
  { header = "HISTORY_GOLD", width = 56, value = function(r)
      return Format.Gold(counter(r, LevelStats.MONEY_EARNED))
    end },
}

local tableWidth = 0
for _, column in ipairs(COLUMNS) do
  tableWidth = tableWidth + column.width
end

local panel = Widgets.CreatePanel("LevelTimerHistory", 0.95)
panel:SetSize(tableWidth + 2 * MARGIN + SCROLLBAR_SPACE,
  -HEADER_TOP + ROW_HEIGHT * (VISIBLE_ROWS + 1) + MARGIN)
panel:SetPoint("CENTER")
panel:SetFrameStrata("DIALOG")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
panel:Hide()
table.insert(UISpecialFrames, "LevelTimerHistory")  -- mit ESC schließen

local closeButton = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -2, -2)

local header = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
header:SetPoint("TOP", 0, -14)

-- Eine Tabellenzeile: Zellen nebeneinander, Zahlen rechtsbündig
local function createRow(parent, fontObject)
  local row = CreateFrame("Frame", nil, parent)
  row:SetSize(tableWidth, ROW_HEIGHT)
  row.cells = {}
  local x = 0
  for i, column in ipairs(COLUMNS) do
    local cell = row:CreateFontString(nil, "OVERLAY", fontObject)
    cell:SetPoint("LEFT", x, 0)
    cell:SetWidth(column.width - CELL_GAP)
    cell:SetJustifyH(i == 1 and "LEFT" or "RIGHT")
    row.cells[i] = cell
    x = x + column.width
  end
  return row
end

local headerRow = createRow(panel, "GameFontNormalSmall")
headerRow:SetPoint("TOPLEFT", MARGIN, HEADER_TOP)

local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", MARGIN, HEADER_TOP - ROW_HEIGHT)
scrollFrame:SetPoint("BOTTOMRIGHT", -MARGIN - SCROLLBAR_SPACE, MARGIN)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(tableWidth, ROW_HEIGHT)
scrollFrame:SetScrollChild(content)

-- Zeilen werden bei Bedarf angelegt und wiederverwendet
local rows = {}

local function getRow(index)
  if not rows[index] then
    local row = createRow(content, "GameFontHighlightSmall")
    row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
    rows[index] = row
  end
  return rows[index]
end

local function fillRow(row, record)
  local r, g, b = 1, 1, 1
  if record.isCurrent then
    r, g, b = unpack(Widgets.COLORS.highlight)
  end
  for i, column in ipairs(COLUMNS) do
    row.cells[i]:SetText(column.value(record))
    row.cells[i]:SetTextColor(r, g, b)
  end
  row:Show()
end

local function refresh()
  header:SetText(L.HISTORY)
  for i, column in ipairs(COLUMNS) do
    headerRow.cells[i]:SetText(L[column.header])
  end

  local records = ns.LevelHistory.GetRecords()
  for i, record in ipairs(records) do
    fillRow(getRow(i), record)
  end
  for i = #records + 1, #rows do
    rows[i]:Hide()
  end
  content:SetHeight(#records * ROW_HEIGHT)
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
