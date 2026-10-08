-- Anzeige für das Lagerfeuer in WoW Forever (Zustände liefert Assist/CampFire.lua) als Karte (Lib/Card.lua):
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
local FADE_IN_SECONDS = 0.2
local UPDATE_INTERVAL = 0.05
local DONE_SECONDS = 4          -- "Lagervorteile aktiv" bleibt so lange stehen
local PREVIEW_SECONDS = 8
local DEMO_DURATION = 60
local DEMO_REMAINING = 42
local PULSE_SPEED = 3
local COLORS = {
  countdown = { 1, 0.82, 0 },
  done = { 0.35, 1, 0.45 },
  hint = { 0.55, 0.8, 1 },
}
local PREVIEW_KINDS = { "hint", "countdown", "done" }

local card = ns.Card.Create("LevelTimerCamp")
local frame = card.frame
frame:SetFrameStrata("HIGH")

local current   -- angezeigter Zustand: { kind, spellId, expiration, duration, frozen, endsAt }
local override  -- Vorschau oder Verschiebemodus; solange gesetzt, ignoriert die Anzeige die echten Zustände
local shownAt

local function titleFor(kind)
  if kind == "countdown" then return L.CAMP_TITLE_COUNTDOWN end
  if kind == "done" then return L.CAMP_DONE end
  return L.CAMP_HINT_TEXT
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
    card.SetTime(string.format(L.SECONDS_SHORT, math.ceil(remaining)))
    card.SetFraction(current.duration > 0 and remaining / current.duration or 0)
  end
  local alpha = math.min(1, (now - shownAt) / FADE_IN_SECONDS)
  if current.kind == "hint" then alpha = alpha * (0.8 + 0.2 * math.sin(now * PULSE_SPEED)) end
  frame:SetAlpha(alpha)
end

local function hide()
  current = nil
  frame:Hide()
end

local function setCard(state)
  card.Set({
    color = COLORS[state.kind],
    icon = state.spellId,
    title = titleFor(state.kind),
    time = state.kind == "countdown",
  })
end

local function display(state)
  current = state
  setCard(state)
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
  if current and current.kind == state.kind then
    if state.kind == "countdown" then  -- nur nachführen, ohne Neuaufbau
      current.expiration = GetTime() + state.remaining
      current.duration = state.duration
    end
    if state.kind ~= "done" then return end
  end
  display({
    kind = state.kind,
    spellId = state.spellId,
    expiration = state.remaining and GetTime() + state.remaining or nil,
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
  if current then setCard(current) end  -- Sprache kann gewechselt haben
end)
