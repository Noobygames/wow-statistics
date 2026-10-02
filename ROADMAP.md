# Roadmap

Aufwand: **S** = klein, **M** = mittel, **L** = groß. Erledigtes wird abgehakt.

## Auswertung und Graphen

- [x] 1. **Prognose bis Max-Level** (M): aus bisherigen Level-Zeiten hochrechnen, z.B. „Level 90 in ca. 14 h /played“.
- [x] 2. **Alle Charaktere vergleichen** (M): Ansicht „Alle“ mit Summen und einer Rangliste, wer am schnellsten levelt.
- [x] 3. **Zonen-Auswertung** (M): XP/h, Kills und Tode pro Zone. Zeigt, welche Zone sich lohnt.
- [x] 4. **Spielzeit pro Tag/Woche** (S): Graph aus den Sessions.
- [x] 5. **XP-Verlauf in der Session** (M): Linie XP über Zeit, zeigt Pausen und Leerlauf.
- [x] 6. **Langzeit-Graphen trotz Limit** (M): alte Journal-Einträge vor dem Löschen zu Tageswerten zusammenfassen.

## Neue Daten

- [x] 7. **Quest-Journal** (S): Name der Quest, Zeitpunkt, XP, Gold.
- [x] 8. **Level-Timeline** (S): wann welches Level erreicht, mit /played. „Level 60 nach 3d 4h“.
- [x] 9. **Instanzen** (M): Zeit, XP und Kills in Dungeons getrennt von der offenen Welt, Dungeon-Läufe zählen.
- [x] 10. **Loot-Journal** (M): seltene und epische Beute mit Zeit und Quelle.
- [x] 11. **Elite- und Rare-Kills** (M): getrennt zählen; Einstufung beim Anvisieren gemerkt, daher in allen Clients.
- [x] 12. **Beinahe-Tode** (M): Leben unter 10 % ohne zu sterben.

## Bedienung

- [x] 13. **Level-Up-Zusammenfassung** (S): Chatzeile beim Level-Up, z.B. „Level 84 in 2h 10m, 312 Kills, 1 Tod“.
- [x] 14. **XP-Balken im Fenster** (S): Fortschritt mit Rested-Anteil.
- [x] 15. **Tabellen sortieren und filtern** (M): Klick auf Spaltenkopf sortiert, Suchfeld für Name, Zone, Zeitraum.
- [x] 16. **Export** (S): Tabelle als CSV in ein Textfeld zum Kopieren.
- [x] 17. **Daten löschen pro Charakter** (S): z.B. nach Löschen eines Charakters.
- [x] 18. **Kompaktmodus** (S): Fenster nur mit Zeit und XP/h.
- [x] 19. **Datentext für Titan Panel und ElvUI** (M): Werte in fremden Leisten anzeigen (LibDataBroker).
- [x] 25. **Horizontale Leiste** (S): Fenster als Info-Leiste, alle Werte in einer Zeile.

## Projekt und Verbreitung

- [ ] 20. **CurseForge-Upload aktivieren** (S): Projekt-ID und API-Key eintragen.
- [x] 21. **Wago und WoWInterface** (S): derselbe Packager lädt mit, braucht je einen Token (IDs in der .toc und Secrets noch eintragen).
- [x] 22. **Tests bei jedem PR** (S): GitHub Action prüft PRs vor dem Merge; Node-20-Warnungen beheben.
- [x] 23. **Weitere Sprachen** (S–M): Französisch, Spanisch usw.
- [x] 24. **Todesursache in Retail** (M): prüfen, ob Retails Death Recap eine Ursache liefert.

## Erledigt

Nach Erledigen oben abhaken und hier kurz vermerken (Version, Nummer).

- v2.0.0: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23, 24, 25
