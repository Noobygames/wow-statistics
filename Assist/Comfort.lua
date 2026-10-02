-- Komfort-Funktionen beim Leveln (Händler, Quests, Gespräche): gemeinsame Regeln.
-- Jede Funktion ist einzeln schaltbar und standardmäßig aus (Reiter "Komfort").
-- Gedrückte Umschalttaste setzt die Automatik im Moment aus, z.B. um bei einem Händler
-- etwas zurückzukaufen oder eine Quest-Belohnung selbst zu wählen.
local _, ns = ...

local Comfort = {}
ns.Comfort = Comfort

-- true, wenn die Komfort-Funktion mit dieser Einstellung jetzt handeln darf
function Comfort.IsActive(setting)
  if not ns.db or not ns.db[setting] then return false end
  if IsShiftKeyDown() then
    ns.Debug("comfort", "%s paused by shift key", setting)
    return false
  end
  return true
end
