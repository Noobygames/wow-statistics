-- Dungeonquest-Geber auf der Minimap (LT-37; Einstellung dungeonQuestMinimap unter dungeonQuestGivers, an; Randsymbole
-- dungeonQuestMinimapEdge, an): Geber mit Ort aus der DungeonDB, die dem Charakter jetzt eine Dungeonquest oder einen
-- Kettenschritt anbieten, erscheinen nach Entfernung zum Spieler auf der Minimap, unabhängig von der Zone (Geber
-- jenseits einer Zonengrenze zählen mit). Kandidaten = alle Geber auf demselben Kontinent (Weltkoordinaten über
-- Lib/MapCoords.lua), neu gesammelt bei geänderter DungeonQuests.Revision oder anderem Kontinent. Außerhalb des
-- Minimap-Radius bis EDGE_YARDS: kleineres, blasses Symbol am Rand in Richtung des Gebers.
-- Quellen: Minimap:GetZoom() (alle Clients), IsIndoors() (alle Clients), CVar rotateMinimap, GetPlayerFacing()
-- (Bogenmaß, 0 = Norden, gegen den Uhrzeigersinn; kann geheim sein), GetMinimapShape() (von Addons gesetzt, sonst rund;
-- Assist/MinimapTweaks.lua). Minimap-Durchmesser je Zoomstufe in Yards wie HereBeDragons-Pins (außen/innen).
-- OpenMap und Leatrix Maps verändern die echte Minimap nicht (Lib/MapCompat.lua).
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    dungeonQuestMinimap = true,
    dungeonQuestMinimapEdge = true,
  },
})
local DungeonQuests = ns.DungeonQuests
local Givers = ns.DungeonQuestGivers

local DungeonQuestMinimap = {}
ns.DungeonQuestMinimap = DungeonQuestMinimap

local OUTDOOR_DIAMETER = { 466 + 2 / 3, 400, 333 + 1 / 3, 266 + 2 / 3, 200, 133 + 1 / 3 }  -- [Zoom + 1] = Yards
local INDOOR_DIAMETER = { 300, 240, 180, 120, 80, 50 }
local UPDATE_SECONDS = 0.2
local PIN_SIZE = 14
local EDGE_SIZE = 10
local EDGE_ALPHA = 0.6
local EDGE_YARDS = 800
local SQUARE = "SQUARE"
local ROTATE_CVAR = "rotateMinimap"

local pins = {}
local candidates = {}
local candidateKey

function DungeonQuestMinimap.IsAvailable()
  return Givers.IsAvailable()
end

local function isEnabled(db)
  return db and db.dungeonQuestGivers and db.dungeonQuestMinimap and DungeonQuestMinimap.IsAvailable() and Minimap ~= nil
end

local function readable(value)
  return type(value) == "number" and not ns.IsSecret(value)
end

-- Spieler in Weltkoordinaten: Instanz, Nord, West oder nil (in Instanzen keine Kartenposition)
local function playerWorld()
  if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return nil end
  local mapID = C_Map.GetBestMapForUnit("player")
  if not readable(mapID) then return nil end
  local position = C_Map.GetPlayerMapPosition(mapID, "player")
  if type(position) ~= "table" or not position.GetXY then return nil end
  return ns.MapCoords.MapToWorld(mapID, position:GetXY())
end

-- Geber auf dem Kontinent des Spielers mit Weltkoordinaten
local function collect(instanceID)
  local list = {}
  for _, uiMapID in ipairs(DungeonQuests.GiverMapIDs()) do
    for _, place in ipairs(DungeonQuests.OffersOnMap(uiMapID)) do
      local placeInstance, north, west = ns.MapCoords.MapToWorld(uiMapID, place.x, place.y)
      if placeInstance == instanceID then
        table.insert(list, { north = north, west = west, offers = place.offers })
      end
    end
  end
  return list
end

-- Sichtradius der Minimap in Yards
function DungeonQuestMinimap.Radius()
  local zoom = Minimap:GetZoom() or 0
  local diameters = IsIndoors and IsIndoors() and INDOOR_DIAMETER or OUTDOOR_DIAMETER
  return (diameters[zoom + 1] or diameters[1]) / 2
end

local function rotation()
  if ns.CVars.Get(ROTATE_CVAR) ~= "1" or not GetPlayerFacing then return 0 end
  local facing = GetPlayerFacing()
  return readable(facing) and facing or 0
end

-- Versatz auf der Minimap (Osten, Norden in Yards, nach Drehung) und ob er am Rand festgehalten wurde; nil = nicht zeigen
function DungeonQuestMinimap.Offset(east, north, radius, facing, square, edge)
  if facing ~= 0 then
    local cos, sin = math.cos(facing), math.sin(facing)
    -- getrennt berechnet: gopher-lua (Tests) wertet Mehrfachzuweisungen nicht wie Lua 5.1 aus
    local rotatedEast = east * cos + north * sin
    north = north * cos - east * sin
    east = rotatedEast
  end
  local reach = square and math.max(math.abs(east), math.abs(north)) or math.sqrt(east * east + north * north)
  if reach <= radius then return east, north, false end
  if not edge or reach > EDGE_YARDS then return nil end
  local factor = radius / reach
  return east * factor, north * factor, true
end

local function getPin(index)
  if pins[index] then return pins[index] end
  local pin = Givers.NewMark(Minimap, PIN_SIZE)
  pin:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 5)
  pin:EnableMouse(true)
  pin:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    Givers.AddOfferLines(GameTooltip, self.offers)
    GameTooltip:Show()
  end)
  pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
  pins[index] = pin
  return pin
end

local function hideFrom(index)
  for i = index, #pins do pins[i]:Hide() end
end

function DungeonQuestMinimap.Update()
  local db = ns.db
  if not isEnabled(db) then return hideFrom(1) end
  local instanceID, north, west = playerWorld()
  if not instanceID then return hideFrom(1) end
  local key = instanceID .. ":" .. DungeonQuests.Revision()
  if key ~= candidateKey then
    candidateKey = key
    candidates = collect(instanceID)
  end
  local radius = DungeonQuestMinimap.Radius()
  local pixels = (Minimap:GetWidth() or 0) / 2 / radius
  local facing = rotation()
  local square = GetMinimapShape and GetMinimapShape() == SQUARE
  local shown = 0
  for _, candidate in ipairs(candidates) do
    -- Weltachsen: Nord = x, West = y; Bildschirm: rechts = Osten
    local east, up, atEdge = DungeonQuestMinimap.Offset(west - candidate.west, candidate.north - north, radius, facing,
      square, db.dungeonQuestMinimapEdge)
    if east then
      shown = shown + 1
      local pin = getPin(shown)
      local size = atEdge and EDGE_SIZE or PIN_SIZE
      pin.offers = candidate.offers
      pin:SetSize(size, size)
      pin:SetAlpha(atEdge and EDGE_ALPHA or 1)
      pin:ClearAllPoints()
      pin:SetPoint("CENTER", Minimap, "CENTER", east * pixels, up * pixels)
      Givers.ShowMark(pin, candidate.offers)
    end
  end
  hideFrom(shown + 1)
end

ns.Every(UPDATE_SECONDS, DungeonQuestMinimap.Update, function(db) return db.dungeonQuestGivers and db.dungeonQuestMinimap end)

local function apply()
  candidateKey = nil
  DungeonQuestMinimap.Update()
end
ns.OnLogin(apply)
ns.RegisterApply(apply)
