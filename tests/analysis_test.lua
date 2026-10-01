-- Auswertungen für die Graphen: Datenreihen aus Historie und Journal.
local Analysis = addon.Analysis
local Journal = addon.Journal
local DAY = 86400

wow.login({ level = 12, xp = 300, xpMax = 1000, playedSeconds = 1800, clock = os.time({ year = 2026, month = 10, day = 14, hour = 12 }) })
local key = addon.characterKey

-- Abgeschlossene Level 10 und 11, laufendes Level 12
addon.character.levelHistory[10] = { level = 10, seconds = 3600, xp = 900, counters = {} }
addon.character.levelHistory[11] = { level = 11, seconds = 7200, xp = 1000, counters = {} }

local times = Analysis.TimePerLevel(key)
expect("Level aufsteigend", times[1].label .. "," .. times[2].label .. "," .. times[3].label, "10,11,12")
expect("Zeit Level 11", times[2].value, 7200)
expect("Text Level 11", times[2].text, "2h 00m")
expect("laufendes Level hervorgehoben", times[3].highlight, true)

local rates = Analysis.XpRatePerLevel(key)
expectNear("XP/h Level 10", rates[1].value, 900)
expectNear("XP/h laufendes Level", rates[3].value, 600)

-- Kills über die Kill-Meldung (zählt Journal und Tageswerte): zwei heute, einer vor drei Tagen,
-- einer vor 20 Tagen, einer vor 40 Tagen (außerhalb der 30 Tage)
local now = wow.state.clock
local function killAt(timestamp, name)
  wow.state.clock = timestamp
  wow.fire("CHAT_MSG_COMBAT_XP_GAIN", name .. " stirbt, Ihr bekommt 10 Erfahrung.")
end
killAt(now, "Wolf")
killAt(now - 60, "Wolf")
killAt(now - 3 * DAY, "Kobold")
killAt(now - 20 * DAY, "Murloc")
killAt(now - 40 * DAY, "Murloc")
wow.state.clock = now
Journal.AddKill(Journal.PVE, nil)  -- Name verborgen (nur Journal)

local perDay = Analysis.KillsPerDay(key)
expect("30 Tage", #perDay, 30)
expect("heute zuletzt und hervorgehoben", perDay[30].highlight, true)
expect("Kills heute", perDay[30].value, 2)
expect("Kills vor drei Tagen", perDay[27].value, 1)
expect("Kills vor 20 Tagen", perDay[10].value, 1)
expect("Tage ohne Kills", perDay[1].value, 0)
expect("Datumsbeschriftung", perDay[30].label, "14.10.")

-- Langzeit: Tageswerte bleiben, auch wenn das Journal geleert wird
addon.character.killLog = {}
expect("Tageswerte unabhängig vom Journal", Analysis.KillsPerDay(key)[30].value, 2)
for _, name in ipairs({ "Wolf", "Wolf", "Kobold", "Murloc" }) do
  Journal.AddKill(Journal.PVE, name)
end
Journal.AddKill(Journal.PVE, nil)

local top = Analysis.TopKills(key)
expect("häufigster Gegner", top[1].label, "Wolf")
expect("Anzahl", top[1].value, 2)
expect("Anzahl mit Anteil", top[1].text, "2 (40%)")
expect("verborgener Name", top[2].label == "Unbekannt" or top[3].label == "Unbekannt" or top[4].label == "Unbekannt", true)

-- Todesursachen: gleiche Ursache zusammengefasst
for _ = 1, 2 do
  Journal.AddDeath({ killer = "Hogger", spell = "Prankenhieb" })
end
Journal.AddDeath({ environment = "FALLING" })
local causes = Analysis.DeathCauses(key)
expect("häufigste Ursache", causes[1].label, "Hogger (Prankenhieb)")
expect("Anzahl Ursache", causes[1].value, 2)
expect("Umgebung übersetzt", causes[2].label, "Sturz")

-- Begrenzung: höchstens 10 Einträge in Ranglisten
for i = 1, 15 do
  Journal.AddKill(Journal.PVE, "Gegner " .. i)
end
expect("Top 10", #Analysis.TopKills(key), 10)
