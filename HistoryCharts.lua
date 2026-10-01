-- Graphen der Historie: ein Reiter mit Unterreitern, je einer pro Diagramm.
-- Daten aus Analysis.lua, Darstellung aus Charts.lua.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local Format = ns.Format
local Analysis = ns.Analysis
local Charts = ns.Charts

local SUBTAB_GAP = 10
local SUBTABS_HEIGHT = 24  -- Zeile der Unterreiter über dem Diagramm

local COLUMN, RANK = "column", "rank"

-- kind: Säulen (Verlauf) oder Rangliste; axis beschriftet bei Säulen den Maximalwert
local CHARTS = {
  { tab = "CHART_LEVEL_TIME", kind = COLUMN, data = Analysis.TimePerLevel, axis = Format.Duration },
  { tab = "CHART_LEVEL_XP_RATE", kind = COLUMN, data = Analysis.XpRatePerLevel, axis = Format.Number },
  { tab = "CHART_KILLS_PER_DAY", kind = COLUMN, data = Analysis.KillsPerDay, axis = tostring },
  { tab = "CHART_TOP_KILLS", kind = RANK, data = Analysis.TopKills },
  { tab = "CHART_DEATH_CAUSES", kind = RANK, data = Analysis.DeathCauses },
}

local function create(parent, width, height)
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetAllPoints(parent)

  local chartHeight = height - SUBTABS_HEIGHT
  local charts = {
    [COLUMN] = Charts.CreateColumnChart(frame, width, chartHeight),
    [RANK] = Charts.CreateRankChart(frame, width, chartHeight),
  }
  for _, chart in pairs(charts) do
    chart:SetPoint("TOPLEFT", 0, -SUBTABS_HEIGHT)
  end

  local emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  emptyText:SetPoint("CENTER", 0, -SUBTABS_HEIGHT / 2)

  local selected = CHARTS[1]
  local characterKey

  local previousTab
  for _, definition in ipairs(CHARTS) do
    definition.tabButton = Widgets.CreateTab(frame, "GameFontHighlightSmall", function()
      selected = definition
      frame:Render(characterKey)
    end)
    if previousTab then
      definition.tabButton:SetPoint("LEFT", previousTab, "RIGHT", SUBTAB_GAP, 0)
    else
      definition.tabButton:SetPoint("TOPLEFT")
    end
    previousTab = definition.tabButton
  end

  function frame:Render(key)
    characterKey = key
    for _, definition in ipairs(CHARTS) do
      definition.tabButton:SetLabel(L[definition.tab])
      definition.tabButton:SetActive(definition == selected)
    end

    local items = selected.data(key)
    local hasData = #items > 0
    emptyText:SetText(L.CHART_EMPTY)
    emptyText:SetShown(not hasData)
    for kind, chart in pairs(charts) do
      chart:SetShown(hasData and kind == selected.kind)
    end
    if hasData then
      charts[selected.kind]:SetItems(items, selected.axis)
    end
  end

  return frame
end

ns.HistoryWindow.AddView({ tab = "HISTORY_TAB_CHARTS", Create = create })
