-- /played: eigene Abfragen erscheinen nicht im Chat, eigene /played-Eingaben schon.
wow.login()
wow.runTimers()                               -- Abfrage nach dem Login
wow.fire("TIME_PLAYED_MSG", 5000, 300)
expect("eigene Abfrage nicht im Chat", wow.playedLines, 0)
expectNear("Antwort trotzdem ausgewertet", addon.PlayedTime.GetTotalSeconds(), 5000)

wow.runTimers()                               -- Chatfenster hören wieder zu
wow.fire("TIME_PLAYED_MSG", 5100, 400)        -- /played des Spielers
expect("/played des Spielers in beiden Chatfenstern", wow.playedLines, 2)

-- Ohne Antwort hören die Chatfenster nach der Wartezeit wieder zu
addon.PlayedTime.Sync()
wow.runTimers()
wow.fire("TIME_PLAYED_MSG", 5200, 500)
expect("nach Zeitüberschreitung wieder im Chat", wow.playedLines, 4)
