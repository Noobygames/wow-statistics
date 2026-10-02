-- Tabellen der Historie: Level, Timeline, Sessions, Kills, Tode, Quests, Beute, Instanzen, Beinahe-Tode, Zonen, Vergleich.
-- Lazy Load: Es gibt nur so viele Zeilen-Widgets, wie sichtbar sind; beim Scrollen
-- (Mausrad oder Leiste) werden sie mit den passenden Einträgen neu gefüllt.
-- So bleiben auch tausende Journal-Einträge flüssig. Klick auf einen Spaltenkopf sortiert,
-- das Suchfeld filtert; die Summenzeile gilt für die gefilterten Zeilen.
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
local TOOLBAR_HEIGHT = 22     -- Zeile mit dem Suchfeld über der Tabelle
local FILTER_WIDTH = 150
local FILTER_HEIGHT = 18
local EXPORT_BUTTON_WIDTH = 70
local SORT_DESCENDING = " v"
local SORT_ASCENDING = " ^"

---------------------------------------------------------------------------
-- Spalten: header = Locale-Key, value(record) = Zellentext, align = LEFT für Text
-- (Standard: erste Spalte links, Zahlen rechts), sort(record) = Sortierschlüssel, wenn der
-- Zellentext formatiert ist (Dauer, Gold, Datum); sonst wird nach value sortiert.
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
  end, sort = function(r) return r.seconds end }
end

local function xpRateColumn(width)
  return { header = "HISTORY_XP_RATE", width = width, value = function(r)
    local rate = Experience.CalculateRate(r.xp, r.seconds)
    return rate and Format.Number(rate) or "-"
  end, sort = function(r) return Experience.CalculateRate(r.xp, r.seconds) end }
end

local function counterColumn(header, name, width)
  return { header = header, width = width, value = function(r) return counter(r, name) end }
end

local function goldColumn(width)
  return { header = "HISTORY_GOLD", width = width, value = function(r)
    return Format.Gold(counter(r, Stats.MONEY_EARNED))
  end, sort = function(r) return counter(r, Stats.MONEY_EARNED) end }
end

local function levelColumn(width)
  return { header = "HISTORY_LEVEL", width = width, value = function(r) return r.level or "" end,
    sort = function(r) return r.level end }
end

local function zoneColumn(width)
  return { header = "HISTORY_ZONE", width = width, align = LEFT, value = function(r) return r.zone or "" end }
end

local function whenColumn(width)
  return { header = "HISTORY_WHEN", width = width, value = function(r)
    return dateTime(L.DATE_TIME_FORMAT, r.time)
  end, sort = function(r) return r.time end }
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
  { header = "HISTORY_START", width = 80, value = function(r) return dateTime(L.DATE_FORMAT, r.startedAt) end,
    sort = function(r) return r.startedAt end },
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
  { header = "HISTORY_REACHED", width = 100, value = function(r) return dateTime(L.DATE_FORMAT, r.reachedAt) end,
    sort = function(r) return r.reachedAt end },
  { header = "HISTORY_TOTAL_PLAYED", width = 90, value = function(r)
      return r.totalPlayed and Format.Duration(r.totalPlayed) or "?"
    end, sort = function(r) return r.totalPlayed end },
  { header = "HISTORY_LEVEL_DURATION", width = 80, value = function(r)
      return r.seconds and Format.Duration(r.seconds) or "?"
    end, sort = function(r) return r.seconds end },
}

-- Art eines Kills: PvP, sonst die Einstufung des Gegners (Elite, Rare, ...) oder PvE
local KIND_BY_CLASSIFICATION = {
  elite = "KIND_ELITE",
  rare = "KIND_RARE",
  rareelite = "KIND_RARE_ELITE",
  worldboss = "KIND_BOSS",
}

local function killKind(r)
  if r.kind == Journal.PVP then return L.KIND_PVP end
  local key = KIND_BY_CLASSIFICATION[r.classification]
  return key and L[key] or L.KIND_PVE
end

local KILL_COLUMNS = {
  whenColumn(100),
  { header = "HISTORY_NAME", width = 140, align = LEFT, value = function(r) return r.name or L.UNKNOWN_NAME end },
  { header = "HISTORY_KIND", width = 40, value = killKind },
  levelColumn(40),
  zoneColumn(126),
}

