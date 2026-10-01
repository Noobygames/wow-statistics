-- Chat-Befehle /lt und /leveltimer
local _, ns = ...
local L = ns.L

local commands = {
  [""] = function() ns.ToggleOptions() end,
  config = function() ns.ToggleOptions() end,
  lock = function()
    ns.Set("locked", true)
    ns.Print(L.LOCKED)
  end,
  unlock = function()
    ns.Set("locked", false)
    ns.Print(L.UNLOCKED)
  end,
  sync = function() ns.PlayedTime.Sync() end,
  show = function() ns.Set("showTimer", true) end,
  hide = function() ns.Set("showTimer", false) end,
  minimap = function() ns.SetMinimapHidden(not ns.db.minimap.hide) end,
}

SLASH_LEVELTIMER1 = "/leveltimer"
SLASH_LEVELTIMER2 = "/lt"
SlashCmdList.LEVELTIMER = function(input)
  local command = commands[strtrim(input or ""):lower()]
  if command then
    command()
  else
    ns.Print(L.HELP)
  end
end
