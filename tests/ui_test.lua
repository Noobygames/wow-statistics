-- Oberfläche und Befehle: nichts darf abstürzen, Einstellungen wirken, Texte sind lokalisiert.
wow.login({ playedSeconds = 600 })

expect("unbekanntes Event -> false statt Fehler", addon.RegisterEvent(wow.UNKNOWN_EVENT, function() end), false)

-- Jede Stat-Zeile liefert Text, für Level und Session
for _, line in ipairs(addon.STAT_LINES) do
  for _, scope in ipairs({ addon.Stats.LEVEL, addon.Stats.SESSION }) do
    local text = line.text(scope)
    expectTrue("Text für " .. line.setting .. " (" .. scope .. ")", type(text) == "string" and text ~= "")
  end
  expectTrue("Default für " .. line.setting, LevelTimerDB[line.setting] ~= nil)
  expectTrue("Locale-Key " .. line.label, addon.L[line.label] ~= line.label)
end

-- Fenster zwischen Level und Session umschalten
addon.Set("windowScope", addon.Stats.SESSION)
expect("Bereich Session", LevelTimerDB.windowScope, "session")
addon.Set("windowScope", addon.Stats.LEVEL)

-- Sprachwechsel greift sofort
expect("deutscher Text", string.format(addon.L.DEATHS, 1), "Tode: 1")
addon.Set("language", "enUS")
expect("englischer Text", string.format(addon.L.DEATHS, 1), "Deaths: 1")

-- Befehle
SlashCmdList.LEVELTIMER("lock")
expect("lock", LevelTimerDB.locked, true)
SlashCmdList.LEVELTIMER(" UNLOCK ")
expect("unlock mit Leerzeichen/Großschreibung", LevelTimerDB.locked, false)
SlashCmdList.LEVELTIMER("hide")
expect("hide", LevelTimerDB.showTimer, false)
SlashCmdList.LEVELTIMER("show")
expect("show", LevelTimerDB.showTimer, true)
SlashCmdList.LEVELTIMER("minimap")
expect("minimap aus", LevelTimerDB.minimap.hide, true)
SlashCmdList.LEVELTIMER("minimap")
expect("minimap an", LevelTimerDB.minimap.hide, false)

local printedBefore = #wow.printed
SlashCmdList.LEVELTIMER("gibtsnicht")
expectTrue("unbekannter Befehl zeigt Hilfe", wow.printed[printedBefore + 1]:find("/lt", 1, true) ~= nil)

-- Fenster öffnen/schließen und Einstellungen ändern ohne Fehler
SlashCmdList.LEVELTIMER("")
SlashCmdList.LEVELTIMER("history")
addon.Set("fontSize", 24)
addon.Set("showMoney", false)
wow.state.shiftDown = true
LevelTimer_OnAddonCompartmentClick()

-- Historie: Session-Ansicht und Charakter-Wechsel rendern ohne Fehler
addon.Set("language", "deDE")
expectTrue("Reiter Sessions klickbar", wow.click("Sessions"))
expectTrue("Reiter Level klickbar", wow.click("Level"))
expectTrue("nächster Charakter", wow.click(">"))
expectTrue("Session-Reiter im Fenster", wow.click("Session"))
expect("Fenster zeigt Session", LevelTimerDB.windowScope, "session")
