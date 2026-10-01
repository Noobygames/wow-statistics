-- Tabellen der Historie: Level, Timeline, Sessions, Kills, Tode.
-- Lazy Load: Es gibt nur so viele Zeilen-Widgets, wie sichtbar sind; beim Scrollen
-- (Mausrad oder Leiste) werden sie mit den passenden Einträgen neu gefüllt.
-- So bleiben auch tausende Journal-Einträge flüssig.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Format = ns.Format
local Experience = ns.Experience
local Stats = ns.Stats
local History = ns.History
local Journal = ns.Journal

local ROW_HEIGHT = 16
local CELL_GAP = 6
local SCROLLBAR_GAP = 6
local WHEEL_STEP = 3  -- Zeilen pro Mausrad-Raste
local WHITE = { 1, 1, 1 }
local LEFT, RIGHT = "LEFT", "RIGHT"

---------------------------------------------------------------------------
-- Spalten: header = Locale-Key, value(record) = Zellentext, align = LEFT für Text
-- (Standard: erste Spalte links, Zahlen rechts)
---------------------------------------------------------------------------
local function counter(record, name)
  return record.counters[name] or 0
end

local function dateTime(format, timestamp)
  return timestamp and date(format, timestamp) or ""
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
  return { header = "HISTORY_ZONE", width = width, align = LEFT, value = function(r) return r.zone or "" end }
end

local function whenColumn(width)
  return { header = "HISTORY_WHEN", width = width, value = function(r)
    return dateTime(L.DATE_TIME_FORMAT, r.time)
  end }
end

local function levelRange(r)
  if not r.startLevel then return "" end
  if r.endLevel and r.endLevel ~= r.startLevel then
    return r.startLevel .. "-" .. r.endLevel
  end
  return r.startLevel
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
  { header = "HISTORY_START", width = 80, value = function(r) return dateTime(L.DATE_FORMAT, r.startedAt) end },
  durationColumn(56),
  { header = "HISTORY_LEVEL", width = 44, value = levelRange },
  xpRateColumn(48),
  counterColumn("HISTORY_PVE", Stats.PVE_KILLS, 36),
  counterColumn("HISTORY_PVP", Stats.PVP_KILLS, 36),
  counterColumn("HISTORY_DEATHS", Stats.DEATHS, 40),
  counterColumn("HISTORY_QUESTS", Stats.QUESTS, 44),
  goldColumn(52),
}

local MILESTONE_COLUMNS = {
  { header = "HISTORY_REACHED_LEVEL", width = 60, value = function(r) return r.reachedLevel end },
  { header = "HISTORY_REACHED", width = 100, value = function(r) return dateTime(L.DATE_FORMAT, r.reachedAt) end },
  { header = "HISTORY_TOTAL_PLAYED", width = 90, value = function(r)
      return r.totalPlayed and Format.Duration(r.totalPlayed) or "?"
    end },
  { header = "HISTORY_LEVEL_DURATION", width = 80, value = function(r)
      return r.seconds and Format.Duration(r.seconds) or "?"
    end },
}

local KILL_COLUMNS = {
  whenColumn(100),
  { header = "HISTORY_NAME", width = 140, align = LEFT, value = function(r) return r.name or L.UNKNOWN_NAME end },
  { header = "HISTORY_KIND", width = 40, value = function(r)
      return r.kind == Journal.PVP and L.KIND_PVP or L.KIND_PVE
    end },
  levelColumn(40),
  zoneColumn(126),
}

