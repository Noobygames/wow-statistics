-- Datentext für Leisten wie Titan Panel, ElvUI oder Bazooka über LibDataBroker.
-- Das Addon bringt die Bibliothek nicht selbst mit: Sie wird genutzt, wenn ein anderes Addon sie
-- geladen hat (beim Login sind alle Addons geladen). Ohne sie bleibt der Datentext einfach aus.
-- Text: Spielzeit und XP/h im Bereich des Fensters; Tooltip: alle eingeschalteten Werte.
local _, ns = ...
local L = ns.L
local Format = ns.Format
local Stats = ns.Stats
local Experience = ns.Experience

local Broker = {}
ns.Broker = Broker

local UPDATE_INTERVAL = 1  -- Sekunden
local TEXT_SEPARATOR = " - "  -- "|" ist in WoW-Texten ein Steuerzeichen

local dataObject  -- nil, solange keine LibDataBroker verfügbar ist

local function brokerText()
  local scope = ns.db.windowScope
  local seconds = Stats.GetSeconds(scope)
  local parts = { seconds and Format.Duration(seconds) or "..." }
  local rate = Experience.IsLeveling() and Experience.GetRatePerHour(scope)
  if rate then
    table.insert(parts, Format.Number(rate) .. " XP/h")
  end
  return table.concat(parts, TEXT_SEPARATOR)
end

local function showTooltip(tooltip)
  local scope = ns.db.windowScope
  tooltip:AddLine("LevelTimer")
  for _, stat in ipairs(ns.STAT_LINES) do
    if ns.db[stat.setting] then
      for _, row in ipairs(stat.rows) do
        tooltip:AddDoubleLine(L[row.label], row.value(scope), 1, 0.82, 0, 1, 1, 1)
      end
    end
  end
  tooltip:AddLine(" ")
  tooltip:AddLine(L.TOOLTIP_LEFT, 0.7, 0.7, 0.7)
  tooltip:AddLine(L.TOOLTIP_SHIFT_LEFT, 0.7, 0.7, 0.7)
  tooltip:AddLine(L.TOOLTIP_RIGHT, 0.7, 0.7, 0.7)
end

-- Klicks wie beim Minimap-Button
local function onClick(_, mouseButton)
  if mouseButton == "RightButton" then
    ns.Set("showTimer", not ns.db.showTimer)
  elseif IsShiftKeyDown() then
    ns.ToggleHistory()
  else
    ns.ToggleOptions()
  end
end

function Broker.Refresh()
  if dataObject then
    dataObject.text = brokerText()
  end
end

ns.OnLogin(function()
  local broker = LibStub and LibStub("LibDataBroker-1.1", true)
  if not broker or dataObject then return end
  dataObject = broker:NewDataObject("LevelTimer", {
    type = "data source",
    label = "LevelTimer",
    icon = ns.Widgets.ICON,
    text = "...",
    OnClick = onClick,
    OnTooltipShow = showTooltip,
  })
end)

local updater = CreateFrame("Frame")
local sinceUpdate = 0
updater:SetScript("OnUpdate", function(_, elapsed)
  sinceUpdate = sinceUpdate + elapsed
  if sinceUpdate < UPDATE_INTERVAL then return end
  sinceUpdate = 0
  Broker.Refresh()
end)
