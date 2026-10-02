-- Händler: beim Öffnen (MERCHANT_SHOW) automatisch reparieren (autoRepair), optional zuerst aus
-- der Gildenbank (autoRepairGuild).
-- APIs wie in Blizzards MerchantFrame aller Clients: CanMerchantRepair, GetRepairAllCost
-- (Kosten, ob etwas zu reparieren ist), RepairAllItems(useGuildBank). Die Gildenbank gibt es nur,
-- wo CanGuildBankRepair existiert (nicht in Classic Era, siehe Client.HasGuildBank).
local _, ns = ...
local L = ns.L
local Comfort = ns.Comfort
local Format = ns.Format

local Merchant = {}
ns.Merchant = Merchant

local UNLIMITED_WITHDRAW = -1  -- GetGuildBankWithdrawMoney beim Gildenmeister

-- Was die Gildenbank für Reparaturen hergibt; wie Blizzards Tooltip am Gildenbank-Button:
-- Abhebelimit, höchstens der Kontostand der Bank
local function guildRepairFunds()
  local limit = GetGuildBankWithdrawMoney()
  local bankMoney = GetGuildBankMoney()
  if limit == UNLIMITED_WITHDRAW then return bankMoney end
  return math.min(limit, bankMoney)
end

-- Gildenbank nur, wenn sie die ganze Reparatur bezahlt; sonst zahlt der Charakter selbst
local function guildPays(cost)
  return ns.db.autoRepairGuild
    and ns.Client.HasGuildBank()
    and CanGuildBankRepair()
    and guildRepairFunds() >= cost
end

function Merchant.Repair()
  if not Comfort.IsActive("autoRepair") or not CanMerchantRepair() then return end
  local cost, canRepair = GetRepairAllCost()
  ns.Debug("merchant", "repair cost %s, can repair %s", cost, canRepair)
  if not canRepair or cost <= 0 then return end
  if guildPays(cost) then
    RepairAllItems(true)
    ns.Print(string.format(L.REPAIRED_GUILD, Format.Money(cost)))
  elseif GetMoney() >= cost then
    RepairAllItems()
    ns.Print(string.format(L.REPAIRED, Format.Money(cost)))
  else
    ns.Print(string.format(L.REPAIR_NO_MONEY, Format.Money(cost)))
  end
end

ns.RegisterEvent("MERCHANT_SHOW", function()
  Merchant.Repair()
end)
