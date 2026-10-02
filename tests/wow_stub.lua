-- Nachgebaute WoW-API für die Addon-Tests (ausgeführt von tools/addontest).
-- Lädt das Addon in .toc-Reihenfolge. Jede *_test.lua läuft danach in einem frischen Lua-Zustand.
--
-- Für Tests verfügbar:
--   addon                  Namespace des Addons (ns)
--   wow.state              Spielzustand, den die API-Funktionen zurückgeben
--   wow.login(options)     Login simulieren (options überschreiben wow.state, playedSeconds = /played-Antwort)
--   wow.logout()           Logout oder /reload simulieren (PLAYER_LOGOUT)
--   wow.levelUp(level, xpMax)  Level-Up wie im Client
--   wow.fire(event, ...)   Event an alle registrierten Frames senden
--   wow.advance(seconds)   Spielzeit (GetTime) und Uhrzeit (time) vorstellen
--   wow.runTimers()        geplante C_Timer.After-Callbacks ausführen
--   wow.printed            alle Chat-Ausgaben (print)
--   expect, expectNear, expectTrue   Prüfungen; Fehlschläge landen in TEST_FAILURES

local ADDON_DIR = ADDON_DIR  -- von tools/addontest gesetzt
local UNKNOWN_EVENT = "EVENT_NOT_IN_THIS_CLIENT"

wow = {
  state = {
    name = "Testchar",
    realm = "Testrealm",
    class = "WARRIOR",
    level = 10,
    xp = 0,
    xpMax = 1000,
    maxLevel = 60,
    rested = 0,
    money = 0,
    now = 1000,             -- GetTime()
    clock = 1700000000,     -- time()
    dead = false,
    honorableKills = 0,
    shiftDown = false,
    cursorX = 0,
    cursorY = 0,
    guid = "Player-1-0001",
    zone = "Wald von Elwynn",
    combatLog = {},          -- Rückgabewerte von CombatLogGetCurrentEventInfo
    questTitle = nil,        -- Titel im offenen Quest-Abgabe-Dialog (GetTitleText)
    questTitles = {},        -- C_QuestLog.GetTitleForQuestID je Quest-ID
    instance = nil,          -- { name, type } wenn in einer Instanz (IsInInstance)
    units = {},              -- weitere Einheiten: units.target = { name, classification, isPlayer }
    inGuild = false,
    inGroup = false,         -- Gruppe (IsInGroup)
    chatLockdown = false,    -- C_ChatInfo.InChatMessagingLockdown
    inCombat = false,
    resting = false,
    buffs = {},              -- aktive Buffs: Name oder { name, spellId } (C_UnitAuras.GetAuraDataByIndex)
    spellNames = { [19705] = "Satt", [1229741] = "Lagervorteile" },  -- C_Spell.GetSpellName
    interface = 120100,      -- Interface-Version (GetBuildInfo); 16001 = WoW Forever
    health = 1000,
    healthMax = 1000,
    -- Händler: Reparatur (CanMerchantRepair, GetRepairAllCost) und Gildenbank
    merchant = { canRepair = false, repairCost = 0, guildRepair = false, guildWithdraw = 0, guildMoney = 0 },
    -- Taschen: bags[bag][slot] = { itemID, quality, stackCount, hasNoValue, isLocked } (C_Container)
    bags = { [0] = {} },
    bagSlots = 16,
    sellPrices = {},         -- Verkaufspreis je itemID (C_Item.GetItemInfo)
  },
  printed = {},
  UNKNOWN_EVENT = UNKNOWN_EVENT,
  ADDON_DIR = ADDON_DIR,
}

---------------------------------------------------------------------------
-- Prüfungen
---------------------------------------------------------------------------
TEST_FAILURES = {}

local function fail(message)
  table.insert(TEST_FAILURES, message)
end

function expect(description, actual, expected)
  if actual ~= expected then
    fail(string.format("%s: erwartet %s, bekommen %s", description, tostring(expected), tostring(actual)))
  end
end

function expectNear(description, actual, expected, tolerance)
  if type(actual) ~= "number" or math.abs(actual - expected) > (tolerance or 0.01) then
    fail(string.format("%s: erwartet ~%s, bekommen %s", description, tostring(expected), tostring(actual)))
  end
end

