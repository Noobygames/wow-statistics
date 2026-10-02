# Roadmap

Aufwand: **S** = klein, **M** = mittel, **L** = groß. Erledigtes wird abgehakt und unter „Erledigt“ mit Version vermerkt. Nummern laufen über alle Versionen weiter.

## v2.5: Streaming

Schwerpunkt: Werte, die Zuschauer im Spielbild sehen und verstehen. Addons haben kein Netzwerk und schreiben keine Dateien, alles muss also im Spiel sichtbar sein.

### Für Zuschauer

- [x] 26. **Splits gegen Bestzeit** (M–L): Zeit des laufenden Levels gegen die schnellste Zeit anderer Charaktere für dieses Level, „+3m 12s“ rot / „-1m 05s“ grün, dazu Gesamtabweichung über alle Level mit Bestzeit (wie „Sum of Best“ bei LiveSplit).
- [x] 27. **Stream-Ansicht** (S): Hintergrund wahlweise Chroma-Grün oder Magenta ohne Rahmen zum Freistellen in OBS; große Schrift über die Größe (bis 200 %), kombinierbar mit der horizontalen Leiste.
- [x] 28. **Session-Ziel** (S–M): `/lt goal 30` setzt ein Ziel-Level; Zeile „Ziel“ zeigt Fortschritt in Prozent und Prognose („Level 30: 45 %, 1h 20m“), Meldung beim Erreichen.
- [x] 29. **Große Einblendungen** (S–M): auffällige Meldung bei Level-Up, Rare-/Elite-Kill, epischer Beute und Beinahe-Tod, einzeln schaltbar (Standard aus). Ereignisse aus `ns.OnLevelStarted` und `Journal.OnAdd`.
- [x] 30. **Session-Abschlusskarte** (M): `/lt recap` zeigt Zeit, Level, XP/h, Kills, Tode, beste Beute und gefährlichsten Gegner der Session, z.B. als Abspann oder Screenshot für Discord.
- [x] 31. **Hardcore-Anzeige** (S): Tode rot, Zeile „Ohne Tod“ (Spielzeit seit dem letzten Tod), dazu die vorhandenen Beinahe-Tode.

- [x] 35. **Fester Vergleichslauf** (M): Splits wahlweise gegen die Bestzeit je Level, die persönliche Bestzeit (schnellster Lauf bis zum aktuellen Level, innerhalb eines Levels fest) oder einen gewählten Charakter (`/lt compare Name`).
- [x] 36. **Split-Liste** (M): eigene kleine Anzeige mit den letzten N Leveln (3–15), Zeit und Abweichung zum Vergleich, darunter die Summe (`/lt splits`).
- [x] 37. **Stream-Modus per Befehl** (S): `/lt stream` schaltet Stream-Einstellungen (transparent, Größe 150 %, Einblendungen, Namen verbergen) gemeinsam ein und stellt beim Ausschalten den vorherigen Stand wieder her.
- [x] 38. **Rote Tode abschaltbar** (S): Hervorhebung der Tode als eigener Schalter, damit alle Stream-Optionen abschaltbar sind.

### Bedienung

- [x] 32. **Neue Session starten** (S): Button in den Einstellungen und `/lt newsession`. Archiviert die laufende Session sofort und startet eine neue, z.B. zu Stream-Beginn, statt auf Logout und Login zu warten.
- [x] 33. **Streamer-Datenschutz** (S): Realm und Namen anderer Charaktere in der Historie ausblenden (gegen Stream-Sniping).
- [x] 34. **Ansage in Gilde/Gruppe** (S): Level-Up-Zusammenfassung optional an Gruppe (bzw. Instanz-Chat) oder Gilde; keine Hardware-Eingabe nötig, bei Retails Chat-Sperre (`C_ChatInfo.InChatMessagingLockdown`, z.B. Bosskampf) wird nichts gesendet.

### Leveln: Buff-Hinweise

- [x] 39. **Hinweis bei fehlendem Food-Buff** (S–M): an/aus schaltbar (Standard aus). Fehlt „Satt“ beim Leveln außerhalb von Kampf und Ruhegebiet, erscheint eine Einblendung plus Chatzeile, höchstens alle 5 min. In WoW Forever gibt Satt 5 % mehr Kill-XP. Erkennung über den übersetzten Namen von Zauber 19705 (`C_Spell.GetSpellName`) und `C_UnitAuras.GetAuraDataByIndex`, beide laut Doku in allen Clients.
- [x] 40. **Hinweis bei fehlendem Camp-Buff** (S–M): an/aus schaltbar (Standard aus), wie 39. WoW Forever: Buff „Lagervorteile“ (Spell 1229741, im Spiel ermittelt) nach einer Minute Sitzen oder Herstellen am Lagerfeuer. Clients ohne diesen Zauber bekommen keinen Hinweis.

