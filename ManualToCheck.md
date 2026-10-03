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

## Stabilität (v2.8.1, aus dem Deep Review)

Nach dem jeweiligen Fix prüfen; Nummern = Roadmap.

- [ ] **97. Beute-Format:** `/dump LOOT_ITEM_SELF, LOOT_ITEM_PUSHED_SELF` in Retail und Forever: endet der Text mit `%s` ohne Punkt? Danach Einzel-Beute (selten+) im Journal prüfen.
- [ ] **100. Session-XP über Level-Up:** große Quest-Belohnung, die ein Level überspringt; Session-XP muss um die volle Belohnung steigen.
- [ ] **101. /played-Unterdrückung:** nach Login darf keine „Gesamtspielzeit“-Zeile im Chat erscheinen (alle Chatfenster), eigenes `/played` muss weiter erscheinen; kein Taint (BugSack).
- [ ] **102. Erholt-XP:** `/dump GetXPExhaustion()` vor und nach einem Kill mit Erholt-Bonus; Abnahme = Grund- plus Bonus-XP?
- [ ] **103. Beinahe-Tod in Retail/Forever:** `/dump issecretvalue(UnitHealth("player"))` im und außerhalb des Kampfs. Die Funktion ist dort jetzt ausgeblendet (Doku: immer geheim); ist der Wert außerhalb des Kampfs doch lesbar, `NearDeath.IsAvailable` lockern.
- [ ] **107. Gildenreparatur:** ohne vorher die Gildenbank zu öffnen beim Händler reparieren lassen (TBC, Retail, Forever); zahlt die Gilde?
- [ ] **108. Wiederholbare Quests:** mit Auto-Annehmen/-Abgeben eine wiederholbare Abgabe-Quest (z.B. Runenstoff) besuchen: darf nicht automatisch laufen.
- [ ] **118. Levelcap der Erweiterung (Retail):** Charakter am Cap des Accounts: XP/h, Prognose, XP-Balken aus? `/dump UnitXPMax("player")` dort.
- [ ] **119. Todesursache (Classic Era/TBC):** `/dump CombatLogGetCurrentEventInfo, C_CombatLog and C_CombatLog.GetCurrentEventInfo` mit CVar `loadDeprecationFallbacks` an und aus.
- [ ] **120. Beinahe-Tod nach Wiederbelebung:** Wiederbelebung mit wenig Gesundheit (Geistheiler, Seelenstein) darf keinen Beinahe-Tod zählen.
- [ ] **121. Reset von innen:** Gruppenleiter setzt zurück, während man selbst noch drin ist: kein Lua-Fehler, Lauf läuft weiter.
- [ ] **123. Normal/Heroisch:** Normal betreten, raus, Heroisch derselben Instanz: neue Kopie und neuer Lauf?
- [ ] **124. Abweisung wegen Tageslimit:** gibt es in Classic/Forever ein Tageslimit, und wie lautet dann die Meldung?
- [ ] **128. Split-Liste skalieren:** Größe der Split-Liste und des Hauptfensters ändern; Liste bleibt oben links an ihrer Stelle.
- [ ] **132. Importierte Laufnamen:** Lauf mit `|cffff0000Name|r` im Namen importieren; Anzeige darf keine Farbe/Links ausführen.
- [ ] **133. Gespräch mit einer Option:** mit `skipGossip` NPC mit genau einer Option (z.B. Flugmeister) ansprechen; nur eine Auswahl, kein Fehler.
- [ ] **138. Goldsymbole:** Einnahmen im Fenster in Forever und mit CVar `loadDeprecationFallbacks` aus: Symbole statt Text?
- [ ] **139. Zeit ab 100 Tagen:** Max-Level-Charakter mit langer Level-Zeit: Zeitanzeige vollständig?
- [ ] **141. Summenzeile Speedrun:** Historie → Speedrun → Läufe/Rekorde: „Gesamt: N“ lesbar?
- [ ] **142. Texte in der Historie:** Historienfenster in fr/es/de: Buttons und Spaltenköpfe abgeschnitten oder übergelaufen?
- [ ] **144. Munition in Forever:** `/dump C_PaperDollInfo and C_PaperDollInfo.AmmoNeeded and C_PaperDollInfo.AmmoNeeded(), UnitUsesAmmo and UnitUsesAmmo("player")` als Jäger.
- [ ] **95. Zeitumstellung:** nach dem Fix am letzten Oktobersonntag zwischen 23 und 24 Uhr ausloggen bzw. Tagesgraph öffnen: kein Hänger.

## Darstellung

- [ ] **Neue Fensterzeilen:** „Instanz“, „Instanzen/h“, „Instanzen heute“ in allen vier Sprachen, auch in der horizontalen Leiste.
- [ ] **Historie → Instanzen:** Spalte XP/h passt in die Breite, Instanzname nicht abgeschnitten (frFR/esES).
- [ ] **Einstellungen:** neue Schalter (Statistiken: Instanz-Lauf, Instanzlimit, Instanzen heute; Hinweise: Instanzlimit) mit Tooltip, Texte passen in allen Sprachen.

## XP/h (Roadmap 90)

- [ ] **„XP/h ohne AFK“ an:** Vergleich der Charaktere, Graph „XP/h je Level“ und Level-Up-Zeile im Chat zeigen dieselbe Rate wie Fenster und Level-Tabelle.
