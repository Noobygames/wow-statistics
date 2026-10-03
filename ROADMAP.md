# Roadmap

Aufwand: **S** = klein, **M** = mittel, **L** = groß. Erledigtes wird abgehakt und unter „Erledigt“ mit Version vermerkt. Nummern laufen über alle Versionen weiter.

## v2.9: Stabilität

Aus dem Deep Review aller Funktionen (10 Prüfer je Bereich plus API-Abgleich gegen Blizzards UI-Quellen für Retail 12.1, Classic Era 1.15.9, TBC Anniversary 2.5.6 und WoW Forever 1.60.1; jeder Fund von zwei Gegenprüfern bestätigt). Sortiert nach Schwere.

### Schwere: kritisch

- [x] 95. **Endlosschleife am Tag der Zeitumstellung** (S): `Daily.BookPlayTime` rechnet Mitternacht + 86400 s; am 25-Stunden-Tag (Ende Sommerzeit) kommt `from` nicht weiter, der Client hängt bei Logout, /reload oder beim Öffnen der Tagesgraphen. Nächste Mitternacht per Kalender (`time({ day = d.day + 1 })`) plus Schutz `untilTime <= from`. `History/Daily.lua:43`

### Schwere: hoch

- [x] 96. **AFK-Prüfung mit geheimem Wert** (S): `TimeBreakdown`: `UnitIsAFK` ist in Retail/Forever während der Chat-Sperre geheim; `isTrue` testet den Wert vor `IsSecret` und wirft jede Sekunde einen Lua-Fehler. Erst `IsSecret`, dann `== true`. `Tracking/TimeBreakdown.lua:25` — betrifft: Retail, WoW Forever
- [x] 97. **Beute ohne Punkt am Formatende** (S): `ChatPatterns.Compile`: endet ein Format mit `%s` (Retail, vermutlich Forever: „Ihr erhaltet Beute: %s“), fängt `(.-)` einen leeren Text; Einzel-Beute wird nie erfasst (Journal, Epic-Einblendung). Letzten Platzhalter als `(.+)` bzw. Link explizit fangen. `Lib/ChatPatterns.lua:16` — betrifft: Retail, vermutlich WoW Forever

### Schwere: mittel

