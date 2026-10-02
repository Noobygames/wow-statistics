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
  splits = function() ns.Set("showSplitList", not ns.db.showSplitList) end,
  -- /lt runs import | backup: Läufe einfügen bzw. alle als Text sichern
  runs = function(argument)
    if argument == "import" then
      ns.ShowRunImport()
    elseif argument == "backup" then
      ns.Export.Show(L.RUNS_BACKUP, ns.Runs.ExportAll())
    else
      ns.Print(L.HELP)
    end
  end,
  -- /lt compare best | pb | Name: Vergleich für die Splits
  compare = function(argument)
    local Splits = ns.Splits
    local mode = argument:lower()
    if mode == Splits.BEST or mode == Splits.PERSONAL_BEST then
      ns.Set("splitComparison", mode)
      ns.Print(L["COMPARE_" .. mode:upper()])
    elseif argument ~= "" and Splits.CompareWith(argument) then
      ns.Print(string.format(L.COMPARE_SET, Splits.GetReferenceName()))
    else
      ns.Print(L.COMPARE_USAGE)
    end
  end,
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
  -- /lt debug schaltet das erweiterte Logging, /lt debug <befehl> löst Testfunktionen aus (DebugTools.lua)
  debug = function(argument)
    if argument ~= "" then
      ns.DebugTools.Run(argument)
      return
    end
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
