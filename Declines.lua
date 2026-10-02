-- Anfragen anderer Spieler automatisch ablehnen, jede Art einzeln schaltbar (Reiter "Komfort", aus):
-- Handel (declineTrades), Gruppeneinladungen (declineGroupInvites).
-- Abläufe wie in Blizzards UIParent/StaticPopup aller Clients: das Event zeigt den Dialog, die
-- Ablehnen-Taste ruft die Funktion; wir lehnen ab und schließen den Dialog. Eine Chatzeile nennt,
-- wer gefragt hat.
local _, ns = ...
local L = ns.L

local Declines = {}
ns.Declines = Declines

-- Je Art: Einstellung, Event (erstes Argument = Name), Ablehnen, Dialog, Chatzeile
Declines.KINDS = {
  { setting = "declineTrades", event = "TRADE_REQUEST", decline = function() CancelTrade() end,
    popup = "TRADE", message = "DECLINED_TRADE" },
  { setting = "declineGroupInvites", event = "PARTY_INVITE_REQUEST", decline = function() DeclineGroup() end,
    popup = "PARTY_INVITE", message = "DECLINED_GROUP" },
}

for _, kind in ipairs(Declines.KINDS) do
  ns.RegisterEvent(kind.event, function(name)
    if not ns.db or not ns.db[kind.setting] then return end
    ns.Debug("declines", "%s from %s", kind.event, name)
    kind.decline()
    StaticPopup_Hide(kind.popup)
    if kind.hide then kind.hide() end
    ns.Print(string.format(L[kind.message], name or L.UNKNOWN_NAME))
  end)
end
