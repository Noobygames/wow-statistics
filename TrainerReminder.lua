-- Hinweis beim Level-Up, wenn beim Klassenlehrer neue Zauber warten (Einstellung remindTrainer).
-- Classic Era, TBC und WoW Forever: neue Ränge gibt es auf geraden Leveln. Retail lernt Zauber
-- automatisch, dort gibt es weder Hinweis noch Einstellung (TrainerReminder.IsAvailable).
local _, ns = ...
local L = ns.L

local TrainerReminder = {}
ns.TrainerReminder = TrainerReminder

local REMINDER_COLOR = { 1, 0.82, 0 }

function TrainerReminder.IsAvailable()
  return not ns.Client.IsRetail()
end

function TrainerReminder.HasNewSpells(level)
  return level % 2 == 0
end

ns.OnLevelStarted(function(newLevel)
  if not ns.db.remindTrainer or not TrainerReminder.IsAvailable() then return end
  if not TrainerReminder.HasNewSpells(newLevel) then return end
  local message = string.format(L.REMIND_TRAINER, newLevel)
  ns.Print(message)
  ns.Alerts.Show(message, REMINDER_COLOR)
end)
