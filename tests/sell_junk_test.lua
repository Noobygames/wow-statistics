-- Schrott verkaufen: nur graue Gegenstände mit Verkaufswert, nicht gesperrte; Umschalttaste setzt aus.
local L = addon.L
local bags = wow.state.bags

local function fill()
  bags[0] = {
    [1] = { itemID = 1, quality = 0, stackCount = 3, hasNoValue = false, isLocked = false },  -- Schrott
    [2] = { itemID = 2, quality = 1, stackCount = 1, hasNoValue = false, isLocked = false },  -- weiß
    [3] = { itemID = 3, quality = 0, stackCount = 1, hasNoValue = true, isLocked = false },   -- ohne Wert
    [4] = { itemID = 4, quality = 0, stackCount = 1, hasNoValue = false, isLocked = true },   -- gesperrt
  }
  bags[1] = { [5] = { itemID = 5, quality = 0, stackCount = 1, hasNoValue = false, isLocked = false } }
end

wow.state.sellPrices = { [1] = 10, [2] = 500, [5] = 25 }
wow.login({ money = 0 })
fill()

wow.fire("MERCHANT_SHOW")
wow.runTimers()
expect("aus: nichts verkauft", wow.state.money, 0)

addon.Set("autoSellJunk", true)
wow.state.shiftDown = true
wow.fire("MERCHANT_SHOW")
wow.runTimers()
expect("Umschalttaste setzt aus", wow.state.money, 0)
wow.state.shiftDown = false

wow.fire("MERCHANT_SHOW")
wow.runTimers()
expect("Erlös aus Schrott beider Taschen", wow.state.money, 3 * 10 + 25)
expect("Schrott weg", bags[0][1], nil)
expect("weiß bleibt", bags[0][2] ~= nil, true)
expect("ohne Wert bleibt", bags[0][3] ~= nil, true)
expect("gesperrt bleibt", bags[0][4] ~= nil, true)
expectTrue("Erlös im Chat", wow.printed[#wow.printed]:find(string.format(L.JUNK_SOLD, 2, "55c"), 1, true) ~= nil)

-- Nichts mehr zu verkaufen: keine Chatzeile
local printed = #wow.printed
wow.fire("MERCHANT_SHOW")
wow.runTimers()
expect("ohne Schrott still", #wow.printed, printed)