- [x] 98. **Fehler eines Moduls stoppt alle anderen** (S): `runAll` (Events, Login, Logout, Level-Up, Apply) ohne `xpcall`: ein Fehler beim Level-Up überspringt `ns.level = newLevel` und alle Resets, beim Logout gehen Session-Zeit und `lastSeen` verloren. Wie `ns.Every` je Callback schützen. `Core/LevelTimer.lua:38`
- [x] 99. **Profilwechsel verschiebt das Fenster nicht** (S): `TimerWindow`: beim Profilwechsel bleibt das Fenster an der alten Stelle, eine Größenänderung überschreibt danach die Position des Profils. `UI/TimerWindow.lua:403`
- [x] 100. **Session-XP nach Level-Up zu niedrig** (M): `Experience.trackXpGained` erkennt Level-Ups nur an sinkender XP; ist die XP auf dem neuen Level ≥ der alten oder überspringt ein Gewinn zwei Level, fehlt XP (Session-XP/h, Recap, Tages-, Zonen- und Instanz-XP). Level-Up über `OnLevelCompleted` verbuchen. `Tracking/Experience.lua:84`
- [x] 101. **/played im Chat nicht unterdrückt** (S): Blizzard ruft in allen Clients `ChatFrameUtil.DisplayTimePlayed` auf, nicht den ersetzten Alias `ChatFrame_DisplayTimePlayed`; jede Addon-Abfrage schreibt in den Chat, und das Flag deckt nur ein Chatfenster ab. Richtige Funktion wrappen, alle Fenster bis zur Antwort unterdrücken, Stub korrigieren. `Tracking/PlayedTime.lua:39`
- [x] 102. **Erholt-XP doppelt gezählt** (S): `GetXPExhaustion` sinkt um Grund- plus Bonus-XP, gebucht wird die ganze Abnahme als Bonus (laut warcraft.wiki.gg zählt die Hälfte). Halbe Abnahme buchen, Test korrigieren. `Tracking/Experience.lua:106`
- [x] 103. **Beinahe-Tode in Retail und Forever nie gezählt** (S): `UnitHealth` ist dort laut Doku immer geheim (`SecretReturns = true`), `NearDeath` steigt nie ein. Im Spiel prüfen; dann Zeile und Optionen dort ausblenden statt dauerhaft 0. `Tracking/NearDeath.lua:17` — betrifft: Retail, WoW Forever
- [x] 104. **Historie stürzt bei alten Twinks ab** (S): Migrationen und Defaults laufen nur für den eingeloggten Charakter; Twinks aus v1.x haben kein `zoneStats`, `dailyStats`, `questLog`, `lootLog`, `nearDeathLog`, `instanceLog` → Lua-Fehler in Historie und Graphen. Alle Charaktere beim Laden migrieren. `History/History.lua:22`
- [x] 105. **Tages- und Wochengraph bei Zeitumstellung** (S): `Analysis`: Tage per 86400 s gezählt, der Frühlings-Umstellungstag fehlt und ältere Wochen verschieben sich auf So–Sa. Kalenderarithmetik nutzen. `History/Analysis.lua:80`
- [x] 106. **Neu erstellter Charakter erbt alten Lauf** (M): Gleicher Name nach Löschen und Neuerstellen: `levelHistory` des alten Charakters bleibt; Gesamt-Split, PB, Läufe und Export mischen zwei Versuche. Neustart beim Login erkennen (gespeichertes Level > aktuelles, /played kleiner) und alten Lauf archivieren. `Speedrun/Splits.lua:305`
- [x] 107. **Gildenreparatur greift fast nie** (M): `GetGuildBankMoney()` ist 0, bis die Gildenbank in dieser Sitzung geöffnet war (oder veraltet); die Gilde zahlt fast nie bzw. die Meldung lügt. Wie Blizzard `RepairAllItems(true)` versuchen, Kosten danach prüfen, sonst selbst zahlen. `Assist/Merchant.lua:21` — betrifft: TBC Anniversary, Retail, WoW Forever
- [x] 108. **Wiederholbare Quests leeren die Taschen** (S): Auto-Annehmen/-Abgeben ignoriert `repeatable`/`frequency`; bei wiederholbaren Abgaben (Runenstoff, Dunkelmond, Argentumdämmerung) läuft die Schleife, bis alle Gegenstände weg sind. Wiederholbare Quests manuell lassen. `Assist/QuestAutomation.lua:136`
- [x] 109. **Historie sortiert jede Sekunde neu** (M): `TableView` filtert und sortiert die ganze Liste (bis 5000 Kills) jede Sekunde, Textvergleich mit 5 `gsub` je Vergleich: Ruckler. Sortierschlüssel einmal normalisieren, nur bei Änderung neu sortieren. `Lib/TableView.lua:346`

### Schwere: niedrig

