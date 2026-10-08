-- Fenster verschieben ("Move Anything"): die Standardfenster des Spiels (Charakter, Zauberbuch, Händler, Quests, ...)
-- lassen sich mit der linken Maustaste an eine andere Stelle ziehen. Die Position wird gemerkt und beim
-- nächsten Öffnen wiederhergestellt (Einstellung moveFrames im Reiter "Komfort", aus).
-- Im Kampf wird nichts verschoben: geschützte Fenster dürfen dann nicht angefasst werden.
-- Fenster, die ein Blizzard-Addon erst später lädt (Talente, Auktionshaus, ...), kommen über ADDON_LOADED dazu.
local _, ns = ...
local L = ns.L

local MoveFrames = {}
ns.MoveFrames = MoveFrames

-- Globale Namen; was ein Client nicht kennt, wird übersprungen
MoveFrames.FRAME_NAMES = {
  "CharacterFrame", "SpellBookFrame", "PlayerTalentFrame", "TalentFrame", "QuestLogFrame", "FriendsFrame",
  "MerchantFrame", "GossipFrame", "QuestFrame", "TradeFrame", "MailFrame", "BankFrame", "ClassTrainerFrame",
  "TradeSkillFrame", "CraftFrame", "AuctionFrame", "AuctionHouseFrame", "InspectFrame", "LootFrame",
  "GuildFrame", "PVEFrame", "LFGParentFrame", "CollectionsJournal", "ProfessionsFrame", "PetStableFrame",
  "TaxiFrame", "TabardFrame", "MacroFrame", "ItemTextFrame",
}

local attached = {}  -- [Name] = true, sobald die Griffe eingehängt sind

local function inCombat()
  return InCombatLockdown and InCombatLockdown()
end

local function isEnabled()
  return ns.db and ns.db.moveFrames
end

local function restore(frame, name)
  local pos = ns.db and ns.db.movedFrames and ns.db.movedFrames[name]
  if not pos or not isEnabled() or inCombat() then return end
  frame:ClearAllPoints()
  frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
end

-- Gemerkt wird nur, was am Bildschirm hängt (nach StopMovingOrSizing immer der Fall)
local function save(frame, name)
  local point, relativeTo, relativePoint, x, y = frame:GetPoint()
  if relativeTo ~= nil and relativeTo ~= UIParent then return end
  ns.db.movedFrames = ns.db.movedFrames or {}
  ns.db.movedFrames[name] = { point, relativePoint or point, x, y }
end

local function attach(name)
  local frame = _G[name]
  if attached[name] or type(frame) ~= "table" or not frame.HookScript then return end
  attached[name] = true
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetClampedToScreen(true)
  frame:RegisterForDrag("LeftButton")
  frame:HookScript("OnDragStart", function(self)
    if isEnabled() and not inCombat() then self:StartMoving() end
  end)
  frame:HookScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if isEnabled() then save(self, name) end
  end)
  -- Blizzard setzt verwaltete Fenster beim Öffnen selbst: nach deren Anordnung noch einmal überschreiben
  frame:HookScript("OnShow", function(self)
    restore(self, name)
    C_Timer.After(0, function() restore(self, name) end)
  end)
  ns.Debug("moveframes", "attached to %s", name)
end

-- Im Kampf nicht anfassen; PLAYER_REGEN_ENABLED holt es nach
local function attachAll()
  if not isEnabled() or inCombat() then return end
  for _, name in ipairs(MoveFrames.FRAME_NAMES) do
    ns.SafeCall(attach, name)
  end
end

-- Gemerkte Positionen vergessen; die Fenster stehen wieder an ihrer Standardstelle, sobald das Spiel sie neu anordnet
function MoveFrames.Reset()
  ns.db.movedFrames = nil
  ns.Print(L.MOVE_FRAMES_RESET_DONE)
end

ns.RegisterEvent("ADDON_LOADED", attachAll)
ns.RegisterEvent("PLAYER_REGEN_ENABLED", attachAll)
ns.RegisterApply(attachAll)
