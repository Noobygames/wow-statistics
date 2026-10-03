-- Anfragen ablehnen: je Art schaltbar, Dialog zu, Chatzeile mit Namen.
local L = addon.L

local function hidden(popup)
  for _, action in ipairs(wow.questActions) do
    if action[1] == "hidePopup" and action[2] == popup then return true end
  end
  return false
end

wow.login()

-- Handel
wow.fire("TRADE_REQUEST", "Fremder")
expect("aus: nichts abgelehnt", #wow.declined, 0)
addon.Set("declineTrades", true)
wow.fire("TRADE_REQUEST", "Fremder")
expect("Handel abgelehnt", wow.declined[#wow.declined], "CancelTrade")
expectTrue("Handelsdialog zu", hidden("TRADE"))
expect("Chatzeile", wow.printed[#wow.printed]:find(string.format(L.DECLINED_TRADE, "Fremder"), 1, true) ~= nil, true)

-- Gruppeneinladung
addon.Set("declineGroupInvites", true)
wow.fire("PARTY_INVITE_REQUEST", "Einlader")
expect("Gruppe abgelehnt", wow.declined[#wow.declined], "DeclineGroup")
expectTrue("Einladungsdialog zu", hidden("PARTY_INVITE"))

-- Einladung mit Rollenwahl (Retail/Forever): eigenes Fenster
LFGInvitePopup = CreateFrame("Frame")
LFGInvitePopup:Show()
StaticPopupSpecial_Hide = function(frame) frame:Hide() end
wow.fire("PARTY_INVITE_REQUEST", "Einlader")
expect("Rollenwahl-Fenster zu", LFGInvitePopup:IsShown(), false)
LFGInvitePopup, StaticPopupSpecial_Hide = nil, nil

-- Gildeneinladung (Retail: eigenes Fenster)
GuildInviteFrame = CreateFrame("Frame")
GuildInviteFrame:Show()
addon.Set("declineGuildInvites", true)
wow.fire("GUILD_INVITE_REQUEST", "Gildenwerber", "Die Gilde")
expect("Gilde abgelehnt", wow.declined[#wow.declined], "DeclineGuild")
expectTrue("Gildendialog zu", hidden("GUILD_INVITE"))
expect("Gildenfenster zu", GuildInviteFrame:IsShown(), false)

-- Duell
addon.Set("declineDuels", true)
wow.fire("DUEL_REQUESTED", "Raufbold")
expect("Duell abgelehnt", wow.declined[#wow.declined], "CancelDuel")
expectTrue("Dueldialog zu", hidden("DUEL_REQUESTED"))

-- Duell bis zum Tod (Hardcore): gleicher Schalter
addon.Set("declineDuels", true)
wow.fire("DUEL_TO_THE_DEATH_REQUESTED", "Hardcore")
expect("Todesduell abgelehnt", wow.declined[#wow.declined], "CancelDuel")
expectTrue("Todesduell-Dialog zu", hidden("DUEL_TO_THE_DEATH_REQUESTED"))
