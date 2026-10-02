-- Todesursache aus dem Death Recap (Retail), wenn das Kampflog nichts liefert.
local Journal = addon.Journal

local recapEvents = nil  -- nil = Recap noch nicht bereit
C_DeathRecap = {
  GetRecapEvents = function() return recapEvents end,
}

local function die()
  wow.state.dead = true
  wow.fire("PLAYER_DEAD")
  wow.state.dead = false
  wow.fire("PLAYER_UNGHOST")
end

wow.login()
wow.runTimers()  -- /played-Abgleich nach dem Login, damit nur Recap-Timer übrig bleiben
local deaths = addon.character.deathLog

-- Tödlicher Treffer = erster Eintrag (wie im Recap-Fenster)
recapEvents = {
  { event = "SPELL_DAMAGE", sourceName = "Hogger", spellName = "Prankenhieb" },
  { event = "SWING_DAMAGE", sourceName = "Wolf" },
}
die()
expect("Recap: Verursacher", deaths[1].killer, "Hogger")
expect("Recap: Zauber", deaths[1].spell, "Prankenhieb")

-- Umgebungsschaden
recapEvents = { { event = "ENVIRONMENTAL_DAMAGE", environmentalType = "Falling" } }
die()
expect("Recap: Umgebung", deaths[2].environment, "Falling")
expect("Recap: Umgebung lokalisiert", addon.History.DeathCauseText(deaths[2]), addon.L.CAUSE_FALLING)
expect("Recap: Umgebung ohne Verursacher", deaths[2].killer, nil)

-- Recap erst kurz nach dem Tod bereit: Ursache wird nachgetragen
recapEvents = nil
die()
expect("Recap fehlt noch", deaths[3].killer, nil)
recapEvents = { { event = "SWING_DAMAGE", sourceName = "Murloc" } }
wow.runTimers()
expect("Recap nachgetragen", deaths[3].killer, "Murloc")

-- Kampflog hat Vorrang vor dem Recap
recapEvents = { { event = "SWING_DAMAGE", sourceName = "Recap-Gegner" } }
wow.combatLog("SWING_DAMAGE", "Kampflog-Gegner", wow.state.guid, 20)
die()
expect("Kampflog vor Recap", deaths[4].killer, "Kampflog-Gegner")
expect("kein Timer bei bekannter Ursache", #wow.timers, 0)

-- Leerer Recap: Ursache bleibt unbekannt
recapEvents = {}
wow.advance(60)
die()
wow.runTimers()
expect("leerer Recap", addon.History.DeathCauseText(deaths[5]), addon.L.CAUSE_UNKNOWN)

expect("fünf Tode", #deaths, 5)
expectTrue("Journal liefert Eintrag", Journal.AddDeath({}) == deaths[6])