local DEATH_COLUMNS = {
  whenColumn(100),
  { header = "HISTORY_CAUSE", width = 180, align = LEFT, value = History.DeathCauseText },
  levelColumn(40),
  zoneColumn(126),
}

local QUEST_COLUMNS = {
  whenColumn(100),
  { header = "HISTORY_QUEST", width = 180, align = LEFT, value = function(r) return r.name or L.UNKNOWN_NAME end },
  { header = "HISTORY_XP", width = 60, value = function(r) return r.xp and Format.Number(r.xp) or "-" end,
    sort = function(r) return r.xp end },
  { header = "HISTORY_GOLD", width = 60, value = function(r) return r.money and Format.Gold(r.money) or "-" end,
    sort = function(r) return r.money end },
  levelColumn(40),
  zoneColumn(86),
}

local INSTANCE_COLUMNS = {
  whenColumn(100),
  { header = "HISTORY_INSTANCE", width = 150, align = LEFT, value = function(r) return r.name or "" end },
  durationColumn(60),
  { header = "HISTORY_XP", width = 60, value = function(r) return Format.Number(r.xp or 0) end,
    sort = function(r) return r.xp end },
  counterColumn("HISTORY_KILLS", "kills", 50),
  counterColumn("HISTORY_DEATHS", "deaths", 40),
  levelColumn(40),
}

local LOOT_COLUMNS = {
  whenColumn(100),
  { header = "HISTORY_ITEM", width = 180, align = LEFT, value = function(r) return r.link or r.name or "" end },
  { header = "HISTORY_QUANTITY", width = 40, value = function(r) return r.quantity or 1 end },
  { header = "HISTORY_SOURCE", width = 130, align = LEFT, value = function(r) return r.source or "-" end },
  levelColumn(40),
}

local NEAR_DEATH_COLUMNS = {
  whenColumn(100),
  { header = "HISTORY_LOWEST_HEALTH", width = 70, value = function(r) return (r.lowestPercent or 0) .. "%" end,
    sort = function(r) return r.lowestPercent end },
  { header = "HISTORY_CAUSE", width = 180, align = LEFT, value = History.DeathCauseText },
  levelColumn(40),
  zoneColumn(110),
}

local ZONE_COLUMNS = {
  { header = "HISTORY_ZONE", width = 160, value = function(r) return r.zone or "" end },
  durationColumn(70),
  { header = "HISTORY_XP", width = 70, value = function(r) return Format.Number(r.xp or 0) end,
    sort = function(r) return r.xp end },
  xpRateColumn(60),
  counterColumn("HISTORY_KILLS", "kills", 50),
  counterColumn("HISTORY_DEATHS", "deaths", 40),
}

local COMPARE_COLUMNS = {
  { header = "HISTORY_CHARACTER_NAME", width = 140, value = function(r) return History.DisplayName(r.key) end },
  levelColumn(40),
  { header = "HISTORY_LEVELS_DONE", width = 56, value = function(r) return r.levelsCompleted end },
  { header = "HISTORY_AVERAGE_LEVEL_TIME", width = 84, value = function(r)
      return r.averageLevelSeconds and Format.Duration(r.averageLevelSeconds) or "-"
    end, sort = function(r) return r.averageLevelSeconds end },
  { header = "HISTORY_XP_RATE", width = 56, value = function(r)
      return r.xpRate and Format.Number(r.xpRate) or "-"
    end, sort = function(r) return r.xpRate end },
  { header = "HISTORY_KILLS", width = 50, value = function(r)
      return counter(r, Stats.PVE_KILLS) + counter(r, Stats.PVP_KILLS)
    end },
  counterColumn("HISTORY_DEATHS", Stats.DEATHS, 40),
  goldColumn(56),
}

-- Vergleich: Zeilen in Klassenfarbe
local function classColor(record)
  local color = RAID_CLASS_COLORS and record.class and RAID_CLASS_COLORS[record.class]
  if color then return { color.r, color.g, color.b } end
  return WHITE
end

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

local function defaultRowColor(record)
  return record.isCurrent and Widgets.COLORS.highlight or WHITE
