-- Zuwachs beim Level-Up: Leben, Mana und Werte vorher -> nachher, Chatzeile und Karte.
local L = addon.L
local LevelGains = addon.LevelGains

wow.login({ level = 10 })
addon.Alerts.Clear()
addon.Set("alertLevelUp", true)

-- Ohne Zuwächse im Ereignis (ältere Clients): sofort, ohne Zeilen
local readyLevel, readyGains
LevelGains.OnReady(function(level, gains) readyLevel, readyGains = level, gains end)
wow.levelUp(11)
expect("ohne Zuwächse: sofort", readyLevel, 11)
expect("ohne Zuwächse: keine Zeilen", readyGains, nil)

-- Mit Zuwächsen: erst nach der Verzögerung, wenn der Client die neuen Werte kennt
addon.Alerts.Clear()
readyLevel, readyGains = nil, nil
wow.state.healthMax = 1290
wow.state.powerMax = 540
wow.state.stats = { 83, 40, 95, 61 }
wow.levelUp(12, nil, { health = 90, power = 40, talents = 1, strength = 3, agility = 1, stamina = 5, intellect = 2 })
expect("mit Zuwächsen: wartet", readyLevel, nil)
wow.runTimers()
expect("mit Zuwächsen: bereit", readyLevel, 12)

local lines = LevelGains.Lines(readyGains)
expect("Leben vorher -> nachher", lines[1], L.GAIN_HEALTH .. " 1200 → 1290 (+90)")
expect("Mana", lines[2], L.GAIN_MANA .. " 500 → 540 (+40)")
expect("Stärke", lines[3], L.GAIN_STRENGTH .. " 80 → 83 (+3)")
expect("Beweglichkeit", lines[4], L.GAIN_AGILITY .. " 39 → 40 (+1)")
expect("Ausdauer", lines[5], L.GAIN_STAMINA .. " 90 → 95 (+5)")
expect("Intelligenz", lines[6], L.GAIN_INTELLECT .. " 59 → 61 (+2)")
expect("Talentpunkte", lines[7], string.format(L.GAIN_TALENTS, 1))

-- Karte mit allen Zeilen, Titel bleibt das Level
expect("Karte: Titel", LevelTimerNotice.title:GetText(), string.format(L.ALERT_LEVEL_UP, 12))
expect("Karte: Zeilen", LevelTimerNotice.body:GetText(), table.concat(lines, "\n"))

-- Einstellung aus: Karte ohne Zeilen
addon.Alerts.Clear()
addon.Set("levelUpGains", false)
wow.levelUp(13, nil, { health = 90, strength = 3 })
wow.runTimers()
expect("aus: Karte ohne Zeilen", LevelTimerNotice.body:GetText() or "", "")
addon.Set("levelUpGains", true)

-- Zuwachs null: keine Zeile; nichts zugelegt: kein Zuwachs
wow.levelUp(14, nil, { health = 0, strength = 0 })
wow.runTimers()
expect("nichts zugelegt", readyGains, nil)

-- Geheime Werte (Retail im Kampf): nur der Zuwachs
local secret = addon.IsSecret
addon.IsSecret = function() return true end
wow.levelUp(15, nil, { health = 90 })
wow.runTimers()
addon.IsSecret = secret
expect("geheim: nur Zuwachs", LevelGains.Lines(readyGains)[1], L.GAIN_HEALTH .. " +90")

-- Fehlersuche: Beispiel
local sample = LevelGains.Sample()
expectTrue("Beispiel hat Zeilen", #LevelGains.Lines(sample) >= 2)
