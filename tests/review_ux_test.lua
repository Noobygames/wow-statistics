-- UX-Funde aus dem Review: Chroma-Farbe der Splits, Rechtsklick auf Reiter, Vorschau durch alle Arten.
local L = addon.L
wow.login({ level = 10 })
addon.Set("alertStyle", "text")

-- 198: auf grünem Chroma-Hintergrund sind schnellere Splits cyan statt grün
local normal = addon.Format.SplitDelta(-60)
addon.Set("windowBackground", "green")
local onGreen = addon.Format.SplitDelta(-60)
expectTrue("normal grün", normal:find("40ff40", 1, true) ~= nil)
expectTrue("auf Grün cyan", onGreen:find("4dd2ff", 1, true) ~= nil)
expectTrue("langsamer bleibt rot", addon.Format.SplitDelta(60):find("ff4040", 1, true) ~= nil)
addon.Set("windowBackground", "default")

-- 211: Rechtsklick auf den Session-Reiter öffnet die Einstellungen, Linksklick wählt den Bereich
local sessionTab = wow.findFrame(function(frame)
  local label = rawget(frame, "label")
  return label and label._text == L.TAB_SESSION
end)
expectTrue("Session-Reiter", sessionTab ~= nil)
expect("Einstellungen zu", LevelTimerOptions:IsShown(), false)
sessionTab._scripts.OnClick(sessionTab, "RightButton")
expect("Rechtsklick öffnet die Einstellungen", LevelTimerOptions:IsShown(), true)
sessionTab._scripts.OnClick(sessionTab, "LeftButton")
expect("Linksklick wählt Session", LevelTimerDB.windowScope, addon.Stats.SESSION)
addon.Set("windowScope", addon.Stats.LEVEL)
SlashCmdList.LEVELTIMER("config")

-- 209: die Vorschau zeigt bei jedem Klick eine andere Art
local seen = {}
for _ = 1, 5 do
  addon.Alerts.Preview()
  seen[LevelTimerAlert.text:GetText()] = true
end
local count = 0
for _ in pairs(seen) do count = count + 1 end
expect("fünf verschiedene Arten", count, 5)
addon.Alerts.Clear()

-- 206: neue Einstellungen zeigen nur die wichtigsten Zeilen
expect("PvP-Kills standardmäßig aus", addon.Database.NewCounters ~= nil and LevelTimerDB.showPvpKills, false)
expect("XP/h standardmäßig an", LevelTimerDB.showXpRate, true)
