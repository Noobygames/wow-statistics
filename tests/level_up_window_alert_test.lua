-- Ist das Level-Up-Fenster an, kommt die Level-Up-Einblendung (Karte) nicht zusätzlich.
-- Blizzards Toast im EventToastManager wird bewusst nicht angefasst (Eingriffe dort ließen die Controller-Leiste verschwinden).
wow.login({ level = 3 })
local gains = { health = 90, strength = 3 }

addon.Set("alertLevelUp", true)
addon.Alerts.Clear()
wow.levelUp(4, nil, gains)
wow.runTimers()
expect("Fenster ersetzt die Karte", LevelTimerNotice:IsShown(), false)

-- Das Fenster ersetzt auch die Gewinnzeile im Chat und den Lehrer-Hinweis, wenn es die Fähigkeiten selbst zeigt
local function printed(text)
  for _, line in ipairs(wow.printed) do
    if line:find(text, 1, true) then return true end
  end
  return false
end
expect("Fenster an: keine Gewinnzeile im Chat", printed(addon.L.GAIN_STRENGTH), false)

-- Lehrer-Hinweis: entfällt nur, wenn das Fenster die Fähigkeiten des Levels kennt
wow.state.interface = 11509
addon.Set("remindTrainer", true)
local class = select(2, UnitClass("player"))
LevelTimerStatsDB.trainerCache = {}
wow.levelUp(6, nil, gains)
expect("Fenster an, Fähigkeiten unbekannt: Hinweis bleibt", printed("neue Zauber beim Lehrer"), true)
LevelTimerStatsDB.trainerCache = { [class] = { ["Heilen|1"] = { name = "Heilen", rank = "", level = 8 } } }
wow.printed = {}
wow.levelUp(8, nil, gains)
expect("Fenster an, Fähigkeiten bekannt: Hinweis entfällt", printed("neue Zauber beim Lehrer"), false)
addon.Set("levelUpWindow", false)
wow.printed = {}
wow.levelUp(10, nil, gains)
LevelTimerStatsDB.trainerCache = { [class] = { ["Heilen|1"] = { name = "Heilen", rank = "", level = 12 } } }
wow.levelUp(12, nil, gains)
expect("Fenster aus: Hinweis bleibt", printed("neue Zauber beim Lehrer"), true)