function expectTrue(description, value)
  if not value then
    fail(description .. ": Bedingung nicht erfüllt")
  end
end

---------------------------------------------------------------------------
-- Frames: unbekannte Methoden sind No-Ops, damit nur das Nötige nachgebaut werden muss
---------------------------------------------------------------------------
local frames = {}

local frameMethods = {
  GetFont = function() return "Fonts\\FRIZQT__.TTF", 12, "" end,
  GetStringWidth = function(self) return #self._text * 6 end,
  GetWidth = function(self) return self._width end,
  SetWidth = function(self, width) self._width = width end,
  SetSize = function(self, width, height) self._width, self._height = width, height or self._height end,
  GetHeight = function(self) return self._height end,
  SetHeight = function(self, height) self._height = height end,
  GetScale = function(self) return self._scale end,
  SetScale = function(self, scale) self._scale = scale end,
  GetLeft = function() return 100 end,
  GetTop = function() return 500 end,
  SetNormalTexture = function(self, texture) self._normalTexture = texture end,
  GetPoint = function() return "CENTER", nil, "CENTER", 0, 0 end,
  SetBackdropColor = function(self, r, g, b, a) self._backdropColor = { r, g, b, a } end,
  SetBackdropBorderColor = function(self, r, g, b, a) self._borderColor = { r, g, b, a } end,
  -- Anker werden nur gemerkt (frame._points), nicht ausgewertet
  SetPoint = function(self, ...) table.insert(self._points, { ... }) end,
  ClearAllPoints = function(self) self._points = {} end,
  GetCenter = function() return 0, 0 end,
  GetEffectiveScale = function() return 1 end,
  IsShown = function(self) return self._shown end,
  Show = function(self) self._shown = true end,
  Hide = function(self) self._shown = false end,
  SetShown = function(self, shown) self._shown = shown and true or false end,
  SetText = function(self, text) self._text = tostring(text) end,
  GetText = function(self) return self._text end,
  GetChecked = function(self) return self._checked end,
  SetChecked = function(self, checked) self._checked = checked end,
  SetScript = function(self, name, handler) self._scripts[name] = handler end,
  -- Wie im Client: vorhandenen Handler behalten und den neuen danach aufrufen
  HookScript = function(self, name, handler)
    local previous = self._scripts[name]
    self._scripts[name] = previous and function(...) previous(...); handler(...) end or handler
  end,
  AddLine = function(self, text) self._lines = self._lines or {}; table.insert(self._lines, text) end,
  ClearLines = function(self) self._lines = {} end,
  SetOwner = function(self) self._lines = {} end,
  RegisterEvent = function(self, event)
    if event == UNKNOWN_EVENT then error("Attempt to register unknown event") end
    self._events[event] = true
  end,
}

local function noop() end

local function newFrame()
  local frame = {
    _shown = true, _scripts = {}, _events = {}, _text = "",
    _width = 200, _height = 100, _scale = 1, _checked = false, _normalTexture = "", _points = {},
  }
  frame.CreateFontString = function() return newFrame() end
  frame.CreateTexture = function() return newFrame() end
  table.insert(frames, frame)
  return setmetatable(frame, {
    __index = function(_, key) return frameMethods[key] or noop end,
  })
end

function wow.fire(event, ...)
  for _, frame in ipairs(frames) do
    if frame._events[event] and frame._scripts.OnEvent then
      frame._scripts.OnEvent(frame, event, ...)
    end
  end
end

function wow.advance(seconds)
  wow.state.now = wow.state.now + seconds
  wow.state.clock = wow.state.clock + seconds
end

function wow.login(options)
  for key, value in pairs(options or {}) do
    wow.state[key] = value
  end
  wow.fire("PLAYER_LOGIN")
  if wow.state.playedSeconds then
    wow.fire("TIME_PLAYED_MSG", wow.state.playedSeconds + 100000, wow.state.playedSeconds)
  end
end

-- Klickt den Button/Reiter mit dieser Beschriftung (Text-Buttons aus Widgets.CreateTab/CreateButton)
function wow.click(text)
  for _, frame in ipairs(frames) do
    local label = rawget(frame, "label")
    local caption = label and label._text or frame._text
    if caption == text and frame._scripts.OnClick then
      frame._scripts.OnClick(frame, "LeftButton")
      return true
    end
  end
  return false