- [x] 110. **Profil-Import ohne Wertprüfung** (S): `Profiles.Import` prüft nur Schlüssel; ein Wert falschen Typs bricht `ApplySettings` bei jedem Login. Werte gegen Typ der Defaults prüfen. `Core/Profiles.lua:139`
- [x] 111. **Charakter ohne Profil überschreibt fremdes Profil** (S): Ohne zugewiesenes Profil übernimmt ein Charakter das zuletzt aktive, seine Änderungen landen in diesem Profil. Standardprofil zuweisen. `Core/Profiles.lua:152`
- [x] 112. **Migration läuft nach Downgrade erneut** (S): `migrate` setzt `schemaVersion` nach einem Downgrade herunter; nicht idempotente Migrationen (Tageswerte) laufen beim Upgrade doppelt. Version nie senken. `Core/Database.lua:220`
- [x] 113. **/lt debug alert für levelUp und nearDeath** (S): Argument wird kleingeschrieben, die Schlüssel `levelUp`/`nearDeath` sind gemischt geschrieben und nie auslösbar. `Core/DebugTools.lua:101`
- [x] 114. **Standardprofil-Name in deDE/frFR/esES** (S): Der in der Liste angezeigte (übersetzte) Name des Standardprofils funktioniert nicht mit `/lt profile`. `Core/Commands.lua:41`
- [x] 115. **Serializer: Stack Overflow bei tiefer Verschachtelung** (S): `Serializer.Decode` wirft bei sehr tief verschachteltem Text statt `nil` zu liefern. Tiefe begrenzen. `Lib/Serializer.lua:54`
- [x] 116. **Veralteter PB-Vergleich nach Löschen** (S): Löschen des eingeloggten Charakters lässt den zwischengespeicherten `pb`-Vergleich bis zum nächsten Level-Up stehen; Cache leeren. `Core/LevelTimer.lua:144`
- [x] 117. **/lt goal mit Kommazahl** (S): `/lt goal 30.5` wird angenommen; Bestätigung und Erreichen nennen verschiedene Level. Nur ganze Zahlen. `Core/Commands.lua:73`
- [x] 118. **Leveln am Erweiterungs-Levelcap (Retail)** (S): `IsLeveling` kennt nur `GetMaxPlayerLevel`; am Levelcap des Accounts bleiben XP/h, Prognose, XP-Balken und Food-Hinweis an. `IsPlayerAtEffectiveMaxLevel` nutzen, wo vorhanden. `Tracking/Experience.lua:15` — betrifft: Retail
- [x] 119. **Todesursache hängt an Kompatibilitäts-Global** (S): `DeathCounter` nutzt in Classic Era/TBC ein Global, das nur mit CVar `loadDeprecationFallbacks` existiert; `CombatLogGetCurrentEventInfo` aus `C_CombatLog` verwenden. `Tracking/DeathCounter.lua:78` — betrifft: Classic Era, TBC Anniversary
- [x] 120. **Beinahe-Tod nach Wiederbelebung** (S): Niedrige Gesundheit direkt nach Wiederbelebung oder Seelenstein zählt als Beinahe-Tod. Kurze Sperre nach `PLAYER_ALIVE`/`PLAYER_UNGHOST`. `Tracking/NearDeath.lua:30`
- [ ] 121. **Reset während man drin ist** (S): `InstanceCopy`: Reset-Meldung für die Instanz, in der man steht, löscht den Besuch; die nächste Bestätigung wirft einen Lua-Fehler und der Lauf endet mitten im Dungeon. Resets der eigenen Instanz ignorieren, Besuch notfalls anlegen. `Tracking/InstanceCopy.lua:101`
- [ ] 122. **Erwartete zoneUID geht vor der Bestätigung verloren** (S): Bei „neu geschätzt“ steht die alte zoneUID nur im Speicher; /reload oder kurzes Rausgehen vor der Bestätigung macht Überzählung und getrennte Läufe dauerhaft. Erwartung im Besuch speichern. `Tracking/InstanceCopy.lua:86`
- [ ] 123. **Normal und Heroisch als dieselbe Kopie** (M): Kopien nur am Namen erkannt; Wechsel Normal/Heroisch (TBC, Retail, Forever) innerhalb 30 min zählt nicht und mischt Läufe. Name plus `difficultyID` als Schlüssel. `Tracking/InstanceCopy.lua:134` — betrifft: TBC Anniversary, Retail, WoW Forever
- [ ] 124. **Abweisung wegen Tageslimit** (S): Weist der Server wegen eines Tageslimits ab, meldet das Addon z.B. „2/5“. Meldung neutral formulieren bzw. Tageszahl nennen. `History/InstanceLimit.lua:117` — betrifft: Classic Era, TBC Anniversary, WoW Forever
- [ ] 125. **Löschen des Charakters in der Instanz** (S): `ns.DeleteCharacter` in einer Instanz setzt `inside = nil`; bis zum nächsten Zonenwechsel wird nichts erfasst. Nach dem Login-Neustart aktuelle Instanz neu einlesen. `Tracking/InstanceCopy.lua:157`
- [ ] 126. **Summe zählt XP von Leveln ohne Dauer** (S): `History.Summarize` addiert XP auch ohne `seconds` (/played fehlte), Gesamt-XP/h und Vergleich sind zu hoch. Nur Einträge mit Dauer in die Rate. `History/History.lua:226`
- [ ] 127. **Vergleichslauf mit sich selbst** (S): Der gewählte Vergleichslauf ist accountweit; der Charakter, dessen Lauf gewählt ist, vergleicht sich mit seiner eigenen Kopie. Je Charakter speichern oder dort ausblenden. `Speedrun/Splits.lua:246`
- [ ] 128. **Split-Liste springt beim Skalieren** (S): Größenänderung der Split-Liste (oder des Hauptfensters) verschiebt sie; wie beim Hauptfenster oben links festhalten. `Speedrun/SplitList.lua:278`
- [ ] 129. **Läufe-Ansicht zeigt 0s** (S): Ohne abgeschlossenes Level des eingeloggten Charakters zeigt jede Zeile „0s“ bis zum aktuellen Level. Dann „-“ bzw. Gesamtzeit zeigen. `Speedrun/SpeedrunViews.lua:50`
- [ ] 130. **Import verweigert alten Lauf nach Neustart** (S): Ein exportierter alter Versuch desselben Charakters wird beim Import als vorhanden abgelehnt, obwohl die Daten zurückgesetzt wurden. `Speedrun/Runs.lua:148`
- [ ] 131. **Export ignoriert Streamer-Datenschutz** (S): Lauf-Export und Sicherung zeigen echten Namen und Realm trotz `streamerPrivacy`. `Speedrun/Runs.lua:103`
- [ ] 132. **Escape-Sequenzen in importierten Namen** (S): Importierte Laufnamen mit `|H`, `|T`, `|c` werden ungefiltert angezeigt. Beim Import `|` entfernen bzw. verdoppeln. `Speedrun/Runs.lua:121`
- [ ] 133. **Gesprächsoption doppelt gewählt** (S): `skipGossip` wählt die einzige Option, obwohl Blizzards GossipFrame sie per `selectOptionWhenOnlyOption` schon gewählt hat. `Assist/QuestAutomation.lua:126`
- [ ] 134. **Gruppeneinladung mit Rollenwahl bleibt offen** (S): `declineGroupInvites` schließt in Retail/Forever das Rollen-Popup (`LFGInvitePopup`) bzw. die Quest-Session-Bestätigung nicht. `Assist/Declines.lua:212` — betrifft: Retail, WoW Forever
- [ ] 135. **Duell bis zum Tod nicht abgelehnt** (S): `declineDuels` kennt `DUEL_TO_THE_DEATH_REQUESTED` (Hardcore, TBC Anniversary) nicht. `Assist/Declines.lua:217` — betrifft: Classic Era
- [ ] 136. **Reparatur meldet zu wenig Gold** (S): Automatische Reparatur läuft vor dem Schrottverkauf und meldet „nicht genug Gold“, obwohl der Erlös gereicht hätte. Erst verkaufen, dann reparieren. `Assist/Merchant.lua:81`
- [ ] 137. **XP-Balken bleibt am Max-Level** (S): Sichtbarkeit des XP-Balkens wird nur beim Anwenden der Einstellungen berechnet; nach dem Max-Level oder abgeschalteter XP bleibt er sichtbar. Bei `PLAYER_LEVEL_UP`/`ENABLE_XP_GAIN` neu prüfen. `UI/TimerWindow.lua:171`
- [ ] 138. **Goldsymbole fehlen in Forever** (S): `Format.Money` nutzt das veraltete `GetCoinTextureString` (nur mit Kompatibilitäts-CVar, in Forever nie). `C_CurrencyInfo.GetCoinTextureString` bzw. eigene Formatierung. `Lib/Format.lua:77` — betrifft: WoW Forever
- [ ] 139. **Zeitanzeige ab 100 Tagen abgeschnitten** (S): Breite der Zeitanzeige reicht für zweistellige Tage; bei 100+ Tagen wird abgeschnitten bzw. umgebrochen. `UI/TimerWindow.lua:29`
- [ ] 140. **Sessions nach Level sortieren** (S): Spalte Level sortiert nach formatiertem Text mit gemischten Zahlen/Texten; Reihenfolge falsch. Numerischen Sortierschlüssel liefern. `UI/HistoryTables.lua:115`
- [ ] 141. **Summenzeile in schmaler Spalte** (S): „Gesamt: N“ steht in Spalte 1, in den Speedrun-Tabellen nur 18–46 px breit und unlesbar. Über mehrere Spalten setzen. `UI/HistoryTables.lua:252`
- [ ] 142. **Feste Breiten in der Historie** (M): Feste Button- und Spaltenbreiten im Historienfenster schneiden fr/es/de-Texte ab bzw. lassen sie überlaufen. Breiten aus Textbreite berechnen. `UI/HistoryWindow.lua:24`
- [ ] 143. **Nur 6 Profile in der Liste** (M): Die Profilliste in den Einstellungen zeigt höchstens 6 Profile; weitere lassen sich dort nicht wählen oder löschen. Scrollbar oder Auswahlmenü. `UI/Options.lua:89`
- [ ] 144. **Munitionshinweis in Forever** (S): Hinweis nimmt an, jeder Jäger außerhalb Retail braucht Munition; Forever hat `C_PaperDollInfo.AmmoNeeded`/`UnitUsesAmmo`. Diese nutzen, wo vorhanden. `Assist/GearWarnings.lua:39` — betrifft: WoW Forever