local DEATH_COLUMNS = {
  whenColumn(100),
  { header = "HISTORY_CAUSE", width = 180, align = LEFT, value = History.DeathCauseText },
  levelColumn(40),
  zoneColumn(126),
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

---------------------------------------------------------------------------
-- Tabelle mit fester Zeilenzahl (Lazy Load)
---------------------------------------------------------------------------
local function tableWidth(columns)
  local width = 0
  for _, column in ipairs(columns) do
    width = width + column.width
  end
  return width
end

local function createRow(parent, columns, fontObject)
  local row = CreateFrame("Frame", nil, parent)
  row:SetSize(tableWidth(columns), ROW_HEIGHT)
  row.cells = {}
  local x = 0
  for i, column in ipairs(columns) do
    local cell = row:CreateFontString(nil, "OVERLAY", fontObject)
    cell:SetPoint("LEFT", x, 0)
    cell:SetWidth(column.width - CELL_GAP)
    cell:SetJustifyH(column.align or (i == 1 and LEFT or RIGHT))
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

-- definition = { tab, group (optional), columns, records(characterKey), footer(columns, records) }
local function createTableView(definition)
  local columns = definition.columns

  local function create(parent, _, height)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints(parent)
    frame.offset = 0  -- Index vor dem ersten sichtbaren Eintrag

    local visibleRows = math.floor(height / ROW_HEIGHT) - 2  -- ohne Kopf- und Summenzeile
    local records = {}

    local headerRow = createRow(frame, columns, "GameFontNormalSmall")
    headerRow:SetPoint("TOPLEFT")
    local footerRow = createRow(frame, columns, "GameFontNormalSmall")
    footerRow:SetPoint("BOTTOMLEFT")

    local rows = {}
    for i = 1, visibleRows do
      rows[i] = createRow(frame, columns, "GameFontHighlightSmall")
      rows[i]:SetPoint("TOPLEFT", 0, -i * ROW_HEIGHT)
    end

    local function draw()
      for i, row in ipairs(rows) do
        local record = records[frame.offset + i]
        if record then
          fillRow(row, recordCells(columns, record), record.isCurrent and Widgets.COLORS.highlight or WHITE)
        else
          row:Hide()
        end
      end
    end

    local scrollBar
    local function scrollTo(offset)
      frame.offset = math.max(0, math.min(offset, #records - visibleRows))
      scrollBar:SetOffsetSilently(frame.offset)
      draw()
    end

    scrollBar = Widgets.CreateScrollBar(frame, scrollTo)
    scrollBar:SetPoint("TOPLEFT", tableWidth(columns) + SCROLLBAR_GAP, -ROW_HEIGHT)
    scrollBar:SetHeight(visibleRows * ROW_HEIGHT)

    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta)
      scrollTo(frame.offset - delta * WHEEL_STEP)
    end)

    function frame:Render(characterKey, selectionChanged)
      for i, column in ipairs(columns) do
        headerRow.cells[i]:SetText(L[column.header])
      end
      records = definition.records(characterKey)
      if selectionChanged then frame.offset = 0 end
      scrollBar:SetRange(math.max(0, #records - visibleRows))
      scrollTo(frame.offset)
      fillRow(footerRow, definition.footer(columns, records), Widgets.COLORS.highlight)
    end

    return frame
  end

  return { tab = definition.tab, group = definition.group, Create = create }
end

local function addTable(tab, group, columns, records, footer)
  ns.HistoryWindow.AddView(createTableView({
    tab = tab, group = group, columns = columns, records = records, footer = footer,
  }))
end

local LEVELS, JOURNAL = "HISTORY_GROUP_LEVELS", "HISTORY_GROUP_JOURNAL"

addTable("HISTORY_TAB_LEVELS", LEVELS, LEVEL_COLUMNS, History.GetLevelRecords, summaryCells)
addTable("HISTORY_TAB_TIMELINE", LEVELS, MILESTONE_COLUMNS, History.GetMilestones, countCells)
addTable("HISTORY_TAB_SESSIONS", nil, SESSION_COLUMNS, History.GetSessionRecords, summaryCells)
addTable("HISTORY_TAB_KILLS", JOURNAL, KILL_COLUMNS, History.GetKillLog, countCells)
addTable("HISTORY_TAB_DEATHS", JOURNAL, DEATH_COLUMNS, History.GetDeathLog, countCells)
