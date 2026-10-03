# Im Spiel zu prüfen

Was die Tests (WoW-Stub) nicht abdecken: echte API-Werte, Chatmeldungen des Servers und Darstellung.

**So füllst du das aus:** Befehle aus den grauen Blöcken in den Chat kopieren (ein Block = eine Zeile).
Die Ausgabe bzw. was du siehst in den Block **Antwort** darunter schreiben, Kästchen abhaken. Fehlende
Zeilen einfach leer lassen.

**Kopieren aus dem Chat:** `/lt copy` öffnet die Zeilen des aktuellen Chatfensters im Kopierfenster;
dort Strg+A, Strg+C. Mit Einstellungen → Komfort → „Chat kopieren“ gibt es dafür einen Button „C“ oben
rechts an jedem Chatfenster.

```
/lt copy
```

**Vorher einmal:** Fehler sichtbar machen und das Debug-Log einschalten (gilt bis `/reload`).

```
/console scriptErrors 1
```

```
/lt debug
```

---

## Schnellcheck: Werte des Clients

Diese Punkte gehen in wenigen Minuten an einem beliebigen Ort. Wenn möglich in **WoW Forever** und in
**Classic Era/Anniversary** prüfen.

### 1. Reset- und Limit-Texte vorhanden (Roadmap 93)

- [x] geprüft

```
/dump INSTANCE_RESET_SUCCESS, INSTANCE_RESET_FAILED, TRANSFER_ABORT_TOO_MANY_INSTANCES
```

**Erwartet:** drei Texte, z.B. „%s wurde zurückgesetzt.“; keiner `nil`.

**Antwort:**

```text
Client:
Ausgabe:
```

Client: Alle
Ausgabe:
[1]="'%s' wurde zurückgesetzt.",
[2]="'%s' kann nicht zurückgesetzt werden. Es halten sich noch Spieler in der Instanz auf.",
[3]="Ihr habt in letzter Zeit zu viele Instanzen betreten."

**Auswertung:** In Ordnung (alle Clients). Die deutschen Texte setzen den Namen in Anführungszeichen; das Muster liest den Namen trotzdem richtig, Test-Stub und Szenarien nutzen jetzt genau diese Texte.

### 2. Beute-Format (Roadmap 97)

- [x] geprüft

```
/dump LOOT_ITEM_SELF, LOOT_ITEM_PUSHED_SELF, LOOT_ITEM_SELF_MULTIPLE
```

**Erwartet:** Texte mit `%s`; ob am Ende ein Punkt steht, ist egal. Danach einen seltenen (blauen)
Gegenstand looten und in Historie → Journal → Beute nachsehen.

**Antwort:**

```text
Client:
Ausgabe:
Seltene Beute im Journal (ja/nein):
```

Client: Forever
Ausgabe:
[1]="Ihr erhaltet Beute: %s",
[2]="Ihr erhaltet einen Gegenstand: %s",
[3]="Ihr erhaltet Beute: %sx%d"

Selte Beute: Nicht geprüft

**Auswertung:** Forever: Beute-Texte ohne Punkt am Ende, genau der Fall aus Roadmap 97 (seit v2.8.1 behoben). Seltene Beute im Journal steht noch aus.

### 3. Gesundheit geheim? (Roadmap 103)

- [x] geprüft

Einmal außerhalb und einmal im Kampf ausführen (im Kampf z.B. per Makro auf einer Taste):

```
/dump issecretvalue(UnitHealth("player"))
```

**Erwartet:** in Forever/Retail laut Doku `true`; in Classic Era/TBC `false`. Ist es in Forever außerhalb
des Kampfs `false`, können Beinahe-Tode dort wieder eingeschaltet werden.

**Antwort:**

```text
Client: Forever
Außerhalb des Kampfs:
Dump: value=issecretvalue(UnitHealth("player"))
[1]=true
Im Kampf:
Dump: value=issecretvalue(UnitHealth("player"))
[1]=true
```

**Auswertung:** Forever: Gesundheit auch außerhalb des Kampfs geheim. Die Doku stimmt; Beinahe-Tode bleiben in Forever ausgeblendet (Roadmap 103).

### 4. XP-Tabelle passt (Roadmap 94)

- [x] geprüft

```
/dump UnitLevel("player"), UnitXPMax("player")
```