## v2.8: Dungeons

Schwerpunkt: Leveln in Dungeons auswerten und das Instanzlimit im Blick behalten.

- [x] 90. **XP/h überall gleich** (S): Vergleich der Charaktere, XP/h-Graph und Level-Up-Zusammenfassung ziehen AFK-Zeit ab wie Fenster und Historie, wenn „XP/h ohne AFK“ an ist (`Experience.RecordRate`).
- [x] 91. **Dungeon-Läufe** (M): Lauf endet erst beim lebendigen Verlassen (Geisterlauf zum Friedhof setzt ihn fort); XP/h je Lauf in der Historie; Zeile „Instanz“ im Fenster mit Zeit und XP des laufenden Laufs.
- [x] 92. **Instanzlimit** (M): Classic Era, Anniversary und WoW Forever erlauben 5 neue Instanzen pro Stunde für alle Charaktere eines Realms (Retail 10). Zeile „Instanzen/h“ mit „3/5, nächste frei in 14m“, Hinweis beim Betreten der vorletzten und letzten; Instanzen heute als Info.
- [x] 93. **Instanz-Kopien erkennen** (M): Kopie an der zoneUID der Gegner-GUIDs (Ziel, Maus, Namensplaketten) wie Nova Instance Tracker; Reset aus `INSTANCE_RESET_SUCCESS`/`_FAILED`. Ein Lauf ist eine Kopie: raus und wieder rein setzt ihn fort, Reset oder andere Kopie beenden ihn; falsche Schätzungen werden geteilt bzw. zusammengeführt, auch im Instanzlimit. Abweisung des Servers zeigt den Stand laut Addon.
- [x] 94. **Prognose mit XP-Tabelle** (S–M): Prognose bis Max-Level und Session-Ziel rechnen die tatsächlich benötigten XP je Level (Classic Era, Anniversary und WoW Forever: Werte von 1.12; TBC: Werte ab 2.3, `XpTable.lua`) durch die XP/h der letzten 5 Level samt laufendem. Ohne passende Tabelle (Retail, abweichende Werte) wie bisher aus den Level-Zeiten.

