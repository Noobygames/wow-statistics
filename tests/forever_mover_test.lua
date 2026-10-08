-- Gespeicherte Positionen bleiben beim Laden unverändert, auch bei Größe ungleich 100 %: die Abstände
-- gelten schon in dieser Größe (sonst würden sie bei jedem Login umgerechnet und wanderten).
LevelTimerDB = {
  alertScale = 0.5, alertPos = { "TOP", "TOP", 100, -200 },
  campScale = 1.5, campPos = { "TOP", "TOP", 30, -60 },
}
wow.login({ level = 30 })
expect("Einblendung: x unverändert", LevelTimerDB.alertPos[3], 100)
expect("Einblendung: y unverändert", LevelTimerDB.alertPos[4], -200)
expect("Lagerfeuer: x unverändert", LevelTimerDB.campPos[3], 30)
expect("Lagerfeuer: y unverändert", LevelTimerDB.campPos[4], -60)
expect("Einblendung: Größe", LevelTimerAlert:GetScale(), 0.5)
expect("Lagerfeuer: Größe", LevelTimerCamp:GetScale(), 1.5)

-- Reload: noch einmal, nichts wandert
wow.logout()
wow.login()
expect("nach Reload: x", LevelTimerDB.alertPos[3], 100)
expect("nach Reload: Lagerfeuer y", LevelTimerDB.campPos[4], -60)

-- Größe ändern bei stehender Position: Abstände werden umgerechnet
addon.Set("campScale", 2)
expect("Größe 1,5 -> 2: x umgerechnet", LevelTimerDB.campPos[3], 22.5)

-- Profilwechsel: die Position des neuen Profils bleibt, wie sie gespeichert wurde
LevelTimerDB.profiles.Zweit = { campScale = 0.5, campPos = { "TOP", "TOP", 10, -20 } }
addon.Profiles.Switch("Zweit")
expect("Profil: x unverändert", LevelTimerDB.campPos[3], 10)
expect("Profil: Größe", LevelTimerCamp:GetScale(), 0.5)
