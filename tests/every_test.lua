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
