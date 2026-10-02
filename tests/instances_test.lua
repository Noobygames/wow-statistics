-- Instanz-Läufe: ein Lauf je Instanz-Kopie. Raus und wieder rein setzt ihn fort, Reset oder eine andere
-- Kopie (erkannt an der zoneUID der Gegner-GUIDs) beendet ihn.
local History = addon.History
local Instances = addon.Instances

local function enter(name, instanceType)
  wow.state.instance = name and { name = name, type = instanceType or "party" } or nil
  wow.fire("PLAYER_ENTERING_WORLD")
end

local function gainXp(amount)
  wow.state.xp = wow.state.xp + amount
  wow.fire("PLAYER_XP_UPDATE", "player")
end

-- Zwei verschiedene Gegner der Kopie anvisieren: bestätigt deren zoneUID
local npcCounter = 0
local function seeCopy(zoneUID)
  for _ = 1, 2 do
    npcCounter = npcCounter + 1
    wow.state.units.target = { name = "Defias-Schurke",
      guid = string.format("Creature-0-4170-36-%d-%d-0000ABCD%02d", zoneUID, 600 + npcCounter, npcCounter) }
    wow.fire("PLAYER_TARGET_CHANGED")
  end
end

local function log() return addon.character.instanceLog end
local function run() return Instances.GetCurrentRun() end

local function instanceRow()
  for _, line in ipairs(addon.STAT_LINES) do
    if line.setting == "showInstanceRun" then return line.rows[1].value() end
  end
end

expect("zoneUID aus Gegner-GUID", addon.InstanceCopy.ZoneUIDOf("Creature-0-4170-36-1234-1732-00002A3F9B"), 1234)
expect("Spieler-GUID ohne zoneUID", addon.InstanceCopy.ZoneUIDOf("Player-1-0001"), nil)

wow.login({ level = 20, xp = 0, xpMax = 100000 })
addon.Set("showInstanceRun", true)
enter(nil)
expect("offene Welt: kein Lauf", run(), nil)
expect("Zeile ohne Lauf", instanceRow(), "-")

---------------------------------------------------------------------------
-- Todesminen: /reload, Tod mit Geisterlauf, Händlergang: alles ein Lauf
---------------------------------------------------------------------------
enter("Die Todesminen")
seeCopy(111)
expect("Kopie bestätigt", run().zoneUID, 111)
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Defias-Schurke stirbt, Ihr bekommt 100 Erfahrung.")
gainXp(3000)
wow.advance(900)
wow.logout()
wow.advance(20)
wow.login()
enter("Die Todesminen")
seeCopy(111)
expect("Reload: derselbe Lauf", #log(), 0)
expectNear("Reload-Pause zählt nicht", Instances.GetRunSeconds(run()), 900)

wow.state.dead = true
wow.fire("PLAYER_DEAD")
wow.fire("PLAYER_ALIVE")  -- Geist freigelassen
enter(nil)
wow.advance(60)
expectNear("Geisterlauf draußen zählt", Instances.GetRunSeconds(run()), 960)
enter("Die Todesminen")
wow.state.dead = false
wow.fire("PLAYER_UNGHOST")
expect("Tod gezählt", run().counters.deaths, 1)

enter(nil)  -- lebend raus zum Händler
wow.advance(600)
gainXp(50)
expectNear("draußen steht die Uhr", Instances.GetRunSeconds(run()), 960)
expect("XP draußen zählt nicht", run().xp, 3000)
expect("Zeile zeigt offenen Lauf", instanceRow(), string.format(addon.L.INSTANCE_RUN_VALUE,
  addon.Format.Duration(Instances.GetRunSeconds(run())), addon.Format.Number(3000)))
enter("Die Todesminen")
seeCopy(111)
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Edwin VanCleef stirbt, Ihr bekommt 500 Erfahrung.")
gainXp(2000)
wow.advance(240)

local current = History.GetInstanceLog(addon.characterKey)[1]
expect("offener Lauf vorne", current.isCurrent, true)
expectNear("Dauer ohne Händlergang", current.seconds, 1200)

---------------------------------------------------------------------------
-- Reset beendet den Lauf endgültig
---------------------------------------------------------------------------
enter(nil)
wow.fire("CHAT_MSG_SYSTEM", "Die Todesminen wurde zurückgesetzt.")
expect("Reset: Lauf beendet", run(), nil)
local finished = log()[1]
expect("Name", finished.name, "Die Todesminen")
expectNear("Dauer", finished.seconds, 1200)
expect("XP", finished.xp, 5000)
expect("Kills", finished.counters.kills, 2)
expect("Tode", finished.counters.deaths, 1)
expect("Level beim Betreten", finished.level, 20)
expect("zoneUID gespeichert", finished.zoneUID, 111)

-- "Noch Spieler drin" setzt für alle draußen trotzdem zurück
enter("Die Todesminen")
seeCopy(222)
enter(nil)
wow.fire("CHAT_MSG_SYSTEM", "Die Todesminen kann nicht zurückgesetzt werden. Es befinden sich noch Spieler in der Instanz.")
expect("gescheiterter Reset beendet auch", #log(), 2)

---------------------------------------------------------------------------
-- Andere Kopie trotz kurzer Pause (Reset nicht gesehen, anderer Gruppenleiter): Lauf wird geteilt
---------------------------------------------------------------------------
enter("Die Todesminen")
seeCopy(333)
gainXp(1000)
wow.advance(300)
enter(nil)
wow.advance(120)
enter("Die Todesminen")
gainXp(500)
wow.advance(60)
expect("vor der Bestätigung: geschätzt derselbe", #log(), 2)
seeCopy(444)
expect("andere Kopie: alter Lauf beendet", #log(), 3)
expect("alter Lauf ohne neue XP", log()[3].xp, 1000)
expectNear("alter Lauf ohne neue Zeit", log()[3].seconds, 300)
expect("neuer Lauf mit seiner XP", run().xp, 500)
expectNear("neuer Lauf mit seiner Zeit", Instances.GetRunSeconds(run()), 60)
expect("neue Kopie gemerkt", run().zoneUID, 444)

---------------------------------------------------------------------------
-- Lange Pause schätzt eine neue Kopie; zeigen die Gegner die alte, wird zusammengeführt
---------------------------------------------------------------------------
enter(nil)
wow.advance(31 * 60)
enter("Die Todesminen")
expect("geschätzt neu: alter Lauf beendet", #log(), 4)
gainXp(200)
seeCopy(444)
expect("doch dieselbe Kopie: zusammengeführt", #log(), 3)
expect("XP zusammen", run().xp, 700)

-- Ein anderer Dungeon beendet den Lauf; Kills draußen zählen nicht
enter(nil)
wow.fire("CHAT_MSG_COMBAT_XP_GAIN", "Wolf stirbt, Ihr bekommt 10 Erfahrung.")
expect("Welt-Kill nicht im Lauf", run().counters.kills, 0)
enter("Geschmolzener Kern", "raid")
expect("anderer Dungeon: alter Lauf beendet", #log(), 4)
expect("Raid erfasst", run().instanceType, "raid")

SlashCmdList.LEVELTIMER("history")
expectTrue("Reiter Instanzen", wow.click("Instanzen"))
