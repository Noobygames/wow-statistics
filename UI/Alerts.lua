-- Große Einblendungen oben in der Bildschirmmitte für Stream-Momente: Level-Up, Rare- und Elite-Kill,
-- epische Beute, Beinahe-Tod. Jede Art ist einzeln schaltbar (Einstellungen alert*), alle aus.
-- Aussehen: alertStyle (Text oder Banner), alertScale, alertDuration, alertSound; Position alertPos
-- (ziehen im Verschiebemodus, Alerts.SetMoving). Dieselbe Einblendung zeigt auch Hinweise (Alerts.Notify).
-- Quellen: ns.OnLevelStarted und neue Journal-Einträge (Journal.OnAdd), kein eigenes Event-Parsing.
-- In Dungeons und Raids ist fast jeder Gegner Elite: dort keine Elite-Einblendung (IsInInstance).
-- In Raids ist epische Beute normal: dort keine Beute-Einblendung.
local _, ns = ...
local L = ns.L
local Journal = ns.Journal
local Classification = ns.Classification

local Alerts = {}
ns.Alerts = Alerts

local FADE_IN_SECONDS = 0.25  -- weich einblenden
local FADE_SECONDS = 1       -- nach der Anzeigedauer ausblenden
local DEFAULT_POSITION = { "TOP", "TOP", 0, -160 }
local EPIC_QUALITY = 4
local GROUP_INSTANCES = { party = true, raid = true }  -- Instanzarten von IsInInstance mit Elite-Gegnern
local WHITE_TEXTURE = "Interface\Buttons\WHITE8x8"
local RAID_WARNING_SOUND = 8959  -- SOUNDKIT.RAID_WARNING, in allen Clients gleich
-- Einstellung alertStyle: nur Text oder Banner (dunkler Grund mit Farbleisten)
Alerts.STYLE_TEXT = "text"
Alerts.STYLE_BANNER = "banner"
Alerts.MIN_SCALE = 0.5
Alerts.MAX_SCALE = 2
Alerts.MIN_DURATION = 1
Alerts.MAX_DURATION = 10
local BANNER_PADDING_X = 28
local BANNER_PADDING_Y = 14
local BANNER_MIN_WIDTH = 280
local BANNER_BACKGROUND_ALPHA = 0.78
local ACCENT_WIDTH = 5       -- Leiste links und rechts
local ACCENT_LINE_HEIGHT = 2 -- Linie unten
local COLORS = {
  levelUp = { 1, 0.82, 0 },
  rare = { 0.75, 0.75, 1 },
  elite = { 1, 0.5, 0.1 },
  loot = { 0.64, 0.21, 0.93 },
  nearDeath = { 1, 0.25, 0.25 },
}
Alerts.WARNING_COLOR = { 1, 0.6, 0.2 }   -- Hinweise beim Leveln (fehlende Buffs, Taschen, ...)
Alerts.REMINDER_COLOR = COLORS.levelUp   -- Hinweise zum Level-Up (Lehrer)

local frame = CreateFrame("Frame", "LevelTimerAlert", UIParent)
frame:SetSize(1, 1)
frame:SetPoint(DEFAULT_POSITION[1], UIParent, DEFAULT_POSITION[2], DEFAULT_POSITION[3], DEFAULT_POSITION[4])
frame:SetFrameStrata("HIGH")
frame:SetClampedToScreen(true)

-- Banner: Hintergrund, Leisten links und rechts und eine Linie unten in der Farbe der Art
local background = frame:CreateTexture(nil, "BACKGROUND")
background:SetTexture(WHITE_TEXTURE)
background:SetAllPoints(frame)
local accentLeft = frame:CreateTexture(nil, "BORDER")
accentLeft:SetTexture(WHITE_TEXTURE)
accentLeft:SetPoint("TOPLEFT")
accentLeft:SetPoint("BOTTOMLEFT")
accentLeft:SetWidth(ACCENT_WIDTH)
local accentRight = frame:CreateTexture(nil, "BORDER")
accentRight:SetTexture(WHITE_TEXTURE)
accentRight:SetPoint("TOPRIGHT")
accentRight:SetPoint("BOTTOMRIGHT")
accentRight:SetWidth(ACCENT_WIDTH)
local accentLine = frame:CreateTexture(nil, "BORDER")
accentLine:SetTexture(WHITE_TEXTURE)
accentLine:SetPoint("BOTTOMLEFT")
accentLine:SetPoint("BOTTOMRIGHT")
accentLine:SetHeight(ACCENT_LINE_HEIGHT)
local bannerParts = { background, accentLeft, accentRight, accentLine }

frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
frame.text:SetPoint("CENTER")
frame:Hide()

local shownAt
local moving  -- Verschiebemodus: bleibt stehen und lässt sich ziehen

local function isBanner()
  return ns.db and ns.db.alertStyle == Alerts.STYLE_BANNER
end

-- Größe aus dem Text; Banner mit Rand und Mindestbreite, Text-Stil nur so groß wie der Text
local function layout()
  local width, height = frame.text:GetStringWidth() or 0, frame.text:GetStringHeight() or 0
  local banner = isBanner()
  for _, part in ipairs(bannerParts) do part:SetShown(banner) end
  if banner then
    frame.text:SetShadowOffset(1, -1)
    frame:SetSize(math.max(BANNER_MIN_WIDTH, width + 2 * BANNER_PADDING_X), height + 2 * BANNER_PADDING_Y)
  else
    frame.text:SetShadowOffset(2, -2)
    frame:SetSize(math.max(1, width), math.max(1, height))
  end
end

local function setColor(color)
  frame.text:SetTextColor(unpack(color))
  local r, g, b = unpack(color)
  background:SetColorTexture(0.03, 0.04, 0.08, BANNER_BACKGROUND_ALPHA)
  for _, part in ipairs({ accentLeft, accentRight, accentLine }) do
    part:SetColorTexture(r, g, b, 1)
  end
end

local function duration()
  return math.max(Alerts.MIN_DURATION, math.min(Alerts.MAX_DURATION, ns.db and ns.db.alertDuration or 3))
end

frame:SetScript("OnUpdate", function(self)
  if moving then return end
  local age = GetTime() - shownAt
  local hold = duration()
  if age >= hold + FADE_SECONDS then
    self:Hide()
  elseif age > hold then
    self:SetAlpha(1 - (age - hold) / FADE_SECONDS)
  elseif age < FADE_IN_SECONDS then
    self:SetAlpha(age / FADE_IN_SECONDS)
  else
    self:SetAlpha(1)
  end
end)

-- Neue Einblendung ersetzt eine laufende; im Verschiebemodus erscheint nichts Neues
function Alerts.Show(message, color)
  ns.Debug("alert", "%s", message)
  if moving then return end
  frame.text:SetText(message)
  setColor(color)
  layout()
  shownAt = GetTime()
  frame:SetAlpha(0)
  frame:Show()
  if ns.db and ns.db.alertSound and PlaySound then PlaySound(RAID_WARNING_SOUND) end
end

---------------------------------------------------------------------------
-- Position: ziehen im Verschiebemodus, gespeichert in alertPos
---------------------------------------------------------------------------
local appliedPos

local function savePosition()
  local point, _, relativePoint, x, y = frame:GetPoint()
  ns.db.alertPos = { point, relativePoint, x, y }
  appliedPos = ns.db.alertPos
end

local function restorePosition()
  appliedPos = ns.db.alertPos
  local pos = ns.db.alertPos or DEFAULT_POSITION
  frame:ClearAllPoints()
  frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
end

frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self)
  if moving then self:StartMoving() end
end)
frame:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  savePosition()
end)
frame:SetScript("OnMouseUp", function(_, mouseButton)
  if moving and mouseButton == "RightButton" then Alerts.SetMoving(false) end
end)

function Alerts.IsMoving()
  return moving or false
end

