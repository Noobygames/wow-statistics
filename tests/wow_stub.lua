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
  RegisterEvent = function(self, event)
    if event == UNKNOWN_EVENT then error("Attempt to register unknown event") end
    self._events[event] = true
  end,
}

local function noop() end

local function newFrame()
  local frame = {
    _shown = true, _scripts = {}, _events = {}, _text = "",
    _width = 200, _height = 100, _scale = 1, _checked = false, _normalTexture = "",
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
COMBATLOG_XPGAIN_FIRSTPERSON = "%s stirbt, Ihr bekommt %d Erfahrung."
COMBATLOG_HONORGAIN = "%s stirbt, ehrenhafter Sieg Rang: %s (Geschätzte Ehrenpunkte: %d)"
C_Timer = { After = noop }
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
function UnitName() return state.name end
function GetRealmName() return state.realm end
function UnitClass() return state.class, state.class end
function UnitIsDeadOrGhost() return state.dead end
function GetPVPSessionStats() return state.honorableKills end
function IsShiftKeyDown() return state.shiftDown end
function RequestTimePlayed() end
function GetCoinTextureString(copper) return copper .. "c" end
function strtrim(text) return (text:gsub("^%s+", ""):gsub("%s+$", "")) end

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
