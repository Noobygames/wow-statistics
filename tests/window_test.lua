-- Fenster: Größe per Einstellung und Ziehgriff, Grenzen, Zurücksetzen, Rechtsklick.
local window = LevelTimerFrame
local grip = wow.findFrame(function(frame)
  return frame._normalTexture:find("SizeGrabber", 1, true) ~= nil
end)
expectTrue("Ziehgriff vorhanden", grip ~= nil)

wow.login()
expect("Standardgröße", window:GetScale(), 1)

-- Regler in den Einstellungen skaliert das ganze Fenster
addon.Set("scale", 1.5)
expect("Größe aus Einstellung", window:GetScale(), 1.5)
expectTrue("Position nach Skalierung gespeichert", LevelTimerDB.pos ~= nil)

addon.Set("scale", 5)
expect("obere Grenze", window:GetScale(), addon.TimerWindow.MAX_SCALE)
addon.Set("scale", 0.1)
expect("untere Grenze", window:GetScale(), addon.TimerWindow.MIN_SCALE)

-- Ziehgriff: Ecke um die halbe Fenstergröße nach rechts unten ziehen = 1,5-fach
addon.Set("scale", 1)
local width, height = window:GetWidth(), window:GetHeight()
wow.state.cursorX, wow.state.cursorY = 300, 300
grip._scripts.OnMouseDown(grip, "LeftButton")
wow.state.cursorX, wow.state.cursorY = 300 + width / 2, 300 - height / 2
grip._scripts.OnUpdate(grip, 0.1)
grip._scripts.OnMouseUp(grip, "LeftButton")
expectNear("Größe nach Ziehen", window:GetScale(), 1.5)
expectNear("gezogene Größe gespeichert", LevelTimerDB.scale, 1.5)

-- Fixiertes Fenster: kein Ziehgriff
addon.Set("locked", true)
expect("Ziehgriff bei fixiertem Fenster versteckt", grip:IsShown(), false)
addon.Set("locked", false)
expect("Ziehgriff wieder da", grip:IsShown(), true)

-- Zurücksetzen
SlashCmdList.LEVELTIMER("reset")
expect("Größe zurückgesetzt", LevelTimerDB.scale, 1)
expect("Fenster zurückgesetzt", window:GetScale(), 1)
expect("Position zurückgesetzt", LevelTimerDB.pos, nil)

-- Rechtsklick öffnet die Einstellungen
window._scripts.OnMouseUp(window, "RightButton")
expect("Einstellungen offen", LevelTimerOptions:IsShown(), true)
window._scripts.OnMouseUp(window, "LeftButton")
expect("Linksklick öffnet nichts", LevelTimerOptions:IsShown(), true)

-- XP-Balken: braucht Platz im Fenster, nur beim Leveln
wow.state.xp, wow.state.xpMax, wow.state.rested = 250, 1000, 200
addon.Set("showXpBar", true)
local withBar = window:GetHeight()
addon.Set("showXpBar", false)
local withoutBar = window:GetHeight()
expectTrue("Balken vergrößert das Fenster", withBar > withoutBar)
addon.Set("showXpBar", true)
wow.state.level, addon.level = 60, 60
addon.ApplySettings()
expect("auf Max-Level kein Balken", window:GetHeight(), withoutBar)
