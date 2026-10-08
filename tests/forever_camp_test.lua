-- Lagerfeuer in WoW Forever (Szenarien forever_* laden als Forever): Hinweis bei Feuer in der Nähe ohne
-- Lagervorteile, Countdown beim einladenden Lagerfeuer, "Lagervorteile aktiv" danach, Vorschau und Position.
local L = addon.L
local Camp = addon.CampFire
local Display = addon.CampDisplay
local NEARBY, INVITING, BENEFITS = 1283391, 1229739, 1229741

local played = {}
function PlaySound(id) table.insert(played, id) end

wow.login({ level = 30 })
expectTrue("als Forever erkannt", Camp.IsAvailable())
local camp = LevelTimerCamp

local function aura(spellId, name, duration, expiration)
  return { spellId = spellId, name = name, duration = duration or 0, expirationTime = expiration or 0 }
end
local function nearby() return aura(NEARBY, "Lagerfeuer in der Nähe") end
local function benefits(expiration) return aura(BENEFITS, "Lagervorteile", 3600, expiration) end
local function inviting(expiration) return aura(INVITING, "Einladendes Lagerfeuer", 60, expiration) end
local function shownText(text)
  return wow.findFrame(function(frame) return frame._text == text end) ~= nil
end
local function tick() camp._scripts.OnUpdate(camp, 1) end

---------------------------------------------------------------------------
-- Hinweis: Feuer in der Nähe, keine Lagervorteile
---------------------------------------------------------------------------
expect("zunächst versteckt", camp:IsShown(), false)
wow.state.buffs = { nearby() }
Camp.Check()
expect("Hinweis sichtbar", camp:IsShown(), true)
expectTrue("Hinweistext", shownText(L.CAMP_HINT_TEXT))

wow.state.buffs = { nearby(), benefits(GetTime() + 3000) }
Camp.Check()
expect("mit Lagervorteilen kein Hinweis", camp:IsShown(), false)

addon.Set("campHint", false)
wow.state.buffs = { nearby() }
Camp.Check()
expect("Hinweis abgeschaltet", camp:IsShown(), false)
addon.Set("campHint", true)

---------------------------------------------------------------------------
-- Countdown: Restzeit aus der Ablaufzeit des Buffs
---------------------------------------------------------------------------
local oldExpiration = GetTime() + 3000
wow.state.buffs = { nearby(), benefits(oldExpiration), inviting(GetTime() + 60) }
Camp.Check()
expect("Countdown sichtbar", camp:IsShown(), true)
expectTrue("60 s", shownText(string.format(L.SECONDS_SHORT, 60)))
wow.advance(20)
Camp.Check()
tick()
expectTrue("nach 20 s noch 40 s", shownText(string.format(L.SECONDS_SHORT, 40)))

-- Countdown vorbei, Lagervorteile erneuert: kurz "aktiv", mit Ton wenn gewünscht
addon.Set("campSound", true)
wow.advance(40)
wow.state.buffs = { nearby(), benefits(GetTime() + 3600) }
Camp.Check()
expect("Meldung nach dem Countdown", camp:IsShown(), true)
expectTrue("Lagervorteile aktiv", shownText(L.CAMP_DONE))
expect("Ton gespielt", #played, 1)
Camp.Check()
expectTrue("bleibt stehen", camp:IsShown())
wow.advance(5)
tick()
expect("danach weg", camp:IsShown(), false)
addon.Set("campSound", false)

-- Vorzeitig aufgestanden: keine Meldung, Lagervorteile unverändert
local unchanged = GetTime() + 3000
wow.state.buffs = { nearby(), benefits(unchanged), inviting(GetTime() + 60) }
Camp.Check()
wow.advance(15)
wow.state.buffs = { nearby(), benefits(unchanged) }
Camp.Check()
wow.advance(5)
Camp.Check()
expect("kein Countdown mehr", camp:IsShown(), false)
expect("keine falsche Erfolgsmeldung", shownText(L.CAMP_DONE) and camp:IsShown(), false)

-- Countdown abgeschaltet
addon.Set("campCountdown", false)
wow.state.buffs = { nearby(), inviting(GetTime() + 60) }
Camp.Check()
expect("Countdown abgeschaltet", camp:IsShown(), false)
addon.Set("campCountdown", true)

---------------------------------------------------------------------------
-- Gesperrte Auren und andere Clients
---------------------------------------------------------------------------
wow.state.buffs = { nearby() }
wow.state.aurasSecret = true
Camp.Check()
expect("gesperrte Auren: nichts, kein Fehler", camp:IsShown(), false)
wow.state.aurasSecret = false

wow.state.interface = 11509
Camp.Check()
expect("nicht in Forever", camp:IsShown(), false)
wow.state.interface = 16001

---------------------------------------------------------------------------
-- Vorschau, Verschieben, Größe
---------------------------------------------------------------------------
Display.Preview()
expectTrue("Vorschau 1: Hinweis", shownText(L.CAMP_HINT_TEXT) and camp:IsShown())
Display.Preview()
expectTrue("Vorschau 2: Countdown", shownText(L.CAMP_TITLE_COUNTDOWN))
Display.Preview()
expectTrue("Vorschau 3: aktiv", shownText(L.CAMP_DONE))
wow.state.buffs = {}
Camp.Check()
expectTrue("echte Zustände stören die Vorschau nicht", camp:IsShown())
wow.advance(9)
tick()
expect("Vorschau endet", camp:IsShown(), false)

Display.SetMoving(true)
expect("Verschiebemodus", Display.IsMoving(), true)
expect("zeigt den Countdown", camp:IsShown(), true)
camp._scripts.OnDragStart(camp)
camp._scripts.OnDragStop(camp)
expectTrue("Position gespeichert", LevelTimerDB.campPos ~= nil)
camp._scripts.OnMouseUp(camp, "RightButton")
expect("Rechtsklick beendet", Display.IsMoving(), false)
expect("danach versteckt", camp:IsShown(), false)

LevelTimerDB.campPos = { "TOP", "TOP", 100, -200 }
addon.Set("campScale", 1)
addon.Set("campScale", 2)
expect("Größe: Abstand x umgerechnet", LevelTimerDB.campPos[3], 50)
expect("Größe: Abstand y umgerechnet", LevelTimerDB.campPos[4], -100)
Display.ResetPosition()
expect("Position zurückgesetzt", LevelTimerDB.campPos, nil)
addon.Set("campScale", 1)

---------------------------------------------------------------------------
-- Einstellungen
---------------------------------------------------------------------------
SlashCmdList.LEVELTIMER("config")
expectTrue("Reiter Hinweise", wow.click(L.OPTIONS_TAB_NOTIFICATIONS))
expectTrue("Button Vorschau", wow.click(L.CAMP_PREVIEW))
expect("Vorschau zeigt Anzeige", camp:IsShown(), true)
expectTrue("Button Verschieben", wow.click(L.CAMP_MOVE))
expect("Button schaltet Verschiebemodus", Display.IsMoving(), true)
expectTrue("Button Verschieben beendet", wow.click(L.CAMP_MOVE))
expect("Verschiebemodus aus", Display.IsMoving(), false)
expectTrue("Button Zurücksetzen", wow.click(L.CAMP_RESET_POSITION))
