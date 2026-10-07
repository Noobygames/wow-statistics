-- Hilfe in Gruppen und einmaliger Hinweis beim ersten Start.
wow.login({ level = 10 })
expectTrue("Hinweis beim ersten Start", wow.printed[#wow.printed]:find(addon.L.INTRO, 1, true) ~= nil)
local count = #wow.printed
wow.logout()
wow.login()
expect("Hinweis nur einmal", #wow.printed, count)

local before = #wow.printed
SlashCmdList.LEVELTIMER("help")
expect("fünf Hilfezeilen", #wow.printed - before, 5)
before = #wow.printed
SlashCmdList.LEVELTIMER("quatsch")
expect("unbekannter Befehl: Hinweis plus Hilfe", #wow.printed - before, 6)