## v2.7: Aufräumen

Schwerpunkt: Struktur und Wartbarkeit nach dem Code- und Architektur-Review, ohne neue Funktionen. Jeder Schritt ändert kein Verhalten; die Tests sichern das ab.

### Doppelten Code zusammenführen

- [x] 78. **Gedrosselter Ticker** (S): `ns.Every(seconds, fn)` im Kern statt fünf eigener OnUpdate-Frames (BuffReminder, GearWarnings, TimeBreakdown, RecentXpRate, Broker).
- [x] 79. **Taschen-Helfer** (S): `Bags.lua` (Taschen durchlaufen, letzte Tasche) statt Kopien in Merchant und GearWarnings.
- [x] 80. **Item-Helfer** (S): `Items.SellPrice(item)` und `Items.GetInfo` statt `getItemInfo` + `SELL_PRICE_INDEX` in Merchant, QuestAutomation und Loot.
- [x] 81. **Hinweis-Helfer** (S): `Alerts.Notify(message, color)` (Chatzeile + Einblendung) für BuffReminder, GearWarnings, TrainerReminder; Declines dokumentiert, warum die Umschalttaste dort nicht gilt.

### Große Dateien teilen

- [x] 82. **TableView** (M): allgemeine Tabelle (Lazy Load, Sortieren, Filtern, CSV) aus `HistoryTables.lua` in `TableView.lua`; HistoryTables behält nur die Spalten.
- [x] 83. **OptionsBuilder** (M): Baukasten (`addPage`, `addToggles`, `addChooser`, Breitenberechnung) aus `Options.lua` in `OptionsBuilder.lua`; Options behält nur den Inhalt.

