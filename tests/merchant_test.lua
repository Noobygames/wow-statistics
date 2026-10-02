-- Händler: automatisch reparieren, optional aus der Gildenbank; Umschalttaste setzt aus.
local L = addon.L
local merchant = wow.state.merchant

local function openMerchant(cost)
  merchant.canRepair = true
  merchant.repairCost = cost
  wow.fire("MERCHANT_SHOW")
end

wow.login({ money = 10000 })

-- Standard aus
openMerchant(500)
expect("aus: keine Reparatur", #wow.repairs, 0)

addon.Set("autoRepair", true)
openMerchant(500)
expect("repariert", #wow.repairs, 1)
expect("selbst bezahlt", wow.state.money, 9500)
expect("Kosten im Chat", wow.printed[#wow.printed]:find(string.format(L.REPAIRED, "500c"), 1, true) ~= nil, true)

-- Nichts kaputt oder Händler ohne Reparatur: nichts tun
openMerchant(0)
expect("nichts zu reparieren", #wow.repairs, 1)
merchant.canRepair = false
merchant.repairCost = 300
wow.fire("MERCHANT_SHOW")
expect("Händler ohne Reparatur", #wow.repairs, 1)

-- Umschalttaste: diesmal nicht
wow.state.shiftDown = true
openMerchant(300)
expect("Umschalttaste setzt aus", #wow.repairs, 1)
wow.state.shiftDown = false

-- Zu wenig Geld: Hinweis statt Reparatur
wow.state.money = 100
openMerchant(300)
expect("zu wenig Geld", #wow.repairs, 1)
expectTrue("Hinweis zu wenig Geld", wow.printed[#wow.printed]:find(string.format(L.REPAIR_NO_MONEY, "300c"), 1, true) ~= nil)

-- Gildenbank: nur wenn eingeschaltet und das Limit die ganze Reparatur deckt
wow.state.money = 10000
addon.Set("autoRepairGuild", true)
merchant.guildRepair = true
merchant.guildWithdraw = 200
merchant.guildMoney = 5000
openMerchant(300)
expect("Limit reicht nicht: selbst bezahlt", wow.repairs[#wow.repairs].guild, false)

merchant.guildWithdraw = 1000
openMerchant(300)
expect("aus der Gildenbank", wow.repairs[#wow.repairs].guild, true)
expect("Gildenbank belastet", merchant.guildMoney, 4700)
expectTrue("Gildenbank im Chat", wow.printed[#wow.printed]:find(string.format(L.REPAIRED_GUILD, "300c"), 1, true) ~= nil)

-- Gildenmeister: unbegrenztes Limit (-1), aber höchstens der Bankstand
merchant.guildWithdraw = -1
merchant.guildMoney = 100
openMerchant(300)
expect("Bank zu leer: selbst bezahlt", wow.repairs[#wow.repairs].guild, false)
merchant.guildMoney = 1000
openMerchant(300)
expect("Gildenmeister: Gildenbank", wow.repairs[#wow.repairs].guild, true)

-- Classic Era hat keine Gildenbank
wow.state.interface = 11509
expect("Classic Era ohne Gildenbank", addon.Client.HasGuildBank(), false)
openMerchant(300)
expect("Classic Era: selbst bezahlt", wow.repairs[#wow.repairs].guild, false)
wow.state.interface = 20506
expect("TBC mit Gildenbank", addon.Client.HasGuildBank(), true)
