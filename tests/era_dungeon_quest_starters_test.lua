-- Tooltipzeilen an Gegenständen und Objekten, die Dungeonquests starten (LT-38): Gegenstand 2874 startet Quest 373
-- (Allianz, ab 16), Objekt 2868 „Crumpled Map“ den Kettenanfang 720 (ab 35). Objekte nur auf englischen Clients.
local Starters = addon.DungeonQuestStarters

local completed = {}
C_QuestLog = C_QuestLog or {}
C_QuestLog.IsQuestFlaggedCompleted = function(questID) return completed[questID] == true end
local locale = "enUS"
function GetLocale() return locale end

wow.state.class = "WARRIOR"
wow.login({ level = 40 })
wow.fire("QUEST_LOG_UPDATE")

-- Gegenstand: Zeile über OnTooltipSetItem
GameTooltip.GetItem = function() return "Map", "|cffffffff|Hitem:2874::::|h[Map]|h|r" end
GameTooltip._lines = {}
GameTooltip._scripts.OnTooltipSetItem(GameTooltip)
local line = GameTooltip._lines[1]
local offer = addon.DungeonQuests.GiverOffers("item", 2874)[1]
expectTrue("Gegenstand: Angebot", offer ~= nil and offer.questID == 373)
expect("Gegenstand: Zeile", line, addon.DungeonQuestGivers.OfferLine(offer))

-- Objekt: Welt-Tooltip mit Titel „Crumpled Map“
GameTooltip.GetItem = function() return nil end
GameTooltip.GetUnit = function() return nil end
GameTooltip.GetOwner = function() return UIParent end
GameTooltip.GetName = function() return "GameTooltip" end
GameTooltipTextLeft1 = CreateFrame("Frame")
GameTooltipTextLeft1.GetText = function() return "Crumpled Map" end
GameTooltip._lines = {}
GameTooltip._scripts.OnShow(GameTooltip)
expect("Objekt: eine Zeile", #GameTooltip._lines, 1)
expect("Objekt: Kettenschritt", #Starters.ObjectOffers("Crumpled Map"), 1)

-- Anderes Objekt, Einheit oder fremder Besitzer: nichts
GameTooltipTextLeft1.GetText = function() return "Mailbox" end
GameTooltip._lines = {}
GameTooltip._scripts.OnShow(GameTooltip)
expect("fremdes Objekt: keine Zeile", #GameTooltip._lines, 0)
GameTooltipTextLeft1.GetText = function() return "Crumpled Map" end
GameTooltip.GetOwner = function() return Minimap end
GameTooltip._lines = {}
GameTooltip._scripts.OnShow(GameTooltip)
expect("kein Welt-Tooltip: keine Zeile", #GameTooltip._lines, 0)

-- Angenommen bzw. andere Sprache: nichts
completed[720] = true
wow.fire("QUEST_LOG_UPDATE")
expect("abgegeben: kein Angebot", #Starters.ObjectOffers("Crumpled Map"), 0)
completed[720] = nil
wow.fire("QUEST_LOG_UPDATE")
locale = "deDE"
expectTrue("deDE: keine Objektnamen", not Starters.NamesAvailable())
expect("deDE: kein Angebot", #Starters.ObjectOffers("Crumpled Map"), 0)

-- Aus: keine Zeile am Gegenstand
addon.Set("dungeonQuestGivers", false)
GameTooltip.GetItem = function() return "Map", "|cffffffff|Hitem:2874::::|h[Map]|h|r" end
GameTooltip._lines = {}
GameTooltip._scripts.OnTooltipSetItem(GameTooltip)
expect("aus: keine Zeile", #GameTooltip._lines, 0)
