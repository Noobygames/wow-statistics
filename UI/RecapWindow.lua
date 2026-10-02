-- Session-Abschlusskarte (/lt recap): Überblick über die laufende Session als kleines Fenster,
-- z.B. als Abspann im Stream oder Screenshot für Discord. Zeilen: Bezeichnung links, Wert rechts.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Format = ns.Format
local Stats = ns.Stats
local History = ns.History

local RecapWindow = {}
ns.RecapWindow = RecapWindow

local MIN_WIDTH = 260
local MARGIN = 16
local CONTENT_TOP = -44
local ROW_HEIGHT = 18
local COLUMN_GAP = 24
local NO_VALUE = "-"

---------------------------------------------------------------------------
-- Inhalt
---------------------------------------------------------------------------

-- Einträge eines Journals seit Beginn der Session
local function sinceSessionStart(log)
  local startedAt = ns.character.currentSession.startedAt or 0
  local entries = {}
  for _, entry in ipairs(log) do
    if (entry.time or 0) >= startedAt then table.insert(entries, entry) end
  end
  return entries
end

-- Beste Beute = höchste Qualität, bei Gleichstand die neueste
local function bestLoot()
  local best
  for _, entry in ipairs(sinceSessionStart(ns.character.lootLog)) do
    if not best or (entry.quality or 0) >= (best.quality or 0) then best = entry end
  end
  return best and (best.link or best.name) or NO_VALUE
end

-- Gefährlichster Gegner = häufigste Ursache von Toden und Beinahe-Toden, "Name (Anzahl)"
local function mostDangerous()
  local counts = {}
  for _, logName in ipairs({ "deathLog", "nearDeathLog" }) do
    for _, entry in ipairs(sinceSessionStart(ns.character[logName])) do
      if entry.killer then counts[entry.killer] = (counts[entry.killer] or 0) + 1 end
    end
  end
  local name, count = nil, 0
  for killer, times in pairs(counts) do
    if times > count or (times == count and killer < name) then name, count = killer, times end
  end
  return name and string.format("%s (%d)", name, count) or NO_VALUE
end

local function xpWithRate()
  local rate = ns.Experience.GetRatePerHour(Stats.SESSION)
  local xp = Format.Number(Stats.GetXp(Stats.SESSION))
  return rate and string.format("%s (%s %s)", xp, Format.Number(rate), L.ROW_XP_RATE) or xp
end

-- Zeilen { label, value } der laufenden Session
function RecapWindow.BuildRows()
  local session = ns.character.currentSession
  return {
    { L.RECAP_CHARACTER, History.DisplayName(ns.characterKey) },
    { L.RECAP_TIME, Format.Duration(Stats.GetSeconds(Stats.SESSION)) },
    { L.RECAP_LEVELS, string.format("%d > %d", session.startLevel or ns.level, ns.level) },
    { L.RECAP_XP, xpWithRate() },
    { L.RECAP_KILLS, tostring(Stats.GetTotalKills(Stats.SESSION)) },
    { L.ROW_DEATHS, tostring(Stats.Get(Stats.SESSION, Stats.DEATHS)) },
    { L.ROW_NEAR_DEATHS, tostring(Stats.Get(Stats.SESSION, Stats.NEAR_DEATHS)) },
    { L.ROW_QUESTS, tostring(Stats.Get(Stats.SESSION, Stats.QUESTS)) },
    { L.ROW_MONEY, Format.Money(Stats.Get(Stats.SESSION, Stats.MONEY_EARNED)) },
    { L.RECAP_BEST_LOOT, bestLoot() },
    { L.RECAP_DANGER, mostDangerous() },
  }
end

---------------------------------------------------------------------------
-- Fenster
---------------------------------------------------------------------------
local panel = Widgets.CreatePanel("LevelTimerRecap", 0.95)
panel:SetPoint("CENTER")
panel:SetFrameStrata("DIALOG")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
panel:Hide()
table.insert(UISpecialFrames, "LevelTimerRecap")  -- mit ESC schließen
Widgets.CreateCloseButton(panel)

local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -14)

local rows = {}  -- { label, value } Schriftzeilen, bei Bedarf angelegt

local function getRow(index)
  if not rows[index] then
    local y = CONTENT_TOP - (index - 1) * ROW_HEIGHT
    local label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", MARGIN, y)
    local value = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    value:SetPoint("TOPRIGHT", -MARGIN, y)
    rows[index] = { label = label, value = value }
  end
  return rows[index]
end

local function render()
  title:SetText(L.RECAP_TITLE)
  local width = math.max(MIN_WIDTH, title:GetStringWidth() + 2 * MARGIN)
  local content = RecapWindow.BuildRows()
  for i, line in ipairs(content) do
    local row = getRow(i)
    row.label:SetText(line[1])
    row.value:SetText(line[2])
    width = math.max(width, row.label:GetStringWidth() + COLUMN_GAP + row.value:GetStringWidth() + 2 * MARGIN)
  end
  panel:SetSize(width, -CONTENT_TOP + #content * ROW_HEIGHT + MARGIN)
end

function ns.ToggleRecap()
  if not ns.db then return end
  if panel:IsShown() then
    panel:Hide()
  else
    render()
    panel:Show()
  end
end

-- Sprachwechsel bei offenem Fenster
ns.RegisterApply(function()
  if panel:IsShown() then render() end
end)