end

-- Erster Frame, für den predicate(frame) true liefert (z.B. ein Ziehgriff ohne Namen)
function wow.findFrame(predicate)
  for _, frame in ipairs(frames) do
    if predicate(frame) then return frame end
  end
end

-- Kampflog-Event in der Feldreihenfolge von CombatLogGetCurrentEventInfo senden
-- (Zeit, Event, hideCaster, Quelle GUID/Name/Flags/RaidFlags, Ziel GUID/Name/Flags/RaidFlags, Zusatzfelder)
function wow.combatLog(subevent, sourceName, destGUID, ...)
  wow.state.combatLog = { wow.state.now, subevent, false, "Creature-1", sourceName, 0, 0, destGUID, "Ziel", 0, 0, ... }
  wow.fire("COMBAT_LOG_EVENT_UNFILTERED")
end

-- Die gerade sichtbare Tabellen-Ansicht der Historie (HistoryTables.lua)
function wow.shownTable()
  return wow.findFrame(function(frame)
    return rawget(frame, "GetVisibleRecords") ~= nil and frame:IsShown()
  end)
end

-- Alle bisher mit C_Timer.After geplanten Callbacks ausführen (Verzögerung egal)
function wow.runTimers()
  local due = wow.timers
  wow.timers = {}
  for _, callback in ipairs(due) do callback() end
end

function wow.logout()
  wow.fire("PLAYER_LOGOUT")
end

-- Level-Up wie im Client: Event mit neuem Level, danach neue XP-Werte
function wow.levelUp(newLevel, newXpMax)
  wow.fire("PLAYER_LEVEL_UP", newLevel)
  wow.state.level = newLevel
  wow.state.xp = 0
  wow.state.xpMax = newXpMax or wow.state.xpMax
end

---------------------------------------------------------------------------
-- WoW-Globals
---------------------------------------------------------------------------
local state = wow.state

-- Benannte Frames landen wie im Client als Global (z.B. LevelTimerFrame)
CreateFrame = function(_, name)
  local frame = newFrame()
  if name then _G[name] = frame end
  return frame
end
UIParent, Minimap, GameTooltip, GameFontNormalLarge = newFrame(), newFrame(), newFrame(), newFrame()
UISpecialFrames, SlashCmdList = {}, {}
StaticPopupDialogs, YES, NO = {}, "Ja", "Nein"
-- Dialog nicht anzeigen, sondern merken; Tests bestätigen mit StaticPopupDialogs[name].OnAccept
function StaticPopup_Show(name, textArg1, textArg2, data)
  wow.popup = { name = name, text = textArg1, data = data }
end
COMBATLOG_XPGAIN_FIRSTPERSON = "%s stirbt, Ihr bekommt %d Erfahrung."
COMBATLOG_HONORGAIN = "%s stirbt, ehrenhafter Sieg Rang: %s (Geschätzte Ehrenpunkte: %d)"
LOOT_ITEM_SELF = "Ihr erhaltet Beute: %s."
LOOT_ITEM_SELF_MULTIPLE = "Ihr erhaltet Beute: %sx%d."
LOOT_ITEM_PUSHED_SELF = "Ihr erhaltet einen Gegenstand: %s."
-- Timer laufen nicht von selbst; Tests starten sie mit wow.runTimers()
wow.timers = {}
C_Timer = { After = function(_, callback) table.insert(wow.timers, callback) end }
ChatFrame_DisplayTimePlayed = noop
date = os.date

function print(...)
  local parts = {}
  for i = 1, select("#", ...) do
    parts[i] = tostring((select(i, ...)))
  end
  table.insert(wow.printed, table.concat(parts, " "))
end

function GetLocale() return "deDE" end
function UnitLevel() return state.level end
function UnitXP() return state.xp end
function UnitXPMax() return state.xpMax end
function GetMaxPlayerLevel() return state.maxLevel end
function GetXPExhaustion() return state.rested > 0 and state.rested or nil end
function GetMoney() return state.money end
function GetTime() return state.now end
function GetCursorPosition() return state.cursorX, state.cursorY end
function UnitGUID() return state.guid end
function GetZoneText() return state.zone end
function CombatLogGetCurrentEventInfo() return unpack(state.combatLog) end
function time(dateTable)
  if dateTable then return os.time(dateTable) end
  return state.clock
