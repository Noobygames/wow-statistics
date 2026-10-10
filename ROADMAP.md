# Roadmap

Aufwand: **S** = klein, **M** = mittel, **L** = groß. Erledigtes wird abgehakt und unter „Erledigt“ mit Version vermerkt. Nummern laufen über alle Versionen weiter.

## v2.13: Quest-Markierung

- [x] 240. **Questziele über der Namensplakette markieren** (M): Einstellung `questMarks` (Komfort → Quest-Markierung, aus) mit Größe `questMarkScale`: ein Symbol links neben dem Lebensbalken (so hoch wie dieser) von Gegnern und NPCs einer aktiven Quest (`C_QuestLog.UnitIsRelatedToActiveQuest`, in WoW Forever per `/dump` geprüft: true für Questmobs). Nach erfülltem Ziel meldet die API selbst false, die Markierung verschwindet also von allein. Bei Gegenstandszielen („Flatterfliegenstaub: 2/5“, Item auf den Mob anwenden) kennt das Spiel keine Beziehung (API false, Tooltip ohne Questzeile, im Spiel geprüft): dort entscheidet ein Textvergleich, steht der Mobname in einem unerfüllten Ziel von `C_QuestLog.GetQuestObjectives` (Namen unter 4 Zeichen ignoriert; Spieler und tote Gegner nie). Geheime Werte werden übergangen. Nur sichtbar, wenn Namensplaketten an sind und in Reichweite. Offen: Welt-Objekte (Kisten, Hebel) lassen sich nicht markieren (keine Einheit); Quest-Items in den Taschen (Karte beim Looten, `C_Container.GetContainerItemQuestInfo`); eigenes Symbol statt des Gossip-Ausrufezeichens; Wirkung in Retail und Classic Era prüfen.

## v2.12: Wünsche aus der Community

- [x] 239. **„Kills/Quests bis Level-Up“ getrennt schaltbar** (S): Die Zeile wurde in „Kills bis Level-Up“ (`showKillsToLevel`) und „Quests bis Level-Up“ (`showQuestsToLevel`) aufgeteilt, damit No-Quest-Läufe keine nutzlose Quest-Zeile sehen. Einstellungs-Migration 5 übernimmt den alten Zustand in beide, auch in Profilen und Stream-Sicherung.

## v2.11: Komfort

- [x] 238. **Fenster verschieben („Move Anything“)** (M): Einstellung `moveFrames` (Komfort → Fenster, aus): Die Standardfenster des Spiels (Charakter, Zauberbuch, Talente, Questlog, Freunde, Händler, Gespräche, Handel, Post, Bank, Lehrer, Berufe, Auktionshaus, Inspizieren, Beute, Gilde, Gruppensuche, Sammlungen, ...) lassen sich mit der linken Maustaste ziehen; die Position wird gemerkt (`movedFrames`) und beim Öffnen wiederhergestellt, auch nach Blizzards eigener Anordnung. Nichts im Kampf. Später geladene Blizzard-Addons kommen über `ADDON_LOADED` dazu. Button „Fensterpositionen zurücksetzen“ (wirkt nach /reload). Offen: eigene Liste erweitern (`/lt move <Framename>`), Rechtsklick-Reset pro Fenster, Skalieren.

## v2.10: Lagerfeuer in WoW Forever

- [x] 236. **Lagerfeuer-Countdown und -Hinweis** (M, nur WoW Forever): Beim Buff „Einladendes Lagerfeuer“ (60 s, Spell 1229739) zeigt eine kleine Anzeige die Restzeit als Zahl und leerlaufenden Balken („Sitzen bleiben!“), danach kurz „Lagervorteile aktiv!“ (nur wenn der Countdown die Lagervorteile 1229741 erneuert hat; optional mit Ton). Ist ein Lagerfeuer in der Nähe (1283391) und fehlen die Lagervorteile, erscheint ein pulsierender Hinweis, sich hinzusetzen. Spell-IDs im Spiel per Aura-Liste ermittelt. Einstellungen im Reiter Hinweise (Abschnitt Lagerfeuer): Countdown, Hinweis, Ton, Größe, Vorschau (Hinweis → Countdown → aktiv), Verschieben und Zurücksetzen. Neue Bausteine: `Lib/Auras.lua` (Buffs lesen mit allen Sperr-Schutzen, von `BuffReminder` mitgenutzt) und `Widgets.CreateMover` (verschiebbare Anzeige mit gespeicherter Position, Größen-Umrechnung und Verschiebemodus; `Alerts.lua` kann darauf umgestellt werden, siehe 234).

- [x] 237. **Hinweise als Karten** (M): Alle Hinweise (Buff fehlt „Satt“ und „Lagervorteile“, Taschen fast voll, Haltbarkeit niedrig, Munition knapp, Lehrer besuchen, Instanzlimit) erscheinen wie die Lagerfeuer-Anzeige: dunkle Karte mit Farbleiste, Symbol (Zauber-Textur oder Item-Symbol), Titel und Text. `Lib/Card.lua` ist der gemeinsame Baustein (auch für `CampDisplay`); `Alerts.Notify` nimmt `{ text, title, icon }` und stellt mehrere Hinweise in die Warteschlange. Größe, Dauer, Position und Ton bleiben die der Einblendungen; die Vorschau zeigt als sechste Art eine Hinweis-Karte.

## v2.9: Instanz-Auswertung und Einblendungen

- [x] 149. **Instanz-Reiter** (M): dritter Reiter „Instanz“ neben Level und Session; zeigt alle Stat-Zeilen für den laufenden Instanz-Lauf (`Stats.INSTANCE`, voller Zählersatz in `currentRun.stats`, gezählt nur bei laufender Lauf-Uhr). Alte offene Läufe werden beim Login umgewandelt.
- [x] 150. **Erhaltene XP** (S): Zeile „Erhaltene XP“ mit den absolut gewonnenen XP im gewählten Bereich (Level, Session oder Instanz), nicht pro Stunde.
- [x] 151. **XP/h ohne AFK in der Historie** (S): Die Zeile des laufenden Levels und der laufenden Session ließ die noch nicht gebuchte AFK-Zeit weg (Historie, Vergleich, Graphen, Prognose zu niedrig); `TimeBreakdown.Snapshot`. Szenario `afk_rate` prüft ETA, Level-Up im AFK und AFK > Spielzeit.
- [x] 152. **Instanz zurücksetzen** (S): Rechtsklick auf den Reiter „Instanz“, Button in den Einstellungen oder `/lt resetinstance` setzen Zeit, XP und Zähler des laufenden Laufs nach Rückfrage auf null; der Lauf bleibt offen, die Uhr läuft weiter.
- [x] 153. **Einblendungen gestalten** (M): Aussehen und Position der Einblendungen und Hinweise (`Alerts.lua`): Stil „Banner“ (dunkler Hintergrund, Farbleisten in der Farbe der Art, weiches Ein- und Ausblenden) oder „Text“, Größe, Anzeigedauer, optional Ton; Position per Ziehen im Verschiebemodus, Vorschau und Zurücksetzen. Eigener Reiter „Einblendungen“ mit den Schaltern aus dem Stream-Reiter.
- [x] 154. **Buttons im Addon-Stil** (S): flacher dunkler Button mit goldenem Rand, Mouseover- und Gedrückt-Zustand für alle Buttons; Fußzeile der Einstellungen in zwei Spalten.
- [x] 155. **Einblendungen mit Warteschlange** (S): eine zweite Einblendung ersetzt die laufende nicht mehr, sie wartet (höchstens 4, die laufende zeigt sich dann kürzer); lange Texte brechen um; der Ton gilt nur für Ereignisse, nicht für wiederholte Hinweise.
- [x] 156. **Instanz-Reiter: Leerzustand und Automatik** (S): ohne Lauf steht „Kein Lauf“ und Striche statt Nullen; optional (Einstellung `autoInstanceTab`) wechselt das Fenster beim Betreten einer Instanz zum Reiter Instanz und beim Verlassen zurück.
- [x] 157. **Hilfe in Gruppen und Willkommenshinweis** (S): `/lt help` zeigt die Befehle nach Themen in fünf Zeilen; beim allerersten Start ein Chat-Hinweis auf Rechtsklick und `/lt help`.
- [x] 158. **Stat-Gruppen und Voreinstellungen** (M): die Stat-Schalter stehen in Gruppen (Erfahrung, Fortschritt, Kämpfe, Instanz, Zeit/Quests/Geld); darüber Voreinstellungen „Minimal“, „Leveln“ und „Dungeon“, die genau ihre Zeilen einschalten.
- [x] 159. **Einstellungen scrollen** (M): jede Seite scrollt mit dem Mausrad; das Fenster wird höchstens 90 % so hoch wie der Bildschirm.
- [x] 160. **Historie: Charakterliste und gemerkter Reiter** (S): Klick auf den Charakternamen öffnet eine Liste aller Charaktere (klassenfarbig, scrollt ab 12); der zuletzt gewählte Reiter bleibt erhalten (`historyTab`).