-- Verschiebemodus: Beispiel bleibt stehen, Ziehen verschiebt, Rechtsklick oder erneuter Aufruf beendet
function Alerts.SetMoving(enabled)
  enabled = enabled and true or false
  if enabled == (moving or false) then return end
  moving = false
  if enabled then
    Alerts.Show(L.ALERT_MOVE_HINT, COLORS.levelUp)
    moving = true
    frame:SetAlpha(1)
    frame:EnableMouse(true)
  else
    frame:EnableMouse(false)
    frame:Hide()
  end
end

function Alerts.ResetPosition()
  ns.db.alertPos = nil
  restorePosition()
end

-- Hinweis an den Spieler: jede Nachricht als Chatzeile, alle zusammen in einer Einblendung.
-- messages = Text oder Liste von Texten
function Alerts.Notify(messages, color)
  if type(messages) == "string" then messages = { messages } end
  for _, message in ipairs(messages) do
    ns.Print(message)
  end
  Alerts.Show(table.concat(messages, "\n"), color)
end

-- Arten: Einstellung, Farbe, Text aus einem Wert (Level, Name, Link, Prozent) und Beispielwert
-- für /lt debug alert
Alerts.KINDS = {
  levelUp = { setting = "alertLevelUp", color = COLORS.levelUp, format = "ALERT_LEVEL_UP",
    sample = function() return ns.level + 1 end },
  rare = { setting = "alertRareKill", color = COLORS.rare, format = "ALERT_RARE_KILL",
    sample = function() return "Hogger" end },
  elite = { setting = "alertEliteKill", color = COLORS.elite, format = "ALERT_ELITE_KILL",
    sample = function() return "Hogger" end },
  loot = { setting = "alertEpicLoot", color = COLORS.loot, format = "ALERT_EPIC_LOOT",
    sample = function() return "[Thunderfury]" end },
  nearDeath = { setting = "alertNearDeath", color = COLORS.nearDeath, format = "ALERT_NEAR_DEATH",
    sample = function() return 4 end },
}

local function showKind(kind, value)
  local definition = Alerts.KINDS[kind]
  Alerts.Show(string.format(L[definition.format], value), definition.color)
end

-- Nur, wenn die Art eingeschaltet ist
local function alert(kind, value)
  if ns.db[Alerts.KINDS[kind].setting] then showKind(kind, value) end
end

-- Beispiel unabhängig von der Einstellung (Fehlersuche); false bei unbekannter Art
function Alerts.ShowSample(kind)
  local definition = Alerts.KINDS[kind]
  if not definition then return false end
  showKind(kind, definition.sample())
  return true
end

ns.OnLevelStarted(function(newLevel)
  alert("levelUp", newLevel)
end)

local function instanceType()
  local inInstance, kind = IsInInstance()
  return inInstance and kind or nil
end

local handlers = {
  killLog = function(entry)
    local name = entry.name or L.UNKNOWN_NAME
    if Classification.IsRare(entry.classification) and ns.db.alertRareKill then
      alert("rare", name)
    elseif Classification.IsElite(entry.classification) and not GROUP_INSTANCES[instanceType()] then
      alert("elite", name)
    end
  end,
  lootLog = function(entry)
    if (entry.quality or 0) >= EPIC_QUALITY and instanceType() ~= "raid" then
      alert("loot", entry.link or entry.name or "?")
    end
  end,
  nearDeathLog = function(entry)
    alert("nearDeath", entry.lowestPercent)
  end,
}

Journal.OnAdd(function(logName, entry)
  local handler = handlers[logName]
  if handler then handler(entry) end
end)

-- Vorschau: eine Beispiel-Einblendung mit den aktuellen Einstellungen
function Alerts.Preview()
  if moving then Alerts.SetMoving(false) end
  Alerts.ShowSample("levelUp")
end

ns.RegisterApply(function(db)
  frame:SetScale(math.max(Alerts.MIN_SCALE, math.min(Alerts.MAX_SCALE, db.alertScale)))
  if db.alertPos ~= appliedPos then restorePosition() end
  layout()
end)

ns.OnLogin(restorePosition)
ns.OnLogout(function() moving = false end)