**Erwartet:** Wert aus der Tabelle in `History/XpTable.lua`. Classic Era, Anniversary (Classic) und Forever:
Level 10 = 7600, 20 = 23200, 30 = 47400, 40 = 90700, 50 = 147500. TBC Anniversary: 30 = 38800,
60 = 494000.

**Antwort:**

```text
Client: Forever
Level, XP-Bedarf: Dump: value=UnitLevel("player"), UnitXPMax("player")
[1]=21,
[2]=25200
```

**Auswertung:** Forever Level 21 = 25200, wie in der Classic-Tabelle. Die Prognose nutzt die XP-Tabelle.

### 5. Kein /played im Chat (Roadmap 101)

- [x] geprüft

```
/reload
```

**Erwartet:** nach dem Laden **keine** Zeile „Gesamtspielzeit …“ in keinem Chatfenster. Dann selbst:

```
/played
```

**Erwartet:** jetzt erscheinen die zwei Zeilen wie gewohnt; keine Fehlermeldung (BugSack).

**Antwort:**

```text
Client: Forever
Nach /reload Zeile im Chat (ja/nein): nein
Eigenes /played sichtbar (ja/nein): ja
Fehler: keiner
```

**Auswertung:** In Ordnung (Forever).

### 6. Kampflog-Funktion für die Todesursache (Roadmap 119, Classic Era/TBC)

- [x] geprüft

```
/dump C_CombatLog and C_CombatLog.GetCurrentEventInfo, CombatLogGetCurrentEventInfo
```

**Erwartet:** der erste Wert ist eine Funktion. Danach sterben (z.B. an einem Gegner) und in
Historie → Journal → Tode prüfen, ob der Gegner als Ursache steht.

**Antwort:**

```text
Client: Forever
Ausgabe:
Dump: value=C_CombatLog and C_CombatLog.GetCurrentEventInfo, CombatLogGetCurrentEventInfo
empty result
Todesursache im Journal:
When,Cause,Level,Zone
10/03 11:53:54,Hezrul Blutmal Estpolie (Blutegel),21,Brachland
```

**Auswertung:** Forever: keine Kampflog-Funktion für Addons (beide nil), wie erwartet; die Todesursache kommt dort aus dem Death Recap und steht im Journal. Classic Era/TBC noch offen.

### 7. Munition in Forever (Roadmap 144, als Jäger)

- [x] geprüft

```
/dump UnitUsesAmmo and UnitUsesAmmo("player"), C_PaperDollInfo and C_PaperDollInfo.AmmoNeeded and C_PaperDollInfo.AmmoNeeded()
```

**Erwartet:** mit Bogen/Gewehr `true`. Bei wenig Munition kommt der Hinweis nur, wenn hier `true` steht.

**Antwort:**

```text
Klasse, Waffe: Hunter, Bogen
Ausgabe:Dump: value=UnitUsesAmmo and UnitUsesAmmo("player"), C_PaperDollInfo and C_PaperDollInfo.AmmoNeeded and C_PaperDollInfo.AmmoNeeded()
[1]=true,
[2]=true
```

**Auswertung:** In Ordnung (Forever, Jäger mit Bogen): beide true.

### 8. Goldsymbole (Roadmap 138)

- [x] geprüft

Zeile „Einnahmen“ im Fenster ansehen (Einstellungen → Statistiken → Einnahmen an).

**Erwartet:** Münzsymbole statt „1g 2s 3c“, auch in Forever.

**Antwort:**

```text
Client: Forever
Symbole (ja/nein): ja
```

---

## Instanzen

**Auswertung:** In Ordnung (Forever).

### 9. Kopie wird an Gegnern erkannt (Roadmap 93)

- [ ] geprüft

Im Dungeon zwei verschiedene Gegner anvisieren. Mit `/lt debug` erscheint im Chat eine Zeile zur Kopie.
Die zoneUID eines Ziels von Hand:

```
/run print(select(5, strsplit("-", UnitGUID("target"))))
```

**Erwartet:** bei allen Gegnern derselben Instanz dieselbe Zahl.

**Antwort:**

```text
Client, Dungeon:
zoneUID von 2 Gegnern:
Debug-Zeile:
```

### 10. Reset ergibt neue Kopie (Roadmap 93)

