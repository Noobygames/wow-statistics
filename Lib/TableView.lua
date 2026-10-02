-- Tabellen-Ansicht für Fenster mit Reitern (z.B. die Historie): Suchfeld, sortierbare Kopfzeile,
-- Zeilen mit Lazy Load, Summenzeile, CSV-Export und optionale Buttons.
-- Lazy Load: Es gibt nur so viele Zeilen-Widgets, wie sichtbar sind; beim Scrollen (Mausrad oder
-- Leiste) werden sie mit den passenden Einträgen neu gefüllt. So bleiben auch tausende Einträge flüssig.
-- Spalten: header = Locale-Key, value(record) = Zellentext, width, align = "LEFT" für Text
-- (Standard: erste Spalte links, Zahlen rechts), sort(record) = Sortierschlüssel, wenn der Zellentext
-- formatiert ist (Dauer, Gold, Datum); sonst wird nach value sortiert.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Format = ns.Format

local TableView = {}
ns.TableView = TableView

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
local EXTRA_BUTTON_WIDTH = 90   -- weitere Buttons der Ansicht (definition.buttons)
local SORT_DESCENDING = " v"
local SORT_ASCENDING = " ^"

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
--   rowColor(record) optional (Standard: laufender Eintrag hervorgehoben, sonst weiß),
--   onRowClick(record, mouseButton) optional,
--   hint = Locale-Key oder function() -> Text optional,
--   buttons = { { label = Locale-Key, onClick() }, ... } optional (neben dem Export-Button) }
-- Ergebnis: Ansicht { tab, group, Create(parent, width, height) -> frame } für HistoryWindow.AddView
function TableView.Create(definition)
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
    local apply  -- unten definiert
    for i = 1, visibleRows do
      rows[i] = createRow(frame, columns, "GameFontHighlightSmall")
      rows[i]:SetPoint("TOPLEFT", 0, -TOOLBAR_HEIGHT - i * ROW_HEIGHT)
    end

    -- Klick auf eine Zeile (nur, wenn die Ansicht etwas damit macht); danach neu zeichnen
    if definition.onRowClick then
      for i, row in ipairs(rows) do
        row:EnableMouse(true)
        row:SetScript("OnMouseUp", function(_, mouseButton)
          local record = records[frame.offset + i]
          if not record then return end
          definition.onRowClick(record, mouseButton)
          frame:Render(frame.characterKey)
        end)
      end
    end

    -- Hinweis unten rechts neben der Summenzeile, z.B. was ein Klick bewirkt
    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMRIGHT", -SCROLLBAR_GAP, 2)

    -- Weitere Buttons der Ansicht rechts neben dem Export-Button
    local extraButtons = {}
    for i, button in ipairs(definition.buttons or {}) do
      local widget = Widgets.CreateButton(frame, EXTRA_BUTTON_WIDTH, FILTER_HEIGHT + 2, button.onClick)
      widget:SetPoint("TOPLEFT", EXPORT_BUTTON_WIDTH + CELL_GAP + (i - 1) * (EXTRA_BUTTON_WIDTH + CELL_GAP), -1)
      extraButtons[i] = { widget = widget, label = button.label }
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
    function apply()
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
      frame.characterKey = characterKey
      filterLabel:SetText(L.FILTER)
      exportButton:SetText(L.EXPORT)
      local hintText = definition.hint
      if type(hintText) == "function" then hintText = hintText() elseif hintText then hintText = L[hintText] end
      hint:SetText(hintText or "")
      for _, button in ipairs(extraButtons) do button.widget:SetText(L[button.label]) end
      allRecords = definition.records(characterKey)
      if selectionChanged then frame.offset = 0 end
      apply()
    end

    return frame
  end

  return { tab = definition.tab, group = definition.group, Create = create }
end