end

---------------------------------------------------------------------------
-- Sortieren und Filtern
---------------------------------------------------------------------------

local plainText = Format.PlainText

local function sortKey(column, record)
  if column.sort then return column.sort(record) end
  return column.value(record)
end

-- Zahlen numerisch, Text ohne Groß-/Kleinschreibung; fehlende Werte immer ans Ende
local function compareKeys(a, b, descending)
  if a == nil or a == "" then return false end
  if b == nil or b == "" then return true end
  if type(a) == "number" and type(b) == "number" then
    if descending then return a > b end
    return a < b
  end
  a, b = plainText(a):lower(), plainText(b):lower()
  if descending then return a > b end
  return a < b
end

-- Gefilterte und sortierte Kopie; sort = { column, descending } oder nil
local function filterAndSort(columns, records, filterText, sort)
  local result = {}
  for index, record in ipairs(records) do
    local include = filterText == ""
    if not include then
      for _, column in ipairs(columns) do
        if plainText(column.value(record)):lower():find(filterText, 1, true) then
          include = true
          break
        end
      end
    end
    if include then
      table.insert(result, { record = record, index = index, key = sort and sortKey(sort.column, record) })
    end
  end

  if sort then
    table.sort(result, function(a, b)
      if a.key == b.key then return a.index < b.index end  -- gleiche Werte: ursprüngliche Reihenfolge
      return compareKeys(a.key, b.key, sort.descending)
    end)
  end

  for i, entry in ipairs(result) do
    result[i] = entry.record
  end
  return result
end

---------------------------------------------------------------------------
-- Tabellen-Ansicht: Suchfeld, sortierbare Kopfzeile, Zeilen (Lazy Load), Summenzeile
---------------------------------------------------------------------------

