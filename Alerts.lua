-- Große Einblendungen oben in der Bildschirmmitte für Stream-Momente: Level-Up, Rare- und Elite-Kill,
-- epische Beute, Beinahe-Tod. Jede Art ist einzeln schaltbar (Einstellungen alert*), alle aus.
-- Quellen: ns.OnLevelStarted und neue Journal-Einträge (Journal.OnAdd), kein eigenes Event-Parsing.
-- In Dungeons und Raids ist fast jeder Gegner Elite: dort keine Elite-Einblendung (IsInInstance).
local _, ns = ...
local L = ns.L
local Journal = ns.Journal
local Classification = ns.Classification

local Alerts = {}
ns.Alerts = Alerts

local HOLD_SECONDS = 3   -- voll sichtbar
local FADE_SECONDS = 1   -- danach ausblenden
local OFFSET_Y = -160    -- Abstand zur Bildschirmoberkante
local EPIC_QUALITY = 4
local GROUP_INSTANCES = { party = true, raid = true }  -- Instanzarten von IsInInstance mit Elite-Gegnern
local COLORS = {
  levelUp = { 1, 0.82, 0 },
  rare = { 0.75, 0.75, 1 },
  elite = { 1, 0.5, 0.1 },
  loot = { 0.64, 0.21, 0.93 },
  nearDeath = { 1, 0.25, 0.25 },
}

local frame = CreateFrame("Frame", "LevelTimerAlert", UIParent)
frame:SetSize(1, 1)
frame:SetPoint("TOP", UIParent, "TOP", 0, OFFSET_Y)
frame:SetFrameStrata("HIGH")
frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
frame.text:SetPoint("CENTER")
frame:Hide()

local shownAt

frame:SetScript("OnUpdate", function(self)
  local age = GetTime() - shownAt
  if age >= HOLD_SECONDS + FADE_SECONDS then
    self:Hide()
  elseif age > HOLD_SECONDS then
    self:SetAlpha(1 - (age - HOLD_SECONDS) / FADE_SECONDS)
  end
end)

-- Neue Einblendung ersetzt eine laufende
function Alerts.Show(message, color)
  ns.Debug("alert", "%s", message)
  frame.text:SetText(message)
  frame.text:SetTextColor(unpack(color))
  shownAt = GetTime()
  frame:SetAlpha(1)
  frame:Show()
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
    if (entry.quality or 0) >= EPIC_QUALITY then alert("loot", entry.link or entry.name or "?") end
  end,
  nearDeathLog = function(entry)
    alert("nearDeath", entry.lowestPercent)
  end,
}

Journal.OnAdd(function(logName, entry)
  local handler = handlers[logName]
  if handler then handler(entry) end
end)
