-- Quests automatisch annehmen: Quest-Text, Gesprächsliste, alte Quest-Liste, geteilte Quests.
local gossip, greeting = wow.state.gossip, wow.state.greeting

local function lastAction()
  local action = wow.questActions[#wow.questActions]
  return action and table.concat(action, " ", 1, #action) or nil
end

local function reset()
  wow.questActions = {}
end

wow.login()

-- Standard aus
wow.fire("QUEST_DETAIL")
expect("aus: nichts angenommen", lastAction(), nil)

addon.Set("autoAcceptQuests", true)
wow.fire("QUEST_DETAIL")
expect("angenommen", lastAction(), "accept")

-- Vom Client schon angenommen (Retail): nur bestätigen
reset()
wow.state.questAutoAccept = true
wow.fire("QUEST_DETAIL")
expect("Auto-Quest bestätigt", lastAction(), "acknowledge")
wow.state.questAutoAccept = false

-- PvP-Quests fragen im Spiel nach: manuell
reset()
wow.state.questPvp = true
wow.fire("QUEST_DETAIL")
expect("PvP manuell", lastAction(), nil)
wow.state.questPvp = false

-- Graue Quest im Quest-Text (Retail/Forever: C_QuestLog.IsQuestTrivial)
reset()
wow.state.questID = 77
wow.state.trivialQuests = { [77] = true }
wow.fire("QUEST_DETAIL")
expect("graue Quest manuell", lastAction(), nil)
wow.state.trivialQuests = {}
wow.fire("QUEST_DETAIL")
expect("normale Quest angenommen", lastAction(), "accept")

-- Von einem Spieler geteilt: nur mit autoAcceptShared
reset()
wow.state.units.questnpc = { name = "Mitspieler", isPlayer = true }
wow.fire("QUEST_DETAIL")
expect("geteilt ohne Schalter: manuell", lastAction(), nil)
addon.Set("autoAcceptShared", true)
wow.fire("QUEST_DETAIL")
expect("geteilt mit Schalter: angenommen", lastAction(), "accept")
addon.Set("autoAcceptShared", false)
wow.state.units.questnpc = { name = "Questgeber", isPlayer = false }
reset()
wow.fire("QUEST_DETAIL")
expect("NPC: angenommen", lastAction(), "accept")
wow.state.units.questnpc = nil
reset()

-- Umschalttaste setzt aus
wow.state.shiftDown = true
wow.fire("QUEST_DETAIL")
expect("Umschalttaste", lastAction(), nil)
wow.state.shiftDown = false

-- Gespräch: erste lohnende Quest öffnen, graue und ignorierte auslassen
gossip.available = {
  { questID = 11, isTrivial = true, isIgnored = false },
  { questID = 12, isTrivial = false, isIgnored = true },
  { questID = 13, isTrivial = false, isIgnored = false },
}
wow.fire("GOSSIP_SHOW")
expect("Gespräch: Quest 13", lastAction(), "selectAvailable 13")

reset()
gossip.available = { { questID = 11, isTrivial = true, isIgnored = false } }
wow.fire("GOSSIP_SHOW")
expect("nur graue: nichts", lastAction(), nil)

-- Alte Quest-Liste ohne Gespräch: Index statt Quest-ID
greeting.available = { { title = "Grau", isTrivial = true }, { title = "Neu", isTrivial = false } }
wow.fire("QUEST_GREETING")
expect("Liste: zweite Quest", lastAction(), "greetingAvailable 2")

-- Geteilte Quest: eigener Schalter
reset()
wow.fire("QUEST_ACCEPT_CONFIRM", "Mitspieler", "Eskorte")
expect("geteilt: aus", lastAction(), nil)
addon.Set("autoAcceptShared", true)
wow.fire("QUEST_ACCEPT_CONFIRM", "Mitspieler", "Eskorte")
expect("bestätigt", wow.questActions[1][1], "confirm")
expect("Dialog zu", lastAction(), "hidePopup QUEST_ACCEPT")

---------------------------------------------------------------------------
-- Abgeben (autoTurnIn): Fortschritt, Belohnung, Gespräch, alte Quest-Liste
---------------------------------------------------------------------------
reset()
wow.fire("QUEST_PROGRESS")
wow.fire("QUEST_COMPLETE")
expect("Abgabe aus", lastAction(), nil)

addon.Set("autoTurnIn", true)
wow.state.questCompletable = false
wow.fire("QUEST_PROGRESS")
expect("nicht fertig: nichts", lastAction(), nil)
wow.state.questCompletable = true
wow.fire("QUEST_PROGRESS")
expect("abschließen", lastAction(), "complete")

-- Belohnung: keine Auswahl = 0, eine = 1
wow.fire("QUEST_COMPLETE")
expect("ohne Auswahl", lastAction(), "reward 0")
wow.state.questChoices = { "Schwert" }
wow.fire("QUEST_COMPLETE")
expect("eine Belohnung", lastAction(), "reward 1")

-- Mehrere: ohne Schalter wählt der Spieler, mit Schalter die wertvollste
reset()
wow.state.questChoices = { "Schwert", "Schild", "Stab" }
wow.state.sellPrices = { Schwert = 100, Schild = 300, Stab = 200 }
wow.fire("QUEST_COMPLETE")
expect("Auswahl: Spieler wählt", lastAction(), nil)
addon.Set("autoChooseReward", true)
wow.fire("QUEST_COMPLETE")
expect("wertvollste", lastAction(), "reward 2")

-- Unbekannter Verkaufswert: lieber nicht raten
reset()
wow.state.sellPrices = { Schwert = 100, Schild = 300 }
wow.fire("QUEST_COMPLETE")
expect("Wert unbekannt: Spieler wählt", lastAction(), nil)
wow.state.questChoices = {}

-- Quest kostet Geld: im Spiel bestätigen
wow.state.questMoney = 500
wow.fire("QUEST_COMPLETE")
expect("kostet Geld: manuell", lastAction(), nil)
wow.state.questMoney = 0

-- Gespräch: fertige Quest vor neuer
gossip.available = { { questID = 21, isTrivial = false, isIgnored = false } }
gossip.active = { { questID = 30, isComplete = false }, { questID = 31, isComplete = true } }
wow.fire("GOSSIP_SHOW")
expect("Gespräch: erst abgeben", lastAction(), "selectActive 31")
gossip.active = { { questID = 30, isComplete = false } }
wow.fire("GOSSIP_SHOW")
expect("dann annehmen", lastAction(), "selectAvailable 21")

-- Alte Quest-Liste
greeting.active = { { title = "Offen", isComplete = false }, { title = "Fertig", isComplete = true } }
wow.fire("QUEST_GREETING")
expect("Liste: fertige abgeben", lastAction(), "greetingActive 2")

---------------------------------------------------------------------------
-- Gespräch überspringen (skipGossip): nur ohne Quests und mit genau einer verfügbaren Option
---------------------------------------------------------------------------
reset()
gossip.available, gossip.active = {}, {}
gossip.options = { { orderIndex = 0, status = 0, name = "Zeigt mir, wohin ich fliegen kann." } }
wow.fire("GOSSIP_SHOW")
expect("überspringen aus", lastAction(), nil)

addon.Set("skipGossip", true)
wow.fire("GOSSIP_SHOW")
expect("einzige Option gewählt", lastAction(), "selectOption 0")

reset()
gossip.options[1].status = 2  -- gesperrt
wow.fire("GOSSIP_SHOW")
expect("gesperrte Option nicht", lastAction(), nil)

gossip.options = { { orderIndex = 0, status = 0 }, { orderIndex = 1, status = 0 } }
wow.fire("GOSSIP_SHOW")
expect("zwei Optionen: Spieler wählt", lastAction(), nil)

-- Offene (nicht fertige) Quest: Gespräch bleibt offen
gossip.options = { { orderIndex = 0, status = 0 } }
gossip.active = { { questID = 30, isComplete = false } }
wow.fire("GOSSIP_SHOW")
expect("mit Quest: Spieler wählt", lastAction(), nil)
