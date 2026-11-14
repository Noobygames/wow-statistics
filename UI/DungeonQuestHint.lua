-- Kleines Hinweisfenster der Dungeonquests (Inhalt aus Assist/DungeonQuestHints.lua): Titel, je Quest eine Zeile
-- (Titel, darunter Geber und Ort), Schließen-Knopf; schließt nach DISPLAY_SECONDS von selbst, unter der Maus bleibt es
-- stehen. Position über Lib/Frames.lua (Edit-Modus mit Beispielinhalt, ziehbar solange nicht gesperrt).
-- DungeonQuestHint.Show(title, rows), rows = { { text, detail, muted, place = { uiMapID, x, y } }, ... }.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets

local DungeonQuestHint = {
  DISPLAY_SECONDS = 20,
  MAX_ROWS = 8,
}
ns.DungeonQuestHint = DungeonQuestHint

local DEFAULT_POSITION = { "TOP", "TOP", 0, -220 }
local PADDING = 10
local MIN_WIDTH = 240
local TITLE_HEIGHT = 18
local CLOSE_SPACE = 24   -- Platz rechts neben dem Titel für den Schließen-Knopf
local ROW_HEIGHT = 30    -- Zeile mit Text und Detailzeile
local LINE_GAP = 2
local FADE_OUT = 0.7
local BACKGROUND_ALPHA = 0.92

local panel = Widgets.CreatePanel(ns.GlobalName("DungeonQuestHint"), BACKGROUND_ALPHA)
panel:Hide()
local closeButton = Widgets.CreateCloseButton(panel)
local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOPLEFT", PADDING, -PADDING)
title:SetJustifyH("LEFT")

local rows = {}
local shownAt
local editing = false

local function setColor(fontString, colorName)
  fontString:SetTextColor(ns.Theme.RGB(colorName))
end

local function getRow(index)
  if rows[index] then return rows[index] end
  local row = CreateFrame("Button", nil, panel)
  row:SetHeight(ROW_HEIGHT)
  row:SetPoint("TOPLEFT", PADDING, -PADDING - TITLE_HEIGHT - (index - 1) * ROW_HEIGHT)
  row:SetPoint("RIGHT", -PADDING, 0)
  row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  row.text:SetPoint("TOPLEFT")
  row.text:SetJustifyH("LEFT")
  row.detail = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.detail:SetPoint("TOPLEFT", row.text, "BOTTOMLEFT", 0, -LINE_GAP)
  row.detail:SetJustifyH("LEFT")
  setColor(row.detail, "muted")
  rows[index] = row
  return row
end

local function hide()
  editing = false
  panel:Hide()
end
closeButton:SetScript("OnClick", hide)

local function layout(titleText, entries)
  title:SetText(titleText)
  local width = title:GetStringWidth() + CLOSE_SPACE
  local count = math.min(#entries, DungeonQuestHint.MAX_ROWS)
  for index = 1, count do
    local entry, row = entries[index], getRow(index)
    row.entry = entry
    row.text:SetText(entry.text)
    setColor(row.text, entry.muted and "inactive" or "text")
    row.detail:SetText(entry.detail or "")
    width = math.max(width, row.text:GetStringWidth(), row.detail:GetStringWidth())
    row:Show()
  end
  for index = count + 1, #rows do rows[index]:Hide() end
  local more = #entries - count
  if more > 0 then  -- letzte Zeile: Hinweis auf die übrigen
    local row = getRow(count + 1)
    row.entry = nil
    row.text:SetText(string.format(L.DUNGEON_QUESTS_MORE, more))
    setColor(row.text, "muted")
    row.detail:SetText("")
    row:Show()
    count = count + 1
  end
  panel:SetSize(math.max(MIN_WIDTH, width + 2 * PADDING), 2 * PADDING + TITLE_HEIGHT + count * ROW_HEIGHT)
end

function DungeonQuestHint.Show(titleText, entries)
  if #entries == 0 then return end
  layout(titleText, entries)
  shownAt = GetTime()
  panel:SetAlpha(1)
  panel:Show()
  ns.Debug("dungeonquests", "hint shown: %s (%s rows)", titleText, #entries)
end

function DungeonQuestHint.IsShown()
  return panel:IsShown()
end

-- Zeilen des Fensters (für Tests und Klicks)
function DungeonQuestHint.Rows()
  return rows
end

ns.SetUpdateScript(panel, "DungeonQuestHint", function(self)
  if editing or not shownAt then return end
  local age = GetTime() - shownAt
  local hold = DungeonQuestHint.DISPLAY_SECONDS
  if self:IsMouseOver() and age > hold then  -- unter der Maus bleibt es stehen
    shownAt = GetTime() - hold
    age = hold
  end
  if age >= hold + FADE_OUT then
    hide()
  elseif age > hold then
    self:SetAlpha(1 - (age - hold) / FADE_OUT)
  end
end)

-- Edit-Modus: Beispielinhalt bleibt stehen, bis der Modus endet
local function setEditing(enabled)
  if enabled then
    layout(L.EDIT_FRAME_DUNGEON_QUEST_HINT, {
      { text = L.DUNGEON_QUEST_HINT_SAMPLE, detail = L.DUNGEON_QUEST_GIVER_NPC },
    })
    editing = true
    panel:SetAlpha(1)
    panel:Show()
  elseif editing then
    hide()
  end
end

ns.Frames.Register({
  id = "dungeonQuestHint", frame = panel, label = "EDIT_FRAME_DUNGEON_QUEST_HINT", default = DEFAULT_POSITION,
  settingsPage = "COMFORT_PAGE_QUESTS", preview = setEditing, dragWhenUnlocked = true,
  available = function() return ns.DungeonQuests.IsAvailable() end,
})
