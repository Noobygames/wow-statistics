-- Ist das Level-Up-Fenster an, kommt die Level-Up-Einblendung (Karte) nicht zusätzlich.
-- Blizzards Toast im EventToastManager wird bewusst nicht angefasst (Eingriffe dort ließen die Controller-Leiste verschwinden).
wow.login({ level = 3 })
local gains = { health = 90, strength = 3 }

addon.Set("alertLevelUp", true)
addon.Alerts.Clear()
wow.levelUp(4, nil, gains)
wow.runTimers()
expect("Fenster ersetzt die Karte", LevelTimerNotice:IsShown(), false)
