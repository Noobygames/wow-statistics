-- Anzeige für das Lagerfeuer in WoW Forever (Zustände liefert Assist/CampFire.lua): Symbol des Zaubers, Text,
-- Restzeit als große Zahl und ein Balken, der sich leert; Farbleiste links je Zustand.
--   countdown  Einladendes Lagerfeuer läuft: "Sitzen bleiben" mit Restzeit und Balken
--   hint       Feuer in der Nähe, aber keine Lagervorteile: Hinweis, sich hinzusetzen (pulsiert leicht)
--   done       kurz nach dem Countdown: "Lagervorteile aktiv"
-- Einstellungen: campScale, campPos (verschiebbar, Vorschau mit CampDisplay.Preview), campSound (bei "done").
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets

local CampDisplay = {}
ns.CampDisplay = CampDisplay

CampDisplay.MIN_SCALE = 0.5  -- Grenzen des Reglers in den Einstellungen
CampDisplay.MAX_SCALE = 2
local DEFAULT_POSITION = { "TOP", "TOP", 0, -230 }  -- unter den Einblendungen
local ICON_SIZE = 36
local PADDING = 10
local ACCENT_WIDTH = 4
local ICON_GAP = 10
local MIN_WIDTH = 210
local MAX_TEXT_WIDTH = 280      -- längere Texte brechen um
local BAR_HEIGHT = 5
local BAR_GAP = 6
local BACKGROUND_COLOR = { 0.03, 0.04, 0.08, 0.82 }
local BAR_BACK_COLOR = { 1, 1, 1, 0.12 }
local FADE_IN_SECONDS = 0.2
local UPDATE_INTERVAL = 0.05
local DONE_SECONDS = 4          -- "Lagervorteile aktiv" bleibt so lange stehen
local PREVIEW_SECONDS = 8
local DEMO_DURATION = 60
local DEMO_REMAINING = 42
local PULSE_SPEED = 3
local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local COLORS = {
  countdown = { 1, 0.82, 0 },
  done = { 0.35, 1, 0.45 },
  hint = { 0.55, 0.8, 1 },
}
local PREVIEW_KINDS = { "hint", "countdown", "done" }

local frame = CreateFrame("Frame", "LevelTimerCamp", UIParent)
frame:SetSize(MIN_WIDTH, ICON_SIZE + 2 * PADDING)
frame:SetFrameStrata("HIGH")
frame:Hide()

local background = frame:CreateTexture(nil, "BACKGROUND")
background:SetColorTexture(unpack(BACKGROUND_COLOR))
background:SetAllPoints(frame)

local accent = frame:CreateTexture(nil, "BORDER")
accent:SetColorTexture(1, 1, 1, 1)
accent:SetPoint("TOPLEFT")
accent:SetPoint("BOTTOMLEFT")
accent:SetWidth(ACCENT_WIDTH)

local icon = frame:CreateTexture(nil, "ARTWORK")
icon:SetSize(ICON_SIZE, ICON_SIZE)
icon:SetPoint("TOPLEFT", ACCENT_WIDTH + PADDING, -PADDING)

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOPLEFT", icon, "TOPRIGHT", ICON_GAP, -2)
title:SetJustifyH("LEFT")

local timeText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
timeText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
timeText:SetJustifyH("LEFT")

local barBack = frame:CreateTexture(nil, "ARTWORK")
barBack:SetColorTexture(unpack(BAR_BACK_COLOR))
barBack:SetHeight(BAR_HEIGHT)
barBack:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", ACCENT_WIDTH + PADDING, PADDING - 2)
barBack:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PADDING, PADDING - 2)

local barFill = frame:CreateTexture(nil, "ARTWORK", nil, 1)
barFill:SetColorTexture(1, 1, 1, 1)
barFill:SetHeight(BAR_HEIGHT)
barFill:SetPoint("TOPLEFT", barBack)

local current   -- angezeigter Zustand: { kind, spellId, expiration, duration, frozen, doneUntil, endsAt }
local override  -- Vorschau oder Verschiebemodus; solange gesetzt, ignoriert die Anzeige die echten Zustände
local shownAt

local function iconFor(spellId)
  local texture = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellId)
  return texture or FALLBACK_ICON
end

local function titleFor(kind)
  if kind == "countdown" then return L.CAMP_TITLE_COUNTDOWN end
  if kind == "done" then return L.CAMP_DONE end
  return L.CAMP_HINT_TEXT
end

-- Größe aus den Texten der gewählten Sprache; Hinweis und "aktiv" ohne Zeit und Balken
local function layout(kind)
  local hasTime = kind == "countdown"
  title:SetWidth(0)  -- erst natürliche Breite, dann bei Bedarf umbrechen
  local titleWidth = title:GetStringWidth() or 0
  if titleWidth > MAX_TEXT_WIDTH then
    title:SetWidth(MAX_TEXT_WIDTH)
    titleWidth = MAX_TEXT_WIDTH
  end
  local titleHeight = title:GetStringHeight() or 0
  timeText:SetShown(hasTime)
  barBack:SetShown(hasTime)
  barFill:SetShown(hasTime)

  local timeWidth, timeHeight = 0, 0
  if hasTime then
    timeText:SetText(string.format(L.SECONDS_SHORT, 99))  -- breiteste Zahl
    timeWidth = timeText:GetStringWidth() or 0
    timeHeight = (timeText:GetStringHeight() or 0) + 2
  end
  local textWidth = math.max(titleWidth, timeWidth)
  local contentHeight = math.max(ICON_SIZE, titleHeight + timeHeight)
  frame:SetWidth(math.max(MIN_WIDTH, ACCENT_WIDTH + PADDING + ICON_SIZE + ICON_GAP + textWidth + PADDING))
  frame:SetHeight(2 * PADDING + contentHeight + (hasTime and BAR_GAP + BAR_HEIGHT or 0))
