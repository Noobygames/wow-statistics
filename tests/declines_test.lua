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
