-- Händler: automatisch reparieren, optional aus der Gildenbank; Umschalttaste setzt aus.
local L = addon.L
local merchant = wow.state.merchant

local function openMerchant(cost)
  merchant.canRepair = true
  merchant.repairCost = cost
  wow.fire("MERCHANT_SHOW")
  wow.runTimers()  -- Gildenreparatur prüfen
  wow.runTimers()  -- Geldbuchung des Servers
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

-- Gildenbank: erst versuchen (Kontostand der Bank ist vorher nicht bekannt), Rest selbst bezahlen
wow.state.money = 10000
addon.Set("autoRepairGuild", true)
merchant.guildRepair = true
merchant.guildFunds = 200
openMerchant(300)
expect("Gilde zahlt nicht: selbst bezahlt", wow.repairs[#wow.repairs].guild, false)
expect("selbst bezahlt: Geld", wow.state.money, 9700)
expectTrue("keine Gildenmeldung", not wow.printed[#wow.printed]:find(string.format(L.REPAIRED_GUILD, "300c"), 1, true))

merchant.guildFunds = 1000
openMerchant(300)
expect("aus der Gildenbank", wow.repairs[#wow.repairs].guild, true)
expect("Gildenbank belastet", merchant.guildFunds, 700)
expect("eigenes Geld unberührt", wow.state.money, 9700)
expectTrue("Gildenbank im Chat", wow.printed[#wow.printed]:find(string.format(L.REPAIRED_GUILD, "300c"), 1, true) ~= nil)

-- Classic Era hat keine Gildenbank
wow.state.interface = 11509
expect("Classic Era ohne Gildenbank", addon.Client.HasGuildBank(), false)
openMerchant(300)
expect("Classic Era: selbst bezahlt", wow.repairs[#wow.repairs].guild, false)
wow.state.interface = 20506
expect("TBC mit Gildenbank", addon.Client.HasGuildBank(), true)