end

local function remainingOf(state)
  if state.frozen then return state.frozen end
  return math.max(0, state.expiration - GetTime())
end

-- Zahl, Balken und Pulsieren; läuft im OnUpdate, solange die Anzeige steht
local function refresh()
  if not current then return end
  local now = GetTime()
  if current.kind == "countdown" then
    local remaining = remainingOf(current)
    timeText:SetText(string.format(L.SECONDS_SHORT, math.ceil(remaining)))
    local fraction = current.duration > 0 and math.min(1, remaining / current.duration) or 0
    barFill:SetWidth(math.max(1, (frame:GetWidth() - ACCENT_WIDTH - 2 * PADDING) * fraction))
  end
  local alpha = math.min(1, (now - shownAt) / FADE_IN_SECONDS)
  if current.kind == "hint" then alpha = alpha * (0.8 + 0.2 * math.sin(now * PULSE_SPEED)) end
  frame:SetAlpha(alpha)
end

local function hide()
  current = nil
  frame:Hide()
end

local function display(state)
  current = state
  local color = COLORS[state.kind]
  accent:SetColorTexture(color[1], color[2], color[3], 1)
  barFill:SetColorTexture(color[1], color[2], color[3], 1)
  title:SetTextColor(color[1], color[2], color[3])
  timeText:SetTextColor(1, 1, 1)
  icon:SetTexture(iconFor(state.spellId))
  title:SetText(titleFor(state.kind))
  layout(state.kind)
  shownAt = GetTime()
  frame:SetAlpha(0)
  frame:Show()
  refresh()
end

local sinceUpdate = 0
frame:SetScript("OnUpdate", function(_, elapsed)
  sinceUpdate = sinceUpdate + elapsed
  if sinceUpdate < UPDATE_INTERVAL then return end
  sinceUpdate = 0
  if not current then return end
  if current.endsAt and GetTime() >= current.endsAt then
    if override == current then override = nil end
    hide()
    return
  end
  refresh()
end)

-- Zustand von CampFire.Check: nil blendet aus, ein laufender "done" bleibt bis zum Ende stehen
function CampDisplay.Show(state)
  if override then return end
  if not state then
    if not (current and current.kind == "done") then hide() end
    return
  end
  local remaining = state.remaining
  if current and current.kind == state.kind and state.kind == "countdown" then
    current.expiration = GetTime() + remaining  -- nur nachführen, ohne Neuaufbau
    current.duration = state.duration
    return
  end
  if current and current.kind == state.kind and state.kind == "hint" then return end
  display({
    kind = state.kind,
    spellId = state.spellId,
    expiration = remaining and GetTime() + remaining or nil,
    duration = state.duration,
  })
end

function CampDisplay.ShowDone()
  if override then return end
  display({ kind = "done", spellId = ns.CampFire.BENEFITS_SPELL_ID, endsAt = GetTime() + DONE_SECONDS })
  if ns.db and ns.db.campSound then ns.Alerts.PlaySound() end
end

---------------------------------------------------------------------------
-- Position, Größe, Vorschau
---------------------------------------------------------------------------
local mover = Widgets.CreateMover(frame, {
  default = DEFAULT_POSITION,
  get = function() return ns.db and ns.db.campPos end,
  set = function(pos) ns.db.campPos = pos end,
  onMovingChanged = function(moving)
    if not moving then
      override = nil
      hide()
    end
  end,
})

local function demoState(kind)
  local spellId = kind == "hint" and ns.CampFire.NEARBY_SPELL_ID
    or kind == "done" and ns.CampFire.BENEFITS_SPELL_ID or ns.CampFire.INVITING_SPELL_ID
  return {
    kind = kind,
    spellId = spellId,
    expiration = GetTime() + DEMO_REMAINING,
    duration = DEMO_DURATION,
    endsAt = GetTime() + PREVIEW_SECONDS,
  }
end

local previewIndex = 0

-- Vorschau: jeder Aufruf zeigt den nächsten Zustand (Hinweis, Countdown, "aktiv") ein paar Sekunden
function CampDisplay.Preview()
  if mover.IsMoving() then CampDisplay.SetMoving(false) end
  previewIndex = previewIndex % #PREVIEW_KINDS + 1
  override = demoState(PREVIEW_KINDS[previewIndex])
  display(override)
end

-- Verschiebemodus: der Countdown steht still (42 s), Ziehen verschiebt, Rechtsklick oder erneuter Aufruf beendet
function CampDisplay.SetMoving(enabled)
  enabled = enabled and true or false
  if enabled == mover.IsMoving() then return end
  if enabled then
    override = { kind = "countdown", spellId = ns.CampFire.INVITING_SPELL_ID, frozen = DEMO_REMAINING, duration = DEMO_DURATION }
    display(override)
    frame:SetAlpha(1)
  end
  mover.SetMoving(enabled)
end

function CampDisplay.IsMoving()
  return mover.IsMoving()
end

function CampDisplay.ResetPosition()
  mover.Reset()
end

ns.OnLogin(mover.Restore)

ns.RegisterApply(function(db)
  mover.SetScale(math.max(CampDisplay.MIN_SCALE, math.min(CampDisplay.MAX_SCALE, db.campScale)))
  mover.Sync()
  if current then  -- Sprache kann gewechselt haben
    title:SetText(titleFor(current.kind))
    layout(current.kind)
  end
end)
