# Roadmap

Aufwand: **S** = klein, **M** = mittel, **L** = groß. Erledigtes wird abgehakt und unter „Erledigt“ mit Version vermerkt. Nummern laufen über alle Versionen weiter.

## v2.5: Streaming

Schwerpunkt: Werte, die Zuschauer im Spielbild sehen und verstehen. Addons haben kein Netzwerk und schreiben keine Dateien, alles muss also im Spiel sichtbar sein.

### Für Zuschauer

- [ ] 26. **Splits gegen Bestzeit** (M–L): jede Level-Zeit gegen eine Bestzeit vergleichen (z.B. schnellster eigener Charakter), „+3m 12s“ rot / „−1m 05s“ grün, Gesamtabweichung wie bei LiveSplit. Daten aus `levelHistory` aller Charaktere.
- [x] 27. **Stream-Ansicht** (S): Hintergrund wahlweise Chroma-Grün oder Magenta ohne Rahmen zum Freistellen in OBS; große Schrift über die Größe (bis 200 %), kombinierbar mit der horizontalen Leiste.
- [ ] 28. **Session-Ziel** (S–M): z.B. „Level 30 bis Stream-Ende“ mit Fortschrittsbalken und Prognose („Ziel in ca. 1h 20m“), nutzt `Forecast.lua`.
- [ ] 29. **Große Einblendungen** (S–M): auffällige Meldung bei Level-Up, Rare-/Elite-Kill, epischer Beute und Beinahe-Tod, einzeln abschaltbar. Ereignisse aus `Stats.OnIncrement` und den Journalen.
- [ ] 30. **Session-Abschlusskarte** (M): `/lt recap` zeigt Zeit, Level, XP/h, Kills, Tode, beste Beute und gefährlichsten Gegner der Session, z.B. als Abspann oder Screenshot für Discord.
- [x] 31. **Hardcore-Anzeige** (S): Tode rot, Zeile „Ohne Tod“ (Spielzeit seit dem letzten Tod), dazu die vorhandenen Beinahe-Tode.

### Bedienung

- [x] 32. **Neue Session starten** (S): Button in den Einstellungen und `/lt newsession`. Archiviert die laufende Session sofort und startet eine neue, z.B. zu Stream-Beginn, statt auf Logout und Login zu warten.
- [ ] 33. **Streamer-Datenschutz** (S): Realm und Namen anderer Charaktere in der Historie ausblenden (gegen Stream-Sniping).
- [ ] 34. **Ansage in Gilde/Gruppe** (S): Level-Up-Zusammenfassung optional nach /gilde oder /gruppe. Vorher in der API-Doku prüfen, wo `SendChatMessage` für Addons erlaubt ist (Retail schränkt das ein).

### Projekt und Verbreitung

- [ ] 20. **Uploads aktivieren** (S): CurseForge-Projekt-ID, Wago- und WoWInterface-ID in die `.toc` eintragen, Secrets `CF_API_KEY`, `WAGO_API_TOKEN`, `WOWI_API_TOKEN` setzen. Workflow ist fertig (21).

## Erledigt

- Nächstes Release (v2.5): 32. Neue Session starten, 31. Hardcore-Anzeige, 27. Stream-Ansicht
- v2.0.0:
  - Auswertung: 1. Prognose bis Max-Level, 2. alle Charaktere vergleichen, 3. Zonen-Auswertung, 4. Spielzeit pro Tag/Woche, 5. XP-Verlauf der Session, 6. Langzeit-Graphen als Tageswerte
  - Daten: 7. Quest-Journal, 8. Level-Timeline, 9. Instanzen, 10. Loot-Journal, 11. Elite- und Rare-Kills, 12. Beinahe-Tode, 24. Todesursache aus dem Death Recap (Retail, WoW Forever)
  - Bedienung: 13. Level-Up-Zusammenfassung, 14. XP-Balken, 15. Tabellen sortieren und filtern, 16. CSV-Export, 17. Daten löschen pro Charakter, 18. Kompaktmodus, 19. LibDataBroker-Datentext, 25. horizontale Leiste
  - Projekt: 21. Upload-Workflow für Wago und WoWInterface, 22. Tests bei jedem PR, 23. Französisch und Spanisch
