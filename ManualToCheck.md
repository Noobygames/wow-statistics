# Im Spiel zu prüfen

Was die Tests (WoW-Stub) nicht abdecken: echte API-Werte, Chatmeldungen des Servers und Darstellung. Erledigtes abhaken, Abweichungen als Issue oder direkt im Code beheben und hier vermerken.

Vorher: Client neu starten (neue Dateien in der `.toc`), `/console scriptErrors 1` oder BugSack, `/lt debug` für die Entscheidungen im Chat.

## Prognose mit XP-Tabelle (Roadmap 94)

- [ ] **WoW Forever nutzt die Classic-Werte:** `/dump UnitXPMax("player")` muss zum Level passen, z.B. Level 30 = 47400, Level 50 = 147500 (Tabelle in `History/XpTable.lua`). Weicht der Wert ab, fällt die Prognose still auf die Level-Zeiten zurück.
- [ ] **Classic Era / Anniversary (Classic):** wie oben, gleiche Werte.
- [ ] **TBC Anniversary:** Werte ab Patch 2.3, z.B. Level 30 = 38800, Level 60 = 494000.
- [ ] **Plausibilität:** Zeile „Bis Max-Level“ nach ein paar Leveln mit eigener Erfahrung vergleichen (eher etwas zu lang erwartet).

## Instanz-Kopien und Läufe (Roadmap 91, 93)

- [ ] **zoneUID-Erkennung:** im Dungeon zwei Gegner anvisieren; `/lt debug` sollte die Bestätigung der Kopie zeigen. Eine Gegner-GUID von Hand: `/dump UnitGUID("target")`, 5. Feld = zoneUID.
- [ ] **Reset ergibt neue zoneUID:** Dungeon zurücksetzen, wieder rein, Gegner anvisieren: andere zoneUID, neuer Lauf in Historie → Journal → Instanzen.
- [ ] **Reset-Texte vorhanden:** `/dump INSTANCE_RESET_SUCCESS, INSTANCE_RESET_FAILED, TRANSFER_ABORT_TOO_MANY_INSTANCES` zeigt drei Texte (auf Deutsch).
- [ ] **Reset als Gruppenleiter:** beendet den offenen Lauf sofort.
- [ ] **Reset als Gruppenmitglied:** kommt die Reset-Meldung bei Mitgliedern an? Laut Nova Instance Tracker nur beim Leiter; dann endet der Lauf bei Mitgliedern erst beim Wiederbetreten (neue zoneUID).
- [ ] **„Noch Spieler drin“:** gescheiterter Reset beendet den Lauf für alle draußen (Annahme aus dem NIT-Code).
- [ ] **Tod im Dungeon:** Geisterlauf zum Friedhof und zurück bleibt ein Lauf, die Uhr läuft weiter; Wiederbelebung beim Geistheiler draußen hält die Uhr an.
- [ ] **Händlergang:** raus und wieder rein in dieselbe Kopie setzt den Lauf fort, Zeit draußen zählt nicht.
- [ ] **Gruppenwechsel:** in die Kopie eines anderen Gruppenleiters: nach dem Anvisieren von Gegnern wird der Lauf geteilt.
- [ ] **Retail / WoW Forever:** ist `UnitGUID` in Instanzen geheim (`SecretWhenUnitIdentityRestricted`)? Dann bleibt es bei der Schätzung, es darf kein Lua-Fehler kommen.

## Instanzlimit (Roadmap 92, 93)

- [ ] **Limit in WoW Forever:** wirklich 5 neue Instanzen pro Stunde für alle Charaktere des Realms? Kein offizieller Beleg gefunden.
- [ ] **Abweisung des Servers:** beim 6. Betreten kommt die Server-Meldung; erscheint dazu „Server: zu viele Instanzen. Laut Addon x/5 ...“? (Annahme: Meldung kommt über `CHAT_MSG_SYSTEM`, wie bei NIT; sonst `UI_ERROR_MESSAGE` prüfen.)
- [ ] **Zähler stimmt mit dem Server:** abgewiesen, obwohl das Addon Platz zeigt = zählt zu wenig; reingekommen, obwohl das Addon 5/5 zeigt = zählt zu viel.
- [ ] **Hinweis bei 4/5 und 5/5:** Einblendung und Chatzeile mit Wartezeit (Schalter im Reiter Hinweise).

## Darstellung

- [ ] **Neue Fensterzeilen:** „Instanz“, „Instanzen/h“, „Instanzen heute“ in allen vier Sprachen, auch in der horizontalen Leiste.
- [ ] **Historie → Instanzen:** Spalte XP/h passt in die Breite, Instanzname nicht abgeschnitten (frFR/esES).
- [ ] **Einstellungen:** neue Schalter (Statistiken: Instanz-Lauf, Instanzlimit, Instanzen heute; Hinweise: Instanzlimit) mit Tooltip, Texte passen in allen Sprachen.

## XP/h (Roadmap 90)

- [ ] **„XP/h ohne AFK“ an:** Vergleich der Charaktere, Graph „XP/h je Level“ und Level-Up-Zeile im Chat zeigen dieselbe Rate wie Fenster und Level-Tabelle.
