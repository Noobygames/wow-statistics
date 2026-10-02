-- Zusammenfassung beim Level-Up mit den Werten des abgeschlossenen Levels:
-- Chatzeile für sich selbst (Einstellung levelUpSummary) und optional als Ansage an
-- Gruppe oder Gilde (Einstellung levelUpAnnounce = "off" | "party" | "guild").
-- Läuft in OnLevelCompleted, also bevor die Zähler für das neue Level zurückgesetzt werden.
local _, ns = ...
local L = ns.L
local Format = ns.Format
local Stats = ns.Stats
local Experience = ns.Experience

local LevelUpSummary = {
  ANNOUNCE_OFF = "off",
  ANNOUNCE_PARTY = "party",
  ANNOUNCE_GUILD = "guild",
}
ns.LevelUpSummary = LevelUpSummary

local ANNOUNCE_PREFIX = "LevelTimer: "

local function summaryText(completedLevel)
  local seconds = Stats.GetSeconds(Stats.LEVEL)
  local rate = Experience.CalculateRate(UnitXPMax("player"), seconds)  -- UnitXPMax: Bedarf des alten Levels
  return string.format(L.LEVEL_UP_SUMMARY,
    completedLevel + 1,
    completedLevel,
    seconds and Format.Duration(seconds) or "?",
    Stats.GetTotalKills(Stats.LEVEL),
    Stats.Get(Stats.LEVEL, Stats.DEATHS),
    rate and Format.Number(rate) or "-")
end

---------------------------------------------------------------------------
-- Ansage: Chat-Art passend zur Einstellung, nil wenn man nicht in Gruppe bzw. Gilde ist.
-- Gruppen aus der Dungeonsuche/Schlachtfeldern erreicht man nur über INSTANCE_CHAT.
---------------------------------------------------------------------------
local function announceChannel(target)
  if target == LevelUpSummary.ANNOUNCE_GUILD then
    return IsInGuild and IsInGuild() and "GUILD" or nil
  end
  if target == LevelUpSummary.ANNOUNCE_PARTY and IsInGroup then
    if LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
    if IsInGroup() then return "PARTY" end
  end
  return nil
end

-- Retail sperrt Chat-Nachrichten von Addons z.B. in Bosskämpfen; dann lieber nichts senden,
-- statt eine "Aktion blockiert"-Meldung auszulösen
local function chatLocked()
  return C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown()
end

-- C_ChatInfo.SendChatMessage ersetzt seit 11.2 die globale Funktion; ältere Clients haben nur diese
local function sendChat(message, chatType)
  local send = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
  send(message, chatType)
end

local function announce(text)
  local chatType = announceChannel(ns.db.levelUpAnnounce)
  if not chatType or chatLocked() then return end
  sendChat(ANNOUNCE_PREFIX .. Format.PlainText(text), chatType)
end

ns.OnLevelCompleted(function(completedLevel)
  local text = summaryText(completedLevel)
  if ns.db.levelUpSummary then ns.Print(text) end
  announce(text)
end)
