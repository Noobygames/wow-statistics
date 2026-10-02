-- Einstellungs-Profile: speichern, wechseln, je Charakter merken, teilen, löschen.
local L = addon.L
local Profiles = addon.Profiles

wow.login({ name = "Erster" })
expect("Standard aktiv", Profiles.GetActive(), "Default")
addon.Set("scale", 1.2)

-- Aktuellen Stand als neues Profil speichern
SlashCmdList.LEVELTIMER("profile save Stream")
expect("neues Profil aktiv", Profiles.GetActive(), "Stream")
addon.Set("windowBackground", "green")
addon.Set("scale", 1.5)

-- Zurück zum Standard: dessen Werte, Stream behält seine
SlashCmdList.LEVELTIMER("profile Default")
expect("Standard: Größe", LevelTimerDB.scale, 1.2)
expect("Standard: Hintergrund", LevelTimerDB.windowBackground, "default")
expect("Fenster folgt", LevelTimerFrame:GetScale(), 1.2)
SlashCmdList.LEVELTIMER("profile Stream")
expect("Stream: Größe", LevelTimerDB.scale, 1.5)
expect("Stream: Hintergrund", LevelTimerDB.windowBackground, "green")

-- Jeder Charakter merkt sich sein Profil
wow.logout()
wow.login({ name = "Zweiter" })
SlashCmdList.LEVELTIMER("profile Default")
expect("zweiter Charakter: Standard", LevelTimerDB.scale, 1.2)
wow.logout()
wow.login({ name = "Erster" })
expect("erster lädt Stream", Profiles.GetActive(), "Stream")
expect("mit seinen Werten", LevelTimerDB.windowBackground, "green")
wow.logout()
wow.login({ name = "Zweiter" })
expect("zweiter lädt Standard", Profiles.GetActive(), "Default")
expect("mit Standard-Werten", LevelTimerDB.windowBackground, "default")

-- Profile als Text: in anderem Client importieren, Name wird nicht überschrieben
local text = Profiles.Export("Stream")
local imported = Profiles.Import(text)
expect("vorhandener Name bekommt Zusatz", imported, "Stream 2")
Profiles.Switch(imported)
expect("importierte Werte", LevelTimerDB.windowBackground, "green")
expect("Ungültiges abgelehnt", Profiles.Import("LT1:run:{}"), nil)

-- Löschen: nicht Standard, nicht das aktive
expect("aktives nicht löschbar", Profiles.Delete("Stream 2"), false)
expect("Standard nicht löschbar", Profiles.Delete("Default"), false)
SlashCmdList.LEVELTIMER("profile delete Stream")
expect("Stream gelöscht", LevelTimerDB.profiles.Stream, nil)
wow.logout()
wow.login({ name = "Erster" })
expect("Charakter mit gelöschtem Profil: unverändert weiter", LevelTimerDB.profiles.Stream, nil)

-- Reiter in den Einstellungen
SlashCmdList.LEVELTIMER("config")
expectTrue("Reiter Profile", wow.click(L.OPTIONS_TAB_PROFILES))
-- "Standard" heißt auch der Fenster-Hintergrund, daher den Listeneintrag über sein Profil suchen
local defaultEntry = wow.findFrame(function(frame) return rawget(frame, "profileName") == "Default" end)
expect("Standard in der Liste", defaultEntry.label._text, L.PROFILE_DEFAULT)
defaultEntry._scripts.OnClick(defaultEntry, "LeftButton")
expect("Klick wechselt", Profiles.GetActive(), "Default")

-- Rechtsklick löscht nach Rückfrage
local streamEntry = wow.findFrame(function(frame) return rawget(frame, "profileName") == "Stream 2" end)
streamEntry._scripts.OnClick(streamEntry, "RightButton")
expect("Rückfrage", wow.popup.data, "Stream 2")
StaticPopupDialogs[wow.popup.name].OnAccept(nil, wow.popup.data)
expect("per Rechtsklick gelöscht", LevelTimerDB.profiles["Stream 2"], nil)
