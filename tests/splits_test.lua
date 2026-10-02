-- Splits: Zeit je Level gegen die schnellste Zeit anderer Charaktere, laufend und gesamt.
local Splits = addon.Splits

local function row(label)
  for _, line in ipairs(addon.STAT_LINES) do
    for _, r in ipairs(line.rows) do
      if r.label == label then return r.value(addon.Stats.LEVEL) end
    end
  end
end

-- Vergleichs-Charaktere: Bestzeit Level 10 = 1 h (Rekord), Level 11 = 30 min
local function otherCharacter(name, levels)
  LevelTimerStatsDB.characters[name .. "-Testrealm"] = {
    name = name, realm = "Testrealm", currentLevel = { level = 30, counters = {} },
    levelHistory = levels, sessionHistory = {}, killLog = {}, deathLog = {},
  }
end

wow.login({ name = "Neu", level = 10, playedSeconds = 0 })
expect("ohne Vergleich kein Split", Splits.GetCurrentDelta(), nil)
expect("Zeile ohne Vergleich", row("ROW_SPLIT_LEVEL"), "-")

otherCharacter("Rekord", { [10] = { level = 10, seconds = 3600 }, [11] = { level = 11, seconds = 1800 } })
otherCharacter("Lahm", { [10] = { level = 10, seconds = 7200 }, [12] = { level = 12, seconds = 5000 } })
expect("Bestzeit = schnellster", Splits.GetReference(10), 3600)
expect("Bestzeit aus anderem Charakter", Splits.GetReference(12), 5000)

-- Level 10 in 50 min: 10 min schneller
wow.advance(3000)
wow.fire("TIME_PLAYED_MSG", 3000, 3000)
expectNear("laufend schneller", Splits.GetCurrentDelta(), -600)
expect("grün", row("ROW_SPLIT_LEVEL"), "|cff40ff40-10m 00s|r")
wow.levelUp(11)

-- Level 11 läuft 35 min: 5 min langsamer, gesamt 5 min schneller
wow.advance(2100)
wow.fire("TIME_PLAYED_MSG", 5100, 2100)
expectNear("laufend langsamer", Splits.GetCurrentDelta(), 300)
expect("rot", row("ROW_SPLIT_LEVEL"), "|cffff4040+5m 00s|r")
expectNear("gesamt", Splits.GetTotalDelta(), -300)

-- Gelöschter Vergleichs-Charakter: Bestzeiten neu
addon.DeleteCharacter("Rekord-Testrealm")
expect("nach Löschen nächstbeste Zeit", Splits.GetReference(10), 7200)
expect("Level 11 ohne Bestzeit", Splits.GetCurrentDelta(), nil)

---------------------------------------------------------------------------
-- Fester Vergleich: persönliche Bestzeit und gewählter Charakter
---------------------------------------------------------------------------
-- Ausgangslage: eingeloggt Level 11, Level 10 in 3000 s abgeschlossen. Vergleichs-Charaktere:
otherCharacter("Schnell", { [10] = { level = 10, seconds = 3200 }, [11] = { level = 11, seconds = 2400 } })  -- 5600
otherCharacter("Stetig", { [10] = { level = 10, seconds = 3400 }, [11] = { level = 11, seconds = 2000 } })   -- 5400
otherCharacter("Kurz", { [11] = { level = 11, seconds = 100 } })  -- ohne Level 10: zählt nicht als Lauf

SlashCmdList.LEVELTIMER("compare pb")
expect("Einstellung pb", LevelTimerDB.splitComparison, "pb")
-- schnellster Lauf bis Level 11 = Stetig (5400 s), nicht die Bestzeit je Level
expect("PB Level 10", Splits.GetReference(10), 3400)
expect("PB Level 11", Splits.GetReference(11), 2000)
expectNear("PB laufend", Splits.GetCurrentDelta(), 2100 - 2000)
expectNear("PB gesamt", Splits.GetTotalDelta(), (3000 - 3400) + (2100 - 2000))

SlashCmdList.LEVELTIMER("compare schnell")
expect("Einstellung Charakter", LevelTimerDB.splitComparison, "character")
expect("Charakter gemerkt", LevelTimerDB.splitCharacter, "Schnell-Testrealm")
expect("Charakter Level 10", Splits.GetReference(10), 3200)
expect("Abweichung einzelnes Level", Splits.GetLevelDelta(10), -200)

SlashCmdList.LEVELTIMER("compare niemand")
expect("unbekannter Name: Hilfe", wow.printed[#wow.printed]:find(addon.L.COMPARE_USAGE, 1, true) ~= nil, true)
expect("unbekannter Name ändert nichts", LevelTimerDB.splitCharacter, "Schnell-Testrealm")

SlashCmdList.LEVELTIMER("compare best")
expect("zurück zur Bestzeit je Level", Splits.GetReference(11), 100)