- [ ] geprüft

Dungeon verlassen, als Gruppenleiter bzw. allein zurücksetzen (Rechtsklick auf das eigene Porträt →
Instanzen zurücksetzen), wieder rein, Gegner anvisieren und den Befehl aus Punkt 9 ausführen.

**Erwartet:** andere zoneUID; in Historie → Journal → Instanzen ein neuer Lauf, der alte beendet.

**Antwort:**

```text
zoneUID vorher / nachher:
Neuer Lauf (ja/nein):
```

### 11. Reset als Gruppenmitglied (Roadmap 93, 121)

- [ ] geprüft

In einer Gruppe setzt der Leiter zurück, (a) während du draußen bist, (b) während du noch drin bist.

**Erwartet:** (a) bei dir erscheint evtl. keine Reset-Meldung; beim nächsten Betreten erkennt das Addon die
neue Kopie an den Gegnern. (b) kein Lua-Fehler, dein Lauf läuft weiter.

**Antwort:**

```text
(a) Reset-Meldung bei dir (ja/nein, Text):
(a) Neuer Lauf nach Wiederbetreten (ja/nein):
(b) Fehler / Lauf weiter:
```

### 12. „Noch Spieler drin“ (Roadmap 93)

- [ ] geprüft

Leiter setzt zurück, während ein Mitglied noch drin ist.

**Erwartet:** Meldung „… kann nicht zurückgesetzt werden …“; für alle, die draußen sind, gilt die Instanz
trotzdem als zurückgesetzt (Annahme aus dem Code von Nova Instance Tracker).

**Antwort:**

```text
Meldung:
Beim Wiederbetreten neue zoneUID (ja/nein):
```

### 13. Tod im Dungeon (Roadmap 91)

- [ ] geprüft

Im Dungeon sterben, als Geist zum Friedhof und zurück laufen, an der Leiche wiederbeleben. Ein anderes Mal
beim Geistheiler draußen wiederbeleben.

**Erwartet:** Geisterlauf: derselbe Lauf, Zeile „Instanz“ zählt weiter (Einstellungen → Statistiken →
Instanz-Lauf an). Geistheiler draußen: Uhr bleibt stehen.

**Antwort:**

```text
Geisterlauf, gleicher Lauf (ja/nein):
Geistheiler, Uhr steht (ja/nein):
```

### 14. Händlergang (Roadmap 91)

- [ ] geprüft

Raus, ein paar Minuten draußen, wieder rein in dieselbe Instanz.

**Erwartet:** derselbe Lauf geht weiter; die Zeit draußen zählt nicht.

**Antwort:**

```text
Gleicher Lauf (ja/nein):
Zeit draußen mitgezählt (ja/nein):
```

### 15. Gruppenwechsel (Roadmap 93)

- [ ] geprüft

Innerhalb von 30 Minuten in die Kopie eines anderen Gruppenleiters wechseln (gleicher Dungeon), Gegner
anvisieren.

**Erwartet:** nach zwei Gegnern wird der Lauf geteilt (alter beendet, neuer läuft).

**Antwort:**

```text
Lauf geteilt (ja/nein):
```

### 16. Normal und Heroisch (Roadmap 123, TBC/Retail/Forever)

- [ ] geprüft

Normal betreten, raus, Schwierigkeit auf Heroisch stellen, wieder rein.

```
/dump GetInstanceInfo()
```

**Erwartet:** dritter Wert (difficultyID) unterscheidet sich; neuer Lauf und ein Eintrag mehr bei
„Instanzen/h“.

**Antwort:**

```text
Ausgabe Normal:
Ausgabe Heroisch:
Neuer Lauf (ja/nein):
```

### 17. Lebend raus, Retail/Forever ohne Fehler (Roadmap 93)

- [ ] geprüft

In Retail oder Forever einen Dungeon laufen und dabei Gegner anvisieren.

```
/dump issecretvalue(UnitGUID("target"))
```

**Erwartet:** kein Lua-Fehler; ist der Wert `true`, bleibt es bei der Schätzung.

**Antwort:**

```text
Client:
Ausgabe (im Kampf / außerhalb):
Fehler:
```

---

## Instanzlimit

### 18. Limit in WoW Forever (Roadmap 92)

- [ ] geprüft

