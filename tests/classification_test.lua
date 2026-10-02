-- Elite- und Rare-Kills: Einstufung aus Ziel, Maus oder Namensplakette, beim Kill per Name nachgeschlagen.
local Stats = addon.Stats

wow.login({ level = 30 })

local function see(unit, name, classification)
  wow.state.units[unit] = { name = name, classification = classification }
end
local function kill(name)
  wow.fire("CHAT_MSG_COMBAT_XP_GAIN", name .. " stirbt, Ihr bekommt 100 Erfahrung.")
end

see("target", "Hogger", "elite")
wow.fire("PLAYER_TARGET_CHANGED")
see("mouseover", "Mor'Ladim", "rareelite")
wow.fire("UPDATE_MOUSEOVER_UNIT")
see("nameplate1", "Morgan der Sammler", "rare")
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
wow.state.units.nameplate2 = { name = "Spieler", classification = "elite", isPlayer = true }
wow.fire("NAME_PLATE_UNIT_ADDED", "nameplate2")

kill("Hogger")
kill("Mor'Ladim")
kill("Morgan der Sammler")
kill("Wolf")  -- nie gesehen: normal

expect("PvE-Kills gesamt", Stats.Get(Stats.LEVEL, Stats.PVE_KILLS), 4)
expect("Elite (inkl. Rare-Elite)", Stats.Get(Stats.LEVEL, Stats.ELITE_KILLS), 2)
expect("Rare (inkl. Rare-Elite)", Stats.Get(Stats.SESSION, Stats.RARE_KILLS), 2)

local kills = addon.character.killLog
expect("Einstufung im Journal", kills[1].classification, "elite")
expect("Rare-Elite im Journal", kills[2].classification, "rareelite")
expect("unbekannte Einstufung", kills[4].classification, nil)
expect("Spieler werden nicht eingestuft", addon.Classification.Of("Spieler"), nil)

addon.Set("showSpecialKills", true)
SlashCmdList.LEVELTIMER("history")
expectTrue("Kill-Liste rendert", wow.click("Kills"))
