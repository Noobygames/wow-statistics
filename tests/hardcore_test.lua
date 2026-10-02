-- Hardcore-Anzeige: Zeit ohne Tod über alle Level und Sessions, Tode rot.
local Stats = addon.Stats
local DeathCounter = addon.DeathCounter

local function statValue(setting, scope)
  for _, line in ipairs(addon.STAT_LINES) do
    if line.setting == setting then return line.rows[1].value(scope) end
  end
end

wow.login({ playedSeconds = 600 })  -- /played gesamt = 600 + 100000 (wow.login)
local total = 600 + 100000
expectNear("noch nie gestorben: gesamte Spielzeit", DeathCounter.GetSecondsSinceDeath(), total)
expect("ohne Tod nicht rot", statValue("showDeaths", Stats.LEVEL), "0")

wow.advance(100)
wow.state.dead = true
wow.fire("PLAYER_DEAD")
expectNear("direkt nach dem Tod", DeathCounter.GetSecondsSinceDeath(), 0)
expectTrue("Tode rot", statValue("showDeaths", Stats.LEVEL):find("|cffff4040", 1, true) == 1)
wow.state.dead = false
wow.fire("PLAYER_UNGHOST")

wow.advance(3600)
expectNear("eine Stunde ohne Tod", DeathCounter.GetSecondsSinceDeath(), 3600)
expect("Zeile zeigt Dauer", statValue("showDeathless", Stats.SESSION), addon.Format.Duration(3600))

-- Gilt über Level-Ups und neue Sessions hinweg
wow.levelUp(11)
SlashCmdList.LEVELTIMER("newsession")
expectNear("über Level und Session hinweg", DeathCounter.GetSecondsSinceDeath(), 3600)

-- Tode aus der Zeit vor dieser Funktion: unbekannt statt falscher Zeit
addon.character.lastDeathPlayed = nil
expect("alter Tod ohne /played", DeathCounter.GetSecondsSinceDeath(), nil)
expect("Zeile ohne Wert", statValue("showDeathless", Stats.LEVEL), "-")

-- Rote Tode abschaltbar
addon.Set("highlightDeaths", false)
expect("ohne Hervorhebung", statValue("showDeaths", Stats.LEVEL):find("|c", 1, true), nil)
addon.Set("highlightDeaths", true)