- [x] 43. **Level-Up-Ansage in /sagen** (S): Auswahl „Sagen (Klick)“. /sagen braucht im Freien eine Hardware-Eingabe, daher erscheint beim Level-Up 60 s lang ein Button; erst der Klick sendet.

- [x] 44. **Debug-Modus** (M): `/lt debug` schaltet erweitertes Logging (Zähler, Journal, Session, /played, Tod, Ansage, Hinweise, Splits, Einblendungen); `/lt debug state | levelup | alert <art> | remind | death | splits` löst Funktionen von Hand aus, ohne Statistiken zu verändern.

### Speedrun (wie ForeverSplits)

- [x] 45. **Split-Liste mit /played** (S): Gesamtspielzeit und Zeit auf dem aktuellen Level in der Split-Liste.
- [x] 46. **Fester Vergleich bleibt fest** (S): Beim Wählen eines Laufs werden seine Level-Zeiten kopiert; levelt der Charakter weiter, ändert sich der Vergleich nicht, bis ein anderer Lauf gewählt wird.
- [x] 47. **Läufe** (M): neue Ansicht in der Historie: alle Läufe (eigene Charaktere und importierte) mit Klasse, erreichtem Level und Zeit bis zum aktuellen Level; Suche nach Name und Klasse, Favoriten, Klick wählt den Lauf als Vergleich.
- [x] 48. **Rekorde** (S–M): Ansicht mit der Bestzeit je Level und dem Lauf, der sie hält.
- [ ] 49. **Läufe teilen und sichern** (M): einen Lauf oder alle als Text exportieren (Kopierfenster) und wieder importieren, z.B. von anderen Spielern oder aus einem anderen Client.

### Einstellungen

- [x] 41. **Einstellungen mit Reitern** (M): Allgemein (Fenster, Kompakt/Horizontal, Sprache, Minimap), Statistiken, Hinweise (Level-Up, Erinnerungen), Stream (Stream-Modus, Hintergrund, Namen, Einblendungen, Splits). Neue Session, Zusammenfassung und Historie unten auf allen Reitern.
- [x] 42. **Client-spezifische Optionen** (S): `Client.lua` erkennt WoW Forever an der Interface-Version (16xxx); Optionen nur für Forever (Camp-Buff) erscheinen in anderen Clients nicht.

- [ ] 50. **Einstellungs-Profile** (M–L): Einstellungen als benanntes Profil speichern, je Charakter ein Profil wählen und Profile als Text exportieren/importieren (für andere Clients oder Accounts; innerhalb eines Accounts und Clients sind Einstellungen schon für alle Charaktere gleich).

### Projekt und Verbreitung

- [ ] 20. **Uploads aktivieren** (S): CurseForge-Projekt-ID, Wago- und WoWInterface-ID in die `.toc` eintragen, Secrets `CF_API_KEY`, `WAGO_API_TOKEN`, `WOWI_API_TOKEN` setzen. Workflow ist fertig (21).

## Erledigt

- Nächstes Release (v2.5): 32. Neue Session starten, 31. Hardcore-Anzeige, 27. Stream-Ansicht, 33. Streamer-Datenschutz, 28. Session-Ziel, 29. Große Einblendungen, 30. Session-Abschlusskarte, 26. Splits, 34. Ansage in Gilde/Gruppe, 38. Rote Tode abschaltbar, 37. Stream-Modus, 35. Fester Vergleichslauf, 36. Split-Liste, 39. Hinweis bei fehlendem Food-Buff, 40. Hinweis bei fehlendem Camp-Buff, 41. Einstellungen mit Reitern, 42. Client-spezifische Optionen, 43. Level-Up-Ansage in /sagen, 44. Debug-Modus, 45. Split-Liste mit /played, 46. Fester Vergleich bleibt fest, 47. Läufe, 48. Rekorde
- v2.0.0:
  - Auswertung: 1. Prognose bis Max-Level, 2. alle Charaktere vergleichen, 3. Zonen-Auswertung, 4. Spielzeit pro Tag/Woche, 5. XP-Verlauf der Session, 6. Langzeit-Graphen als Tageswerte
  - Daten: 7. Quest-Journal, 8. Level-Timeline, 9. Instanzen, 10. Loot-Journal, 11. Elite- und Rare-Kills, 12. Beinahe-Tode, 24. Todesursache aus dem Death Recap (Retail, WoW Forever)
  - Bedienung: 13. Level-Up-Zusammenfassung, 14. XP-Balken, 15. Tabellen sortieren und filtern, 16. CSV-Export, 17. Daten löschen pro Charakter, 18. Kompaktmodus, 19. LibDataBroker-Datentext, 25. horizontale Leiste
  - Projekt: 21. Upload-Workflow für Wago und WoWInterface, 22. Tests bei jedem PR, 23. Französisch und Spanisch
