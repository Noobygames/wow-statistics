-- Historie und Auswertung: Fenster mit Charakter-Auswahl und einem Reiter pro Ansicht.
-- Die Ansichten registrieren sich über HistoryWindow.AddView (HistoryTables.lua, HistoryCharts.lua);
-- die Ladereihenfolge bestimmt die Reihenfolge der Reiter.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local History = ns.History

local HistoryWindow = {
  CONTENT_WIDTH = 470,   -- Platz, den jede Ansicht bekommt
  CONTENT_HEIGHT = 290,
}
ns.HistoryWindow = HistoryWindow

local MARGIN = 16
local HEADER_TOP = -14
local CHARACTER_ROW_TOP = -40
local TABS_TOP = -66
local CONTENT_TOP = -90
local ARROW_SIZE = 22
local DELETE_BUTTON_WIDTH = 110
local DELETE_BUTTON_HEIGHT = 20
local TAB_GAP = 12
local UPDATE_INTERVAL = 1  -- Sekunden; hält laufende Einträge aktuell

local panel = Widgets.CreatePanel("LevelTimerHistory", 0.95)
panel:SetSize(HistoryWindow.CONTENT_WIDTH + 2 * MARGIN, -CONTENT_TOP + HistoryWindow.CONTENT_HEIGHT + MARGIN)
panel:SetPoint("CENTER")
panel:SetFrameStrata("DIALOG")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
panel:Hide()
table.insert(UISpecialFrames, "LevelTimerHistory")  -- mit ESC schließen

Widgets.CreateCloseButton(panel)

local header = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
header:SetPoint("TOP", 0, HEADER_TOP)

local content = CreateFrame("Frame", nil, panel)
content:SetPoint("TOPLEFT", MARGIN, CONTENT_TOP)
content:SetSize(HistoryWindow.CONTENT_WIDTH, HistoryWindow.CONTENT_HEIGHT)

local views = {}
local selectedView
local selectedCharacter  -- Schlüssel "Name-Realm"; nil = eingeloggter Charakter
local rendered = {}      -- zuletzt angezeigte Ansicht und Charakter (Wechsel setzt den Bildlauf zurück)
local refresh            -- unten definiert

---------------------------------------------------------------------------
-- Ansichten
---------------------------------------------------------------------------

-- view = { tab = Locale-Key, Create = function(parent, width, height) -> frame }
-- Der Frame braucht frame:Render(characterKey, selectionChanged).
function HistoryWindow.AddView(view)
  view.frame = view.Create(content, HistoryWindow.CONTENT_WIDTH, HistoryWindow.CONTENT_HEIGHT)
  view.frame:Hide()

  view.tabButton = Widgets.CreateTab(panel, "GameFontNormal", function()
    selectedView = view
    refresh()
  end)
  local previous = views[#views]
  if previous then
    view.tabButton:SetPoint("LEFT", previous.tabButton, "RIGHT", TAB_GAP, 0)
  else
    view.tabButton:SetPoint("TOPLEFT", MARGIN, TABS_TOP)
  end

  table.insert(views, view)
  selectedView = selectedView or view
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

---------------------------------------------------------------------------
-- Daten des gewählten Charakters löschen (mit Rückfrage)
---------------------------------------------------------------------------
local DELETE_POPUP = "LEVELTIMER_DELETE_CHARACTER"

StaticPopupDialogs[DELETE_POPUP] = {
  button1 = YES or "Yes",
  button2 = NO or "No",
  OnAccept = function(_, characterKey)
    ns.DeleteCharacter(characterKey)
    refresh()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,  -- eigener Platz, kollidiert nicht mit Blizzard-Dialogen
}

local deleteButton = Widgets.CreateButton(panel, DELETE_BUTTON_WIDTH, DELETE_BUTTON_HEIGHT, function()
  local character = History.GetCharacter(selectedCharacter)
  StaticPopupDialogs[DELETE_POPUP].text = L.DELETE_CHARACTER_CONFIRM  -- aktuelle Sprache
  StaticPopup_Show(DELETE_POPUP, (character.name or "?") .. " - " .. (character.realm or "?"), nil, selectedCharacter)
end)
deleteButton:SetPoint("TOPLEFT", MARGIN, HEADER_TOP + 4)

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
-- Aufbau
---------------------------------------------------------------------------
function refresh()
  if not History.GetCharacter(selectedCharacter or "") then
    selectedCharacter = ns.characterKey
  end

  header:SetText(L.HISTORY)
  deleteButton:SetText(L.DELETE_CHARACTER)
  showCharacterName(History.GetCharacter(selectedCharacter))

  local selectionChanged = rendered.view ~= selectedView or rendered.character ~= selectedCharacter
  rendered.view, rendered.character = selectedView, selectedCharacter

  for _, view in ipairs(views) do
    view.tabButton:SetLabel(L[view.tab])
    view.tabButton:SetActive(view == selectedView)
    if view == selectedView then
      view.frame:Render(selectedCharacter, selectionChanged)
      view.frame:Show()
    else
      view.frame:Hide()
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
