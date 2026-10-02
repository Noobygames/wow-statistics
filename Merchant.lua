-- Händler: beim Öffnen (MERCHANT_SHOW) automatisch reparieren (autoRepair), optional zuerst aus
-- der Gildenbank (autoRepairGuild), und grauen Schrott verkaufen (autoSellJunk).
-- APIs wie in Blizzards MerchantFrame aller Clients: CanMerchantRepair, GetRepairAllCost
-- (Kosten, ob etwas zu reparieren ist), RepairAllItems(useGuildBank). Die Gildenbank gibt es nur,
-- wo CanGuildBankRepair existiert (nicht in Classic Era, siehe Client.HasGuildBank).
-- Schrott: Taschen über C_Container (GetContainerItemInfo: quality, hasNoValue, isLocked) in allen
-- Clients; verkauft wird mit C_Container.UseContainerItem bei offenem Händler. Den Erlös zählt
-- MoneyCounter wie jede Einnahme.
local _, ns = ...
local L = ns.L
local Comfort = ns.Comfort
local Format = ns.Format

local Merchant = {}
ns.Merchant = Merchant

local UNLIMITED_WITHDRAW = -1  -- GetGuildBankWithdrawMoney beim Gildenmeister
local POOR_QUALITY = 0         -- Enum.ItemQuality.Poor (grau)
local BACKPACK = 0
local DEFAULT_BAG_SLOTS = 4    -- ausgerüstete Taschen, falls der Client die Konstante nicht kennt
local SELL_PRICE_INDEX = 11    -- Rückgabewert sellPrice von GetItemInfo

local getItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo

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

-- Letzte Tasche: Retail zählt die Reagenzientasche mit (NUM_TOTAL_EQUIPPED_BAG_SLOTS)
local function lastBag()
  return NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or DEFAULT_BAG_SLOTS
end

local function isJunk(info)
  return info and info.quality == POOR_QUALITY and not info.hasNoValue and not info.isLocked
end

local function sellPrice(info)
  return (select(SELL_PRICE_INDEX, getItemInfo(info.itemID)) or 0) * info.stackCount
end

-- Alle grauen Gegenstände mit Verkaufswert verkaufen; Anzahl und erwarteter Erlös im Chat
function Merchant.SellJunk()
  if not Comfort.IsActive("autoSellJunk") then return end
  local count, total = 0, 0
  for bag = BACKPACK, lastBag() do
    for slot = 1, C_Container.GetContainerNumSlots(bag) do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      if isJunk(info) then
        count = count + 1
        total = total + sellPrice(info)
        C_Container.UseContainerItem(bag, slot)
      end
    end
  end
  ns.Debug("merchant", "sold %s junk items for %s", count, total)
  if count > 0 then
    ns.Print(string.format(L.JUNK_SOLD, count, Format.Money(total)))
  end
end

ns.RegisterEvent("MERCHANT_SHOW", function()
  Merchant.SellJunk()
  Merchant.Repair()
end)
