-- Zielarten. Jede Art ist ein Eintrag mit:
--   color, icon        Farbe und Symbol der Karte (Alerts.ICONS von Level Time: Zahl = Spell-ID, sonst Pfad)
--   validate(params, target) -> Fehlertext oder nil
--   initial()          Startstand (nur wo er nicht 0 ist, z.B. das aktuelle Level)
--   title(goal)        Überschrift der Karte
--   body(goal)         zweite Zeile (optional)
-- Params je Art:
--   level:  keine (target = Ziel-Level)
--   kills:  { source = "any"|"pve"|"pvp", battleground = true|nil }
--   item:   { itemId, link, name, boss } (boss = Anmerkung für die Karte, wird nicht geprüft)
--   bgwin:  { battleground = Name oder nil } (Teilstring des Schlachtfeld-Namens)
local _, ns = ...
local LT = ns.LT
local Goals = ns.Goals
local L = ns.L
local Alerts = LT.Alerts

local Kinds = {}
ns.Kinds = Kinds

Kinds.ORDER = { "level", "kills", "item", "bgwin" }
Kinds.KILL_SOURCES = { "any", "pve", "pvp" }

local COLORS = {
  level = { 0.96, 0.79, 0.36 },
  kills = { 0.9, 0.3, 0.3 },
  item = { 0.64, 0.21, 0.93 },
  bgwin = { 0.3, 0.6, 1 },
}
local BGWIN_ICON = "Interface\\Icons\\INV_BannerPVP_02"
local KILL_TITLES = { any = "SG_GOAL_KILLS_ANY", pve = "SG_GOAL_KILLS_PVE", pvp = "SG_GOAL_KILLS_PVP" }

local function validAmount(target)
  if type(target) ~= "number" or target < 1 or target ~= math.floor(target) then
    return L.SG_ERR_AMOUNT
  end
end

-- Item-ID und Link aus einem Link, "item:123..." oder einer Zahl; nil, wenn nichts Brauchbares darin steckt
function Kinds.ParseItem(text)
  text = text or ""
  local itemId = tonumber((text:match("item:(%d+)"))) or tonumber((text:match("^%s*(%d+)%s*$")))
  if not itemId then return nil end
  local link = text:match("|c.-|r")
  return itemId, link
end

-- Anzeigename des Items: gespeicherter Link, sonst aus dem Client, sonst die ID
local function itemLabel(params)
  if params.link then return params.link end
  local getItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local name, link
  if getItemInfo then name, link = getItemInfo(params.itemId) end
  return link or name or ("item:" .. params.itemId)
end

Goals.RegisterKind("level", {
  color = COLORS.level,
  icon = Alerts.ICONS.levelUp,
  validate = function(_, target)
    if type(target) ~= "number" or target <= LT.level then
      return string.format(L.SG_ERR_LEVEL, LT.level)
    end
  end,
  initial = function() return LT.level end,
  title = function(goal) return string.format(L.SG_GOAL_LEVEL, goal.target) end,
})

Goals.RegisterKind("kills", {
  color = COLORS.kills,
  icon = Alerts.ICONS.elite,
  validate = function(params, target)
    params.source = params.source or "any"
    if not KILL_TITLES[params.source] then return string.format(L.SG_ERR_UNKNOWN_KIND, params.source) end
    return validAmount(target)
  end,
  title = function(goal) return string.format(L[KILL_TITLES[goal.params.source]], goal.target) end,
  body = function(goal) return goal.params.battleground and L.SG_ONLY_BG or nil end,
})

Goals.RegisterKind("item", {
  color = COLORS.item,
  icon = Alerts.ICONS.loot,
  validate = function(params, target)
    if not params.itemId then return L.SG_ERR_ITEM end
    return validAmount(target)
  end,
  title = function(goal)
    local label = itemLabel(goal.params)
    if goal.target > 1 then return string.format(L.SG_GOAL_ITEM_COUNT, label, goal.target) end
    return string.format(L.SG_GOAL_ITEM, label)
  end,
  body = function(goal)
    return goal.params.boss and string.format(L.SG_SOURCE, goal.params.boss) or nil
  end,
})

Goals.RegisterKind("bgwin", {
  color = COLORS.bgwin,
  icon = BGWIN_ICON,
  validate = function(_, target) return validAmount(target) end,
  title = function(goal)
    local name = goal.params.battleground
    if name then return string.format(L.SG_GOAL_BGWIN_NAMED, name, goal.target) end
    return string.format(L.SG_GOAL_BGWIN_ANY, goal.target)
  end,
})
