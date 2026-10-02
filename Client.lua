-- Welcher Client läuft. Für Funktionen, die es nur in einem Client gibt (z.B. Camp-Buffs in
-- WoW Forever); deren Einstellungen erscheinen in anderen Clients gar nicht.
-- Grundlage ist die Interface-Version (4. Wert von GetBuildInfo), z.B. 16001 = WoW Forever 1.60.1.
-- Gleiche Zuordnung wie beim BigWigs-Packager (16xxx = forever).
local _, ns = ...

local Client = {}
ns.Client = Client

local FOREVER_FIRST, FOREVER_LAST = 16000, 16999

function Client.GetInterfaceVersion()
  return select(4, GetBuildInfo())
end

function Client.IsForever()
  local version = Client.GetInterfaceVersion()
  return version >= FOREVER_FIRST and version <= FOREVER_LAST
end
