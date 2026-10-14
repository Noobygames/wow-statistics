-- Anzeige der laufenden Ziele am Bildschirm: je Ziel eine Karte (Lib/Card.lua von Level Time) mit Titel, Zeile,
-- Stand "12 / 100" und Fortschrittsbalken, untereinander in einem verschiebbaren Rahmen. Beim Erreichen eines
-- Ziels erscheint die Einblendung von Level Time (Alerts.Show) und eine Chatzeile.
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local L = ns.L
local Card = LT.Card
local Widgets = LT.Widgets
local Alerts = LT.Alerts

local Tracker = {}
ns.Tracker = Tracker

local CARD_GAP = 6
local DEFAULT_POSITION = { "TOPRIGHT", "TOPRIGHT", -40, -220 }
local DONE_COLOR = { 0.4, 0.9, 0.4 }
local MIN_SCALE, MAX_SCALE = 0.5, 2

Tracker.MIN_SCALE, Tracker.MAX_SCALE = MIN_SCALE, MAX_SCALE

local frame = CreateFrame("Frame", "StreamGoalTracker", UIParent)
frame:SetSize(1, 1)
frame:Hide()
Tracker.frame = frame

local cards = {}  -- eine Karte je Platz, wird wiederverwendet

local function cardAt(index)
  if not cards[index] then
    cards[index] = Card.Create("StreamGoalCard" .. index)
    cards[index].frame:SetParent(frame)
  end
  return cards[index]
end

-- Karten neu aufbauen: Inhalt aus den Zielen, gleiche Breite, untereinander
function Tracker.Refresh()
  if not ns.db then return end
  local active = Goals.Active()
  local visible = ns.db.settings.showTracker and #active > 0
  frame:SetShown(visible)
  for i = #active + 1, #cards do cards[i].frame:Hide() end
  if not visible then return end

  local width, height = 0, 0
  for i, goal in ipairs(active) do
    local def = Goals.GetKind(goal.kind)
    local card = cardAt(i)
    card.Set({
      color = def.color,
      icon = def.icon,
      title = def.title(goal),
      body = def.body and def.body(goal) or nil,
      time = true,
    })
    card.SetTime(string.format("%d / %d", goal.progress, goal.target))
    card.frame:Show()
    width = math.max(width, card.frame:GetWidth())
  end
  for i, goal in ipairs(active) do
    local card = cards[i]
    card.frame:SetWidth(width)
    card.SetFraction(Goals.Fraction(goal))
    card.frame:ClearAllPoints()
    if i == 1 then
      card.frame:SetPoint("TOPLEFT", frame, "TOPLEFT")
    else
      card.frame:SetPoint("TOPLEFT", cards[i - 1].frame, "BOTTOMLEFT", 0, -CARD_GAP)
    end
    height = height + card.frame:GetHeight() + (i > 1 and CARD_GAP or 0)
  end
  frame:SetSize(width, height)
end

---------------------------------------------------------------------------
-- Position und Größe
---------------------------------------------------------------------------
local mover = Widgets.CreateMover(frame, {
  default = DEFAULT_POSITION,
  get = function() return ns.db and ns.db.settings.pos end,
  set = function(pos) ns.db.settings.pos = pos end,
  onMovingChanged = function(moving)
    if moving then
      -- Beispielkarte, damit man im Verschiebemodus etwas zum Greifen hat
      if #Goals.Active() == 0 then Tracker.ShowSample() end
    else
      Tracker.Refresh()
    end
  end,
})
Tracker.mover = mover

function Tracker.ShowSample()
  local card = cardAt(1)
  card.Set({ color = { 0.96, 0.79, 0.36 }, icon = Alerts.ICONS.levelUp,
    title = string.format(L.SG_GOAL_LEVEL, 20), time = true })
  card.SetTime("12 / 20")
  card.frame:Show()
  card.frame:ClearAllPoints()
  card.frame:SetPoint("TOPLEFT", frame, "TOPLEFT")
  frame:SetSize(card.frame:GetWidth(), card.frame:GetHeight())
  card.SetFraction(0.6)
  frame:Show()
end

function Tracker.SetScale(scale)
  scale = math.max(MIN_SCALE, math.min(MAX_SCALE, scale))
  ns.db.settings.scale = scale
  mover.SetScale(scale)
  return scale
end

function Tracker.SetShown(shown)
  ns.db.settings.showTracker = shown and true or false
  Tracker.Refresh()
end

---------------------------------------------------------------------------
-- Ereignisse
---------------------------------------------------------------------------
Goals.OnChange(function(event, goal)
  if event == "done" then
    local title = Goals.Title(goal)
    ns.Print(string.format(L.SG_CHAT_DONE, title))
    Alerts.Show(title, DONE_COLOR, {
      sound = ns.db.settings.sound,
      notice = { icon = Goals.GetKind(goal.kind).icon, title = L.SG_NOTICE_DONE, body = title },
    })
  end
  Tracker.Refresh()
end)

LT.OnLogin(function()
  mover.SetScale(ns.db.settings.scale)
  mover.Restore()
  Tracker.Refresh()
end)