## v2.9: Funde aus dem Review

Aus dem Review des Branches `feature/alert-style` (fünf Prüfer: Clean Code, Wiederverwendbarkeit, Bugs im neuen Code, Bugs im Kern, UX/Texte; Funde nur gelesen, nicht im Spiel getestet). „im Spiel prüfen“ = der Prüfer war unsicher, siehe `ManualToCheck.md`. Bereits behoben: Texturpfad in `Alerts.lua` (einfache Backslashes, der Banner wäre unsichtbar gewesen).

### Bugs im neuen Code

- [x] 161. **Auto-Instanz-Reiter bleibt hängen** (S): `scopeBeforeInstance` liegt nur im Speicher. Steht `windowScope` schon auf „instance“ (z.B. `/reload` in der Instanz), merkt sich `OnEnter` nichts; nach dem Verlassen bleibt das Fenster auf „Kein Lauf“. Beim Verlassen ohne Merker auf Level zurückfallen oder den vorigen Reiter speichern; auch Logout und `DeleteCharacter` bedenken. `UI/TimerWindow.lua:334`
- [x] 162. **Zeitaufteilung blutet über die Lauf-Grenze** (S): Ungebuchte Kampf-, Flug- und AFK-Zeit (bis 10 s) von vor dem Betreten landet im Lauf, ebenso nach „Instanz zurücksetzen“. `TimeBreakdown` beim Fortsetzen, Pausieren und Zurücksetzen des Laufs flushen. `Tracking/TimeBreakdown.lua:60`, `History/Instances.lua:212`
- [x] 163. **Einblendungen im Verschiebemodus verloren** (S): `Alerts.Show` kehrt im Verschiebemodus zurück; echte Warnungen und Level-Ups gehen verloren (die Chatzeile bleibt). Merken und nach dem Verschieben abspielen, oder den Modus bei einer echten Einblendung beenden. `UI/Alerts.lua:203`
- [ ] 164. **Vorschau und Debug verwerfen die Warteschlange** (S): `ShowSample` ruft `Alerts.Clear()` und löscht dabei wartende echte Einblendungen. Nur im Debug- und Vorschau-Pfad, daher niedrig. `UI/Alerts.lua:266` **Bewusst belassen: Vorschau und Debug sollen sofort zeigen.**
- [x] 165. **Skalierung verschiebt die Einblendung** (S): Ankerabstände gelten in der Skalierung des Rahmens; der Größenregler verschiebt die Einblendung, ohne dass die Position gespeichert wird. Nach `SetScale` neu verankern (wie `setScaleKeepingTopLeft`). `UI/Alerts.lua` (`restorePosition`, `RegisterApply`)
- [x] 166. **Broker im leeren Instanz-Reiter** (S): Mit `windowScope = "instance"` ohne Lauf zeigt der Broker „0s“ und die Tooltip-Zeilen lesen einen leeren Bereich statt „-“. `Stats.IsOpen` prüfen, `L.INSTANCE_NONE` zeigen. `UI/Broker.lua:20`
- [x] 167. **Gemerkter Historie-Reiter: Profil und Zeitpunkt** (S): `historyTab` ist Profil-Einstellung und wird bei jedem Klick am Profil vorbei per `ns.db` geschrieben; nach einem Profilwechsel folgt das Fenster nicht (`restored` bleibt true). Über `ns.Set` schreiben, `restored` im Apply zurücksetzen oder die Einstellung außerhalb der Profile speichern. `UI/HistoryWindow.lua:326`
- [x] 168. **Charakterliste schließt nicht bei Klick daneben** (S): Das Menü schließt nur bei Klick auf den Namen, auf einen Eintrag, ESC oder Schließen des Fensters. Klick außerhalb (Fänger über dem Fenster) schließt es auch; die Eintragsbreite füllt das Menü nicht. `UI/HistoryWindow.lua:140`
- [x] 169. **Zusammenführen: nil-Arithmetik** (S): Das Zusammenführen eines Laufs rechnet `stats[k] + previous.xp` ohne `or 0`; fehlt ein Zähler in älteren Daten, wird die Korrektur still übersprungen. `History/Instances.lua:155`
- [x] 170. **Button ohne Deaktiviert-Zustand** (S): `Widgets.CreateButton` kennt `OnDisable`/`OnEnable` nicht; ein späteres `Disable()` sähe aktiv aus. Zustand in `paint` berücksichtigen. `Lib/Widgets.lua:174`

### Bugs im Kern

