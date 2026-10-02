-- Große Einblendungen: nur eingeschaltete Arten, aus Journal und Level-Up, blenden nach Zeit aus.
local L = addon.L
local Journal = addon.Journal
local alert = LevelTimerAlert

local function shownText()
  return alert:IsShown() and alert.text:GetText() or nil
end

wow.login({ level = 10 })
expect("startet versteckt", shownText(), nil)

-- Standard: alles aus
wow.levelUp(11)
Journal.AddKill(Journal.PVE, "Seuchenbiss", "rare")
expect("ohne Einstellung keine Einblendung", shownText(), nil)

addon.Set("alertLevelUp", true)
addon.Set("alertRareKill", true)
addon.Set("alertEpicLoot", true)
addon.Set("alertNearDeath", true)

wow.levelUp(12)
expect("Level-Up", shownText(), string.format(L.ALERT_LEVEL_UP, 12))

Journal.AddKill(Journal.PVE, "Seuchenbiss", "rare")
expect("Rare-Kill", shownText(), string.format(L.ALERT_RARE_KILL, "Seuchenbiss"))

-- Elite ist getrennt schaltbar (in Dungeons sehr häufig)
Journal.AddKill(Journal.PVE, "Wächter", "elite")
expect("Elite aus: bleibt beim Rare", shownText(), string.format(L.ALERT_RARE_KILL, "Seuchenbiss"))
addon.Set("alertEliteKill", true)
Journal.AddKill(Journal.PVE, "Wächter", "elite")
expect("Elite-Kill", shownText(), string.format(L.ALERT_ELITE_KILL, "Wächter"))

-- In Dungeons und Raids keine Elite-Einblendung (dort ist fast alles Elite)
for _, kind in ipairs({ "party", "raid" }) do
  wow.state.instance = { name = "Todesminen", type = kind }
  Journal.AddKill(Journal.PVE, "Minenarbeiter", "elite")
  expect("keine Elite in " .. kind, shownText(), string.format(L.ALERT_ELITE_KILL, "Wächter"))
end
wow.state.instance = nil

-- Nur epische Beute, seltene nicht
Journal.AddLoot({ link = "[Blauer Ring]", quality = 3 })
expect("seltene Beute ohne Einblendung", shownText(), string.format(L.ALERT_ELITE_KILL, "Wächter"))
Journal.AddLoot({ link = "[Lila Schwert]", quality = 4 })
expect("epische Beute", shownText(), string.format(L.ALERT_EPIC_LOOT, "[Lila Schwert]"))

-- Im Raid ist epische Beute normal: keine Einblendung; im Dungeon schon
wow.state.instance = { name = "Geschmolzener Kern", type = "raid" }
Journal.AddLoot({ link = "[Raid-Helm]", quality = 4 })
expect("keine Beute im Raid", shownText(), string.format(L.ALERT_EPIC_LOOT, "[Lila Schwert]"))
wow.state.instance = { name = "Todesminen", type = "party" }
Journal.AddLoot({ link = "[Dungeon-Helm]", quality = 4 })
expect("Beute im Dungeon", shownText(), string.format(L.ALERT_EPIC_LOOT, "[Dungeon-Helm]"))
wow.state.instance = nil

Journal.AddNearDeath(4, {})
expect("Beinahe-Tod", shownText(), string.format(L.ALERT_NEAR_DEATH, 4))

-- Ausblenden: erst nach Haltezeit durchsichtiger, dann weg
wow.advance(3.5)
alert._scripts.OnUpdate(alert, 0.1)
expect("blendet aus, noch sichtbar", alert:IsShown(), true)
wow.advance(1)
alert._scripts.OnUpdate(alert, 0.1)
expect("nach Ablauf versteckt", alert:IsShown(), false)
