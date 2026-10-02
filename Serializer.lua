-- Daten als kopierbarer Text und zurück, z.B. zum Teilen von Läufen oder Einstellungs-Profilen.
-- Ohne loadstring: Der Text kommt von anderen Spielern und wird nur gelesen, nie ausgeführt.
--
-- Text: "LT1:<art>:<wert>"
--   Tabelle  { schlüssel=wert, ... }  (Schlüssel sind selbst Werte)
--   Text     s<prozentkodiert>        (alles außer Buchstaben, Ziffern, _ . - als %XX)
--   Zahl     n<zahl>
--   Wahr     b1 / Falsch b0
-- So enthält der Text keine Zeichen, die Chat oder Eingabefelder umdeuten ("|", Umbrüche).
local _, ns = ...

local Serializer = {}
ns.Serializer = Serializer

local VERSION_PREFIX = "LT1"

---------------------------------------------------------------------------
-- Schreiben
---------------------------------------------------------------------------
local function encodeString(text)
  return (text:gsub("[^%w_%.%-]", function(char) return string.format("%%%02X", char:byte()) end))
end

local encodeValue

local function encodeTable(value)
  local entries = {}
  for key, entry in pairs(value) do
    table.insert(entries, encodeValue(key) .. "=" .. encodeValue(entry))
  end
  table.sort(entries)  -- feste Reihenfolge, gleiche Daten ergeben gleichen Text
  return "{" .. table.concat(entries, ",") .. "}"
end

function encodeValue(value)
  local kind = type(value)
  if kind == "table" then return encodeTable(value) end
  if kind == "string" then return "s" .. encodeString(value) end
  if kind == "number" then return "n" .. tostring(value) end
  if kind == "boolean" then return value and "b1" or "b0" end
  error("Serializer: unsupported type " .. kind)
end

-- kind = kurzer Name der Datenart (z.B. "run"), damit Import falsche Texte erkennt
function Serializer.Encode(kind, value)
  return VERSION_PREFIX .. ":" .. kind .. ":" .. encodeValue(value)
end

---------------------------------------------------------------------------
-- Lesen: rekursiv über den Text; jeder Fehler ergibt nil
---------------------------------------------------------------------------
local decodeValue

local function decodeTable(text, position)
  local result = {}
  position = position + 1  -- "{"
  if text:sub(position, position) == "}" then return result, position + 1 end
  while true do
    local key, value
    key, position = decodeValue(text, position)
    if key == nil or text:sub(position, position) ~= "=" then return nil end
    value, position = decodeValue(text, position + 1)
    if value == nil then return nil end
    result[key] = value
    local separator = text:sub(position, position)
    if separator == "}" then return result, position + 1 end
    if separator ~= "," then return nil end
    position = position + 1
  end
end

function decodeValue(text, position)
  local tag = text:sub(position, position)
  if tag == "{" then return decodeTable(text, position) end
  if tag == "s" then
    local raw = text:match("^[%w_%.%-%%]*", position + 1)
    local decoded = raw:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end)
    return decoded, position + 1 + #raw
  end
  if tag == "n" then
    local raw = text:match("^[%d%.%-+eE]+", position + 1)
    local number = raw and tonumber(raw)
    if not number then return nil end
    return number, position + 1 + #raw
  end
  if tag == "b" then
    local flag = text:sub(position + 1, position + 1)
    if flag == "1" then return true, position + 2 end
    if flag == "0" then return false, position + 2 end
  end
  return nil
end

-- Wert aus dem Text oder nil, wenn der Text kaputt ist oder eine andere Datenart enthält
function Serializer.Decode(kind, text)
  text = (text or ""):gsub("%s", "")  -- Umbrüche aus dem Kopieren ignorieren
  local prefix = VERSION_PREFIX .. ":" .. kind .. ":"
  if text:sub(1, #prefix) ~= prefix then return nil end
  local value, position = decodeValue(text, #prefix + 1)
  if value == nil or position ~= #text + 1 then return nil end
  return value
end