- [x] 171. **Geheime Werte in Klassifikation, Instanz-Kopie und Zonen** (S): `UnitIsPlayer`, `UnitName` und `UnitClassification` werden vor `ns.IsSecret` per Wahrheitstest geprüft; in Retail/Forever (eingeschränkte Instanzen, Bosskämpfe) wirft jedes Mouseover-, Ziel- und Namensplaketten-Ereignis einen Fehler und die Elite-/Rare-Erkennung fällt aus. Dasselbe, seltener: `InstanceCopy.lua:61` (`not guid or ns.IsSecret(guid)`), `Zones.lua:24` (`zone == ""` vor `IsSecret`). Reihenfolge tauschen, Tests mit geheimen Werten ergänzen (bisher nur `near_death_secret_test`). `Tracking/Classification.lua:15` — betrifft: Retail, WoW Forever — im Spiel prüfen
- [x] 172. **Profil-Import ohne Wertebereiche** (S): `SanitizeSettings` prüft nur den Typ; `scale=0`, `reminderInterval=0`, `splitListRows=-5`, `bgAlpha=9`, `alertScale=0` kommen durch (Fenster unbenutzbar, Erinnerung alle 5 s). NaN und inf (`n1e999` im Serializer) abweisen. Min/Max je Einstellung. `Core/Database.lua:274`, `Core/Profiles.lua:148`
- [x] 173. **Migrationen ungeschützt** (S): `Database.Load` migriert jeden Charakter in einer ungeschützten Schleife; ein kaputter Eintrag (Nicht-Tabelle in `killLog`, schlechte `sessionHistory`) wirft in `startTracking`, `ns.db` und `ns.character` bleiben nil, alle Module sind für die Sitzung tot. Pro Charakter über `ns.SafeCall`, defekte Charaktere überspringen und melden. `Core/Database.lua:360`
- [x] 174. **Listener-Schleifen ungeschützt** (S): `Stats.Increment` (`OnIncrement`), `Journal.append` und `InstanceCopy.notify` rufen Listener ohne `SafeCall`; ein Fehler bricht die übrigen und den Aufrufer ab. In `TimeBreakdown.flush` bleibt dann `pending` stehen und die Sekunden werden doppelt gebucht, `pendingTitle` in `QUEST_TURNED_IN` bleibt hängen. Jeden Listener über `ns.SafeCall`; `pending` vor dem Buchen zurücksetzen. `Tracking/Stats.lua:80`, `Tracking/Journal.lua:41`, `Tracking/InstanceCopy.lua:42`
- [ ] 175. **`UnitXPMax` beim Level-Up** (S): Der Historie-Eintrag liest `UnitXPMax` bei `PLAYER_LEVEL_UP` und nimmt an, dass es noch den alten Wert liefert. Ist es schon der neue, stimmt `xp` der abgeschlossenen Level nicht (XP/h-Graph, Prognose, `RecordRate`). `lastXpMax` aus `Experience.lua` verwenden. `History/History.lua:204` — im Spiel prüfen
- [x] 176. **`lastDeathPlayed` mit nil überschrieben** (S): Stirbt man vor der ersten `TIME_PLAYED_MSG` (ca. 3 s nach dem Login), löscht die Zuweisung den vorigen Wert; die Zeile „Ohne Tod“ bleibt bis zum nächsten Tod leer. Nur bei vorhandenem Wert schreiben. `Tracking/DeathCounter.lua:134`
- [x] 177. **Einstellungs-Migrationen 2 und 3 übergehen Profile** (S): Nur Migration 4 geht durch `profiles`; ältere gespeicherte Profile behalten `fontSize` und `showKills`, der Übertrag der Schalter geht beim Wechsel verloren. Jede Migration auch auf alle Profile und `streamBackup`. `Core/Database.lua:188`
- [x] 178. **`/lt profile`: Schlüsselwörter verdecken Namen** (S): Ein Profil „save x“, „delete x“, „export“ oder „import“ ist per Befehl nicht anwählbar; `/lt profile delete me` löst `delete` aus. Eigene Aktion `switch <Name>` oder zuerst prüfen, ob das ganze Argument ein Profilname ist. `Core/Commands.lua:34`
- [ ] 179. **Gildenreparatur: Abhebelimit** (S): CLAUDE.md sagt „nur wenn das Abhebelimit die Kosten deckt“, der Code prüft nur `CanGuildBankRepair()`, versucht `RepairAllItems(true)` und zahlt nach 1 s selbst. Kein doppeltes Abbuchen gefunden. Doku anpassen oder `GetGuildBankWithdrawMoney` prüfen. `Assist/Merchant.lua:47` — im Spiel prüfen
- [ ] 180. **Todesursache ohne `recapID`** (S): `C_DeathRecap.GetRecapEvents()` wird ohne ID aufgerufen; ist sie nötig, schlägt der `pcall` fehl und die Ursache bleibt in Retail/Forever „unbekannt“. `Tracking/DeathRecap.lua:37` — betrifft: Retail, WoW Forever — im Spiel prüfen (`/dump C_DeathRecap.GetRecapEvents()`)
- [ ] 181. **Gespräch überspringen: gefährliche Optionen** (M): Eine einzige Gesprächsoption wird gewählt, auch beim Geistheiler („Wiederbeleben“, kostet Wiederbelebungsschwäche oder Haltbarkeit) und bei Optionen mit Kosten; es gibt keine Tiefenbegrenzung für verkettete Einzeloptionen. Optionen mit Kosten, `flags` oder Belohnungen ausschließen, Kette begrenzen. `Assist/QuestAutomation.lua:241` — im Spiel prüfen **Teilweise: Erledigt: als Geist nie, dieselbe Option nicht zweimal in 2 s. Offen: Optionen mit Kosten/Flags ausschließen (Struktur der Option im Spiel prüfen).**
- [ ] 182. **Wiederholbare Quests: Lücke und Kommentar** (S): Der Ausschluss gilt nur in den Gesprächs- und Grußlisten; `QUEST_PROGRESS`/`QUEST_COMPLETE` geben von Hand geöffnete wiederholbare Quests ab. Vermutlich gewollt, dann den Kopfkommentar „bleibt manuell“ präzisieren. `Assist/QuestAutomation.lua:201` **Teilweise: Erledigt: Kommentar präzisiert (Verhalten bleibt).**
- [x] 183. **Instanzlimit: Reihenfolge nach Korrektur** (S): `add(name, enteredAt)` hängt einen Eintrag mit früherer Zeit hinter neuere; `prune` und `GetSecondsUntilNextFree` setzen „ältester zuerst“ voraus. Nach dem Einfügen sortieren. `History/InstanceLimit.lua:299`
- [x] 184. **Quest-Titel veraltet** (S): `pendingTitle` wird nur bei `QUEST_TURNED_IN` gelöscht; ein geöffnetes und verworfenes Fenster hängt den alten Titel an die nächste Quest (Clients ohne `C_QuestLog.GetTitleForQuestID`). Auch bei `QUEST_FINISHED` löschen. `Tracking/QuestCounter.lua:20`
- [x] 185. **Session: `lastSeen` in der Zukunft** (S): Wird die Systemuhr zurückgestellt, ist `time() - lastSeen` negativ und besteht die Prüfung `<= RESUME_GAP_SECONDS`; eine alte Session setzt fort. `>= 0` ergänzen. `Tracking/Session.lua:56`
- [ ] 186. **Journal-Grenzen sehr groß** (S–M): 5000 Kills, 2000 Beute, 2000 Quests, 1000 Tode, 500 Beinahe-Tode und 500 Läufe ergeben je Charakter über 2 MB; bei zehn Charakteren langsames Login. Kleinere Grenzen oder kompakte Tupel. `Tracking/Journal.lua:19`
- [ ] 187. **Elite-/Rare-Erkennung nur nach Name** (S): Gleichnamige Gegner mit anderer Einstufung erben die zuletzt gesehene. Bewusste Näherung; mindestens dokumentieren. `Tracking/KillCounter.lua:35`, `Tracking/Classification.lua:24` **Teilweise: Erledigt: im Code dokumentiert (Verhalten bleibt).**

### Texte und Übersetzung

