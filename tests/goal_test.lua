-- Session-Ziel: Ziel-Level per Befehl, Fortschritt, Prognose und Meldung beim Erreichen.
local Goal = addon.Goal
local L = addon.L

local function goalRow()
  for _, line in ipairs(addon.STAT_LINES) do
    if line.setting == "showGoal" then return line.rows[1].value(addon.Stats.LEVEL) end
  end
end

wow.login({ level = 10, xp = 0, xpMax = 1000, playedSeconds = 0 })
expect("ohne Ziel", goalRow(), "-")

-- Ungültige Ziele
SlashCmdList.LEVELTIMER("goal 10")
expect("aktuelles Level ist kein Ziel", Goal.Get(), nil)
SlashCmdList.LEVELTIMER("goal 61")
expect("über Max-Level kein Ziel", Goal.Get(), nil)
SlashCmdList.LEVELTIMER("goal abc")
expect("keine Zahl", wow.printed[#wow.printed]:find(L.GOAL_INVALID, 1, true) ~= nil, true)

-- Ziel Level 12 = zwei Level Weg; Zeile wird eingeschaltet
SlashCmdList.LEVELTIMER("goal 12")
expect("Ziel gesetzt", Goal.Get().level, 12)
expect("Zeile eingeschaltet", LevelTimerDB.showGoal, true)
expect("noch kein Fortschritt", Goal.GetProgress(), 0)

-- Halbes Level in 30 min: 50 % von zwei Leveln = 25 %, Prognose 30 min Rest + 60 min für Level 11
wow.advance(1800)
wow.fire("TIME_PLAYED_MSG", 1800, 1800)
wow.state.xp = 500
wow.fire("PLAYER_XP_UPDATE", "player")
expectNear("Fortschritt", Goal.GetProgress(), 0.25)
expectNear("Prognose", Goal.GetSecondsLeft(), 1800 + 3600)
expect("Zeile", goalRow(), string.format(L.GOAL_PROGRESS, 12, "25%", addon.Format.Duration(5400)))

-- Erreichen: Meldung und Zeile "erreicht"
wow.levelUp(11)
wow.levelUp(12)
expect("erreicht", Goal.Get().reached, true)
expect("Meldung", wow.printed[#wow.printed]:find(string.format(L.GOAL_REACHED, 12), 1, true) ~= nil, true)
expect("Zeile erreicht", goalRow(), string.format(L.GOAL_DONE, 12))
expect("Fortschritt voll", Goal.GetProgress(), 1)

-- Bleibt über Sessions, Entfernen ohne Zahl
SlashCmdList.LEVELTIMER("newsession")
expect("übersteht neue Session", Goal.Get().level, 12)
SlashCmdList.LEVELTIMER("goal")
expect("entfernt", Goal.Get(), nil)

-- Kommazahlen sind kein Level
expect("Kommazahl abgelehnt", addon.Goal.Set(addon.level + 1.5), false)
