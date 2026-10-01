-- XP-Verlauf der Session in 5-Minuten-Abschnitten.
local Analysis = addon.Analysis

wow.login({ xp = 0, xpMax = 10000 })
expect("ohne XP leer", #Analysis.SessionXpTimeline(addon.characterKey), 0)

local function gainXp(amount)
  wow.state.xp = wow.state.xp + amount
  wow.fire("PLAYER_XP_UPDATE", "player")
end

wow.advance(120)
gainXp(100)    -- Abschnitt 1 (0:00)
wow.advance(400)
gainXp(50)     -- Abschnitt 2 (0:05), bei 8:40
wow.advance(900)
gainXp(30)     -- Abschnitt 5 (0:20), bei 23:40; dazwischen Pause

local items = Analysis.SessionXpTimeline(addon.characterKey)
expect("fünf Abschnitte bis jetzt", #items, 5)
expect("Abschnitt 1", items[1].value, 100)
expect("Abschnitt 2", items[2].value, 50)
expect("Pause sichtbar", items[3].value, 0)
expect("Abschnitt 5", items[5].value, 30)
expect("Beschriftung", items[2].label, "0:05")
expect("aktueller Abschnitt hervorgehoben", items[5].highlight, true)

-- /reload: Verlauf läuft in derselben Session weiter
wow.logout()
wow.login()
wow.advance(60)
gainXp(20)
items = Analysis.SessionXpTimeline(addon.characterKey)
expect("nach Reload weiter im Abschnitt 5", items[5].value, 50)
