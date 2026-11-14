-- Tooltipzeilen an Objekten und Gegenständen, die eine Dungeonquest oder einen Kettenschritt starten (LT-38; unter der
-- Einstellung dungeonQuestGivers): dieselben Zeilen wie an NPCs ("Dungeonquest: Titel (Instanz)", "Vorquest: ...",
-- DungeonQuestGivers.AddOfferLines), nur solange der Charakter die Quest jetzt annehmen kann.
-- Gegenstände: Item-ID aus tooltip:GetItem() (Taschen, Beute, Links); Anschluss wie QuestItemTooltip.lua:
-- TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item) mit dem Tooltip-Datensystem, sonst
-- HookScript("OnTooltipSetItem") an GameTooltip und ItemRefTooltip.
-- Objekte der Spielwelt haben im Tooltip weder Einheit noch ID: erkannt am Titel (GameTooltipTextLeft1) beim Zeigen
-- eines Welt-Tooltips (Besitzer UIParent, keine Einheit, kein Gegenstand), verglichen mit den Namen aus
-- ns.DungeonDB.objectNames.
-- shortcut: QuestieDB führt Objektnamen nur englisch, daher nur auf enUS/enGB-Clients; mit einer Quelle übersetzter
-- Objektnamen (oder einer Objekt-ID im Tooltip, Prüfung LT38.tooltip.object) auf alle Sprachen erweitern.
local _, ns = ...

local DungeonQuests = ns.DungeonQuests
local Givers = ns.DungeonQuestGivers

local DungeonQuestStarters = {}
ns.DungeonQuestStarters = DungeonQuestStarters

local NAME_LOCALES = { enUS = true, enGB = true }

local objectsByName  -- [Name] = { objectID, ... }

local function readable(value)
  if value == nil or ns.IsSecret(value) then return nil end
  return value
end

local function isEnabled()
  return ns.db and ns.db.dungeonQuestGivers and Givers.IsAvailable()
end

-- Werden Objektnamen in dieser Spielsprache erkannt?
function DungeonQuestStarters.NamesAvailable()
  return GetLocale ~= nil and NAME_LOCALES[GetLocale()] == true
end

-- Angebote aller Objekte mit diesem Namen
function DungeonQuestStarters.ObjectOffers(name)
  local db = ns.DungeonDB
  if not (db and db.objectNames and DungeonQuestStarters.NamesAvailable()) then return {} end
  if not objectsByName then
    objectsByName = {}
    for objectID, objectName in pairs(db.objectNames) do
      objectsByName[objectName] = objectsByName[objectName] or {}
      table.insert(objectsByName[objectName], objectID)
    end
  end
  local offers = {}
  for _, objectID in ipairs(objectsByName[name] or {}) do
    for _, offer in ipairs(DungeonQuests.GiverOffers("object", objectID)) do table.insert(offers, offer) end
  end
  return offers
end

local function onItemTooltip(tooltip)
  if not isEnabled() or type(tooltip) ~= "table" or type(tooltip.GetItem) ~= "function" then return end
  local _, link = tooltip:GetItem()
  link = readable(link)
  local itemID = type(link) == "string" and tonumber((link:match("item:(%d+)")))
  if not itemID then return end
  Givers.AddOfferLines(tooltip, DungeonQuests.GiverOffers("item", itemID))
end

-- Welt-Tooltip ohne Einheit und Gegenstand: Titel als Objektname
local function onTooltipShow(tooltip)
  if not isEnabled() or tooltip:GetOwner() ~= UIParent then return end
  if readable(tooltip:GetUnit()) or readable(tooltip:GetItem()) then return end
  local frameName = tooltip:GetName()
  local title = type(frameName) == "string" and _G[frameName .. "TextLeft1"]
  local name = title and readable(title:GetText())
  if type(name) ~= "string" then return end
  local offers = DungeonQuestStarters.ObjectOffers(name)
  if #offers == 0 then return end
  Givers.AddOfferLines(tooltip, offers)
  tooltip:Show()  -- Größe nach den neuen Zeilen anpassen
end

local hooked = false
local function hook()
  if hooked or not GameTooltip then return end
  hooked = true
  local itemType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and itemType then
    TooltipDataProcessor.AddTooltipPostCall(itemType, onItemTooltip)
  else
    for _, tooltip in ipairs({ GameTooltip, ItemRefTooltip }) do
      tooltip:HookScript("OnTooltipSetItem", function(self)
        onItemTooltip(self)
        self:Show()
      end)
    end
  end
  if DungeonQuestStarters.NamesAvailable() then GameTooltip:HookScript("OnShow", onTooltipShow) end
end

ns.RegisterApply(function(db)
  if db.dungeonQuestGivers and Givers.IsAvailable() then hook() end
end)
