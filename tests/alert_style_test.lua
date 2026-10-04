-- Aussehen und Position der Einblendungen: Stil, Größe, Dauer, Ton, Verschiebemodus.
local L = addon.L
local Alerts = addon.Alerts
local alert = LevelTimerAlert

wow.login({ level = 10 })
local played = {}
function PlaySound(id) table.insert(played, id) end

-- Standard: Banner, Größe 100 %, 3 s
expect("Stil Banner", LevelTimerDB.alertStyle, "banner")
expect("Größe", alert:GetScale(), 1)
Alerts.ShowSample("levelUp")
expectTrue("Banner hat Mindestbreite", alert:GetWidth() >= 280)
expect("kein Ton im Standard", #played, 0)

-- Größe und Stil wirken sofort
addon.Set("alertScale", 1.5)
expect("Größe 150 %", alert:GetScale(), 1.5)
addon.Set("alertStyle", "text")
Alerts.ShowSample("levelUp")
expectTrue("Text-Stil ohne Mindestbreite", alert:GetWidth() < 280)
addon.Set("alertStyle", "banner")

-- Ton
addon.Set("alertSound", true)
Alerts.ShowSample("rare")
expect("Ton gespielt", #played, 1)
addon.Set("alertSound", false)

-- Dauer: bei 6 s nach 4 s noch voll sichtbar, bei 1 s nach 4 s weg
addon.Set("alertDuration", 6)
Alerts.ShowSample("levelUp")
wow.advance(4)
alert._scripts.OnUpdate(alert, 0.1)
expect("lange Dauer: noch voll", alert:GetAlpha(), 1)
addon.Set("alertDuration", 1)
Alerts.ShowSample("levelUp")
wow.advance(4)
alert._scripts.OnUpdate(alert, 0.1)
expect("kurze Dauer: weg", alert:IsShown(), false)

-- Verschiebemodus: bleibt stehen, neue Einblendungen ersetzen ihn nicht, Ziehen speichert die Position
Alerts.SetMoving(true)
expect("Verschiebemodus an", Alerts.IsMoving(), true)
expect("zeigt Hinweis", alert.text:GetText(), L.ALERT_MOVE_HINT)
wow.advance(60)
alert._scripts.OnUpdate(alert, 0.1)
expect("bleibt sichtbar", alert:IsShown(), true)
Alerts.ShowSample("levelUp")
expect("Hinweis bleibt", alert.text:GetText(), L.ALERT_MOVE_HINT)
alert._scripts.OnDragStart(alert)
alert._scripts.OnDragStop(alert)
expectTrue("Position gespeichert", LevelTimerDB.alertPos ~= nil)
alert._scripts.OnMouseUp(alert, "RightButton")
expect("Rechtsklick beendet", Alerts.IsMoving(), false)
expect("danach versteckt", alert:IsShown(), false)

-- Zurücksetzen
Alerts.ResetPosition()
expect("Position zurückgesetzt", LevelTimerDB.alertPos, nil)

-- Gespeicherte Position kommt aus den Einstellungen; Müll im Profil wird verworfen
local clean = addon.Database.SanitizeSettings({ alertPos = { "TOP", "TOP", 5, -10 }, alertScale = "groß" })
expect("gültige Position bleibt", clean.alertPos[3], 5)
expect("falscher Typ fliegt raus", clean.alertScale, nil)
expect("ungültige Position fliegt raus", addon.Database.SanitizeSettings({ alertPos = { 1, 2 } }).alertPos, nil)

-- Optionen: Reiter und Buttons vorhanden
SlashCmdList.LEVELTIMER("config")
expectTrue("Reiter Einblendungen", wow.click(L.OPTIONS_TAB_ALERTS))
expectTrue("Button Vorschau", wow.click(L.ALERT_PREVIEW))
expect("Vorschau zeigt Level-Up", alert:IsShown(), true)
expectTrue("Button Verschieben", wow.click(L.ALERT_MOVE))
expect("Button schaltet Verschiebemodus", Alerts.IsMoving(), true)
expectTrue("Button Verschieben beendet", wow.click(L.ALERT_MOVE))
expect("Verschiebemodus aus", Alerts.IsMoving(), false)