end
function UnitName(unit)
  if unit == nil or unit == "player" then return state.name end
  return state.units[unit] and state.units[unit].name
end
function UnitExists(unit) return unit == "player" or state.units[unit] ~= nil end
function UnitIsPlayer(unit) return unit == "player" or (state.units[unit] and state.units[unit].isPlayer) or false end
function UnitClassification(unit) return state.units[unit] and state.units[unit].classification or "normal" end
function GetRealmName() return state.realm end
function UnitClass() return state.class, state.class end
function UnitIsDeadOrGhost() return state.dead end
function UnitHealth() return state.health end
function IsInGuild() return state.inGuild end
function GetBuildInfo() return "12.1.0", "1", "2026-01-01", state.interface end
function UnitAffectingCombat() return state.inCombat end
function IsResting() return state.resting end
C_Spell = { GetSpellName = function(spellID) return state.spellNames[spellID] end }
C_UnitAuras = {
  GetAuraDataByIndex = function(_, index)
    local buff = state.buffs[index]
    if type(buff) == "string" then return { name = buff } end
    return buff
  end,
}
function IsInGroup() return state.inGroup end
-- Gesendete Chat-Nachrichten landen in wow.sentChat als { message, chatType }
wow.sentChat = {}
C_ChatInfo = {
  SendChatMessage = function(message, chatType) table.insert(wow.sentChat, { message = message, chatType = chatType }) end,
  InChatMessagingLockdown = function() return state.chatLockdown end,
}
function UnitHealthMax() return state.healthMax end
function GetPVPSessionStats() return state.honorableKills end
function IsShiftKeyDown() return state.shiftDown end
function RequestTimePlayed() end
function GetCoinTextureString(copper) return copper .. "c" end
function GetTitleText() return state.questTitle end
function IsInInstance()
  if state.instance then return true, state.instance.type end
  return false, "none"
end
function GetInstanceInfo() return state.instance and state.instance.name or GetZoneText() end
C_QuestLog = { GetTitleForQuestID = function(questID) return state.questTitles[questID] end }
function strtrim(text) return (text:gsub("^%s+", ""):gsub("%s+$", "")) end

-- Händler; RepairAllItems bucht die Kosten ab und merkt sich die Reparatur in wow.repairs
wow.repairs = {}
function CanMerchantRepair() return state.merchant.canRepair end
function GetRepairAllCost() return state.merchant.repairCost, state.merchant.repairCost > 0 end
function RepairAllItems(useGuildBank)
  local merchant = state.merchant
  table.insert(wow.repairs, { cost = merchant.repairCost, guild = useGuildBank and true or false })
  if useGuildBank then
    merchant.guildMoney = merchant.guildMoney - merchant.repairCost
  else
    state.money = state.money - merchant.repairCost
  end
  merchant.repairCost = 0
end
function CanGuildBankRepair() return state.merchant.guildRepair end
function GetGuildBankWithdrawMoney() return state.merchant.guildWithdraw end
function GetGuildBankMoney() return state.merchant.guildMoney end

-- Taschen; UseContainerItem verkauft (Händler offen angenommen): Gegenstand weg, Geld dazu
C_Container = {
  GetContainerNumSlots = function(bag) return state.bags[bag] and state.bagSlots or 0 end,
  GetContainerItemInfo = function(bag, slot) return state.bags[bag] and state.bags[bag][slot] end,
  UseContainerItem = function(bag, slot)
    local info = state.bags[bag][slot]
    state.money = state.money + (state.sellPrices[info.itemID] or 0) * info.stackCount
    state.bags[bag][slot] = nil
  end,
}
C_Item = {
  GetItemInfo = function(itemID)
    return "Item " .. itemID, nil, nil, nil, nil, nil, nil, nil, nil, nil, state.sellPrices[itemID]
  end,
}

---------------------------------------------------------------------------
-- Addon laden
---------------------------------------------------------------------------
addon = {}
for line in io.lines(ADDON_DIR .. "/LevelTimer.toc") do
  line = line:gsub("\r", "")
  if line ~= "" and not line:match("^#") then
    local chunk, err = loadfile(ADDON_DIR .. "/" .. line)
    if not chunk then error(err, 0) end
    chunk("LevelTimer", addon)
  end
end
