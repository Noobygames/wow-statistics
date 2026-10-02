-- Texte passen in ihre Fenster: Einstellungen wachsen mit der Sprache, Unterreiter der Historie brechen um.
local L = addon.L

wow.login()

local function findByLabel(text)
  return wow.findFrame(function(frame)
    local label = rawget(frame, "label")
    return label and label._text == text and frame._points[1] ~= nil
  end)
end

-- x-Abstand eines Ankers "TOPLEFT", x, y zum Elternfenster
local function anchorX(frame)
  local point = frame._points[1]
  return point[#point - 1]
end

---------------------------------------------------------------------------
-- Einstellungen: Schalter in einer Zeile überlappen nicht, Sprachwahl passt ins Fenster
---------------------------------------------------------------------------
local options = LevelTimerOptions

local function checkOptions(language)
  addon.Set("language", language)
  SlashCmdList.LEVELTIMER("config")

  -- Minimap-Button (links) und Level-Up im Chat (rechts) teilen sich eine Zeile
  local left = findByLabel(L.SHOW_MINIMAP)
  local right = findByLabel(L.LEVEL_UP_SUMMARY_TOGGLE)
  local leftEnd = anchorX(left) + left:GetWidth() + addon.Widgets.CHECKBOX_LABEL_GAP + left.label:GetStringWidth()
  expectTrue(language .. ": rechte Spalte beginnt hinter der linken Beschriftung", anchorX(right) > leftEnd)
  expectTrue(language .. ": rechte Spalte passt ins Fenster",
    anchorX(right) + right:GetWidth() + right.label:GetStringWidth() <= options:GetWidth())

  -- Sprachwahl: Beschriftung und alle Reiter nebeneinander
  local row = L.LANGUAGE:len() * 6
  for _, entry in ipairs(addon.languages) do
    row = row + findByLabel(entry.name):GetWidth()
  end
  expectTrue(language .. ": Sprachwahl passt ins Fenster", row < options:GetWidth())

  SlashCmdList.LEVELTIMER("config")  -- schließen
end

checkOptions("deDE")
checkOptions("frFR")
checkOptions("esES")

---------------------------------------------------------------------------
-- Historie: Unterreiter der Graphen bleiben in der Breite, der Inhalt rückt nach unten
---------------------------------------------------------------------------
addon.Set("language", "deDE")
SlashCmdList.LEVELTIMER("history")
local history = LevelTimerHistory
expectTrue("Reiter Graphen", wow.click(L.HISTORY_TAB_CHARTS))

local SUBTABS_TOP = -88  -- wie in HistoryWindow.lua
local SINGLE_ROW_HEIGHT = 110 + addon.HistoryWindow.CONTENT_HEIGHT + 16  -- Fenster mit einer Unterreiter-Zeile
local contentRight = 16 + addon.HistoryWindow.CONTENT_WIDTH

-- Unterreiter: sichtbare Buttons mit Anker "TOPLEFT", x, y ab der Unterreiter-Zeile
local subtabs = {}
wow.findFrame(function(frame)
  local label = rawget(frame, "label")
  local point = frame._points[1]
  if label and frame:IsShown() and point and point[1] == "TOPLEFT" and #point == 3 and point[3] <= SUBTABS_TOP then
    table.insert(subtabs, frame)
  end
  return false
end)
expectTrue("Unterreiter gefunden", #subtabs > 5)

local wrapped = false
for _, subtab in ipairs(subtabs) do
  local x, y = subtab._points[1][2], subtab._points[1][3]
  expectTrue("Unterreiter " .. subtab.label._text .. " in der Breite", x + subtab:GetWidth() <= contentRight)
  if y < SUBTABS_TOP then wrapped = true end
end
expectTrue("Unterreiter brechen in eine zweite Zeile um", wrapped)
expectTrue("Fenster wächst mit den Zeilen", history:GetHeight() > SINGLE_ROW_HEIGHT)
