-- Split-Liste: laufendes Level und die letzten abgeschlossenen, mit Abweichung zur Bestzeit.
local SplitList = addon.SplitList
local list = LevelTimerSplits

wow.login({ name = "Neu", level = 14, playedSeconds = 0 })
LevelTimerStatsDB.characters["Rekord-Testrealm"] = {
  name = "Rekord", realm = "Testrealm", currentLevel = { level = 30, counters = {} },
  levelHistory = { [12] = { level = 12, seconds = 1000 }, [13] = { level = 13, seconds = 1000 } },
  sessionHistory = {}, killLog = {}, deathLog = {},
}
for level = 10, 13 do
  addon.character.levelHistory[level] = { level = level, seconds = 1100 }
end

expect("standardmäßig versteckt", list:IsShown(), false)
SlashCmdList.LEVELTIMER("splits")
expect("per Befehl an", list:IsShown(), true)

addon.Set("splitListRows", 3)
local lines = SplitList.BuildLines()
expect("Zahl der Zeilen", #lines, 3)
expect("laufendes Level zuerst", lines[1].level, 14)
expect("dann neuestes abgeschlossenes", lines[2].level, 13)
expect("Zeit", lines[2].seconds, 1100)
expect("Abweichung zur Bestzeit", lines[2].delta, 100)
expect("ohne Vergleich keine Abweichung", lines[1].delta, nil)

addon.Set("splitListRows", 10)
expect("nur vorhandene Level", #SplitList.BuildLines(), 5)

-- Größe und Hintergrund folgen dem Hauptfenster
addon.Set("scale", 1.5)
expect("Größe wie Fenster", list:GetScale(), 1.5)
addon.Set("windowBackground", "green")
expect("Chroma wie Fenster", list._backdropColor[2], 1)

-- Anzeige rendert ohne Fehler und lässt sich ausschalten
list._scripts.OnUpdate(list, 1)
expectTrue("Fensterhöhe für Zeilen", list:GetHeight() > 5 * 14)
SlashCmdList.LEVELTIMER("splits")
expect("aus", list:IsShown(), false)
