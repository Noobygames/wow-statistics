-- Chat-Befehle /lt und /leveltimer
local _, ns = ...
local L = ns.L

local commands = {
  [""] = function() ns.ToggleOptions() end,
  config = function() ns.ToggleOptions() end,
  history = function() ns.ToggleHistory() end,
  lock = function()
    ns.Set("locked", true)
    ns.Print(L.LOCKED)
  end,
  unlock = function()
    ns.Set("locked", false)
    ns.Print(L.UNLOCKED)
  end,
  reset = function() ns.TimerWindow.ResetLayout() end,
  compact = function() ns.Set("compactMode", not ns.db.compactMode) end,
  bar = function() ns.Set("horizontalLayout", not ns.db.horizontalLayout) end,
  newsession = function() ns.StartNewSession() end,
  recap = function() ns.ToggleRecap() end,
  stream = function() ns.StreamMode.Toggle() end,
  -- /lt goal 30 setzt das Ziel-Level, /lt goal ohne Zahl entfernt es
  goal = function(argument)
    if argument == "" then
      ns.Goal.Clear()
      ns.Print(L.GOAL_CLEARED)
    elseif ns.Goal.Set(tonumber(argument)) then
      ns.Set("showGoal", true)
      ns.Print(string.format(L.GOAL_SET, ns.Goal.Get().level))
    else
      ns.Print(L.GOAL_INVALID)
    end
  end,
  debug = function()
    ns.debug = not ns.debug  -- bewusst nicht gespeichert, gilt bis /reload
    ns.Print(ns.debug and L.DEBUG_ON or L.DEBUG_OFF)
  end,
  sync = function() ns.PlayedTime.Sync() end,
  show = function() ns.Set("showTimer", true) end,
  hide = function() ns.Set("showTimer", false) end,
  minimap = function() ns.SetMinimapHidden(not ns.db.minimap.hide) end,
}

SLASH_LEVELTIMER1 = "/leveltimer"
SLASH_LEVELTIMER2 = "/lt"
-- Erstes Wort = Befehl, der Rest wird als Argument übergeben (z.B. "goal 30")
SlashCmdList.LEVELTIMER = function(input)
  local name, argument = strtrim(input or ""):match("^(%S*)%s*(.-)$")
  local command = commands[name:lower()]
  if command then
    command(argument)
  else
    ns.Print(L.HELP)
  end
end