### Struktur

- [x] 84. **Unterordner** (M): `Lib/`, `Core/`, `Tracking/`, `History/`, `Speedrun/`, `Assist/`, `UI/` statt 66 Dateien im Hauptordner (`.toc`-Änderung: Client neu starten).
- [ ] 85. **Locales je Sprache** (S–M): `Locales/Core.lua` plus eine Datei je Sprache statt 1.700 Zeilen in einer.
- [ ] 86. **Standardwerte je Modul** (M): Module melden ihre Einstellungen und Zähler selbst an (`ns.RegisterDefaults`), statt alles zentral in `Database.lua`.
- [ ] 87. **Migrationen ohne Fachmodule** (S): Charakter-Migrationen v4/v5 rufen nicht mehr `ns.Daily` auf (eigener Helfer).
- [ ] 88. **Zyklen auflösen** (S–M): `Stats.GetSeconds` bekommt die Zeitquellen (Session, /played) übergeben statt sie selbst zu kennen; Ladereihenfolge = Abhängigkeiten.
- [ ] 89. **Test-Stub teilen** (S): `tests/wow_stub.lua` nach API-Bereichen aufteilen (Händler, Quests, Taschen, Chat, ...).

## v2.6: Leveln ohne Umwege

Schwerpunkt: Komfort-Funktionen, die beim Leveln Klicks sparen, und Werte, die zeigen, wo Zeit verloren geht. Jede Komfort-Funktion ist einzeln schaltbar (Standard aus) und liegt im neuen Reiter „Komfort“; gedrückte Umschalttaste setzt die Automatik im Moment aus. Nutzt jemand schon Leatrix Plus o.ä., bleiben unsere Schalter einfach aus. Alle API-Annahmen werden vor der Umsetzung je Client gegen die Doku geprüft.

### Komfort

- [x] 55. **Automatisch reparieren** (S): beim Händler mit Reparatur (`MERCHANT_SHOW`, `CanMerchantRepair`, `GetRepairAllCost`, `RepairAllItems`); optional zuerst aus der Gildenbank, nur in Clients mit `CanGuildBankRepair`. Kosten als Chatzeile.
- [x] 56. **Schrott verkaufen** (S–M): graue Gegenstände beim Händler verkaufen; `C_MerchantFrame.SellAllJunkItems`, wo vorhanden, sonst Taschen über `C_Container` durchgehen (Qualität 0, Verkaufspreis > 0). Erlös als Chatzeile.
- [x] 57. **Quests automatisch annehmen** (S): `QUEST_DETAIL` → `AcceptQuest`; geteilte Quests und Eskorten (`QUEST_ACCEPT_CONFIRM`) als eigener Schalter.
- [x] 58. **Quests automatisch abgeben** (M): `QUEST_PROGRESS` → `CompleteQuest`, wenn `IsQuestCompletable`; `QUEST_COMPLETE` → `GetQuestReward` nur bei höchstens einer Belohnung. Bei Auswahl bleibt das Fenster offen; optional die Belohnung mit dem höchsten Verkaufswert (eigener Schalter).
- [x] 59. **Gespräche überspringen** (S–M): `GOSSIP_SHOW`/`QUEST_GREETING`: fertige Quests abgeben, verfügbare öffnen, sonst die einzige Gesprächsoption wählen (`C_GossipInfo`). Nie bei mehreren Optionen oder Optionen mit Bestätigung/Kosten.
- [x] 73. **Trades** (S): Handel automatisch ablehnen
- [x] 74. **Invites** (S): Gruppen Invite automatisch ablehnen
- [x] 75. **Gilde** (S): Gilden Invite automatisch ablehnen
- [x] 76. **Duell** (S): Duell Invite automatisch ablehnen

### Statistik: wohin die Zeit geht