- [x] 188. **Minimap-Tooltip beschreibt falsche Klicks** (S): `SHOW_MINIMAP_TIP` (alle vier Sprachen) sagt Linksklick = Fenster, Rechtsklick = Einstellungen; tatsächlich: Linksklick öffnet die Einstellungen, Shift+Linksklick die Historie, Rechtsklick blendet das Fenster ein/aus. `UI/MinimapButton.lua:59`
- [x] 189. **Ton-Tooltip verspricht zu viel** (S): `ALERT_SOUND_TIP` nennt „jede Einblendung und jeden Hinweis“, `Alerts.Notify` spielt aber keinen Ton (Warnungen sind still). Entweder `{ sound = true }` in `Notify` (Warnungen brauchen Ton) oder den Text auf Ereignisse beschränken. `UI/Alerts.lua:232`
- [x] 190. **Spanisch: falsche und englische Begriffe** (S): „Estancias“/„Estancia“ (heißt „Aufenthalt“) → „Instancias“/„Instancia“; `INSTANCE_NONE = "Sin run"` → „Sin instancia“; „Carcajs“ → „Carcajes“; „muertes“ für Kills und Tode gleichzeitig → Kills „Abatidos“; `REMIND_FOOD_TOGGLE` ungrammatisch → „Aviso: falta «Bien alimentado»“; „al subir de nivel“ klingt nach Level-Up → „mientras subes de nivel“; `ROW_LEVEL_ETA` „Subes en“ → „Siguiente nivel en“; `STAT_INSTANCE_RUN` „Incursión“ (= Raid) → „Recorrido de instancia“; Reiter „Avisos“ doppelt belegt → Reiter „Alertas“. `Locales/Locales.lua`
- [x] 191. **Französisch: tu/vous, Kills, Buff** (S): Teile der Tooltips duzen („tu/ton“), andere siezen („vous“); WoW FR siezt → überall „vous“. „Victimes“ für Kills → „Éliminations“ (PvP „Victoires honorables“). `SECTION_LEVEL_UP`/`ALERT_TOGGLE_LEVEL_UP` „Niveau“ allein → „Passage de niveau“. `ROW_LEVEL_ETA` → „Prochain niveau dans“. Buff „Bien nourri“ statt „rassasié“. `ROW_INSTANCES_TODAY` „auj.“ → „aujourd'hui“. `Locales/Locales.lua`
- [x] 192. **Begriff „Lauf“ kollidiert** (S): „Lauf“ steht für Speedrun-Versuch (`HISTORY_TAB_RUNS`, `RUNS_*`) und Instanz-Durchgang (`INSTANCE_RESET_*`, `TAB_INSTANCE_TIP`, `STAT_INSTANCE_RUN`); ebenso fr „course“/„expédition“, es „partida“/„incursión“. „Runs“ für Speedruns lassen, den Instanz-Lauf „Instanz-Durchgang“ (fr „Passage en instance“, es „Visita a la instancia“) nennen. Footer-Button „Instanz zurücksetzen“ liest sich wie der Spiel-Reset → „Instanz-Daten zurücksetzen“; die Rückfrage nennt, dass es die Daten des Laufs sind. `Locales/Locales.lua`
- [x] 193. **Falsche Bezeichnungen** (S): `STAT_GOAL` „Session-Ziel“ → „Ziel-Level“ (das Ziel gilt je Charakter); `STAT_SPLITS` „Splits gegen Bestzeit“ → „Splits (Vergleich)“, weil auch persönliche Bestzeit oder gewählter Lauf vergleichbar sind (alle vier Sprachen). `Locales/Locales.lua`
- [ ] 194. **Einheiten nicht lokalisiert** (M): `Format.Duration`, `Format.Clock`, `Format.Number` und `Format.Gold` schreiben „d h m s“, „k/M“ und „g“ fest; de/fr/es erwarten „T“, „j“ usw. Schlüssel `UNIT_DAY_SHORT` und Verwandte. `Lib/Format.lua:21`
- [x] 195. **Abschnitts- und Reiternamen** (S): `SECTION_GENERAL` kommt zweimal im Reiter „Allgemein“ vor (zweiter z.B. „Sprache & Minimap“); der Reiter „Einblendungen“ heißt in en „Alerts“, in es „Avisos“ wie ein anderer Abschnitt. `UI/Options.lua:184`
- [x] 196. **„Optionen“ und „Einstellungen“** (S): `SETTINGS` sagt „Options“/„Optionen“, `INTRO`, `HELP` und die Tooltips „réglages“/„ajustes“. Einen Begriff je Sprache wählen. `Locales/Locales.lua`
- [ ] 197. **Fest verdrahtete Texte** (S): `Broker.lua:25` schreibt „ XP/h“ fest (es: „PX/h“) → `L.ROW_XP_RATE`; die Split-Liste zeigt das Datum der Rekorde roh → lokalisiertes Datum. `UI/Broker.lua:25`, `Speedrun/SplitList.lua:93` **Teilweise: Erledigt: Broker nutzt `L.ROW_XP_RATE`. Offen: Datum der Rekorde in der Split-Liste lokalisieren.**

### UX

- [x] 198. **Chroma-Grün versteckt „schneller“** (S): Schnellere Splits sind in reinem Grün (`|cff40ff40`), der Chroma-Hintergrund ist reines Grün; in OBS wird die Schrift ausgestanzt. Bei grünem Hintergrund Cyan (`|cff4dd2ff`), optional Schattentext und ein blauer Chroma-Hintergrund; das Vorzeichen bleibt. `Lib/Format.lua:49`, `UI/TimerWindow.lua:41`, `Speedrun/SplitList.lua:218`
- [ ] 199. **Voreinstellungen ohne Rückmeldung** (S): `ApplyStatPreset` überschreibt alle Zeilen still, zeigt nicht, welche aktiv ist, und kennt kein Rückgängig. Chatzeile „Voreinstellung ‚Minimal‘ angewendet“, vorherigen Stand wie `streamBackup` merken. `UI/StatLines.lua:236` **Teilweise: Erledigt: Chatzeile „Voreinstellung … angewendet“. Offen: vorherigen Stand merken (Rückgängig).**
- [ ] 200. **Profile: stilles Überschreiben und leerer Name** (S): `Profiles.SaveAs` überschreibt ein gleichnamiges Profil ohne Rückfrage; ein leerer Name tut nichts, ohne Meldung. Rückfrage „Profil überschreiben?“, Meldung „Erst einen Namen eingeben“. `PROFILE_HINT` sagt außerdem nicht, dass Änderungen im geteilten Profil aller Charaktere landen, die es nutzen; ein Profilwechsel verschiebt Fenster und kann die Sprache ändern. `Core/Profiles.lua:109`, `UI/Options.lua:156` **Teilweise: Erledigt: leerer Name meldet sich, Überschreiben fragt nach, `PROFILE_HINT` nennt geteilte Profile. Offen: `/lt profile delete` ohne Rückfrage.**
- [ ] 201. **Befehle: Rückmeldung und Vorsicht** (S): `/lt reset` setzt Position und Größe beider Fenster ohne Meldung zurück; `/lt goal` ohne Zahl löscht das Ziel (besser: Status und Gebrauch zeigen, `/lt goal off` löscht); ein unbekannter Befehl zeigt die Hilfe, ohne „unbekannter Befehl“ zu sagen; `/lt profile delete` fragt nicht nach (die Oberfläche schon); `show`, `hide`, `compact`, `bar`, `splits`, `minimap` und `sync` melden nichts; `LOCKED`/`UNLOCKED` sind nackt („locked“) → „Fenster gesperrt/entsperrt“. `Core/Commands.lua:23` **Teilweise: Erledigt: `/lt reset` meldet, `/lt goal` zeigt den Stand und `/lt goal off` löscht, unbekannter Befehl wird gemeldet, `lock`/`unlock` mit klaren Texten. Offen: `show`/`hide`/`compact`/`bar`/`splits`/`minimap`/`sync` melden nichts, `/lt profile delete` ohne Rückfrage.**
- [x] 202. **Level- und Session-Reiter ohne Tooltip** (S): Nur der Instanz-Reiter erklärt sich. `TAB_LEVEL_TIP` („Zeit und Werte seit Beginn dieses Levels, /played des Servers“) und `TAB_SESSION_TIP` („Seit dem Login. /reload setzt fort, `/lt newsession` beendet“); die Bedeutung der Session steht sonst nirgends in der Oberfläche. `UI/TimerWindow.lua:53`
- [ ] 203. **Tabellenspalten schneiden ab** (M): Zellen sind mit `SetWordWrap(false)` fest breit; „Rare-Elite“ (Typ-Spalte 40 px), „Muertes“, „Misiones“, „Victimes“, „Abatidos“ passen nicht. Untergrenze aus der Kopf-Textbreite oder kurze Schlüssel. `Lib/TableView.lua:42`, `UI/HistoryTables.lua:155` **Teilweise: Erledigt: Typ-Spalte der Kills breiter. Offen: allgemeine Untergrenze aus der Kopf-Textbreite für die übrigen Spalten.**
- [x] 204. **Fenster liegen übereinander** (S): Einstellungen, Historie, Zusammenfassung und Export öffnen alle bei `CENTER`; „Historie“ im Footer verdeckt die Einstellungen und sieht nach „Einstellungen zu“ aus. Versetzt öffnen oder die Position je Fenster speichern. `Lib/OptionsBuilder.lua:69`, `UI/HistoryWindow.lua:32`, `UI/RecapWindow.lua:86`
- [ ] 205. **Leerer Zustand in Tabellen** (S): Charts zeigen „Noch keine Daten“, Tabellen nur Kopf und „Gesamt: 0“. Grauer Hinweis in `TableView`; den Unterreiter „Beinahe-Tode“ ausblenden, wo `NearDeath.IsAvailable` false ist (Retail: immer leer); Journal-Grenzen nennen. `Lib/TableView.lua` **Teilweise: Erledigt: leere Tabellen zeigen „Noch nichts aufgezeichnet“. Offen: Unterreiter „Beinahe-Tode“ ausblenden, wo `NearDeath.IsAvailable` false ist.**
- [x] 206. **Standardfenster ist voll** (S): Neun Zeilen sind standardmäßig an (XP/h, XP, Level-ETA, Max-Level-ETA, PvE-, PvP-Kills, Tode, Quests, Geld) plus Reiter und XP-Balken. Voreinstellung „Leveln“ als Start, oder PvP, Quests, Geld aus; das `INTRO` nennt die Voreinstellungen. `Core/Database.lua:24`
- [ ] 207. **Warnungen nutzen den Einblendungs-Look: Hinweis und Reiter** (S–M): Warnungen und Erinnerungen erscheinen mit Größe, Stil, Position und Ton aus dem Reiter „Einblendungen“, der Reiter „Hinweise“ sagt das nicht (`addHint("WARN_LOOK_HINT")`). Acht Reiter machen das Fenster in fr/es über 650 px breit; Einblendungen in „Stream“ oder „Hinweise“ zusammenlegen (7 Reiter) oder „Erweitert“ einführen. `UI/Options.lua:243`, `Lib/OptionsBuilder.lua:345` **Teilweise: Erledigt: Hinweis „Warnungen nutzen den Look aus dem Reiter Einblendungen“. Offen: Reiter zusammenlegen (acht Reiter).**
- [ ] 208. **Fußzeile: Neue Session und Instanz-Reset** (S): „Neue Session“ archiviert und setzt sofort zurück, ohne Rückfrage und ohne Hinweis auf „Die bisherige steht in der Historie“; „Instanz zurücksetzen“ steht auf jedem Reiter, ist aber nur in einer Instanz sinnvoll → in den Reiter „Statistiken“ verlegen. `UI/Options.lua:413` **Teilweise: Erledigt: „Instanz-Daten zurücksetzen“ steht jetzt im Reiter Statistiken (Gruppe Instanz). Offen: Rückfrage bei „Neue Session“ (die Chatzeile nennt die Historie schon).**
- [ ] 209. **Vorschau, Stream-Modus, Recap** (S): „Vorschau“ zeigt nur das Level-Up-Banner → bei jedem Klick die nächste Art (Rare, Elite, Beute, Beinahe-Tod, Warnung). `STREAM_MODE_TIP` („alle Stream-Einstellungen“) und `STREAM_MODE_ON` („Einblendungen an“) sind ungenau: es schaltet Level-Up, Rare, Beute, Beinahe-Tod und Namen verbergen ein. Die Zusammenfassungskarte kennt keinen Chroma-Hintergrund und aktualisiert sich nur beim Öffnen; im Stream-Reiter fehlt eine Abkürzung „Minimap-Button ausblenden“. `UI/Alerts.lua:308`, `UI/StreamMode.lua:12`, `UI/RecapWindow.lua:111` **Teilweise: Erledigt: Vorschau wechselt durch alle Arten, Stream-Modus-Texte genau. Offen: Zusammenfassungskarte mit Chroma-Hintergrund und Aktualisierung, Abkürzung „Minimap-Button ausblenden“ im Reiter Stream.**
- [x] 210. **Komfort-Tooltips mit Warnungen** (S): `AUTO_SELL_JUNK_TIP` soll sagen, dass sich Schrott beim Händler zurückkaufen lässt; `DECLINE_GROUP_INVITES`/`_GUILD_INVITES` lehnen auch Einladungen von Freunden und Gildenmitgliedern ab, sofern `Declines.lua` sie nicht ausnimmt (prüfen, im Tooltip nennen). `Assist/Declines.lua`
- [x] 211. **Rechtsklick uneinheitlich** (S): Rechtsklick aufs Fenster öffnet die Einstellungen, auf den Instanz-Reiter die Rückfrage zum Zurücksetzen, auf Level- und Session-Reiter nichts (der Klick wird geschluckt). Auf allen Reitern an die Einstellungen weitergeben oder in den Tooltips nennen. `UI/TimerWindow.lua:64`
- [ ] 212. **Tabellen: Sortierung und Verlinkung** (S): Der erste Klick auf einen Text-Spaltenkopf sortiert absteigend (Z–A); Sortieren ist nicht auffindbar (Hinweis „Klick auf den Kopf sortiert“); Gegenstands- und Quest-Links in Beute und Quests zeigen keinen Spiel-Tooltip. `Lib/TableView.lua:253` **Teilweise: Erledigt: Text-Spalten sortieren zuerst A–Z, Hinweis „Klick auf einen Spaltenkopf sortiert“. Offen: Spiel-Tooltip auf Gegenstands- und Quest-Links.**
- [ ] 213. **Historie aktualisiert jede Sekunde** (M): `refresh()` filtert und sortiert alle Einträge (bis 5000 Kills) jede Sekunde neu; mit Filtertext läuft `plainText` je Zelle. Nur den laufenden Eintrag oder nur bei Änderungen. (Ähnlich Roadmap 109; das dort Behobene gilt für die Tabelle, nicht für das Fenster.) `UI/HistoryWindow.lua:313` **Teilweise: Erledigt: `TableView` baut nur bei Änderung neu auf (Charakter, Sprache, Anzahl, jüngster Eintrag, spätestens alle 5 s). Offen: Zeitpunkt der Datenabfrage selbst.**
- [x] 214. **„Daten löschen“ nah an den Pfeilen** (S): Der Button liegt 6 px über dem „<“-Pfeil; mit Rückfrage nur ein Fehlklick-Risiko. In die Fußzeile oder rechts neben den Titel. `UI/HistoryWindow.lua:234`
- [ ] 215. **Split-Liste ohne Kopfzeile** (S): Zeilen aus Level, Zeit und Abweichung sind unbeschriftet; die Rekordzeilen zeigen ein rohes Datum. Kopfzeile „Level / Zeit / ±“ und Tooltip am Titel. `Speedrun/SplitList.lua`
- [ ] 216. **Kontrast und reine Farbinformation** (S): Hinweise in `GameFontDisableSmall` (Umschalttaste, Profile, Strg+C, Zeilenklick) sind schwer lesbar; aktive und inaktive Reiter unterscheiden sich nur durch Farbe (Gold gegen Grau) → Unterstreichung; die blaue Hervorhebung „aktuell/heute“ in den Charts hat keine Legende. `Lib/OptionsBuilder.lua:287`, `Lib/Widgets.lua:166`, `Lib/Charts.lua:11` **Teilweise: Erledigt: Hinweise heller (`Widgets.COLORS.muted`). Offen: Unterstreichung des aktiven Reiters, Legende der blauen Chart-Hervorhebung.**
- [x] 217. **Hilfe ohne Beschreibung** (S): `HELP` nennt Befehle wie `bar`, `compact`, `sync` ohne Erklärung; je Gruppe eine kurze Beschreibung („compact = nur Zeit, XP-Balken und XP/h“). `Locales/Locales.lua`

### Clean Code

- [ ] 218. **Gemeinsame Konstanten und Helfer** (S–M): `WHITE_TEXTURE` ist in `Widgets.lua`, `Alerts.lua` und `HistoryWindow.lua` dreimal definiert (`Widgets.WHITE_TEXTURE`); die Button-Polsterung 24 steht dreimal (`Widgets.BUTTON_TEXT_PADDING`); das Muster „StaticPopup mit Text zur Anzeigezeit“ ist in `Options.lua`, `HistoryWindow.lua` und `TimerWindow.lua` dreimal geschrieben (`Widgets.ConfirmPopup(name, textKey, onAccept)`); Mausrad-Scrollen mit Grenzen steht in `OptionsBuilder`, `TableView` und der Zeichenliste (`Widgets.CreateScrollArea`).
- [ ] 219. **`TimerWindow.lua` aufteilen** (M): 473 Zeilen mit drei Aufgaben (Fenster, Auto-Reiter, Rückfrage zum Zurücksetzen). Auto-Reiter und Dialog in `UI/InstanceReset.lua` neben `Instances.ResetCurrent`; `Instances.ConfirmReset` statt `ns.ConfirmInstanceReset`. `UI/TimerWindow.lua:326`
- [ ] 220. **`Alerts.lua` aufteilen** (M): 320 Zeilen mit Warteschlange und Anzeige, Position und Verschiebemodus sowie den Arten samt `Journal`-Auslösern (`UI/AlertPosition.lua`, `UI/AlertTriggers.lua`). `SetMoving` setzt `moving = false` nur, um an der Sperre in `Show` vorbeizukommen; `display` bekommt eine Umgehung statt Flag-Wechsel. `UI/Alerts.lua:201`
- [ ] 221. **`HistoryWindow.lua`: Charakterliste auslagern** (S): Rund 70 Zeilen Menü (Rahmen, Zeilen, Bildlauf, Klassenfarbe) inline, 340 Zeilen insgesamt, mit eigenem `RAID_CLASS_COLORS`-Zugriff, obwohl `HistoryTables.ClassColor` existiert, und fester Farbe `0.04, 0.05, 0.1, 0.98`. `UI/CharacterMenu.lua`. `UI/HistoryWindow.lua:140`
- [ ] 222. **Bereiche über Registrierung** (M): `Stats.IsOpen`/`IsCounting`/`GetSeconds` rufen `ns.Instances` zur Laufzeit auf (Tracking → History gegen die Schichtung). `Stats.RegisterScope(INSTANCE, { counters, seconds, isOpen, isCounting })`, `Instances` meldet sich selbst an. `Tracking/Stats.lua:52`
- [ ] 223. **`Instances.lua` aufräumen** (S): `upgrade()` wiederholt die Umwandlung xp/kills/deaths für `run` und `run.unconfirmed` (`convert(fields)`); `Summarize`/`ToRecord` kennen das alte Format dauerhaft (nach `upgrade` unnötig); der Merge hat drei Felder fest verdrahtet, jeder spätere Zähler geht verloren (über `Journal`-Eintrag mit vollen Zählern); `copyCounters` doppelt `Stats.Snapshot`/`Database.NewCounters` (`Database.CopyCounters`). `History/Instances.lua:21`
- [ ] 224. **Einstellungen nur über `ns.Set`** (S): `ApplyStatPreset` und `historyTab` schreiben direkt in `ns.db`, am Vertrag „über `ns.Set` ändern“ vorbei; ein Stapel-Setter im Kern oder ein Kommentar mit Begründung. `UI/StatLines.lua:236`, `UI/HistoryWindow.lua:55`
- [ ] 225. **`OptionsBuilder` ordnen** (S): Der Kommentar „Nach dem letzten Baustein: Höhe …“ steht über `maxPanelHeight` statt über `Finish`; `wantedHeight` ist zwischen Funktionen deklariert (an den Anfang von `New`); die Berechnung „breitester Text plus Polsterung mal Spalten“ steht in `footerWidth` und `buttonRowsWidth` doppelt (`fitButtons`). `Lib/OptionsBuilder.lua:292`
- [ ] 226. **Magische Zahlen und Farben** (S): `Alerts.lua`: Standarddauer 3 steht nackt in `duration()` und zusätzlich in `Database.lua` (`Alerts.DEFAULT_DURATION`), `RAID_WARNING_SOUND = 8959` fest (`SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959`), Hintergrundfarbe `0.03, 0.04, 0.08` als Literal, `setColor` entpackt zweimal und baut je Aufruf eine Tabelle. `Widgets.lua`: Button-Farben als Literale außerhalb von `Widgets.COLORS`. `UI/Alerts.lua:106`, `Lib/Widgets.lua:174`
- [ ] 227. **`TimerWindow`: kleine Dinge** (S): `layoutVertical` ruft `levelTab:ClearAllPoints()` zweimal; `instanceTab` bekommt seinen Klick nach der Erzeugung per `SetScript`, die anderen Reiter über `CreateTab` (zwei Muster); `timeText:SetText(not open and … or seconds and … or "...")` ist eine and/or-Kette, und `GetSeconds` wird vor `IsOpen` gelesen (`scopeTimeText(scope)`); `NO_VALUE = "-"` steht in `TimerWindow` und `StatLines` (`Format.NO_VALUE`). `UI/TimerWindow.lua:190`
- [ ] 228. **Stat-Gruppen und Voreinstellungen absichern** (S): `STAT_GROUPS` wiederholt die Schlüssel, die jede Stat-Zeile als `group` trägt (aus `STAT_LINES` ableiten); `STAT_PRESETS` nennt Einstellungen als Strings, ohne dass etwas deren Existenz prüft (Test). `UI/StatLines.lua:156`

### Wiederverwendbarkeit (Vorbereitung weiterer Addons)

Alle Dateien teilen eine `ns`-Tabelle; Einstellungen und Sprache werden über `ns.db`, `ns.L`, `ns.Set` gelesen, nichts ist von `addonName` abhängig. `Lib/` ist fachlich weitgehend sauber. Reihenfolge von klein und risikoarm zu groß.

- [ ] 229. **Lib ohne eingefangene Sprache und Einstellungen** (S): `OptionsBuilder` (`local L = ns.L`, `ns.Set`), `TableView` (`L.FILTER`, `L.EXPORT`, `ns.Export`) und `Export` (`L.*`, `ns.Print`) bekommen `L`, `get`, `set` und `print` über den Konstruktor. Die Tests laufen weiter, weil `ns` sie liefert. `Lib/OptionsBuilder.lua:10`, `Lib/TableView.lua:9`, `Lib/Export.lua:4`
- [ ] 230. **Globale Namen aus einer Addon-ID** (S): Fest verdrahtet sind `LevelTimerExport`, `LevelTimerAlert`, `LevelTimerMinimapButton`, `LevelTimerSplits`, `LevelTimerFrame`, `LevelTimer_OnAddonCompartmentClick` (steht in der `.toc`), die StaticPopup-Schlüssel und das Serializer-Kennzeichen `LT1:`. Aus einer ID ableiten; für LevelTimer bleiben die Werte gleich (Positionen, SavedVariables). `Lib/Export.lua:47`, `UI/Alerts.lua:49`, `UI/MinimapButton.lua:7,98`
- [ ] 231. **Migration, Defaults und Profile parametrisieren** (S): `migrate` und `applyDefaults` aus `Database.lua` als `Lib.Migrate.Run`/`Lib.Defaults.Apply` exportieren; `Profiles.New({ db, characterKey, applyDefaults, metaKeys })` statt Zugriff auf `ns.db`; `Database.lua:166` ruft `ns.Daily.Entry` (Migration hängt am Fachmodul) → Tagesschlüssel hineingeben. `Core/Profiles.lua:2`, `Core/Database.lua:223`
- [ ] 232. **`LevelTimer.lua` trennen** (M): Zeilen 10–136 (`Print`, `Debug`, `IsSecret`, `SafeCall`, `RegisterEvent`, `Every`, `OnLogin`, `OnLogout`, `RegisterApply`, `Set`) sind allgemein; ab 140 (`ns.character`, `ns.level`, `OnLevelCompleted/Started`, `DeleteCharacter`) fachlich → `Lib/Lifecycle.lua` und `Core/LevelTimer.lua`. Ladereihenfolge in der `.toc` und im Stub prüfen. `Core/LevelTimer.lua:10`
- [ ] 233. **Alerts, Minimap-Button und Befehle konfigurierbar** (M): `Alerts` in Warteschlange/Anzeige (allgemein) und Auslöser (`Journal`, `Classification`, Rare-/Elite-Regeln, bleiben im Addon); `MinimapButton.New({ name, getPos, setPos, icon, onClick, tooltip })`; `Commands.New(slashNames, table)` als Verteiler mit Hilfe, die Befehle liefert das Addon; `Commands.lua:119` fasst `LevelTimerStatsDB.introShown` direkt an. `UI/Alerts.lua:10`, `UI/MinimapButton.lua:33`, `Core/Commands.lua:3`
- [ ] 234. **Gemeinsame Bausteine statt Kopien** (M): Reiterzeilen sind dreimal gebaut (`OptionsBuilder`, `HistoryWindow` samt `layoutSubtabs`, `TimerWindow`) → eine `TabStrip` mit Umbruch; Speichern und Wiederherstellen von Fensterpositionen steht in `Widgets.CreatePanel`, `Alerts`, `MinimapButton`, `TimerWindow` und `SplitList` getrennt (`Widgets.MakeMovable(frame, getPos, setPos)`); Bildlauflisten in `OptionsBuilder`, `TableView` und `Options.lua` mit eigener Offset-Logik (`Widgets.CreateScrollArea`).
- [ ] 235. **`Shared/` auslagern und ein zweites Addon anbinden** (L): `Lib/` und die gelösten Teile nach `Shared/` (`Init(addonId, host)`, `host = { addonId, displayName, getSettings, set, L, iconPath }`), Aliase `ns.Widgets = Shared.Widgets` während der Umstellung; `.toc`, Installer (`assetDirs`), `.pkgmeta` und Stub-Lader anpassen (Client-Neustart). Einbindung per Git-Submodul oder `externals` des Packagers, nicht per Kopie (Drift). Vorher: Namenskonvention für gemeinsame Locale-Schlüssel, Locale-Test für die Shared-Texte, `alert*`- und `minimap`-Schlüssel account-kompatibel halten.

## v2.8.2: Komfort und Fixes aus dem Spiel

- [x] 145. **Chat kopieren** (S): `/lt copy` öffnet die Zeilen des aktuellen Chatfensters im Kopierfenster (ohne Farben, Links und Texturen; geheime Zeilen gezählt). Optional (Reiter Komfort, aus) ein Button „C“ oben rechts an jedem Chatfenster.
- [x] 146. **Ziehgriff an der Split-Liste** (S): Größe der Split-Liste wie beim Hauptfenster mit dem Griff unten rechts ändern (`Widgets.CreateResizeGrip`, gemeinsam für beide Fenster).
- [x] 147. **Einfügen im Import-Fenster** (S): Klick irgendwo in den Textbereich fokussiert das Eingabefeld; ein leeres mehrzeiliges Feld ist nur eine Zeile hoch, Strg+V ging sonst ins Leere (im Spiel gemeldet).
- [x] 148. **Buff-Hinweis im Bosskampf** (S): In Retail und WoW Forever bricht `C_UnitAuras.GetAuraDataByIndex` bei gesperrten Auren (Kampf, Bosskampf, Mythisch+, PvP) mit Fehler ab; der Food-/Camp-Hinweis fragt nur noch, wenn `C_Secrets.ShouldAurasBeSecret()` false ist, und fängt den Fehler sonst ab (im Spiel gemeldet).

## v2.8.1: Stabilität

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
- [x] 121. **Reset während man drin ist** (S): `InstanceCopy`: Reset-Meldung für die Instanz, in der man steht, löscht den Besuch; die nächste Bestätigung wirft einen Lua-Fehler und der Lauf endet mitten im Dungeon. Resets der eigenen Instanz ignorieren, Besuch notfalls anlegen. `Tracking/InstanceCopy.lua:101`
- [x] 122. **Erwartete zoneUID geht vor der Bestätigung verloren** (S): Bei „neu geschätzt“ steht die alte zoneUID nur im Speicher; /reload oder kurzes Rausgehen vor der Bestätigung macht Überzählung und getrennte Läufe dauerhaft. Erwartung im Besuch speichern. `Tracking/InstanceCopy.lua:86`
- [x] 123. **Normal und Heroisch als dieselbe Kopie** (M): Kopien nur am Namen erkannt; Wechsel Normal/Heroisch (TBC, Retail, Forever) innerhalb 30 min zählt nicht und mischt Läufe. Name plus `difficultyID` als Schlüssel. `Tracking/InstanceCopy.lua:134` — betrifft: TBC Anniversary, Retail, WoW Forever
- [x] 124. **Abweisung wegen Tageslimit** (S): Weist der Server wegen eines Tageslimits ab, meldet das Addon z.B. „2/5“. Meldung neutral formulieren bzw. Tageszahl nennen. `History/InstanceLimit.lua:117` — betrifft: Classic Era, TBC Anniversary, WoW Forever
- [x] 125. **Löschen des Charakters in der Instanz** (S): `ns.DeleteCharacter` in einer Instanz setzt `inside = nil`; bis zum nächsten Zonenwechsel wird nichts erfasst. Nach dem Login-Neustart aktuelle Instanz neu einlesen. `Tracking/InstanceCopy.lua:157`
- [x] 126. **Summe zählt XP von Leveln ohne Dauer** (S): `History.Summarize` addiert XP auch ohne `seconds` (/played fehlte), Gesamt-XP/h und Vergleich sind zu hoch. Nur Einträge mit Dauer in die Rate. `History/History.lua:226`
- [x] 127. **Vergleichslauf mit sich selbst** (S): Der gewählte Vergleichslauf ist accountweit; der Charakter, dessen Lauf gewählt ist, vergleicht sich mit seiner eigenen Kopie. Je Charakter speichern oder dort ausblenden. `Speedrun/Splits.lua:246`
- [x] 128. **Split-Liste springt beim Skalieren** (S): Größenänderung der Split-Liste (oder des Hauptfensters) verschiebt sie; wie beim Hauptfenster oben links festhalten. `Speedrun/SplitList.lua:278`
- [x] 129. **Läufe-Ansicht zeigt 0s** (S): Ohne abgeschlossenes Level des eingeloggten Charakters zeigt jede Zeile „0s“ bis zum aktuellen Level. Dann „-“ bzw. Gesamtzeit zeigen. `Speedrun/SpeedrunViews.lua:50`
- [x] 130. **Import verweigert alten Lauf nach Neustart** (S): Ein exportierter alter Versuch desselben Charakters wird beim Import als vorhanden abgelehnt, obwohl die Daten zurückgesetzt wurden. `Speedrun/Runs.lua:148`
- [x] 131. **Export ignoriert Streamer-Datenschutz** (S): Lauf-Export und Sicherung zeigen echten Namen und Realm trotz `streamerPrivacy`. `Speedrun/Runs.lua:103`
- [x] 132. **Escape-Sequenzen in importierten Namen** (S): Importierte Laufnamen mit `|H`, `|T`, `|c` werden ungefiltert angezeigt. Beim Import `|` entfernen bzw. verdoppeln. `Speedrun/Runs.lua:121`
- [x] 133. **Gesprächsoption doppelt gewählt** (S): `skipGossip` wählt die einzige Option, obwohl Blizzards GossipFrame sie per `selectOptionWhenOnlyOption` schon gewählt hat. `Assist/QuestAutomation.lua:126`
- [x] 134. **Gruppeneinladung mit Rollenwahl bleibt offen** (S): `declineGroupInvites` schließt in Retail/Forever das Rollen-Popup (`LFGInvitePopup`) bzw. die Quest-Session-Bestätigung nicht. `Assist/Declines.lua:212` — betrifft: Retail, WoW Forever
- [x] 135. **Duell bis zum Tod nicht abgelehnt** (S): `declineDuels` kennt `DUEL_TO_THE_DEATH_REQUESTED` (Hardcore, TBC Anniversary) nicht. `Assist/Declines.lua:217` — betrifft: Classic Era
- [x] 136. **Reparatur meldet zu wenig Gold** (S): Automatische Reparatur läuft vor dem Schrottverkauf und meldet „nicht genug Gold“, obwohl der Erlös gereicht hätte. Erst verkaufen, dann reparieren. `Assist/Merchant.lua:81`
- [x] 137. **XP-Balken bleibt am Max-Level** (S): Sichtbarkeit des XP-Balkens wird nur beim Anwenden der Einstellungen berechnet; nach dem Max-Level oder abgeschalteter XP bleibt er sichtbar. Bei `PLAYER_LEVEL_UP`/`ENABLE_XP_GAIN` neu prüfen. `UI/TimerWindow.lua:171`
- [x] 138. **Goldsymbole fehlen in Forever** (S): `Format.Money` nutzt das veraltete `GetCoinTextureString` (nur mit Kompatibilitäts-CVar, in Forever nie). `C_CurrencyInfo.GetCoinTextureString` bzw. eigene Formatierung. `Lib/Format.lua:77` — betrifft: WoW Forever
- [x] 139. **Zeitanzeige ab 100 Tagen abgeschnitten** (S): Breite der Zeitanzeige reicht für zweistellige Tage; bei 100+ Tagen wird abgeschnitten bzw. umgebrochen. `UI/TimerWindow.lua:29`
- [x] 140. **Sessions nach Level sortieren** (S): Spalte Level sortiert nach formatiertem Text mit gemischten Zahlen/Texten; Reihenfolge falsch. Numerischen Sortierschlüssel liefern. `UI/HistoryTables.lua:115`
- [x] 141. **Summenzeile in schmaler Spalte** (S): „Gesamt: N“ steht in Spalte 1, in den Speedrun-Tabellen nur 18–46 px breit und unlesbar. Über mehrere Spalten setzen. `UI/HistoryTables.lua:252`
- [x] 142. **Feste Breiten in der Historie** (M): Feste Button- und Spaltenbreiten im Historienfenster schneiden fr/es/de-Texte ab bzw. lassen sie überlaufen. Breiten aus Textbreite berechnen. `UI/HistoryWindow.lua:24`
- [x] 143. **Nur 6 Profile in der Liste** (M): Die Profilliste in den Einstellungen zeigt höchstens 6 Profile; weitere lassen sich dort nicht wählen oder löschen. Scrollbar oder Auswahlmenü. `UI/Options.lua:89`
- [x] 144. **Munitionshinweis in Forever** (S): Hinweis nimmt an, jeder Jäger außerhalb Retail braucht Munition; Forever hat `C_PaperDollInfo.AmmoNeeded`/`UnitUsesAmmo`. Diese nutzen, wo vorhanden. `Assist/GearWarnings.lua:39` — betrifft: WoW Forever

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

- v2.12.0: 239. „Kills/Quests bis Level-Up“ getrennt schaltbar (Community-Wunsch für No-Quest-Läufe)
- v2.11.0: 238. Fenster verschieben („Move Anything“): Standardfenster des Spiels ziehbar, Positionen gemerkt, Reset-Button
- v2.10.0: 236. Lagerfeuer-Countdown und -Hinweis (WoW Forever), 237. Hinweise als Karten (Satt fehlt, Taschen, Haltbarkeit, Munition, Lehrer, Instanzlimit); neue Bausteine `Lib/Auras.lua`, `Lib/Card.lua`, `Widgets.CreateMover`
- v2.9.0: 149.–160. Instanz-Reiter mit Leerzustand und Auto-Reiter, Erhaltene XP, Instanz-Daten zurücksetzen, XP/h-Fix für das laufende Level, Einblendungen gestalten (Banner, Größe, Dauer, Ton, Position, Warteschlange), Buttons im Addon-Stil, Stat-Gruppen und Voreinstellungen, scrollende Einstellungen, Charakterliste der Historie; Review-Funde 161–217 zu großen Teilen behoben (geheime Werte, geschützte Migrationen und Listener, Profil-Import mit Wertebereichen, Texte in allen Sprachen, Befehle mit Rückmeldung, Chroma-Cyan für Splits); offen: 175, 180, 186, 194, 215 und Clean-Code/Wiederverwendbarkeit 218–235
- v2.8.2: 145. Chat kopieren, 146. Ziehgriff an der Split-Liste, 147. Einfügen im Import-Fenster, 148. Buff-Hinweis im Bosskampf; Test-Stub mit den echten Reset-Texten
- v2.8.1: 95.–144. Stabilität aus dem Deep Review (Endlosschleife bei Zeitumstellung, Lua-Fehler durch geheime Werte, Beute in Retail, Session- und Erholt-XP, /played im Chat, alte Twinks, wiederholbare Quests, Gildenreparatur, Instanz-Kopien, Profile, Speedrun, Darstellung)
- v2.8.0: 78. Gedrosselter Ticker, 79. Taschen-Helfer, 80. Item-Helfer, 81. Hinweis-Helfer, 82. TableView, 83. OptionsBuilder, 84. Unterordner, 90. XP/h überall gleich, 91. Dungeon-Läufe, 92. Instanzlimit, 93. Instanz-Kopien erkennen, 94. Prognose mit XP-Tabelle; Anzeigename „Level Time“
- v2.6.0: 55. Automatisch reparieren, 56. Schrott verkaufen, 57. Quests annehmen, 58. Quests abgeben, 59. Gespräche überspringen, 60. Zeitaufteilung, 61. XP/h ohne AFK, 62. Aktuelle XP/h, 63. Kills/Quests bis Level-Up, 64. Erholt-Anzeige, 65. Ausgaben, 66. Taschen fast voll, 67. Haltbarkeit niedrig, 68. Lehrer besuchen, 69. Munition knapp, 70. Stream-Modus ohne Größe/Transparenz, 71. Keine Elite-Einblendung in Instanzen, 72. Keine Beute-Einblendung in Raids, 73.–76. Handel, Gruppen-, Gilden- und Duellanfragen ablehnen, 77. Level-Up-Ansage ohne /sagen
- v2.5.2: Fix der Zeile /played in der Split-Liste, 52. Erinnerungs-Abstand einstellbar, 53. Speedrun-Reiter, 54. Tooltips in den Einstellungen
- v2.5.0: 32. Neue Session starten, 31. Hardcore-Anzeige, 27. Stream-Ansicht, 33. Streamer-Datenschutz, 28. Session-Ziel, 29. Große Einblendungen, 30. Session-Abschlusskarte, 26. Splits, 34. Ansage in Gilde/Gruppe, 38. Rote Tode abschaltbar, 37. Stream-Modus, 35. Fester Vergleichslauf, 36. Split-Liste, 39. Hinweis bei fehlendem Food-Buff, 40. Hinweis bei fehlendem Camp-Buff, 41. Einstellungen mit Reitern, 42. Client-spezifische Optionen, 43. Level-Up-Ansage in /sagen, 44. Debug-Modus, 45. Split-Liste mit /played, 46. Fester Vergleich bleibt fest, 47. Läufe, 48. Rekorde, 49. Läufe teilen und sichern, 50. Einstellungs-Profile, 51. Speedrun-Rekorde
- v2.0.0:
  - Auswertung: 1. Prognose bis Max-Level, 2. alle Charaktere vergleichen, 3. Zonen-Auswertung, 4. Spielzeit pro Tag/Woche, 5. XP-Verlauf der Session, 6. Langzeit-Graphen als Tageswerte
  - Daten: 7. Quest-Journal, 8. Level-Timeline, 9. Instanzen, 10. Loot-Journal, 11. Elite- und Rare-Kills, 12. Beinahe-Tode, 24. Todesursache aus dem Death Recap (Retail, WoW Forever)
  - Bedienung: 13. Level-Up-Zusammenfassung, 14. XP-Balken, 15. Tabellen sortieren und filtern, 16. CSV-Export, 17. Daten löschen pro Charakter, 18. Kompaktmodus, 19. LibDataBroker-Datentext, 25. horizontale Leiste
  - Projekt: 21. Upload-Workflow für Wago und WoWInterface, 22. Tests bei jedem PR, 23. Französisch und Spanisch
