# Roadmap

Aufwand: **S** = klein, **M** = mittel, **L** = groß. Erledigtes wird abgehakt.

## Auswertung und Graphen

- [x] 1. **Prognose bis Max-Level** (M): aus bisherigen Level-Zeiten hochrechnen, z.B. „Level 90 in ca. 14 h /played“.
- [ ] 2. **Alle Charaktere vergleichen** (M): Ansicht „Alle“ mit Summen und einer Rangliste, wer am schnellsten levelt.
- [ ] 3. **Zonen-Auswertung** (M): XP/h, Kills und Tode pro Zone. Zeigt, welche Zone sich lohnt.
- [ ] 4. **Spielzeit pro Tag/Woche** (S): Graph aus den Sessions.
- [ ] 5. **XP-Verlauf in der Session** (M): Linie XP über Zeit, zeigt Pausen und Leerlauf.
- [ ] 6. **Langzeit-Graphen trotz Limit** (M): alte Journal-Einträge vor dem Löschen zu Tageswerten zusammenfassen.

## Neue Daten

- [ ] 7. **Quest-Journal** (S): Name der Quest, Zeitpunkt, XP, Gold.
- [x] 8. **Level-Timeline** (S): wann welches Level erreicht, mit /played. „Level 60 nach 3d 4h“.
- [ ] 9. **Instanzen** (M): Zeit, XP und Kills in Dungeons getrennt von der offenen Welt, Dungeon-Läufe zählen.
- [ ] 10. **Loot-Journal** (M): seltene und epische Beute mit Zeit und Quelle.
- [ ] 11. **Elite- und Rare-Kills** (M): getrennt zählen, nur wo das Kampflog frei ist (Classic).
- [ ] 12. **Beinahe-Tode** (M): Leben unter 10 % ohne zu sterben.

## Bedienung

- [x] 13. **Level-Up-Zusammenfassung** (S): Chatzeile beim Level-Up, z.B. „Level 84 in 2h 10m, 312 Kills, 1 Tod“.
- [ ] 14. **XP-Balken im Fenster** (S): Fortschritt mit Rested-Anteil.
- [ ] 15. **Tabellen sortieren und filtern** (M): Klick auf Spaltenkopf sortiert, Suchfeld für Name, Zone, Zeitraum.
- [ ] 16. **Export** (S): Tabelle als CSV in ein Textfeld zum Kopieren.
- [x] 17. **Daten löschen pro Charakter** (S): z.B. nach Löschen eines Charakters.
- [ ] 18. **Kompaktmodus** (S): Fenster nur mit Zeit und XP/h.
- [ ] 19. **Datentext für Titan Panel und ElvUI** (M): Werte in fremden Leisten anzeigen (LibDataBroker).

## Projekt und Verbreitung

- [ ] 20. **CurseForge-Upload aktivieren** (S): Projekt-ID und API-Key eintragen.
- [ ] 21. **Wago und WoWInterface** (S): derselbe Packager lädt mit, braucht je einen Token.
- [x] 22. **Tests bei jedem PR** (S): GitHub Action prüft PRs vor dem Merge; Node-20-Warnungen beheben.
- [ ] 23. **Weitere Sprachen** (S–M): Französisch, Spanisch usw.
- [ ] 24. **Todesursache in Retail** (M): prüfen, ob Retails Death Recap eine Ursache liefert.

## Erledigt

Nach Erledigen oben abhaken und hier kurz vermerken (Version, Nummer).

- Nächstes Release: 1, 8, 13, 17, 22