- [x] 60. **Zeitaufteilung** (M–L): Spielzeit je Level und Session aufgeteilt in Kampf (`PLAYER_REGEN_DISABLED/ENABLED`), Flugroute (`UnitOnTaxi`), tot, AFK (`UnitIsAFK`) und Rest (Laufen, Questen). Zeilen im Fenster, Spalten in der Historie.
- [x] 61. **XP/h ohne AFK** (S): Schalter, ob AFK-Zeit in XP/h und Prognose zählt (baut auf 60 auf).
- [x] 62. **Aktuelle XP/h** (S): gleitender Wert der letzten 15 min neben dem Durchschnitt, damit Einbrüche (Laufwege, Flugrouten) sofort sichtbar sind.
- [x] 63. **Kills/Quests bis Level-Up** (S): „noch ~38 Kills oder ~5 Quests“ aus der durchschnittlichen Kill- und Quest-XP des laufenden Levels.
- [x] 64. **Erholt-Anzeige** (S): verbleibende Erholt-XP in Prozent des Levels (`GetXPExhaustion`) als eigene Zeile.
- [x] 65. **Ausgaben** (M): bisher zählen nur Einnahmen. Ausgaben nach Art (Reparatur, Händler, Flugmeister, Lehrer) über das gerade offene Fenster zuordnen; Schrotterlös als eigene Einnahme.

### Hinweise

- [x] 66. **Taschen fast voll** (S): Einblendung, wenn weniger als N Plätze frei sind (verlorene Beute).
- [x] 67. **Haltbarkeit niedrig** (S): Hinweis unter 20 % (`GetInventoryItemDurability`), bevor die Ausrüstung kaputtgeht.
- [x] 68. **Lehrer besuchen** (S): Hinweis beim Level-Up, wenn neue Zauber lernbar sind (Classic Era, TBC und WoW Forever: gerade Level). Retail lernt automatisch, dort keine Option.
- [x] 69. **Munition knapp** (S): Jäger in Classic Era, TBC und WoW Forever, Hinweis unter N Schuss; in Retail nicht sichtbar.

### Streamer

- [x] 70. **Visuals** (S): Streamer mode soll weder größe noch transparenz von elementen ändern
- [x] 71. **Elite Kill** (S): Elite Kill alerts sollten NICHT in dungeons passieren
- [x] 72. **Epic Loot** (S): Epic loot alerts sollten NICHT in raids passieren
- [x] 77. **Level-Up-Ansage ohne /sagen** (S): /sagen braucht außerhalb von Instanzen einen Klick und kam beim Level-Up nicht an; Auswahl und Button entfernt, alte Einstellung wird zu „aus“.

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
- [x] 49. **Läufe teilen und sichern** (M): einen Lauf oder alle als Text exportieren (Kopierfenster) und wieder importieren, z.B. von anderen Spielern oder aus einem anderen Client.

- [x] 51. **Speedrun-Rekorde** (M): Rekorde von speedrun.com (WoW Classic: Leveling, SSF Softcore) für 1-10, 1-20 und 1-60, gesamt und je Klasse. Vergleich mit der /played-Zeit beim Erreichen des Levels in der Split-Liste und in Historie → Speedrun → „Speedrun-Rekorde“. Daten offline in `SpeedrunRecords.lua`, aktualisiert mit `make records`.

- [x] 52. **Erinnerungs-Abstand einstellbar** (S): Food- und Camp-Hinweis wiederholen sich, solange der Buff fehlt; Abstand 1–30 min im Reiter Hinweise (Standard 5).

- [x] 53. **Speedrun-Reiter** (S–M): eigener Reiter in den Einstellungen: Split-Liste (Zeilen Gesamt und /played, eigene Größe, Zahl der Level, Vergleich) und Speedrun-Rekorde (an/aus, je Abschnitt, Stand der Daten mit Alter in Tagen, Rekord der Klasse oder gesamt).

### Einstellungen

- [x] 54. **Tooltips in den Einstellungen** (M): jeder Schalter, Regler, jede Auswahl und jeder Button erklärt sich bei Mauskontakt (alle vier Sprachen); Klick auf die Beschriftung schaltet den Schalter.

- [x] 41. **Einstellungen mit Reitern** (M): Allgemein (Fenster, Kompakt/Horizontal, Sprache, Minimap), Statistiken, Hinweise (Level-Up, Erinnerungen), Stream (Stream-Modus, Hintergrund, Namen, Einblendungen, Splits). Neue Session, Zusammenfassung und Historie unten auf allen Reitern.
- [x] 42. **Client-spezifische Optionen** (S): `Client.lua` erkennt WoW Forever an der Interface-Version (16xxx); Optionen nur für Forever (Camp-Buff) erscheinen in anderen Clients nicht.