-- definition = { tab, group (optional), columns, records(characterKey), footer(columns, records),
--                rowColor(record) (optional, Standard: laufender Eintrag hervorgehoben, sonst weiß) }
local function createTableView(definition)
  local columns = definition.columns
  local rowColor = definition.rowColor or defaultRowColor

  local function create(parent, _, height)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints(parent)
    frame.offset = 0  -- Index vor dem ersten sichtbaren Eintrag

    local visibleRows = math.floor((height - TOOLBAR_HEIGHT) / ROW_HEIGHT) - 2  -- ohne Kopf- und Summenzeile
    local allRecords, records = {}, {}  -- alle Einträge bzw. gefiltert und sortiert
    local filterText = ""
    local sort  -- { column, index, descending } oder nil (ursprüngliche Reihenfolge)

    -- Suchfeld oben rechts
    local filterBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    filterBox:SetSize(FILTER_WIDTH, FILTER_HEIGHT)
    filterBox:SetPoint("TOPRIGHT", -SCROLLBAR_GAP, -2)
    filterBox:SetAutoFocus(false)
    local filterLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    filterLabel:SetPoint("RIGHT", filterBox, "LEFT", -8, 0)

    local headerRow = createRow(frame, columns, "GameFontNormalSmall")
    headerRow:SetPoint("TOPLEFT", 0, -TOOLBAR_HEIGHT)
    local footerRow = createRow(frame, columns, "GameFontNormalSmall")
    footerRow:SetPoint("BOTTOMLEFT")

    local rows = {}
    for i = 1, visibleRows do
      rows[i] = createRow(frame, columns, "GameFontHighlightSmall")
      rows[i]:SetPoint("TOPLEFT", 0, -TOOLBAR_HEIGHT - i * ROW_HEIGHT)
    end

    local function draw()
      for i, row in ipairs(rows) do
        local record = records[frame.offset + i]
        if record then
          fillRow(row, recordCells(columns, record), rowColor(record))
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
    scrollBar:SetPoint("TOPLEFT", tableWidth(columns) + SCROLLBAR_GAP, -TOOLBAR_HEIGHT - ROW_HEIGHT)
    scrollBar:SetHeight(visibleRows * ROW_HEIGHT)

    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta)
      scrollTo(frame.offset - delta * WHEEL_STEP)
    end)

    local function showHeaders()
      for i, column in ipairs(columns) do
        local marker = ""
        if sort and sort.index == i then
          marker = sort.descending and SORT_DESCENDING or SORT_ASCENDING
        end
        headerRow.cells[i]:SetText(L[column.header] .. marker)
      end
    end

    -- Filter und Sortierung auf alle Einträge anwenden und neu zeichnen
    local function apply()
      records = filterAndSort(columns, allRecords, filterText, sort)
      showHeaders()
      scrollBar:SetRange(math.max(0, #records - visibleRows))
      scrollTo(frame.offset)
      fillRow(footerRow, definition.footer(columns, records), Widgets.COLORS.highlight)
    end

    -- Nach einer Spalte sortieren: erst absteigend, beim nächsten Aufruf für dieselbe Spalte aufsteigend
    function frame:SortBy(index)
      if sort and sort.index == index then
        sort.descending = not sort.descending
      else
        sort = { column = columns[index], index = index, descending = true }
      end
      frame.offset = 0
      apply()
    end

    -- Klick auf einen Spaltenkopf sortiert
    local x = 0
    for i, column in ipairs(columns) do
      local headerButton = CreateFrame("Button", nil, headerRow)
      headerButton:SetPoint("TOPLEFT", x, 0)
      headerButton:SetSize(column.width, ROW_HEIGHT)
      headerButton:SetScript("OnClick", function() frame:SortBy(i) end)
      x = x + column.width
    end

    -- Zeilen auf Einträge beschränken, deren Text den Suchbegriff enthält (ohne Groß-/Kleinschreibung)
    function frame:SetFilter(text)
      filterText = plainText(text):lower()
      frame.offset = 0
      apply()
    end

    filterBox:SetScript("OnTextChanged", function(self) frame:SetFilter(self:GetText()) end)
    filterBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    -- Aktuell angezeigte (gefilterte und sortierte) Einträge, z.B. für den Export
    function frame:GetVisibleRecords()
      return records
    end

    -- Angezeigte Zeilen als CSV (Spaltenköpfe in der aktuellen Sprache, Zellen ohne Farbcodes)
    function frame:BuildCsv()
      local headers, rowsText = {}, {}
      for i, column in ipairs(columns) do
        headers[i] = L[column.header]
      end
      for _, record in ipairs(records) do
        local cells = recordCells(columns, record)
        for i, cell in ipairs(cells) do
          cells[i] = plainText(cell)
        end
        table.insert(rowsText, cells)
      end
      return ns.Export.ToCsv(headers, rowsText, L.CSV_SEPARATOR)
    end

    local exportButton = Widgets.CreateButton(frame, EXPORT_BUTTON_WIDTH, FILTER_HEIGHT + 2, function()
      ns.Export.Show(L[definition.tab], frame:BuildCsv())
    end)
    exportButton:SetPoint("TOPLEFT", 0, -1)

    function frame:Render(characterKey, selectionChanged)
      filterLabel:SetText(L.FILTER)
      exportButton:SetText(L.EXPORT)
      allRecords = definition.records(characterKey)
      if selectionChanged then frame.offset = 0 end
      apply()
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
addTable("HISTORY_TAB_QUESTS", JOURNAL, QUEST_COLUMNS, History.GetQuestLog, countCells)
addTable("HISTORY_TAB_LOOT", JOURNAL, LOOT_COLUMNS, History.GetLootLog, countCells)
addTable("HISTORY_TAB_INSTANCES", JOURNAL, INSTANCE_COLUMNS, History.GetInstanceLog, summaryCells)
addTable("HISTORY_TAB_NEAR_DEATHS", JOURNAL, NEAR_DEATH_COLUMNS, History.GetNearDeathLog, countCells)
addTable("HISTORY_TAB_ZONES", nil, ZONE_COLUMNS, ns.Zones.GetRecords, summaryCells)

-- Vergleich gilt für alle Charaktere, die Charakter-Auswahl spielt hier keine Rolle
ns.HistoryWindow.AddView(createTableView({
  tab = "HISTORY_TAB_COMPARE",
  columns = COMPARE_COLUMNS,
  records = function() return History.GetCharacterComparison() end,
  footer = countCells,
  rowColor = classColor,
}))
