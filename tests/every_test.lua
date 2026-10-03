-- ns.Every: wiederkehrende Aufgaben erst nach dem Login, mit der vergangenen Zeit.
local runs = {}
addon.Every(5, function(elapsed) table.insert(runs, elapsed) end)

wow.update(10)
expect("vor dem Login nichts", #runs, 0)

wow.login()
wow.update(3)
expect("noch nicht fällig", #runs, 0)
wow.update(3)
expect("fällig", #runs, 1)
expect("vergangene Zeit", runs[1], 6)
wow.update(5)
expect("wieder fällig", #runs, 2)

-- Ein Fehler in einer Aufgabe stoppt die übrigen nicht
local after = 0
addon.Every(1, function() error("kaputt") end)
addon.Every(1, function() after = after + 1 end)
wow.update(1)
expect("Aufgabe nach dem Fehler läuft", after, 1)
expect("Fehler an den Handler", #wow.errors, 1)
wow.update(1)
expect("auch beim nächsten Tick", after, 2)

-- Login, Level-Up und Events: ein fehlerhafter Callback hält die übrigen nicht auf
local errorsBefore = #wow.errors
addon.OnLevelCompleted(function() error("kaputt beim Level-Up") end)
local started
addon.OnLevelStarted(function(level) started = level end)
wow.levelUp(addon.level + 1)
expect("neues Level trotz Fehler", started, addon.level)
expect("Level-Bereich neu begonnen", addon.character.currentLevel.level, addon.level)
expect("Fehler gemeldet", #wow.errors, errorsBefore + 1)
local handled
addon.RegisterEvent("PLAYER_REGEN_ENABLED", function() error("kaputt im Event") end)
addon.RegisterEvent("PLAYER_REGEN_ENABLED", function() handled = true end)
wow.fire("PLAYER_REGEN_ENABLED")
expect("zweiter Handler läuft", handled, true)
wow.errors = {}  -- absichtlich ausgelöste Fehler
