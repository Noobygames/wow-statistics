-- Oberfläche und Befehle: nichts darf abstürzen, Einstellungen wirken, Texte sind lokalisiert.
wow.login({ playedSeconds = 600 })

expect("unbekanntes Event -> false statt Fehler", addon.RegisterEvent(wow.UNKNOWN_EVENT, function() end), false)

-- Jede Stat-Zeile liefert Text
for _, line in ipairs(addon.STAT_LINES) do
  local text = line.text()
  expectTrue("Text für " .. line.setting, type(text) == "string" and text ~= "")
  expectTrue("Default für " .. line.setting, LevelTimerDB[line.setting] ~= nil)
  expectTrue("Locale-Key " .. line.label, addon.L[line.label] ~= line.label)
end

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
