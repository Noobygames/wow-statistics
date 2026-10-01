-- Anzeigefenster: Level, Spielzeit auf dem Level und Kills.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets

local UPDATE_INTERVAL = 0.25          -- Sekunden zwischen zwei Anzeige-Updates
local PADDING_X = 20
local PADDING_Y = 8
local LINE_GAP = 3
local MIN_WIDTH = 160
local WIDEST_TIME = "00d 00h 00m 00s" -- für die Fensterbreite
local DEFAULT_POSITION = { "TOP", "TOP", 0, -120 }

local window = Widgets.CreatePanel("LevelTimerFrame", 0.8)
window:Hide()  -- erst nach Login anzeigen, wenn Daten und Einstellungen bereitstehen

local title = window:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
title:SetPoint("TOP", 0, -PADDING_Y)

local timeText = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
timeText:SetPoint("TOP", title, "BOTTOM", 0, -LINE_GAP)
timeText:SetTextColor(unpack(Widgets.COLORS.highlight))

local killsText = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
killsText:SetPoint("TOP", timeText, "BOTTOM", 0, -LINE_GAP)

local function formatTime(totalSeconds)
  totalSeconds = math.floor(totalSeconds)
  local days = math.floor(totalSeconds / 86400)
  local hours = math.floor(totalSeconds / 3600) % 24
  local minutes = math.floor(totalSeconds / 60) % 60
  local seconds = totalSeconds % 60
  if days > 0 then
    return string.format("%dd %02dh %02dm %02ds", days, hours, minutes, seconds)
  end
  return string.format("%02dh %02dm %02ds", hours, minutes, seconds)
end

local function refreshTexts()
  title:SetText(string.format(L.TIME_ON_LEVEL, ns.level))
  local levelSeconds = ns.PlayedTime.GetLevelSeconds()
  timeText:SetText(levelSeconds and formatTime(levelSeconds) or "...")
  killsText:SetText(string.format(L.KILLS, ns.KillCounter.GetKills()))
end

local function fontSize(fontString)
  local _, size = fontString:GetFont()
  return size
end

-- Fenstergröße aus Schriftgrößen berechnen, Breite am längsten möglichen Zeittext
local function updateLayout(db)
  local font, _, flags = GameFontNormalLarge:GetFont()
  timeText:SetFont(font, db.fontSize, flags)
  killsText:SetShown(db.showKills)

  timeText:SetText(WIDEST_TIME)
  local width = math.max(MIN_WIDTH, timeText:GetStringWidth() + 2 * PADDING_X)

  local height = 2 * PADDING_Y + fontSize(title) + LINE_GAP + db.fontSize
  if db.showKills then
    height = height + LINE_GAP + fontSize(killsText)
  end
  window:SetSize(width, height)
end

local function savePosition()
  local point, _, relativePoint, x, y = window:GetPoint()
  ns.db.pos = { point, relativePoint, x, y }
end

local function restorePosition()
  local pos = ns.db.pos or DEFAULT_POSITION
  window:ClearAllPoints()
  window:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
end

window:SetScript("OnDragStart", function(self)
  if not ns.db.locked then self:StartMoving() end
end)
window:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  savePosition()
end)

local sinceUpdate = 0
window:SetScript("OnUpdate", function(_, elapsed)
  sinceUpdate = sinceUpdate + elapsed
  if sinceUpdate < UPDATE_INTERVAL then return end
  sinceUpdate = 0
  refreshTexts()
end)

ns.OnLogin(restorePosition)

ns.RegisterApply(function(db)
  updateLayout(db)
  refreshTexts()
  Widgets.SetBackgroundAlpha(window, db.bgAlpha)
  window:SetShown(db.showTimer)
end)