- [x] 50. **Einstellungs-Profile** (M–L): Einstellungen als benanntes Profil speichern, je Charakter ein Profil wählen und Profile als Text exportieren/importieren (für andere Clients oder Accounts; innerhalb eines Accounts und Clients sind Einstellungen schon für alle Charaktere gleich).

### Projekt und Verbreitung

- [ ] 20. **Uploads aktivieren** (S): CurseForge aktiv (Projekt 1721235, Secret `CF_API_KEY`). Offen: Wago- und WoWInterface-ID in die `.toc`, Secrets `WAGO_API_TOKEN` und `WOWI_API_TOKEN`.

## Erledigt

- v2.8.0: 78. Gedrosselter Ticker, 79. Taschen-Helfer, 80. Item-Helfer, 81. Hinweis-Helfer, 82. TableView, 83. OptionsBuilder, 84. Unterordner, 90. XP/h überall gleich, 91. Dungeon-Läufe, 92. Instanzlimit, 93. Instanz-Kopien erkennen, 94. Prognose mit XP-Tabelle; Anzeigename „Level Time“
- v2.6.0: 55. Automatisch reparieren, 56. Schrott verkaufen, 57. Quests annehmen, 58. Quests abgeben, 59. Gespräche überspringen, 60. Zeitaufteilung, 61. XP/h ohne AFK, 62. Aktuelle XP/h, 63. Kills/Quests bis Level-Up, 64. Erholt-Anzeige, 65. Ausgaben, 66. Taschen fast voll, 67. Haltbarkeit niedrig, 68. Lehrer besuchen, 69. Munition knapp, 70. Stream-Modus ohne Größe/Transparenz, 71. Keine Elite-Einblendung in Instanzen, 72. Keine Beute-Einblendung in Raids, 73.–76. Handel, Gruppen-, Gilden- und Duellanfragen ablehnen, 77. Level-Up-Ansage ohne /sagen
- v2.5.2: Fix der Zeile /played in der Split-Liste, 52. Erinnerungs-Abstand einstellbar, 53. Speedrun-Reiter, 54. Tooltips in den Einstellungen
- v2.5.0: 32. Neue Session starten, 31. Hardcore-Anzeige, 27. Stream-Ansicht, 33. Streamer-Datenschutz, 28. Session-Ziel, 29. Große Einblendungen, 30. Session-Abschlusskarte, 26. Splits, 34. Ansage in Gilde/Gruppe, 38. Rote Tode abschaltbar, 37. Stream-Modus, 35. Fester Vergleichslauf, 36. Split-Liste, 39. Hinweis bei fehlendem Food-Buff, 40. Hinweis bei fehlendem Camp-Buff, 41. Einstellungen mit Reitern, 42. Client-spezifische Optionen, 43. Level-Up-Ansage in /sagen, 44. Debug-Modus, 45. Split-Liste mit /played, 46. Fester Vergleich bleibt fest, 47. Läufe, 48. Rekorde, 49. Läufe teilen und sichern, 50. Einstellungs-Profile, 51. Speedrun-Rekorde
- v2.0.0:
  - Auswertung: 1. Prognose bis Max-Level, 2. alle Charaktere vergleichen, 3. Zonen-Auswertung, 4. Spielzeit pro Tag/Woche, 5. XP-Verlauf der Session, 6. Langzeit-Graphen als Tageswerte
  - Daten: 7. Quest-Journal, 8. Level-Timeline, 9. Instanzen, 10. Loot-Journal, 11. Elite- und Rare-Kills, 12. Beinahe-Tode, 24. Todesursache aus dem Death Recap (Retail, WoW Forever)
  - Bedienung: 13. Level-Up-Zusammenfassung, 14. XP-Balken, 15. Tabellen sortieren und filtern, 16. CSV-Export, 17. Daten löschen pro Charakter, 18. Kompaktmodus, 19. LibDataBroker-Datentext, 25. horizontale Leiste
  - Projekt: 21. Upload-Workflow für Wago und WoWInterface, 22. Tests bei jedem PR, 23. Französisch und Spanisch
