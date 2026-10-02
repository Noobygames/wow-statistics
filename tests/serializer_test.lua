-- Serializer: Tabellen als Text und zurück, ohne Code auszuführen.
local Serializer = addon.Serializer

local data = {
  name = "Zwerg | mit Sonderzeichen: äöü {x=1}",
  level = 42,
  ratio = -1.5,
  flag = true,
  off = false,
  times = { [10] = 3600, [11] = 1800.25 },
  nested = { list = { "a", "b" } },
}
local text = Serializer.Encode("test", data)
expectTrue("Präfix", text:find("LT1:test:", 1, true) == 1)
expect("kein Pipe-Zeichen", text:find("|", 1, true), nil)
expect("keine Umbrüche", text:find("\n", 1, true), nil)

local back = Serializer.Decode("test", text)
expect("Text", back.name, data.name)
expect("Zahl", back.level, 42)
expect("Kommazahl", back.ratio, -1.5)
expect("wahr", back.flag, true)
expect("falsch", back.off, false)
expect("Zahlen-Schlüssel", back.times[10], 3600)
expect("Bruchteil", back.times[11], 1800.25)
expect("verschachtelt", back.nested.list[2], "b")

expect("gleiche Daten, gleicher Text", Serializer.Encode("test", back), text)
expect("Umbrüche beim Einfügen egal", Serializer.Decode("test", text:sub(1, 20) .. "\n " .. text:sub(21)).level, 42)

-- Ungültiges wird abgelehnt
expect("falsche Art", Serializer.Decode("andere", text), nil)
expect("abgeschnitten", Serializer.Decode("test", text:sub(1, #text - 3)), nil)
expect("Müll dahinter", Serializer.Decode("test", text .. "x"), nil)
expect("leer", Serializer.Decode("test", ""), nil)
expect("nil", Serializer.Decode("test", nil), nil)
expect("Code wird nicht ausgeführt", Serializer.Decode("test", "LT1:test:os.exit()"), nil)