Fünf verschiedene Instanzen innerhalb einer Stunde betreten (z.B. Dungeon betreten und zurücksetzen), dann
eine sechste.

**Erwartet:** die sechste wird abgewiesen; das Addon zeigt dabei „Server: zu viele Instanzen. Laut Addon
5/5 …“.

**Antwort:**

```text
Client:
Abgewiesen bei Nr.:
Text der Server-Meldung:
Zeile des Addons erschienen (ja/nein):
```

### 19. Hinweis bei 4/5 und 5/5 (Roadmap 92)

- [ ] geprüft

Einstellungen → Hinweise → Instanzlimit an, dann die vierte und fünfte Instanz betreten.

**Erwartet:** jeweils Einblendung und Chatzeile mit Wartezeit.

**Antwort:**

```text
Hinweis bei 4/5 (ja/nein):
Hinweis bei 5/5 (ja/nein):
```

### 20. Tageslimit (Roadmap 124)

- [ ] geprüft

Nur falls du je abgewiesen wirst, obwohl „Instanzen/h“ weniger als 5 zeigt.

**Antwort:**

```text
Instanzen/h laut Addon:
Instanzen heute laut Addon:
Text der Server-Meldung:
```

---

## Stabilität (v2.8.1)

### 21. Session-XP über einen Level-Up (Roadmap 100)

- [ ] geprüft

Vor einer großen Quest-Belohnung, die über eine Levelgrenze geht, die Session-XP notieren (Zeile
„Erfahrung“ in der Session-Zusammenfassung), Quest abgeben und erneut nachsehen:

```
/lt recap
```

**Erwartet:** Session-XP steigt um die volle Belohnung.

**Antwort:**

```text
Belohnung laut Quest:
Session-XP vorher / nachher:
```

### 22. Erholt-XP (Roadmap 102)

- [x] geprüft

Mit Erholt-Bonus vor und nach einem Kill:

```
/dump GetXPExhaustion(), UnitXP("player")
```

**Erwartet:** der erste Wert sinkt um Grund- plus Bonus-XP (doppelt so viel wie der Bonus im Chat).

**Antwort:**

```text
Vorher:
Dump: value=GetXPExhaustion(), UnitXP("player")
[1]=1216,
[2]=19782
Nachher:
Dump: value=GetXPExhaustion(), UnitXP("player")
[1]=1108,
[2]=19890
XP-Zeile im Chat:
Level Time: [debug] stats: combatSeconds +10.045000416227
Level Time: [debug] stats: pveKills +1
Level Time: [debug] stats: xpKills +108
Level Time: [debug] journal: killLog: Oasenschnappkiefer
Level Time: XP message counted as kill: Oasenschnappkiefer stirbt, Ihr bekommt 108 Erfahrung.
Level Time: [debug] stats: xpGained +108
Level Time: [debug] stats: xpRested +54
Level Time: [debug] stats: combatSeconds +2.0160001059994
Eure Fertigkeit 'Kürschnerei' hat sich auf 148 erhöht.
Ihr erhaltet Beute: [Verdorbene Lederfetzen]
```

```text
Vorher:
Dump: value=GetXPExhaustion(), UnitXP("player")
[1]=1108,
[2]=19890

Nachher:

Dump: value=GetXPExhaustion(), UnitXP("player")
[1]=972,
[2]=20026

XP-Zeile im Chat:

Level Time: [debug] stats: combatSeconds +10.060000490397
Level Time: [debug] stats: pveKills +1
Level Time: [debug] stats: xpKills +136
Level Time: [debug] journal: killLog: Oasenschnappkiefer
Level Time: XP message counted as kill: Oasenschnappkiefer stirbt, Ihr bekommt 136 Erfahrung.
Level Time: [debug] stats: xpGained +136
Level Time: [debug] stats: xpRested +68
Level Time: [debug] stats: combatSeconds +4.0260001625866

```

**Auswertung:** In Ordnung: der Pool sank um 108 bzw. 136 (Grund- plus Bonus-XP), gebucht wurde jeweils die Hälfte als Erholt-Bonus (54 bzw. 68). Genau das Verhalten aus Roadmap 102.

### 23. Gildenreparatur (Roadmap 107, TBC/Retail/Forever)

- [ ] geprüft

