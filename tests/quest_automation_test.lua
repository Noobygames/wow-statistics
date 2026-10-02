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
