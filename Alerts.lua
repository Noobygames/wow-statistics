-- Große Einblendungen oben in der Bildschirmmitte für Stream-Momente: Level-Up, Rare- und Elite-Kill,
-- epische Beute, Beinahe-Tod. Jede Art ist einzeln schaltbar (Einstellungen alert*), alle aus.
-- Quellen: ns.OnLevelStarted und neue Journal-Einträge (Journal.OnAdd), kein eigenes Event-Parsing.
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
  frame.text:SetText(message)
  frame.text:SetTextColor(unpack(color))
  shownAt = GetTime()
  frame:SetAlpha(1)
  frame:Show()
end

ns.OnLevelStarted(function(newLevel)
  if ns.db.alertLevelUp then
    Alerts.Show(string.format(L.ALERT_LEVEL_UP, newLevel), COLORS.levelUp)
  end
end)

local function onKill(entry)
  local name = entry.name or L.UNKNOWN_NAME
  if ns.db.alertRareKill and Classification.IsRare(entry.classification) then
    Alerts.Show(string.format(L.ALERT_RARE_KILL, name), COLORS.rare)
  elseif ns.db.alertEliteKill and Classification.IsElite(entry.classification) then
    Alerts.Show(string.format(L.ALERT_ELITE_KILL, name), COLORS.elite)
  end
end

local handlers = {
  killLog = onKill,
  lootLog = function(entry)
    if ns.db.alertEpicLoot and (entry.quality or 0) >= EPIC_QUALITY then
      Alerts.Show(string.format(L.ALERT_EPIC_LOOT, entry.link or entry.name or "?"), COLORS.loot)
    end
  end,
  nearDeathLog = function(entry)
    if ns.db.alertNearDeath then
      Alerts.Show(string.format(L.ALERT_NEAR_DEATH, entry.lowestPercent), COLORS.nearDeath)
    end
  end,
}

Journal.OnAdd(function(logName, entry)
  local handler = handlers[logName]
  if handler then handler(entry) end
end)