Komfort → Automatisch reparieren und „zuerst aus der Gildenbank“ an. **Ohne** vorher die Gildenbank zu
öffnen, beschädigt zum Händler.

**Erwartet:** die Gilde zahlt (Chatzeile „aus der Gildenbank“); reicht ihr Limit nicht, zahlt der Rest der
Charakter.

**Antwort:**

```text
Client:
Chatzeilen:
```

### 24. Wiederholbare Quests (Roadmap 108)

- [ ] geprüft

Mit Auto-Annehmen und Auto-Abgeben eine wiederholbare Abgabe-Quest besuchen (z.B. Runenstoff in einer
Hauptstadt).

**Erwartet:** nichts passiert automatisch, alle Gegenstände bleiben.

**Antwort:**

```text
NPC / Quest:
Automatisch abgegeben (ja/nein):
```

### 25. Levelcap der Erweiterung (Roadmap 118, Retail)

- [ ] geprüft

Charakter am Levelcap des Accounts (z.B. Trial oder ältere Erweiterung):

```
/dump UnitLevel("player"), UnitXPMax("player"), GameRulesUtil.IsPlayerAtEffectiveMaxLevel()
```

**Erwartet:** letzter Wert `true`; im Fenster kein XP-Balken, keine XP/h und Prognose.

**Antwort:**

```text
Ausgabe:
XP-Balken / XP/h sichtbar (ja/nein):
```

### 26. Beinahe-Tod nach Wiederbelebung (Roadmap 120, Classic Era/TBC)

- [ ] geprüft

Mit wenig Gesundheit wiederbeleben (Geistheiler, Seelenstein, niedriger Wiederbelebungszauber) und danach
heilen.

**Erwartet:** kein neuer Beinahe-Tod (Zeile „Beinahe-Tode“ bleibt gleich).

**Antwort:**

```text
Beinahe-Tode vorher / nachher:
```

### 27. Split-Liste skalieren (Roadmap 128)

- [x] geprüft

```
/lt splits
```

Dann Speedrun → Größe der Split-Liste ändern, und die Größe des Hauptfensters ändern.

**Erwartet:** die Split-Liste bleibt mit ihrer linken oberen Ecke stehen.

**Antwort:**

```text
Springt (ja/nein): bleibt in ihrer ecke stehen. Aber es fehlt der "drag to scale" button wie im hauptfenster des addons.
```

**Auswertung:** Bleibt stehen. Der fehlende Ziehgriff ist nachgerüstet (Roadmap 146): unten rechts an der Split-Liste wie am Hauptfenster; bitte einmal ausprobieren.

### 28. Importierte Laufnamen (Roadmap 132)

- [ ] geprüft

```
/lt runs import
```

Diesen Text einfügen und importieren (ein Lauf namens Test mit Farbcode im Namen, Level 10 in 100 s):

```
LT1:run:{sname=s%7Ccffff0000Test%7Cr,stimes={n10=n100}}
```

**Erwartet:** der Name erscheint ohne Farbe, als `cffff0000Testr`.

**Antwort:** Ich kann keinen Text in "Import runs" fenster kopieren - es passiert nichts auch kein LUA fehler

```text
Import-Meldung:
Name in Historie → Speedrun → Läufe:
```

**Auswertung:** Fehler bestätigt, Ursache vermutet: ein leeres mehrzeiliges Eingabefeld ist nur eine Zeile hoch; ein Klick in den freien Bereich trifft es nicht, Strg+V geht dann ins Leere. Jetzt fokussiert jeder Klick in den Textbereich das Feld (Roadmap 147). Bitte erneut prüfen; klappt es weiterhin nicht, bitte sagen, ob ein Textcursor im Feld blinkt.

### 29. Gespräch mit einer Option (Roadmap 133)

- [ ] geprüft

Komfort → Gespräche überspringen an, einen NPC mit genau einer Option ansprechen (z.B. Flugmeister,
Gastwirt mit nur „Händler“).

**Erwartet:** die Option wird einmal gewählt, kein Fehler.

**Antwort:**

```text
NPC:
Ergebnis:
```

### 30. Zeit ab 100 Tagen (Roadmap 139)

- [ ] geprüft

Nur falls du einen Charakter mit 100+ Tagen auf dem aktuellen Level hast (meist Max-Level).

**Erwartet:** die Zeitanzeige ist vollständig.

**Antwort:**

```text
Anzeige vollständig (ja/nein):
```

### 31. Summenzeile Speedrun (Roadmap 141)

- [ ] geprüft

```
/lt history
```

Reiter Speedrun → Läufe und Rekorde.

**Erwartet:** „Gesamt: N“ unten lesbar.

**Antwort:**

```text
Lesbar (ja/nein):
```

### 32. Texte in Historie und Einstellungen (Roadmap 142, Darstellung)

- [x] geprüft

Sprache in Einstellungen → Allgemein nacheinander auf Français, Español, Deutsch stellen; Historie und
Einstellungen öffnen:

```
/lt history
```

```
/lt config
```

**Erwartet:** Buttons „Daten löschen“ und „Als Profil speichern“ ganz lesbar; das Sortierzeichen (v/^) steht vor
dem Spaltennamen. Neue Zeilen „Instanz“, „Instanzen/h“, „Instanzen heute“ und ihre Schalter mit Tooltip
passen in allen Sprachen, auch in der horizontalen Leiste (`/lt bar`).

**Antwort:**

```text
Abgeschnitten (Sprache, Stelle): alles top
```

**Auswertung:** In Ordnung (alle Sprachen).

### 33. Zeitumstellung (Roadmap 95)

- [ ] geprüft

Am Sonntag, 25.10.2026, zwischen 23 und 24 Uhr ausloggen oder `/reload`, bzw. Historie → Graphen →
Spielzeit pro Tag öffnen.

**Erwartet:** kein Hänger.

**Antwort:**

```text
Hänger (ja/nein):
```

### 34. XP/h ohne AFK überall gleich (Roadmap 90)

- [ ] geprüft

Einstellungen → Statistiken → „XP/h ohne AFK-Zeit“ an; ein paar Minuten AFK, dann leveln.

**Erwartet:** Vergleich der Charaktere, Graph „XP/h je Level“ und die Level-Up-Zeile im Chat zeigen dieselbe
Rate wie Fenster und Level-Tabelle.

**Antwort:**

```text
Abweichung (wo, Werte):
```

### 35. Prognose plausibel (Roadmap 94)

- [ ] geprüft

Nach ein paar Leveln die Zeile „Max-Level in“ mit deinem Gefühl vergleichen.

**Erwartet:** eher etwas zu lang.

**Antwort:**

```text
Level, Prognose:
Einschätzung:
```

### 36. Chat kopieren (Roadmap 145)

- [ ] geprüft

Einstellungen → Komfort → „Chat kopieren“ an, Button „C“ oben rechts im Chatfenster anklicken; ohne
Button:

```
/lt copy
```

**Erwartet:** Kopierfenster mit den Zeilen des Fensters, älteste oben, ohne Farbcodes; Links als
`[Name]`. Der Button verdeckt nichts Wichtiges und erscheint in jedem Chatfenster (auch Reitern wie
„Kampflog“).

**Antwort:**

```text
Client:
Zeilen vollständig (ja/nein):
Button stört (wo):
Fehler:
```

---

## Errors

### When starting boss fight

Message: GetAuraDataByIndex(): Auras cannot be accessed when secret while tainted by 'LevelTimer'
Lua Taint: LevelTimer
Time: Sat Oct 3 12:27:23 2026
Count: 1
Stack:
[C]: in function 'xpcall'
[Interface/AddOns/LevelTimer/Core/LevelTimer.lua]:42: in function 'SafeCall'
[Interface/AddOns/LevelTimer/Core/LevelTimer.lua]:116: in function <Interface/AddOns/LevelTimer/Core/LevelTimer.lua:109>

Locals:

Message: GetAuraDataByIndex(): Auras cannot be accessed when secret while tainted by 'LevelTimer'
Lua Taint: LevelTimer
Time: Sat Oct 3 12:27:23 2026
Count: 2
Stack:
[C]: in function 'xpcall'
[Interface/AddOns/LevelTimer/Core/LevelTimer.lua]:42: in function 'SafeCall'
[Interface/AddOns/LevelTimer/Core/LevelTimer.lua]:116: in function <Interface/AddOns/LevelTimer/Core/LevelTimer.lua:109>

Locals:
