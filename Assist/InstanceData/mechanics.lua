-- GENERIERT von tools/mechanics ("make mechanics"), nicht von Hand bearbeiten.
-- Quelle: Guide-Recherche docs/research/mechanics/*.json (je Instanz eine Datei), siehe sources.md.
-- ns.Mechanics = { [npcID] = { { spellID, Typ, Text deDE, Text enUS }, ... } }
--   spellID 0 = keine passende Zauber-ID (Zeile ohne Zaubersymbol), Typ: avoid, interrupt, dispel, tank, survive, adds,
--   positioning. Deutsche Clients lesen den deutschen Text, alle anderen (auch frFR/esES) den englischen; die Texte
--   laufen bewusst nicht über Locales (Spieldaten, kein UI-Text). Leser: Assist/Mechanics.lua.
local _, ns = ...
-- Nur Classic Era und Forever: klassische Instanzen, Retail hat andere Fähigkeiten an denselben NPCs.
local flavor = ns.Client.Flavor()
if flavor ~= "forever" and flavor ~= "classic_era" then return end

ns.Mechanics = {
  [639] = { -- Edwin VanCleef (The Deadmines)
    { 5200, "adds", "Ruft bei wenig Leben zwei Schwarzwachen: kontrollieren oder töten", "Calls two Blackguards at low health: control or kill them" },
    { 3391, "tank", "Erhält Extraangriffe: Schadensspitzen auf dem Tank", "Gains extra attacks: burst damage on the tank" },
  },
  [642] = { -- Sneed's Shredder (The Deadmines)
    { 7399, "survive", "Furcht 4 Sek.: nicht in weitere Gegner laufen", "Fears a player for 4 sec: avoid running into extra mobs" },
    { 3603, "survive", "Verlangsamt Zauber um 35 %: mit längeren Zaubern rechnen", "Slows a caster's casting by 35%: plan longer casts" },
    { 5141, "adds", "Sneed springt beim Tod des Schredders heraus: als Nächstes töten", "Sneed jumps out when the shredder dies: kill him next" },
  },
  [643] = { -- Sneed (The Deadmines)
    { 6713, "tank", "Entwaffnet den Tank: kurz weniger Bedrohung einplanen", "Disarms the tank: expect lower threat for a few seconds" },
  },
  [644] = { -- Rhahk'Zor (The Deadmines)
    { 6304, "tank", "Hieb betäubt den Tank 3 Sek.: Tank voll geheilt halten", "Slam stuns the tank for 3 sec: keep the tank topped up" },
  },
  [645] = { -- Cookie (The Deadmines)
    { 6306, "avoid", "Naturschaden um ihn 30 Sek. lang: Fernkämpfer halten Abstand", "Nature damage around him for 30 sec: ranged keep away" },
    { 5174, "interrupt", "Heilt sich selbst: Kochen unterbrechen", "Heals himself: interrupt the cooking" },
  },
  [646] = { -- Mr. Smite (The Deadmines)
    { 6432, "survive", "Betäubt bei 75 % und 50 % die Gruppe: vorher hochheilen", "Stuns the whole group at 75% and 50%: heal up before" },
    { 0, "adds", "Getarnte Wachen an der Rampe vor dem Pull beseitigen", "Clear the stealthed guards at the ramp before the pull" },
  },
  [647] = { -- Captain Greenskin (The Deadmines)
    { 5208, "dispel", "Vergiftet einen Spieler per Harpune: Gift heilen", "Poisons a player with his harpoon: cure poison" },
    { 40505, "positioning", "Spaltet nach vorne: nur der Tank steht vor ihm", "Cleaves in front: only the tank faces him" },
  },
  [1663] = { -- Dextren Ward (The Stockade)
    { 19134, "survive", "Furchterregender Ruf: 6 Sek Furcht für Nahe; Zusatzpulls vermeiden", "Frightening Shout fears nearby players for 6 sec; avoid extra pulls" },
  },
  [1666] = { -- Kam Deepfury (The Stockade)
    { 8242, "tank", "Schildschlag betäubt den Tank 2 Sek", "Shield Slam stuns the tank for 2 sec" },
    { 871, "survive", "Schildwall senkt erlittenen Schaden 12 Sek um 60 %; Burst aufheben", "Shield Wall cuts his damage taken by 60% for 12 sec; hold burst" },
  },
  [1696] = { -- Targorr the Dread (The Stockade)
    { 3391, "tank", "Dreschen gibt Extraangriffe; Tankschaden kommt in Spitzen", "Thrash grants extra attacks; spiky tank damage" },
    { 8599, "tank", "Wutanfall erhöht Schaden und Tempo; Tank stärker heilen", "Enrage raises his damage and attack speed; heal the tank harder" },
  },
  [1716] = { -- Bazil Thredd (The Stockade)
    { 7964, "avoid", "Rauchbombe betäubt alle in seiner Nähe 4 Sek", "Smoke Bomb stuns everyone near him for 4 sec" },
    { 9128, "tank", "Schlachtruf erhöht die Angriffskraft naher Verbündeter", "Battle Shout boosts nearby allies' attack power" },
  },
  [1717] = { -- Hamhock (The Stockade)
    { 421, "interrupt", "Kettenblitz unterbrechen, springt auf drei Spieler", "Interrupt Chain Lightning, it jumps to three players" },
    { 6742, "dispel", "Kampfrausch von ihm oder Verbündeten reinigen", "Purge Bloodlust from him or his allies" },
  },
  [1763] = { -- Gilnid (The Deadmines)
    { 5213, "dispel", "Verbrennt und verlangsamt einen Spieler: gegenheilen", "Burns and slows a player: heal through it" },
    { 5159, "avoid", "Geschmolzenes Erz auf Nahen stapelt: Fernkämpfer bleiben hinten", "Molten ore on nearby players stacks: ranged stay back" },
  },
  [1853] = { -- Darkmaster Gandling (Scholomance)
    { 17950, "adds", "Teleportiert Spieler in Nebenräume mit Adds; freikämpfen", "Ports players into side rooms with adds; fight out" },
    { 18702, "dispel", "Seinen Fluch entfernen", "Remove his curse" },
    { 12040, "tank", "Schirmt sich ab; Nahkämpfer halten Aggro, Fernkämpfer auf Treppe", "Shields himself; melee keep threat, ranged on stairs" },
  },
  [2748] = { -- Archaedas (Uldaman)
    { 0, "adds", "Weckt alle 10 Sek. einen Irdenen; flächig töten oder abtanken", "Wakes an Earthen Custodian every 10 sec; AoE or off-tank" },
    { 0, "adds", "Bei 66 % erwachen sechs Wächter mit Wirbelwind; Boss fokussieren", "At 66% six Guardians wake and whirlwind; burn the boss" },
    { 0, "survive", "Erdbeben betäubt alle Spieler in der Nähe", "Ground Tremor stuns all nearby players" },
  },
  [3654] = { -- Mutanus the Devourer (Wailing Caverns)
    { 7967, "survive", "Schläfert einen Spieler bis 15 Sek. ein: Treffer weckt auf", "Sleeps one player up to 15 sec: hit them to wake them" },
    { 7399, "survive", "Furcht 4 Sek. auf ein Ziel: auf zusätzliche Gegner achten", "Fears a target for 4 sec: watch for extra pulls" },
    { 8150, "avoid", "Naturstoß betäubt Nahe: Fernkämpfer bleiben auf Distanz", "Nature blast stuns nearby players: ranged stay at range" },
  },
  [3669] = { -- Lord Cobrahn (Wailing Caverns)
    { 7965, "tank", "Wird zur Schlange und schlägt im Nahkampf härter zu", "Turns into a serpent and hits harder in melee" },
    { 744, "dispel", "Vergiftet in Schlangengestalt: Gift heilen", "Poisons in serpent form: cure poison" },
    { 8040, "interrupt", "Schläfert Spieler ein: Zauber unterbrechen", "Sleeps a player: interrupt the cast" },
  },
  [3670] = { -- Lord Pythas (Wailing Caverns)
    { 8147, "avoid", "Naturstoß in 10 m verlangsamt: Fernkämpfer halten Abstand", "Nature blast within 10 yd slows: ranged keep their distance" },
    { 8040, "interrupt", "Schläfert Spieler ein: Zauber unterbrechen", "Sleeps a player: interrupt the cast" },
    { 11431, "interrupt", "Heilt sich selbst: Heilung unterbrechen", "Heals himself: interrupt the heal" },
  },
  [3671] = { -- Lady Anacondra (Wailing Caverns)
    { 8040, "interrupt", "Schläfert Spieler 6 Sek. ein: Zauber unterbrechen", "Sleeps a player for 6 sec: interrupt the cast" },
    { 23381, "interrupt", "Heilt sich selbst: Unterbrechung für die Heilung aufheben", "Heals herself: save an interrupt for the heal" },
    { 8148, "survive", "Dornen verletzen Nahkämpfer: Heiler achten auf Nahkämpfer", "Thorns hurt melee attackers: healers watch melee health" },
  },
  [3673] = { -- Lord Serpentis (Wailing Caverns)
    { 700, "interrupt", "Schlaf bis 20 Sek.: unterbrechen, Schaden weckt auf", "Sleeps a player up to 20 sec: interrupt, damage wakes" },
    { 23381, "interrupt", "Große Selbstheilung: immer unterbrechen", "Large self heal: always interrupt" },
  },
  [3674] = { -- Skum (Wailing Caverns)
    { 6254, "interrupt", "Blitz springt auf bis zu 3 Spieler: unterbrechen", "Bolt jumps to up to 3 players: interrupt it" },
  },
  [3887] = { -- Baron Silverlaine (Shadowfang Keep)
    { 7068, "dispel", "Senkt erhaltene Heilung 15 Sek. um 75 %: Fluch entfernen", "Cuts healing taken by 75% for 15 sec: remove the curse" },
  },
  [3914] = { -- Rethilgore (Shadowfang Keep)
    { 7295, "survive", "Fesselt einen Spieler 10 Sek. und saugt Leben: gegenheilen", "Roots a player for 10 sec and drains health: heal them" },
  },
  [3927] = { -- Wolf Master Nandos (Shadowfang Keep)
    { 7487, "adds", "Ruft Worgs und einen Wolfsschrecken: Adds tanken und töten", "Calls worgs and a Lupine Horror: tank and kill the adds" },
  },
  [3974] = { -- Houndmaster Loksey (Scarlet Monastery: Library)
    { 6742, "adds", "Kommt mit Hunden und beschleunigt sie; Hunde AoE oder CC", "Comes with hounds and speeds them up; AoE or CC the dogs" },
    { 77808, "tank", "Ruf erhöht seinen Nahkampfschaden; Tank mit Cooldowns", "Shout raises his melee damage; tank with cooldowns" },
  },
  [3975] = { -- Herod (Scarlet Monastery: Armory)
    { 8989, "avoid", "Wirbelt magieimmun; alle außer Tank weglaufen", "Spins with magic immunity; everyone but tank runs away" },
    { 8269, "tank", "Bei wenig Leben schnellere Angriffe; Tank-Cooldowns sparen", "Attack speed jumps at low health; save tank cooldowns" },
    { 0, "adds", "Nach dem Tod 20 schwache Rekruten; AoE nutzen", "Twenty weak trainees spawn on death; use AoE" },
  },
  [3976] = { -- Scarlet Commander Mograine (Scarlet Monastery: Cathedral)
    { 5589, "survive", "Betäubt Spieler; Heiler nicht lange ausfallen lassen", "Stuns a player; healer must not be locked out long" },
    { 1020, "tank", "Gottesschild bei wenig Leben; weitertanken", "Bubbles at low health; keep tanking, swap to Whitemane" },
    { 9257, "survive", "Nach Wiederbelebung heilt er Weißkrähe voll", "After Whitemane revives him he fully heals her" },
  },
  [3977] = { -- High Inquisitor Whitemane (Scarlet Monastery: Cathedral)
    { 0, "survive", "Bei halbem Leben schläft die ganze Gruppe 8 Sek.", "At half health she sleeps the whole party for 8 sec" },
    { 0, "survive", "Belebt Mograine im Schlaf; beide kommen voll zurück", "Revives Mograine while you sleep; both return full" },
    { 0, "dispel", "Kann Spieler übernehmen; bannen oder kontrollieren", "Can mind control a player; dispel or CC them" },
  },
  [3983] = { -- Interrogator Vishas (Scarlet Monastery: Graveyard)
    { 9034, "dispel", "Feuer-DoT auf Spieler; bannen oder gegenheilen", "Fire DoT on a player; dispel or heal through it" },
    { 14032, "dispel", "Schatten-DoT; Magiebannung entfernt ihn", "Shadow DoT; magic dispel removes it" },
  },
  [4274] = { -- Fenrus the Devourer (Shadowfang Keep)
    { 7125, "dispel", "Gift entzieht Mana und macht Naturschaden: Gift heilen", "Poison drains mana and deals nature damage: cure poison" },
  },
  [4275] = { -- Archmage Arugal (Shadowfang Keep)
    { 7621, "survive", "Verwandelt einen Spieler 10 Sek. in einen Worgen: nicht angreifen", "Turns a player into a worgen for 10 sec: avoid hitting them" },
    { 7803, "avoid", "Naturstoß betäubt Nahe: Abstand halten", "Nature burst stuns nearby players: keep distance" },
    { 7588, "interrupt", "Starker Schattenblitz: unterbrechen oder Ziel heilen", "Heavy shadow bolt: interrupt or heal the target" },
  },
  [4278] = { -- Commander Springvale (Shadowfang Keep)
    { 1026, "interrupt", "Heilt sich mit Heiligem Licht: unterbrechen", "Heals himself with Holy Light: interrupt it" },
    { 5588, "survive", "Betäubt einen Spieler 4 Sek.", "Stuns a player for 4 sec" },
  },
  [4279] = { -- Odo the Blindwatcher (Shadowfang Keep)
    { 7481, "tank", "Schaden steigt mit jedem Heulen: schnell töten", "Damage rises with each howl: burn him down fast" },
  },
  [4420] = { -- Overlord Ramtusk (Razorfen Kraul)
    { 15548, "survive", "Donnerknall schadet und verlangsamt Nahe; Nahkämpfer heilen", "Thunderclap damages and slows everyone close; melee heal up" },
    { 9128, "tank", "Schlachtruf erhöht die Angriffskraft seiner Gruppe", "Battle Shout raises his group's attack power" },
  },
  [4421] = { -- Charlga Razorflank (Razorfen Kraul)
    { 8292, "interrupt", "Kettenblitz unterbrechen, springt zwischen Spielern", "Interrupt Chain Bolt, it jumps between players" },
    { 6077, "dispel", "Erneuerung bei ihr reinigen", "Purge Renew from her" },
  },
  [4422] = { -- Agathelos the Raging (Razorfen Kraul)
    { 8269, "tank", "Raserei verstärkt seine Angriffe; Tank spart Cooldowns dafür", "Frenzy boosts his attacks; tank saves cooldowns for it" },
  },
  [4424] = { -- Aggem Thorncurse (Razorfen Kraul)
    { 14900, "interrupt", "Kettenheilung unterbrechen", "Interrupt Chain Heal" },
    { 8286, "adds", "Ruft einen Ebergeist als Add", "Summons a Boar Spirit add" },
  },
  [4428] = { -- Death Speaker Jargba (Razorfen Kraul)
    { 14515, "dispel", "Übernimmt einen Spieler; bannen oder kontrollieren", "Mind controls a player; dispel or crowd-control them" },
    { 9613, "interrupt", "Schattenblitz unterbrechen", "Interrupt Shadow Bolt" },
  },
  [4542] = { -- High Inquisitor Fairbanks (Scarlet Monastery: Cathedral)
    { 22678, "survive", "Furcht auf Spieler; nicht in weitere Gruppen laufen", "Fears a player; avoid running into extra pulls" },
    { 12039, "interrupt", "Heilt sich selbst; Heilung unterbrechen", "Heals himself; interrupt his Heal" },
    { 8282, "dispel", "Fluch erhöht erlittenen Schaden; entfluchen", "Curse adds physical damage taken; decurse" },
  },
  [4543] = { -- Bloodmage Thalnos (Scarlet Monastery: Graveyard)
    { 12470, "positioning", "Feuerstoß um ihn; Fernkampf und Heiler halten Abstand", "Fire burst around him; ranged and healer keep distance" },
    { 23038, "survive", "Sofortiger Feuertreffer mit Brand auf sein Ziel", "Instant fire hit plus burn on his target" },
    { 20825, "interrupt", "Wirkt Schattenblitz; unterbrechen spart Schaden", "Casts Shadow Bolt; kick it to cut damage" },
  },
  [4829] = { -- Aku'mai (Blackfathom Deeps)
    { 3815, "avoid", "Giftwolke macht Naturschaden um sie herum; Gift entfernen", "Poison Cloud ticks nature damage around her; cure poison" },
    { 3490, "tank", "Rasende Wut erhöht ihr Angriffstempo stark; Tank nutzt Cooldowns", "Frenzied Rage speeds her attacks a lot; tank uses cooldowns" },
  },
  [4830] = { -- Old Serra'kis (Blackfathom Deeps)
    { 8433, "survive", "Unterwasserkampf: Blutegelpuls entzieht allen Nahen Leben; Atem beachten", "Underwater fight: Leech Pulse drains everyone near him; watch breath" },
  },
  [4831] = { -- Lady Sarevess (Blackfathom Deeps)
    { 865, "avoid", "Frostnova friert Nahe ein; Fernkämpfer und Heiler halten Abstand", "Frost Nova roots everyone close; ranged and healers keep range" },
  },
  [4832] = { -- Twilight Lord Kelris (Blackfathom Deeps)
    { 8399, "positioning", "Schlaf trifft Spieler im 5-m-Radius; Heiler und Fernkämpfer weiter weg", "Sleep hits players within 5 yd; healer and ranged stand farther" },
    { 15587, "interrupt", "Gedankenschlag unterbrechen", "Interrupt Mind Blast" },
  },
  [4842] = { -- Earthcaller Halmgar (Razorfen Kraul)
    { 2484, "positioning", "Totem der Erdbindung verlangsamt; Totem zerstören", "Earthbind Totem slows everyone; destroy the totem" },
    { 8270, "adds", "Ruft einen Steingrollen als Add", "Summons a Stone Rumbler add" },
  },
  [4854] = { -- Grimlok (Uldaman)
    { 0, "dispel", "Schrumpfen ist ein Fluch, der schwächt; entfluchen", "Shrink is a curse that weakens a player; decurse it" },
    { 0, "interrupt", "Kettenblitz und Blitzschlag unterbrechen", "Interrupt his Chain Bolt and Lightning Bolt casts" },
    { 0, "dispel", "Kampfrausch von ihm oder seinem Basilisken bannen", "Purge Bloodlust from him or his basilisk" },
  },
  [4887] = { -- Ghamoo-ra (Blackfathom Deeps)
    { 5568, "positioning", "Trampeln trifft auch Spieler neben dem Tank; Nahkämpfer verteilen", "Trample also hits players next to the tank; melee spread a bit" },
  },
  [5709] = { -- Shade of Eranikus (Sunken Temple)
    { 12890, "survive", "Tiefer Schlummer schläfert Spieler ein; Heiler verteilen", "Deep Slumber puts players to sleep; keep healers spread" },
    { 12891, "avoid", "Säureatem im Kegel; Tank dreht ihn weg", "Acid Breath cone; tank turns him away" },
    { 11876, "survive", "Kriegsdonner betäubt alle in der Nähe", "War Stomp stuns everyone close" },
  },
  [5710] = { -- Jammal'an the Prophet (Sunken Temple)
    { 12480, "dispel", "Verhexung wendet einen Spieler gegen die Gruppe; bannen oder CC", "Hex turns a player against the group; dispel or CC" },
    { 12492, "interrupt", "Heilt mit Welle der Heilung; unterbrechen", "Heals with Healing Wave; interrupt" },
    { 8376, "adds", "Totem des Erdgriffs wurzelt fest; zerstören", "Earthgrab Totem roots players; destroy it" },
  },
  [5711] = { -- Ogom the Wretched (Sunken Temple)
    { 12471, "interrupt", "Wirkt Schattenblitze; unterbrechen", "Casts Shadow Bolts; interrupt" },
    { 12493, "dispel", "Fluch der Schwäche auf Nahkämpfern; entfluchen", "Curse of Weakness on melee; decurse" },
  },
  [5712] = { -- Zolo (Sunken Temple)
    { 12058, "interrupt", "Kettenblitz springt zwischen Spielern; unterbrechen", "Chain Lightning jumps between players; interrupt it" },
    { 12506, "adds", "Stellt ein Skeletttotem; zerstören", "Drops a skeleton totem; destroy it" },
  },
  [5713] = { -- Gasher (Sunken Temple)
    { 15580, "tank", "Harte Nahkampfschläge auf den Tank", "Heavy melee strikes on the tank" },
  },
  [5714] = { -- Loro (Sunken Temple)
    { 9205, "tank", "Setzt seine Bedrohung zurück; Tank schnell zurückspotten", "Wipes his threat list; tank must taunt back fast" },
    { 8242, "tank", "Schildschlag trifft den Tank hart", "Shield Slam hits the tank hard" },
  },
  [5715] = { -- Hukku (Sunken Temple)
    { 12790, "adds", "Beschwört Dämonen; Begleiter töten", "Summons demon pets; kill the pets" },
    { 9081, "interrupt", "Schattenblitzsalve trifft die Gruppe; unterbrechen", "Shadow Bolt Volley hits the group; interrupt" },
    { 12279, "dispel", "Fluch des Blutes erhöht erlittenen Schaden; entfluchen", "Curse of Blood raises damage taken; decurse" },
  },
  [5716] = { -- Zul'Lor (Sunken Temple)
    { 15584, "positioning", "Spaltet nach vorn; nur der Tank steht vor ihm", "Cleaves in front; only the tank faces him" },
    { 12530, "dispel", "Gebrechlichkeit schwächt Spieler; entfluchen", "Frailty curse weakens players; decurse" },
  },
  [5717] = { -- Mijan (Sunken Temple)
    { 11899, "adds", "Stellt einen Heilungszauberschutz; sofort zerstören", "Drops a Healing Ward; destroy it right away" },
    { 12492, "interrupt", "Heilt mit Welle der Heilung; unterbrechen", "Heals with Healing Wave; interrupt" },
  },
  [5719] = { -- Morphaz (Sunken Temple)
    { 12884, "avoid", "Säureatem im Kegel; Tank dreht den Drachen weg", "Acid Breath cone; tank turns the dragon away" },
    { 12882, "positioning", "Flügelschlag stößt zurück; Tank an einer Wand", "Wing Flap knocks players back; tank near a wall" },
  },
  [5720] = { -- Weaver (Sunken Temple)
    { 12884, "avoid", "Säureatem im Kegel; Tank dreht den Drachen weg", "Acid Breath cone; tank turns the dragon away" },
    { 12882, "positioning", "Flügelschlag stößt zurück; Tank an einer Wand", "Wing Flap knocks players back; tank near a wall" },
  },
  [5721] = { -- Dreamscythe (Sunken Temple)
    { 12884, "avoid", "Säureatem im Kegel; Tank dreht den Drachen weg", "Acid Breath cone; tank turns the dragon away" },
    { 12882, "positioning", "Flügelschlag stößt zurück; Tank an einer Wand", "Wing Flap knocks players back; tank near a wall" },
  },
  [5722] = { -- Hazzas (Sunken Temple)
    { 12884, "avoid", "Säureatem im Kegel; Tank dreht den Drachen weg", "Acid Breath cone; tank turns the dragon away" },
    { 12882, "positioning", "Flügelschlag stößt zurück; Tank an einer Wand", "Wing Flap knocks players back; tank near a wall" },
  },
  [5775] = { -- Verdan the Everliving (Wailing Caverns)
    { 8142, "positioning", "Ranken werfen um und fesseln Nahe: Fernkämpfer bleiben hinten", "Vines root and knock down nearby players: ranged stay back" },
  },
  [6168] = { -- Roogug (Razorfen Kraul)
    { 8270, "adds", "Ruft einen Steingrollen; tanken oder töten", "Summons a Stone Rumbler; tank or kill it" },
    { 9532, "interrupt", "Blitzschlag unterbrechen", "Interrupt Lightning Bolt" },
  },
  [6228] = { -- Dark Iron Ambassador (Gnomeregan)
    { 9053, "interrupt", "Feuerball unterbrechen", "Interrupt Fireball" },
    { 10870, "adds", "Ruft brennende Diener; abfangen oder töten", "Summons fire servants; pick them up or kill them" },
  },
  [6229] = { -- Crowd Pummeler 9-60 (Gnomeregan)
    { 8374, "positioning", "Bogenschmettern trifft vorne; nur der Tank steht davor", "Arcing Smash cleaves in front; only the tank faces him" },
    { 10887, "avoid", "Massenprügel trifft alle in der Nähe; Fernkämpfer bleiben weg", "Crowd Pummel hits all nearby players; ranged stay out" },
  },
  [6235] = { -- Electrocutioner 6000 (Gnomeregan)
    { 11085, "positioning", "Kettenblitz springt zwischen Spielern; verteilt stehen", "Chain Bolt jumps between players; spread out" },
    { 11082, "survive", "Megavolt macht hohen Naturschaden; Leben hoch halten", "Megavolt deals heavy nature damage; keep health high" },
  },
  [6243] = { -- Gelihast (Blackfathom Deeps)
    { 6533, "tank", "Netz hält 2 Sek fest; fliehende Murlocs laufen zu ihm, verlangsamen", "Nets a player for 2 sec; fleeing murlocs run to him, snare them" },
  },
  [6487] = { -- Arcanist Doan (Scarlet Monastery: Library)
    { 9435, "avoid", "Bei halbem Leben Blase, dann Detonation; Sichtlinie brechen", "At half health he bubbles, then detonates; break line of sight" },
    { 13323, "dispel", "Verwandelt Spieler in Schaf; Magie bannen", "Sheeps a player; dispel magic to free them" },
    { 8988, "survive", "Flächenstille sperrt Zauberer; vorher heilen", "Area silence locks casters; heal before it lands" },
  },
  [6906] = { -- The Lost Dwarves (Uldaman)
    { 6268, "tank", "Eric stürmt auf einen Spieler, sein nächster Schlag trifft härter", "Eric charges a player and his next hit lands harder" },
    { 8242, "tank", "Olaf betäubt sein Ziel 2 Sek. mit Schildschlag", "Olaf stuns his target for 2 sec with Shield Slam" },
    { 15620, "adds", "Drei Zwerge zugleich; Baelog beschießt auch Fernkämpfer", "Three dwarves at once; Baelog also shoots casters at range" },
  },
  [6910] = { -- Revelosh (Uldaman)
    { 16006, "interrupt", "Kettenblitz unterbrechen, er springt zwischen nahen Spielern", "Kick his Chain Lightning, it jumps between grouped players" },
    { 15801, "interrupt", "Blitzschlag unterbrechen, um den Schaden zu senken", "Interrupt Lightning Bolt to cut his damage" },
  },
  [7023] = { -- Obsidian Sentinel (Uldaman)
    { 9941, "avoid", "Kann Zauber zurückwerfen; Zauberer achten auf Schaden", "Can reflect spells; casters watch their damage" },
    { 10072, "adds", "Spaltet Obsidiansplitter ab; töten, jeder schwächt ihn", "Splits off Obsidian Shards; kill them, each one weakens him" },
  },
  [7079] = { -- Viscous Fallout (Gnomeregan)
    { 21687, "dispel", "Toxische Salve vergiftet die Gruppe; Gift entfernen", "Toxic Volley poisons the whole group; cure poison" },
  },
  [7206] = { -- Ancient Stone Keeper (Uldaman)
    { 10094, "adds", "Beschwört Sandstürme für 30 Sek.; aus dem Weg gehen", "Summons Sand Storms that fight for 30 sec; move away" },
  },
  [7228] = { -- Ironaya (Uldaman)
    { 11876, "survive", "Kriegsdonner betäubt alle in ihrer Nähe", "War Stomp stuns everyone close to her" },
    { 8374, "positioning", "Bogenschlag trifft vorne; nur der Tank steht vor ihr", "Arcing Smash hits in front of her; only the tank faces her" },
    { 0, "tank", "Wegschlagen wirft den Tank zurück und senkt Bedrohung", "Knock Away throws the tank back and lowers threat" },
  },
  [7267] = { -- Chief Ukorz Sandscalp (Zul'Farrak)
    { 11837, "positioning", "Weiter Hieb trifft vorne im Kegel; nur der Tank vorne", "Wide Slash hits a frontal cone; only the tank in front" },
    { 8269, "tank", "Raserei erhöht Angriffstempo und Schaden", "Frenzy raises his attack speed and damage" },
    { 15496, "positioning", "Spaltet; Nahkämpfer hinter ihm", "Cleaves; melee stay behind him" },
  },
  [7271] = { -- Witch Doctor Zum'rah (Zul'Farrak)
    { 0, "adds", "Zauberschutz zerstören, er ruft alle 5 Sek. ein Skelett", "Destroy his ward, it spawns a skeleton every 5 sec" },
    { 0, "interrupt", "Schattenblitzsalve und Welle der Heilung unterbrechen", "Interrupt Shadow Bolt Volley and Healing Wave" },
    { 0, "adds", "Erweckt Zombies aus Gräbern; von den Gräbern wegziehen", "Raises zombies from graves; pull him away from them" },
  },
  [7272] = { -- Theka the Martyr (Zul'Farrak)
    { 8600, "dispel", "Fiebrige Seuche ist eine Krankheit; heilen oder unterbrechen", "Fevered Plague is a disease; cure it or interrupt" },
    { 0, "survive", "Bei wenig Leben immun gegen Körper- und Schattenschaden", "Low on health he turns immune to physical and shadow" },
  },
  [7273] = { -- Gahz'rilla (Zul'Farrak)
    { 0, "positioning", "Schlag stößt Nahe zurück; nicht am Rand stehen", "Slam knocks nearby players back; avoid ledges" },
    { 0, "survive", "Festfrieren betäubt und macht 6 Sek. Frostschaden", "Freeze Solid stuns and deals frost damage over 6 sec" },
    { 0, "survive", "Eiszapfen trifft und verlangsamt 10 Sek. um 50 %", "Icicle hits and slows by 50% for 10 sec" },
  },
  [7274] = { -- Sandfury Executioner (Zul'Farrak)
    { 15496, "positioning", "Spaltet; Gruppe hinter ihm halten", "Cleaves; keep the group behind him" },
  },
  [7275] = { -- Shadowpriest Sezz'ziz (Zul'Farrak)
    { 13704, "survive", "Psychischer Schrei fürchtet bis zu 5; keine Adds ziehen", "Psychic Scream fears up to 5 players; avoid pulling more" },
    { 12039, "interrupt", "Heilen unterbrechen; Erneuerung bannen", "Interrupt Heal; dispel his Renew" },
    { 12739, "interrupt", "Schattenblitz unterbrechen, wenn er nicht heilt", "Kick Shadow Bolt when no heal is being cast" },
  },
  [7291] = { -- Galgann Firehammer (Uldaman)
    { 0, "survive", "Feuernova trifft alle um ihn; Nahkämpfer brauchen Heilung", "Fire Nova burns everyone around him; melee needs heals" },
    { 0, "dispel", "Flammenpeitsche stapelt erhöhten Feuerschaden; heilen", "Flame Lash stacks fire damage taken; tank swap or heal" },
    { 0, "interrupt", "Flammenstachel der Geologen-Wachen unterbrechen", "Interrupt his Geologist guards' Flame Spike" },
  },
  [7355] = { -- Tuten'kash (Razorfen Downs)
    { 12252, "survive", "Netzt Spieler fest; Heiler auf Abstand", "Webs players in place; healer keep range" },
    { 12251, "dispel", "Gift-DoT; Gift entfernen", "Poison DoT; cure poison" },
    { 12255, "dispel", "Fluch auf Spielern; entfluchen", "Curse on players; decurse it" },
  },
  [7356] = { -- Plaguemaw the Rotting (Razorfen Downs)
    { 11442, "dispel", "Krankheit schwächt Spieler; Krankheit heilen", "Disease weakens players; cure disease" },
    { 12946, "survive", "Gestankaura schadet der Gruppe; schnell töten", "Stench aura hurts the group; burn him fast" },
  },
  [7357] = { -- Mordresh Fire Eye (Razorfen Downs)
    { 12466, "interrupt", "Starker Feuerball; unterbrechen", "Hard-hitting Fireball; interrupt it" },
    { 12470, "positioning", "Feuerstoß in seiner Nähe; Zauberer bleiben weg", "Fire burst near him; casters stay back" },
  },
  [7358] = { -- Amnennar the Coldbringer (Razorfen Downs)
    { 13009, "survive", "Frost-Flächenpuls auf Gruppe; gegenheilen", "Frost AoE pulse on the group; heal through it" },
    { 12642, "adds", "Beschwört Frostgespenster; AoE oder tanken", "Summons frost spectres; AoE or tank them" },
    { 15531, "survive", "Friert Nahkämpfer fest; vorbereitet sein", "Roots nearby players; melee stay ready" },
  },
  [7361] = { -- Grubbis (Gnomeregan)
    { 12057, "tank", "Stoß verursacht Tankschaden; Chomper kämpft an seiner Seite", "Strike adds burst damage on the tank; Chomper fights beside him" },
  },
  [7795] = { -- Hydromancer Velratha (Zul'Farrak)
    { 0, "interrupt", "Welle der Heilung unterbrechen", "Interrupt Healing Wave" },
    { 0, "interrupt", "Wasserblitz unterbrechen, um Frostschaden zu senken", "Interrupt Water Bolt to reduce frost damage" },
  },
  [7796] = { -- Nekrum Gutchewer (Zul'Farrak)
    { 8600, "dispel", "Fiebrige Seuche; Krankheit heilen oder unterbrechen", "Fevered Plague disease; cure it or interrupt" },
  },
  [7797] = { -- Ruuzlu (Zul'Farrak)
    { 0, "positioning", "Spaltet auch Nachbarn des Tanks; hinter ihm stehen", "Cleaves the tank's neighbour; stand behind" },
    { 0, "tank", "Hinrichten unter 20 % Leben; Tank voll halten", "Executes targets under 20% health; keep the tank topped" },
  },
  [7800] = { -- Mekgineer Thermaplugg (Gnomeregan)
    { 0, "adds", "Bombenmaschinen schicken Laufbomben; Knöpfe drücken stoppt sie", "Bomb machines send homing bombs; press their buttons to stop them" },
  },
  [8127] = { -- Antu'sul (Zul'Farrak)
    { 0, "adds", "Heilungszauberschutz und Erdgriff-Totem schnell zerstören", "Kill his Healing Ward and Earthgrab Totem fast" },
    { 0, "adds", "Bei 75 % und 25 % kommen Basilisken, die versteinern", "At 75% and 25% basilisk servants join; they petrify" },
    { 0, "interrupt", "Seine Selbstheilung unterbrechen", "Interrupt his self heal" },
  },
  [8443] = { -- Avatar of Hakkar (Sunken Temple)
    { 12888, "survive", "Wahnsinn verursachen übernimmt einen Spieler; per CC sichern", "Cause Insanity takes control of a player; CC them" },
    { 12889, "dispel", "Fluch der Sprachen verlangsamt Zauber; entfluchen", "Curse of Tongues slows casting; decurse" },
  },
  [8567] = { -- Glutton (Razorfen Downs)
    { 12795, "tank", "Raserei bei wenig Leben; Tank-Cooldowns bereit", "Frenzies at low health; tank cooldowns ready" },
    { 77978, "survive", "Krankheitswolke um ihn; Krankheit heilen", "Disease cloud around him; cure disease" },
  },
  [8580] = { -- Atal'alarion (Sunken Temple)
    { 12887, "positioning", "Fegender Schlag stößt vorn zurück; Nahkampf hinter ihn", "Sweeping Slam knocks back players in front; melee behind" },
    { 6524, "survive", "Erdbeben betäubt Spieler in seiner Nähe", "Ground Tremor stuns players close to him" },
  },
  [8923] = { -- Panzor the Invincible (Blackrock Depths)
    { 9941, "positioning", "Schild kann Zauber zurückwerfen; Zauberer vorsichtig", "Shield that can reflect spells; casters be careful" },
  },
  [8929] = { -- Princess Moira Bronzebeard (Blackrock Depths)
    { 15586, "interrupt", "Heilt den Imperator; unterbrechen oder kontrollieren", "Heals the emperor; interrupt or crowd control her" },
    { 15587, "survive", "Schattenzauber auf einen Spieler", "Shadow nuke on one player" },
  },
  [8983] = { -- Golem Lord Argelmach (Blackrock Depths)
    { 15305, "interrupt", "Blitz springt auf bis zu 5 Spieler; verteilen, unterbrechen", "Lightning jumps up to 5 players; spread and interrupt" },
    { 0, "adds", "Zwei Golemwachen helfen; er läuft und zieht Gegner mit", "Two golem guards join; he runs and pulls uncleared mobs" },
  },
  [9016] = { -- Bael'Gar (Blackrock Depths)
    { 13895, "adds", "Ruft Feuerbrut mit Feuerstoß herbei", "Summons fire spawns with a burst of fire damage" },
    { 23379, "tank", "Feuertreffer plus 24 Sek. Brennschaden am Ziel", "Fire hit plus a burn over 24 sec on the target" },
  },
  [9017] = { -- Lord Incendius (Blackrock Depths)
    { 13899, "avoid", "Flammensäule hinterlässt 30 Sek. Feuerboden; rausgehen", "Flame pillar leaves burning ground for 30 sec; move out" },
    { 14099, "positioning", "Stößt den Tank zurück; Rücken nicht zur Lava", "Knocks the tank back; keep his back away from lava" },
    { 26977, "dispel", "Senkt Feuerwiderstand 1 Min. um 100; entfluchen", "Cuts fire resistance by 100 for 1 min; decurse" },
  },
  [9018] = { -- High Interrogator Gerstahn (Blackrock Depths)
    { 13704, "survive", "Fürchtet bis zu 5 Spieler in der Nähe 6 Sek.; Zusatzgruppen meiden", "Fears up to 5 nearby players for 6 sec; watch for extra pulls" },
    { 14033, "interrupt", "Verbrennt viel Mana eines Zauberers; unterbrechen", "Burns a lot of mana from one caster; interrupt it" },
    { 12040, "dispel", "Schild absorbiert Schaden; reinigen oder wegschlagen", "Self shield that absorbs damage; purge or burn it down" },
  },
  [9019] = { -- Emperor Dagran Thaurissan (Blackrock Depths)
    { 15636, "survive", "10 Sek. immun gegen Magie, Treffer mit Feuerschaden", "Immune to magic for 10 sec, melee hits add fire" },
    { 17492, "dispel", "Feuertreffer betäubt einen Spieler 5 Sek.", "Fire hit that stuns a player for 5 sec" },
    { 0, "positioning", "Moira verschonen oder nicht - ändert die Belohnung", "Keep Moira alive (or not) - killing her changes rewards" },
  },
  [9024] = { -- Pyromancer Loregrain (Blackrock Depths)
    { 15038, "adds", "Setzt ein Feuertotem, das angreift; schnell zerstören", "Drops a fire totem that attacks; kill it quickly" },
    { 15095, "interrupt", "Feuerzauber auf einen Spieler; unterbrechen", "Fire nuke on one player; interrupt it" },
  },
  [9025] = { -- Lord Roccor (Blackrock Depths)
    { 6524, "positioning", "Betäubt alle im 20-m-Umkreis für 2 Sek.; Fernkämpfer auf Abstand", "Stuns everyone within 20 yards for 2 sec; ranged stay at distance" },
    { 13729, "dispel", "Feuertreffer plus 12 Sek. Brennschaden auf einem Spieler", "Fire hit plus a burn over 12 sec on one player" },
  },
  [9027] = { -- Gorosh the Dervish (Blackrock Depths)
    { 13736, "avoid", "Wirbelt und trifft alle in 8 m; Nahkämpfer raus", "Spins and hits all within 8 yards; melee step out" },
    { 16856, "tank", "Harter Schlag, halbiert die Heilung am Tank 5 Sek.", "Heavy hit that halves healing on the tank for 5 sec" },
  },
  [9028] = { -- Grizzle (Blackrock Depths)
    { 6524, "positioning", "Kurze Flächenbetäubung im 20-m-Umkreis", "Short AoE stun within 20 yards" },
    { 8269, "tank", "Greift unter 50 % Leben viel schneller an", "Attacks much faster below 50% health" },
  },
  [9029] = { -- Eviscerator (Blackrock Depths)
    { 7121, "positioning", "6 Sek. immun gegen Magie; Zauberer warten, Nahkampf weiter", "Immune to magic for 6 sec; casters pause, melee keep going" },
    { 15245, "survive", "Schattenschaden auf alle im 30-m-Umkreis", "Shadow damage on everyone within 30 yards" },
  },
  [9030] = { -- Ok'thor the Breaker (Blackrock Depths)
    { 13323, "dispel", "Verwandelt einen Spieler 6 Sek. in ein Schaf", "Turns a player into a sheep for 6 sec" },
    { 13747, "dispel", "Verlangsamt Angriff, Zauber und Laufen im 20-m-Umkreis", "Slows attacks, casts and movement within 20 yards" },
    { 15453, "avoid", "Arkanstoß auf alle im 30-m-Umkreis", "Arcane burst on everyone within 30 yards" },
  },
  [9031] = { -- Anub'shiah (Blackrock Depths)
    { 15470, "dispel", "Zauberer im 30-m-Umkreis wirken 50 % langsamer; entfluchen", "Casters in 30 yards cast 50% slower; decurse" },
    { 15471, "survive", "Wurzelt und bringt einen Spieler 4 Sek. zum Schweigen", "Roots and silences one player for 4 sec" },
    { 8994, "survive", "Nimmt einen Spieler eine Weile aus dem Kampf", "Removes one player from the fight for a while" },
  },
  [9032] = { -- Hedrum the Creeper (Blackrock Depths)
    { 3609, "dispel", "Gift betäubt einen Spieler; Gift entfernen", "Poison that stuns one player; cure poison" },
    { 15474, "survive", "Fesselt alle im 30-m-Umkreis für 5 Sek.", "Roots everyone within 30 yards for 5 sec" },
  },
  [9033] = { -- General Angerforge (Blackrock Depths)
    { 0, "adds", "Ruft bei ca. 40 % Leben Wachen und Sanitäter", "Calls a wave of guards and medics at about 40% health" },
    { 15572, "tank", "Stapelt Rüstungsverringerung auf dem Tank", "Stacks armor reduction on the tank" },
  },
  [9039] = { -- The Seven (Blackrock Depths)
    { 0, "adds", "Sieben Zwerge greifen nacheinander an; zuletzt Doom'rel", "Seven dwarves attack one after another; last one is Doom'rel" },
    { 0, "interrupt", "Doom'rel wirkt Schattensalve und ruft Leerwandler", "Doom'rel casts a shadow volley and summons voidwalkers" },
  },
  [9041] = { -- Warder Stilgiss (Blackrock Depths)
    { 12674, "positioning", "Frostschaden, fesselt nahe Spieler bis zu 8 Sek.", "Frost damage and roots nearby players up to 8 sec" },
    { 12675, "interrupt", "Frostblitz mit Verlangsamung; unterbrechen", "Frost bolt that slows; interrupt" },
    { 15042, "dispel", "Sein Hund Verek verflucht: mehr erlittener körperlicher Schaden", "His dog Verek curses targets to take more physical damage" },
  },
  [9056] = { -- Fineous Darkvire (Blackrock Depths)
    { 0, "interrupt", "Heilt sich oder Verbündete; Zauber unterbrechen", "Heals himself or allies; interrupt the cast" },
    { 0, "adds", "Wenig Schaden, viel Leben; zuerst seine Helfer töten", "Low damage, lots of health; kill his helpers first" },
  },
  [9156] = { -- Ambassador Flamelash (Blackrock Depths)
    { 0, "adds", "Geister laufen von den Runen zu ihm, stärken ihn; töten", "Spirits run to him from the runes; each one buffs him, kill them" },
  },
  [9196] = { -- Highlord Omokk (Lower Blackrock Spire)
    { 10101, "positioning", "Tank mit Rücken zur Wand, sonst in Adds geschleudert", "Tank with back to a wall to avoid being knocked into adds" },
    { 8269, "tank", "Wütend schlägt er viel härter; Abklingzeiten aufheben", "Hits much harder when enraged; save cooldowns" },
  },
  [9217] = { -- Spirestone Lord Magus (Lower Blackrock Spire)
    { 13323, "dispel", "Verwandelt Spieler in Schaf; Verwandlung bannen", "Sheeps a player; dispel the polymorph" },
    { 16170, "dispel", "Beschleunigt einen Oger; reinigen oder Magus zuerst töten", "Hastes an ally ogre; purge or kill him first" },
  },
  [9236] = { -- Shadow Hunter Vosh'gajin (Lower Blackrock Spire)
    { 16097, "dispel", "Verwandelt Spieler in der Nähe in Frösche; bannen", "Turns nearby players into frogs; dispel or wait it out" },
    { 16098, "dispel", "Fluch erhöht erlittenen Schaden; Tank entfluchen", "Curse raises physical damage taken; decurse the tank" },
  },
  [9237] = { -- War Master Voone (Lower Blackrock Spire)
    { 15284, "positioning", "Frontaler Spalter; nur der Tank steht vor ihm", "Frontal cleave; only the tank in front of him" },
    { 0, "survive", "Wirft Axt auf zufälligen Spieler, kurze Betäubung", "Throws an axe at a random player and stuns briefly" },
  },
  [9319] = { -- Houndmaster Grebmar (Blackrock Depths)
    { 13730, "tank", "Senkt Angriffskraft in der Nähe; kommt mit zwei Hunden", "Lowers melee attack power nearby; comes with two hounds" },
    { 0, "positioning", "Flieht bei 15 % Leben; aufhalten, bevor er Gegner holt", "Flees at 15% health; stop him before he pulls more mobs" },
  },
  [9476] = { -- Watchman Doomgrip (Blackrock Depths)
    { 11971, "tank", "Stapelt Rüstungsverringerung auf dem Tank", "Stacks armor reduction on the tank" },
    { 15504, "survive", "Trinkt einen Heiltrank; Schaden bündeln", "Drinks a potion to heal himself; burst him" },
  },
  [9499] = { -- Plugger Spazzring (Blackrock Depths)
    { 0, "survive", "Hexer: verbannt, verflucht; Ärger zieht die ganze Bar", "Warlock: banishes and curses; angering him pulls the bar" },
  },
  [9502] = { -- Phalanx (Blackrock Depths)
    { 0, "positioning", "Stößt Spieler zurück; mit Wand im Rücken kämpfen", "Knocks players back; fight with walls behind you" },
  },
  [9537] = { -- Hurley Blackbreath (Blackrock Depths)
    { 14872, "tank", "Raserei: 15 Sek. schnellere, härtere Nahkampfschläge", "Enrages: much faster and harder melee for 15 sec" },
    { 9573, "positioning", "Feueratem im Frontkegel; vom Trupp wegdrehen", "Fire breath in a frontal cone; face him away" },
  },
  [9568] = { -- Overlord Wyrmthalak (Lower Blackrock Spire)
    { 12887, "positioning", "Kegel mit Rückstoß; Nahkampf hinter ihm", "Cone knockback; melee stand behind him" },
    { 15284, "positioning", "Frontaler Spalter trifft bis zu zwei weitere", "Frontal cleave hits up to two others" },
    { 0, "adds", "Bei 50 % kommen zwei Wachen; abtanken oder kontrollieren", "At 50% two guards join; off-tank or control them" },
  },
  [9596] = { -- Bannok Grimaxe (Lower Blackrock Spire)
    { 13737, "tank", "Senkt Heilung am Tank; gegen den Debuff anheilen", "Cuts healing on the tank; heal through the debuff" },
    { 15128, "survive", "Markiert ein Ziel, es erleidet mehr Feuerschaden", "Marks a target to take more fire damage" },
  },
  [9718] = { -- Ghok Bashguud (Lower Blackrock Spire)
    { 11972, "survive", "Unterbricht Zauber; Heiler nicht in Nahkampfreichweite", "Interrupts casters; healers stay out of melee" },
    { 8269, "tank", "Angriffstempo steigt; Tank-Abklingzeiten aufheben", "Attack speed boost; save tank cooldowns" },
  },
  [9736] = { -- Quartermaster Zigris (Lower Blackrock Spire)
    { 16497, "avoid", "Bombe betäubt im kleinen Bereich; verteilen", "Fire bomb stuns players in a small area; spread out" },
    { 15504, "interrupt", "Trinkt Heiltrank; schnell Schaden oder betäuben", "Drinks a healing potion; burst or stun him" },
    { 15609, "survive", "Fesselt zufälligen Spieler 3 Sek. mit Netz", "Nets a random player in place for 3 sec" },
  },
  [9816] = { -- Pyroguard Emberseer (Upper Blackrock Spire)
    { 0, "adds", "Zuerst die Kerkermeister töten; sie betäuben Spieler", "Kill the Incarcerators first; they stun random players" },
    { 17366, "avoid", "Feuernova trifft Nahkampf; Fernkampf auf Abstand", "Fire nova hits melee; ranged keep distance" },
    { 0, "survive", "Stapelnder Feuer-Debuff; Feuerresistenz hilft", "Stacking fire damage taken debuff; fire resist helps" },
  },
  [9938] = { -- Magmus (Blackrock Depths)
    { 24375, "positioning", "Rückstoß und lange Betäubung für nahe Spieler", "Knockback and long stun on players near him" },
    { 13900, "avoid", "Feuerstoß auf ein Gebiet; Wandstatuen speien Flammen", "Fire burst on an area; wall statues also shoot flames" },
  },
  [10184] = { -- Onyxia (Onyxia's Lair)
    { 18435, "positioning", "Feueratem nach vorn; nur der Tank steht am Kopf", "Frontal fire breath; only the tank stands at her head" },
    { 15847, "positioning", "Schwanz schleudert Spieler hinter ihr; von der Seite angreifen", "Tail knocks back players behind her; attack from the sides" },
    { 17086, "avoid", "Phase 2: Tiefer Atem quer durch den Raum; Bahn verlassen", "Phase 2 Deep Breath across the room; leave its path" },
    { 18431, "survive", "Phase 3: Raidfurcht; Furchtzauberschutz oder Erdstoßtotem", "Phase 3 raid fear; Fear Ward or Tremor Totem help" },
  },
  [10220] = { -- Halycon (Lower Blackrock Spire)
    { 13738, "tank", "Blutung am Tank; durchheilen", "Bleed on the tank; heal through it" },
    { 3391, "tank", "Extra-Angriffe; Schadensspitzen am Tank", "Gains extra attacks; damage spikes on the tank" },
  },
  [10263] = { -- Burning Felguard (Lower Blackrock Spire)
    { 16046, "avoid", "Feuerwelle um ihn verlangsamt; Zauberer auf Abstand", "Fire blast around him slows; casters keep distance" },
    { 15548, "tank", "Flächenschlag verlangsamt Angriff und Tempo im Nahkampf", "AoE slows attack and movement of melee nearby" },
  },
  [10264] = { -- Solakar Flamewreath (Upper Blackrock Spire)
    { 0, "adds", "Fünf Wellen Drachkin; zuerst die Brüter töten", "Five waves of dragonkin; kill Hatchers first" },
    { 0, "avoid", "Eier schlüpfen bei Nähe; nicht darüberlaufen", "Eggs hatch whelps when you walk near; stay off them" },
    { 16727, "positioning", "Flächenbetäubung um ihn; Fernkampf auf Abstand", "AoE stun near him; ranged stay away" },
  },
  [10268] = { -- Gizrul the Slavener (Lower Blackrock Spire)
    { 7938, "tank", "Saugt Leben ab und heilt sich selbst", "Drains health and heals himself" },
    { 8269, "tank", "Raserei, schnellere Angriffe; besänftigen oder Abklingzeit", "Frenzies for faster attacks; soothe or cooldown" },
    { 16128, "dispel", "Krankheit erhöht erlittenen Schaden; heilen", "Disease raises physical damage taken; cure it" },
  },
  [10339] = { -- Gyth (Upper Blackrock Spire)
    { 20667, "positioning", "Säureatem senkt Rüstung; von der Gruppe weg", "Acid breath lowers armor; keep it off the group" },
    { 0, "avoid", "Frostkegel betäubt; nicht vor ihm stehen", "Frost cone stuns; avoid the front" },
  },
  [10363] = { -- General Drakkisath (Upper Blackrock Spire)
    { 23023, "tank", "Verbrennt und lähmt ein Ziel; zweiter Tank spottet", "Burns and panics a target; second tank taunts" },
    { 0, "adds", "Zwei Elitewachen helfen; töten oder ihn wegziehen", "Two elite guards join; kill them or pull him away" },
    { 0, "avoid", "Feuersäulen am Boden; herausgehen", "Fire pillars on the ground; step out" },
  },
  [10376] = { -- Crystal Fang (Lower Blackrock Spire)
    { 16416, "adds", "Ruft Spinnchen; töten, bevor sie Heiler angreifen", "Calls spiderlings; kill them before they swarm healers" },
  },
  [10393] = { -- Skul (Stratholme)
    { 16799, "interrupt", "Rarer Zauberer: Frostblitz unterbrechen", "Rare caster: kick his Frostbolt casts" },
    { 15499, "survive", "Frostschock verlangsamt und trifft hart, gegenheilen", "Instant Frost Shock slows and hurts, heal through it" },
  },
  [10429] = { -- Warchief Rend Blackhand (Upper Blackrock Spire)
    { 0, "adds", "Viele Wellen in der Arena, dann kommen Rend und Gyth", "Many add waves in the arena before Rend and Gyth jump in" },
    { 20712, "positioning", "Gyth speit Kegel; von der Gruppe wegdrehen", "Gyth breathes cones; face him away from the group" },
    { 15589, "avoid", "Rend wirbelt nach Absteigen; Nahkampf zurücktreten", "Rend whirlwinds after dismount; melee step back" },
  },
  [10430] = { -- The Beast (Upper Blackrock Spire)
    { 16785, "positioning", "Rückstoß-Feuer; Tank mit Rücken zur Wand", "Knockback AoE; tank with back to a wall" },
    { 0, "survive", "Fürchtet Spieler; Fernkampf auf maximale Distanz", "Fears players nearby; ranged stay at max range" },
    { 0, "tank", "Stürmt zufälligen Spieler an; Tank holt Aggro zurück", "Charges a random player; tanks re-grab aggro" },
  },
  [10432] = { -- Vectus (Scholomance)
    { 18399, "avoid", "Flammenstoß-Fläche sofort verlassen", "Leave the Flamestrike area at once" },
    { 16046, "positioning", "Feuerwelle im Nahbereich; verteilen und Abstand halten", "Point-blank fire burst; spread out and stay at range" },
  },
  [10433] = { -- Marduk Blackpool (Scholomance)
    { 12040, "positioning", "Schattenschild schadet Nahkämpfern; Fernkämpfer übernehmen", "Shadow shield hurts melee; let ranged do the work" },
    { 17695, "positioning", "Aura schadet in der Nähe; Fernkämpfer auf Abstand", "Aura damages nearby players; ranged keep distance" },
    { 15754, "positioning", "Spaltet nach vorn; nur der Tank steht vor ihm", "Cleaves in front; only the tank faces him" },
  },
  [10435] = { -- Magistrate Barthilas (Stratholme)
    { 10887, "positioning", "Massenschlag stößt alle Nahkämpfer um ihn zurück", "Crowd Pummel knocks back all melee around him" },
    { 14099, "tank", "Mächtiger Stoß ist ein schwerer Treffer auf den Tank", "Mighty Blow is a heavy tank hit" },
  },
  [10436] = { -- Baroness Anastari (Stratholme)
    { 16867, "dispel", "Bansheefluch lässt Angriffe verfehlen, Fluch entfernen", "Banshee Curse makes you miss attacks, decurse it" },
  },
  [10437] = { -- Nerub'enkan (Stratholme)
    { 17235, "adds", "Erweckt untote Skarabäen, mit Flächenschaden töten", "Raises undead scarabs, AoE them down" },
    { 4962, "survive", "Umhüllende Netze fesseln Spieler an Ort und Stelle", "Encasing Webs roots players in place" },
    { 6016, "tank", "Rüstung durchstechen senkt die Rüstung des Tanks", "Pierce Armor lowers the tank's armor" },
  },
  [10438] = { -- Maleki the Pallid (Stratholme)
    { 17503, "interrupt", "Seine Frostblitze unterbrechen", "Interrupt his Frostbolts" },
    { 16869, "dispel", "Eisgrab friert einen Spieler ein, bannen", "Ice Tomb freezes a player solid, dispel it" },
    { 17243, "survive", "Entzieht Zauberern Mana, Heilermana im Blick behalten", "Drains mana from casters, watch healer mana" },
  },
  [10439] = { -- Ramstein the Gorger (Stratholme)
    { 5568, "positioning", "Trampeln trifft alle vor ihm, nur der Tank davor", "Trample hits everyone in front, only the tank faces him" },
    { 17307, "tank", "Niederschlag betäubt den Tank, Ersatz bereithalten", "Knockout stuns the tank, off-tank may need to pick up" },
  },
  [10440] = { -- Baron Rivendare (Stratholme)
    { 17467, "survive", "Unheilige Aura macht dauerhaft Schattenschaden an allen", "Unholy Aura deals shadow damage to the group nonstop" },
    { 15708, "tank", "Tödlicher Stoß senkt die Heilung auf dem Tank", "Mortal Strike cuts healing on the tank" },
    { 15754, "positioning", "Spalten trifft Spieler neben dem Tank, hinten stehen", "Cleave hits players beside the tank, stand behind" },
  },
  [10502] = { -- Lady Illucia Barov (Scholomance)
    { 14515, "interrupt", "Gedankenkontrolle auf Spieler; unterbrechen oder kontrollieren", "Mind control on a player; interrupt or crowd-control" },
    { 12542, "survive", "Furcht auf einen Spieler; Schattenwiderstand hilft", "Fears a player; shadow resistance helps" },
    { 12528, "positioning", "Flächenstille; Zauberer verteilen sich", "AoE silence; casters spread out" },
  },
  [10503] = { -- Jandice Barov (Scholomance)
    { 17773, "adds", "Beschwört viele Trugbilder; echte Jandice markieren und angreifen", "Spawns many illusions; mark and focus the real Jandice" },
    { 16098, "dispel", "Fluch erhöht erlittenen körperlichen Schaden; entfernen", "Curse raises physical damage taken; remove it" },
  },
  [10504] = { -- Lord Alexei Barov (Scholomance)
    { 17467, "survive", "Schattenaura trifft die Gruppe; Heiler brauchen Mana", "Group-wide shadow aura; healers need mana for it" },
    { 17820, "dispel", "Fluch senkt erhaltene Heilung; zuerst entfluchen", "Curse cuts healing taken; decurse it first" },
    { 0, "adds", "Zwei Adds kommen mit; eins fesseln, Alexei zuerst", "Two adds join; shackle one and kill Alexei first" },
  },
  [10505] = { -- Instructor Malicia (Scholomance)
    { 17843, "interrupt", "Heilt sich selbst; Heilungen unterbrechen", "Heals herself; interrupt her heals" },
    { 13747, "dispel", "Verlangsamung senkt Angriffs- und Lauftempo; bannen", "Slow cuts attack and move speed; dispel it" },
  },
  [10506] = { -- Kirtonos the Herald (Scholomance)
    { 18144, "positioning", "Gargoylegestalt: nicht vor ihm stehen, Kegel betäubt", "Gargoyle form: stay out of the frontal stun cone" },
    { 12882, "positioning", "Tank an die Wand, damit der Rückstoß nicht wegschleudert", "Tank against a wall so the knockback does not throw him" },
    { 12889, "dispel", "Menschengestalt verflucht; Zauberer schnell entfluchen", "Human form casts curses; decurse casters fast" },
  },
  [10507] = { -- The Ravenian (Scholomance)
    { 18670, "positioning", "Rückstoß kann Spieler in nicht geräumte Gegner werfen", "Knockback can throw players into uncleared trash" },
    { 17963, "positioning", "Spaltangriff nach vorn; hinter ihm stehen", "Frontal cleave; stand behind him" },
  },
  [10508] = { -- Ras Frostwhisper (Scholomance)
    { 12096, "survive", "Furcht auf Spieler; vorher Adds töten, sonst Zusatzpulls", "Fears players; clear his adds first so no extra pulls" },
    { 18099, "positioning", "Frostnova wurzelt Nahkämpfer; Fernkämpfer auf Maximaldistanz", "Frost nova roots melee; ranged stay at max range" },
    { 8398, "interrupt", "Frostblitzsalven unterbrechen", "Interrupt the frostbolt volleys" },
  },
  [10516] = { -- The Unforgiven (Stratholme)
    { 14907, "positioning", "Frostnova fesselt Nahkämpfer, Fernkämpfer auf Abstand", "Frost Nova roots melee in place, ranged keep distance" },
  },
  [10558] = { -- Hearthsinger Forresten (Stratholme)
    { 16798, "dispel", "Schlaflied lässt Spieler einschlafen, Magie bannen", "Lullaby puts players to sleep, dispel the magic effect" },
    { 14443, "positioning", "Mehrfachschuss trifft mehrere Ziele, nicht stapeln", "Multi-Shot hits several targets, do not stack" },
  },
  [10584] = { -- Urok Doomhowl (Lower Blackrock Spire)
    { 16508, "survive", "Fürchtet Spieler 8 Sek.; Furchtschutz nutzen", "Fears nearby players for 8 sec; use fear wards" },
    { 0, "adds", "Oger-Wellen vor Urok; kontrollieren und töten", "Ogre waves come before Urok; crowd control and kill" },
  },
  [10596] = { -- Mother Smolderweb (Lower Blackrock Spire)
    { 16468, "dispel", "Gift fesselt Spieler; Gift schnell entfernen", "Poison roots players; cure poison quickly" },
    { 16104, "survive", "Betäubt Spieler für einige Sekunden", "Stuns players for a few seconds" },
    { 16103, "adds", "Setzt beim Tod Spinnchen frei; per Fläche töten", "Releases spiderlings on death; AoE them down" },
  },
  [10808] = { -- Timmy the Cruel (Stratholme)
    { 17470, "tank", "Gieriger Klauenhieb trifft den Tank hart, Heilung halten", "Ravenous Claw hits the tank hard, keep heals on him" },
    { 8599, "survive", "Wird bei wenig Leben wütend, schnell herunterbrennen", "Enrages at low health, burn him down fast" },
  },
  [10809] = { -- Stonespine (Stratholme)
    { 14331, "tank", "Bösartiges Zerfleischen lässt den Tank bluten, gegenheilen", "Vicious Rend bleeds the tank, heal the damage over time" },
  },
  [10811] = { -- Archivist Galford (Stratholme)
    { 17366, "avoid", "Feuernova verbrennt alle in der Nähe, Zauberer Abstand", "Fire Nova burns everyone close, casters stay back" },
    { 17293, "survive", "Brennende Winde verursachen Feuerschaden über Zeit", "Burning Winds deals fire damage over time to the group" },
  },
  [10813] = { -- Balnazzar (Stratholme)
    { 17405, "survive", "Übernimmt Spieler per Gedankenkontrolle, kontrollieren", "Mind-controls a player, crowd-control them, do not kill" },
    { 13704, "positioning", "Psychischer Schrei lässt Nahe fliehen, verteilt stehen", "Psychic Scream fears nearby players, ranged spread out" },
    { 17287, "interrupt", "Gedankenschlag auf Heiler unterbrechen", "Interrupt Mind Blast casts on healers" },
  },
  [10899] = { -- Goraluk Anvilcrack (Upper Blackrock Spire)
    { 6253, "tank", "Betäubt den Tank; Zweittank spottet währenddessen", "Stuns the tank; off-tank taunts during the stun" },
    { 16172, "tank", "Senkt die Ausdauer des Tanks für einige Zeit", "Lowers the tank's stamina for a while" },
  },
  [10901] = { -- Lorekeeper Polkelt (Scholomance)
    { 18149, "positioning", "Infizierter schadet Verbündeten in der Nähe; weggehen", "Infected player hurts nearby allies; move away" },
    { 8245, "tank", "Säure senkt Rüstung; Zombie-Adds explodieren beim Tod", "Acid lowers armor; zombie adds explode on death" },
  },
  [10997] = { -- Cannon Master Willey (Stratholme)
    { 17279, "adds", "Ruft Scharlachrote Schützen, töten oder separat tanken", "Calls Crimson Riflemen, kill or off-tank them" },
    { 10101, "tank", "Wegschlagen schleudert den Tank weg und senkt Bedrohung", "Knock Away throws the tank back and drops threat" },
  },
  [11032] = { -- Malor the Zealous (Stratholme)
    { 15493, "interrupt", "Seine Selbstheilung Heiliges Licht unterbrechen", "Interrupt his Holy Light self-heal" },
    { 17233, "survive", "Heilt sich einmal per Handauflegung voll, Burst aufheben", "Can fully heal once with Lay on Hands, save burst" },
  },
  [11143] = { -- Postmaster Malown (Stratholme)
    { 12741, "dispel", "Fluch der Schwäche von Nahkämpfern entfernen", "Remove his Curse of Weakness from melee" },
  },
  [11261] = { -- Doctor Theolen Krastinov (Scholomance)
    { 8269, "tank", "Raserei bei 50 Prozent; schnell töten, Tank nutzt Cooldowns", "Enrages at 50 percent; burn fast, tank uses cooldowns" },
    { 16509, "survive", "Blutung auf dem Tank; Spieler mit wenig Rüstung Abstand halten", "Bleed on the tank; low-armor players keep away" },
  },
  [11380] = { -- Jin'do the Hexxer (Zul'Gurub)
    { 24262, "adds", "Totem übernimmt einen Spieler; schnell zerstören", "Totem mind-controls a player; destroy it fast" },
    { 24309, "adds", "Schutz heilt Jin'do; sofort töten", "Ward heals Jin'do; kill it at once" },
    { 24306, "dispel", "Fluch zeigt Schemen; Schemen töten, dann entfluchen", "Curse lets you see shades; kill shades, then decurse" },
    { 17172, "dispel", "Verhext den Tank; Magie bannen", "Hexes the tank; dispel magic" },
  },
  [11382] = { -- Bloodlord Mandokir (Zul'Gurub)
    { 24314, "avoid", "Ziel des Blicks darf nichts tun, bis er endet", "Gaze target must not act or move until it ends" },
    { 24318, "tank", "Wird mit Toden stärker; Tode vermeiden", "Grows stronger after kills; avoid deaths" },
    { 16856, "tank", "Harter Schlag senkt Heilung am Tank", "Big hit that cuts healing on the tank" },
  },
  [11486] = { -- Prince Tortheldrin (Dire Maul)
    { 0, "avoid", "Wirbelt, trifft alle im Umkreis von 8 Metern; Nahkämpfer zurück", "Spins hitting everyone within 8 yards; melee step back" },
    { 0, "survive", "Sperrt einen Zauberer 15 Sek.; Heilung aufteilen", "Locks out a caster for 15 sec; spread healer duty" },
    { 0, "positioning", "Arkantreffer mit Rückstoß; Tank mit Rücken zur Wand", "Arcane hit with knockback; tank with back to a wall" },
  },
  [11487] = { -- Magister Kalendris (Dire Maul)
    { 0, "survive", "Übernimmt 10 Sek. einen Spieler; diesen kontrollieren", "Mind-controls a player for 10 sec; crowd control them" },
    { 0, "dispel", "Schattenschaden über Zeit auf einem Spieler; Magie bannen", "Shadow damage over time on a player; dispel magic" },
    { 0, "survive", "Ab 50% steigt sein Schattenschaden um 40%; schnell töten", "At 50% his shadow damage rises 40%; burn him fast" },
  },
  [11488] = { -- Illyanna Ravenoak (Dire Maul)
    { 0, "avoid", "Arkaner Regen auf eine Fläche für 6 Sek.; herausgehen", "Arcane rain over an area for 6 sec; move out" },
    { 0, "avoid", "Legt Feuerfallen; nicht darüberlaufen", "Lays fire traps; do not walk over them" },
    { 0, "adds", "Ihr Bär Ferra stürmt und betäubt; separat tanken", "Her bear Ferra charges and stuns; tank it separately" },
  },
  [11489] = { -- Tendris Warpwood (Dire Maul)
    { 0, "adds", "Ruft lebende Eisenborkenbeschützer; diese vor dem Pull töten", "Calls living Ironbark Protectors; kill them before the pull" },
    { 0, "avoid", "Wirft Spieler in der Nähe um und wurzelt sie 10 Sek. fest", "Knocks down and roots nearby players for 10 sec" },
    { 0, "dispel", "Wurzelt ein Ziel fest, Naturschaden über Zeit", "Roots one target with nature damage over time" },
  },
  [11490] = { -- Zevrim Thornhoof (Dire Maul)
    { 22651, "survive", "Holt einen Spieler auf den Altar und saugt Leben ab; durchheilen", "Ports a player to the altar and drains health; heal them through it" },
    { 22478, "survive", "Schattenschaden über Zeit auf alle im Umkreis von 20 Metern", "Shadow damage over time on everyone within 20 yards" },
  },
  [11492] = { -- Alzzin the Wildshaper (Dire Maul)
    { 22662, "dispel", "Naturschaden über Zeit, senkt Stärke", "Nature damage over time that lowers strength" },
    { 22689, "tank", "Wolfsform: Schaden über Zeit und 50% Verlangsamung am Tank", "Wolf form: bleed-like damage and 50% slow on the tank" },
    { 0, "adds", "Mitten im Kampf bricht die Wand, Wichtel strömen herein; flächig töten", "Midway the wall breaks and imps swarm in; AoE them down" },
  },
  [11496] = { -- Immol'thar (Dire Maul)
    { 22950, "tank", "Teleportiert zufälligen Spieler; Bedrohung halten, ggf. spotten", "Teleports a random player and drops threat; keep him taunted" },
    { 16128, "tank", "Naturschaden über Zeit, erhöht erlittenen physischen Schaden", "Nature damage over time and more physical damage taken" },
    { 0, "adds", "Augen erscheinen und verlangsamen einen Spieler; schnell töten", "Eyes spawn and slow a player's actions; kill them quickly" },
  },
  [11501] = { -- King Gordok (Dire Maul)
    { 22886, "survive", "Stürmt auf zufälligen Spieler und schleudert ihn hoch", "Charges a random player and tosses them up" },
    { 16856, "tank", "Starker Schlag, halbiert Heilung am Tank", "Big hit that halves healing on the tank" },
    { 16727, "avoid", "Betäubt alle im Umkreis von 5 Metern für 4 Sek.", "Stuns all within 5 yards for 4 sec" },
  },
  [11502] = { -- Ragnaros (Molten Core)
    { 20566, "positioning", "Stößt Nahkampf zurück; Bedrohung kann wechseln, Zweittank bereit", "Knocks melee back; tank can lose threat, second tank ready" },
    { 20565, "tank", "Trifft Fernkämpfer, wenn keiner im Nahkampf ist; Nahkampf halten", "Hits ranged hard when nobody is in melee range; keep melee up" },
    { 20564, "tank", "Feuerschaden über Zeit auf sein Nahkampfziel", "Fire damage over time on his melee target" },
  },
  [11517] = { -- Oggleflint (Ragefire Chasm)
    { 40505, "positioning", "Spaltet Tank und Nachbarn: nur der Tank steht vorne", "Cleaves the tank and a neighbour: only the tank stands in front" },
  },
  [11518] = { -- Jergosh the Invoker (Ragefire Chasm)
    { 20800, "dispel", "Feuerschaden über Zeit auf Spieler: gegenheilen oder bannen", "Fire damage over time on a player: heal through or dispel" },
    { 18267, "dispel", "Fluch senkt Nahkampfschaden: Fluch vom Tank entfernen", "Curse lowers melee damage: remove the curse from the tank" },
  },
  [11519] = { -- Bazzalan (Ragefire Chasm)
    { 744, "dispel", "Naturgift tickt 15 Sek.: Gift beim Tank heilen", "Nature poison ticks for 15 sec: cure poison on the tank" },
    { 14873, "tank", "Schnelle harte Schläge auf den Tank: gleichmäßig heilen", "Quick hard strikes on the tank: keep healing steady" },
  },
  [11520] = { -- Taragaman the Hungerer (Ragefire Chasm)
    { 18072, "positioning", "Aufwärtshaken schleudert weg: Tank mit Rücken zur Wand, weg von der Lava", "Uppercut knocks targets back: tank with your back to a wall, away from lava" },
    { 11970, "avoid", "Feuerstoß um ihn herum: Begleiter und Fernkämpfer auf Abstand halten", "Fire burst around him: keep pets and ranged out of melee range" },
  },
  [11583] = { -- Nefarian (Blackwing Lair)
    { 22539, "tank", "Schattenflamme nach vorn; Tank braucht Onyxiaschuppenumhang", "Frontal shadowflame; tank needs Onyxia Scale Cloak" },
    { 22686, "survive", "Raidfurcht; Furchtzauberschutz oder Erdstoßtotem", "Raid fear; Fear Ward or Tremor Totem" },
    { 22687, "dispel", "Fluch senkt Heilung am Tank; entfluchen", "Curse cuts healing on the tank; decurse" },
    { 23401, "survive", "Priester-Ruf: Heilungen schaden; Priester pausieren", "Priest class call: their heals hurt; priests stop healing" },
  },
  [11622] = { -- Rattlegore (Scholomance)
    { 16727, "survive", "Flächenbetäubung um ihn; Nahkämpfer brauchen Heilung", "AoE stun around him; melee need heals ready" },
    { 10101, "tank", "Schlägt den Tank weg; lässt den Schlüssel zum Sichtraum fallen", "Knocks the tank back; drops the Viewing Room Key" },
  },
  [11981] = { -- Flamegor (Blackwing Lair)
    { 23342, "tank", "Raserei; Jäger entfernen sie per Einlullender Schuss", "Frenzy; hunters remove it with Tranquilizing Shot" },
    { 22539, "tank", "Schattenflamme nach vorn; Tank braucht Onyxiaschuppenumhang", "Frontal shadowflame; tank needs Onyxia Scale Cloak" },
    { 23339, "tank", "Rückstoß senkt Bedrohung", "Knocks back and drops threat" },
  },
  [11982] = { -- Magmadar (Molten Core)
    { 19451, "tank", "Gerät oft in Raserei; Jäger entfernen sie per Einlullender Schuss", "Frenzies often; hunters must remove it with Tranquilizing Shot" },
    { 19408, "survive", "Raidweite Furcht; Furchtzauberschutz oder Totem des Erdstoßes für den Tank", "Raid-wide fear; Fear Ward or Tremor Totem on the tank" },
    { 19411, "avoid", "Hinterlässt brennende Lavapfützen am Boden; heraustreten", "Leaves burning lava patches on the floor; step out" },
  },
  [11983] = { -- Firemaw (Blackwing Lair)
    { 23341, "positioning", "Stapelnder Feuer-Debuff; Sichtlinie brechen", "Stacking fire debuff on the raid; break line of sight" },
    { 23339, "tank", "Rückstoß senkt Bedrohung; Tanks wechseln", "Knocks back and drops threat; tanks swap" },
    { 22539, "tank", "Schattenflamme nach vorn; Tank braucht Onyxiaschuppenumhang", "Frontal shadowflame; tank needs Onyxia Scale Cloak" },
  },
  [11988] = { -- Golemagg the Incinerator (Molten Core)
    { 20553, "positioning", "Kernwüter in seiner Nähe werden stärker; Hunde weg tanken", "Core Ragers near him get stronger; tank the dogs away" },
    { 13880, "tank", "Stapelnder Rüstungs- und Feuer-Debuff auf dem Tank", "Stacking armor and fire debuff on the tank" },
    { 19798, "survive", "Unter 10 % Erdbeben gegen Nahkampf; schnell töten", "Below 10% health quakes hurt all melee; burn him fast" },
  },
  [12017] = { -- Broodlord Lashlayer (Blackwing Lair)
    { 24573, "tank", "Harter Schlag senkt Heilung am Tank", "Big hit that cuts healing on the tank" },
    { 23331, "positioning", "Feuer-AoE um ihn; Zauberer auf Abstand", "Fire AoE around him; casters keep range" },
    { 18670, "tank", "Stößt Tank zurück, senkt Bedrohung; Ersatztank bereit", "Knocks the tank back and cuts threat; keep a backup tank" },
  },
  [12018] = { -- Majordomo Executus (Molten Core)
    { 20619, "avoid", "Adds reflektieren Zauber; Zauberer pausieren", "Adds reflect spells while active; casters stop casting" },
    { 21075, "avoid", "Adds schaden Nahkämpfern; Nahkampf pausiert", "Adds hurt melee attackers while active; melee stop" },
    { 20534, "tank", "Schickt zufälligen Spieler in die Lavagrube; heilen", "Sends a random player into the lava pit; heal them out" },
  },
  [12056] = { -- Baron Geddon (Molten Core)
    { 20475, "positioning", "Ziel explodiert nach Sekunden; vom Raid weglaufen", "Target explodes after a few seconds; run away from the raid" },
    { 19659, "dispel", "Verbrennt Mana mit Schaden; Magie bei Zauberern bannen", "Burns mana and deals damage; dispel magic on casters" },
    { 19695, "avoid", "Pulsierendes Feuer um ihn; Nahkampf weicht aus", "Pulsing fire around him; melee back away while it lasts" },
  },
  [12057] = { -- Garr (Molten Core)
    { 19492, "survive", "Puls entfernt Magie-Buffs naher Spieler; danach neu buffen", "Pulse strips magic buffs from nearby players; rebuff after" },
    { 19496, "positioning", "Verlangsamt nahe Spieler; Fernkämpfer und Heiler verteilen", "Slows nearby players; keep ranged and healers spread out" },
    { 19516, "adds", "Wird pro getötetem Feuergeschworenen stärker; Adds getrennt halten", "Gains damage per Firesworn killed; tank or banish adds apart" },
  },
  [12098] = { -- Sulfuron Harbinger (Molten Core)
    { 19775, "interrupt", "Flammenschuppen-Priester heilen; jeden Zauber unterbrechen", "Flamewaker Priests heal allies; interrupt every cast" },
    { 19780, "survive", "Betäubt und stößt Spieler in seiner Nähe zurück", "Stuns and knocks back players near him" },
    { 19779, "tank", "Beschleunigt Angriffe naher Adds; Adds von ihm wegziehen", "Boosts attack speed of nearby adds; tank adds away from him" },
  },
  [12118] = { -- Lucifron (Molten Core)
    { 19702, "dispel", "Fluch, der beim Ablauf Schattenschaden macht; Flüche schnell entfernen", "Curse that deals shadow damage when it expires; remove curses fast" },
    { 19703, "dispel", "Fluch verdoppelt Mana- und Wutkosten; Raid entfluchen", "Curse doubles mana and rage costs; decurse the raid" },
    { 20604, "dispel", "Übernimmt einen Spieler; bannen oder kontrollieren", "Mind-controls a player; dispel or crowd-control the victim" },
  },
  [12201] = { -- Princess Theradras (Maraudon)
    { 21869, "survive", "Abstoßender Blick lässt Spieler fliehen; Furchtschutz oder Erdstoß", "Repulsive Gaze fears nearby players; Fear Ward or Tremor" },
    { 21909, "avoid", "Staubfeld schadet in ihrer Nähe; Nahkampf kurz raus", "Dust Field hurts players close to her; melee step out" },
    { 21832, "survive", "Wirft Felsbrocken auf Spieler auf Distanz", "Throws boulders at players at range" },
  },
  [12203] = { -- Landslide (Maraudon)
    { 18670, "tank", "Schlägt den Tank weg und senkt Bedrohung; Ersatztank bereit", "Knocks the tank back and drops threat; second tank ready" },
    { 21808, "adds", "Ruft Felssplitter; sie sterben mit ihm, notfalls AoE", "Calls rock shardlings; they die with him, AoE if needed" },
  },
  [12225] = { -- Celebras the Cursed (Maraudon)
    { 21793, "interrupt", "Kanalisiert Verderbte Gelassenheit; Kanalisierung unterbrechen", "Channels Twisted Tranquility; interrupt the channel" },
    { 12747, "dispel", "Wurzelt Spieler fest; Magie bannen", "Roots players in place; dispel magic" },
    { 21968, "adds", "Ruft verderbte Pflanzen herbei; aufnehmen und töten", "Summons corrupted plant adds; tank and kill them" },
  },
  [12236] = { -- Lord Vyletongue (Maraudon)
    { 21655, "positioning", "Teleportiert sich weg und schießt; Tank und Nahkampf folgen", "Blinks away and shoots; tank and melee chase him" },
    { 7964, "survive", "Rauchbombe betäubt Spieler in seiner Nähe", "Smoke Bomb stuns players near him" },
  },
  [12237] = { -- Meshlok the Harvester (Maraudon)
    { 24375, "survive", "Kriegsdonner betäubt alle in der Nähe; Zauberer Abstand halten", "War Stomp stuns everyone close; casters stay at range" },
  },
  [12258] = { -- Razorlash (Maraudon)
    { 11427, "positioning", "Spaltet nach vorn; nur der Tank steht vor ihm", "Cleaves in front; only the tank faces him" },
    { 15976, "tank", "Durchbohren senkt die Tank-Rüstung; Tank gut heilen", "Puncture shreds tank armor; heal the tank up" },
  },
  [12259] = { -- Gehennas (Molten Core)
    { 19716, "dispel", "Fluch senkt erhaltene Heilung um 75 %; schnell entfluchen", "Curse cuts healing taken by 75%; decurse quickly" },
    { 19717, "avoid", "Feuerregen auf Spielergruppe; sofort herauslaufen", "Fire rain on a group of players; move out at once" },
  },
  [12264] = { -- Shazzrah (Molten Core)
    { 19712, "positioning", "Starke Arkan-AoE um ihn; nur Nahkampf und Tank stehen nah", "Heavy arcane AoE around him; only melee and tank stay close" },
    { 23138, "tank", "Teleportiert zu zufälligem Spieler, Bedrohung weg; Tanks holen ihn", "Blinks to a random player and wipes threat; tanks re-pick him" },
    { 19713, "dispel", "Fluch verdoppelt erlittenen Magieschaden; entfluchen", "Curse doubles magic damage taken; decurse" },
    { 19714, "dispel", "Selbstbuff halbiert Magieschaden; reinigen oder bannen", "Self buff halves magic damage; purge or dispel it" },
  },
  [12435] = { -- Razorgore the Untamed (Blackwing Lair)
    { 19873, "adds", "Phase 1: gesteuerter Boss zerstört Eier, Raid hält die Adds", "Phase 1: mind-controlled boss breaks eggs while raid holds adds" },
    { 22425, "avoid", "Phase 2 Feuerballsalve; hinter Säulen verstecken", "Phase 2 fireball volley; hide behind pillars" },
    { 23023, "tank", "Desorientiert den Tank mit Feuer; anderer Tank übernimmt", "Disorients the tank with fire; another tank takes over" },
  },
  [12876] = { -- Baron Aquanis (Blackfathom Deeps)
    { 15043, "interrupt", "Frostblitz unterbrechen, trifft hart und verlangsamt", "Interrupt Frostbolt, it hits hard and slows" },
    { 15541, "avoid", "Frostnova friert Nahe ein; Fernkämpfer bleiben zurück", "Frost Nova roots players nearby; ranged stay back" },
  },
  [12902] = { -- Lorgus Jett (Blackfathom Deeps)
    { 12550, "dispel", "Blitzschlagschild reinigen, sonst werden Nahkämpfer beim Treffen geschockt", "Purge his Lightning Shield or melee get zapped on every hit" },
    { 12167, "interrupt", "Blitzschlag unterbrechen", "Interrupt Lightning Bolt" },
  },
  [13020] = { -- Vaelastrasz the Corrupt (Blackwing Lair)
    { 18173, "positioning", "Ziel stirbt nach kurzer Zeit; vor der Explosion raus", "Target dies after a while; leave the raid before exploding" },
    { 23461, "positioning", "Atem nach vorn; nur der Tank steht davor", "Frontal breath; only the tank stands in front" },
    { 15847, "positioning", "Schwanz trifft Spieler hinter ihm; seitlich stehen", "Tail hits players behind him; stand at the sides" },
    { 23513, "survive", "Raid erhält Mana und Energie; schnell töten", "Raid gets free mana and energy; burn him fast" },
  },
  [13280] = { -- Hydrospawn (Dire Maul)
    { 22419, "positioning", "Rückstoß mit kurzer Entwaffnung; Rücken zur Wand, vorher Trash räumen", "Knockback with short disarm; keep your back to a wall, clear trash first" },
    { 22714, "adds", "Zwei Hydrolinge bei 50%; ihre Treffer stoßen zurück und löschen Bedrohung", "Two Hydrolings at 50%; their hits knock back and wipe threat" },
  },
  [13282] = { -- Noxxion (Maraudon)
    { 21687, "dispel", "Giftsalve trifft die Gruppe; Gifte entfernen", "Poison volley hits the whole group; cure poisons" },
    { 21707, "adds", "Teilt sich in kleine Brut auf und ist unangreifbar; Brut per AoE töten", "Splits into small spawns while untouchable; AoE them" },
  },
  [13596] = { -- Rotgrip (Maraudon)
    { 16495, "tank", "Tödlicher Biss trifft den Tank sehr hart; durchheilen", "Fatal Bite hits the tank very hard; heal through it" },
  },
  [13601] = { -- Tinkerer Gizlock (Maraudon)
    { 21833, "avoid", "Feuerkegel vor ihm; aus dem Kegel gehen", "Fire cone in front of him; step out of it" },
    { 9143, "survive", "Wirft Bomben mit Flächenschaden", "Throws bombs that hit players in an area" },
  },
  [14020] = { -- Chromaggus (Blackwing Lair)
    { 23310, "avoid", "Einer von zwei Zufallsatems; hinter Torwänden verstecken", "One of two random breaths; hide behind the gate walls" },
    { 23170, "dispel", "Betäubt zufällig; nur Stundenglassand entfernt es", "Stuns randomly; only Hourglass Sand removes it" },
    { 23174, "dispel", "Fünf Gebrechen machen Spieler feindlich; früh reinigen", "Five afflictions turn a player hostile; cleanse early" },
    { 23128, "tank", "Raserei; per Einlullender Schuss entfernen", "Frenzy; remove with Tranquilizing Shot" },
  },
  [14321] = { -- Guard Fengus (Dire Maul)
    { 0, "positioning", "Zufälliger Ansturm mit Rückstoß in andere Gruppen", "Random charge with knockback into other packs" },
    { 0, "adds", "Raserei und Hilferuf bei 50%", "Frenzies and calls help at 50%" },
  },
  [14322] = { -- Stomper Kreeg (Dire Maul)
    { 0, "positioning", "Kegel nach vorn senkt Trefferchance um 75%; nur Tank vorne", "Frontal cone cuts hit chance by 75%; only the tank in front" },
    { 0, "avoid", "Wirbelt, trifft alle im Umkreis von 8 Metern", "Spins hitting all within 8 yards" },
    { 0, "tank", "Ab 50% setzt jeder Treffer die Bedrohung zurück; er wandert", "From 50% his threat resets on each hit; he roams" },
  },
  [14323] = { -- Guard Slip'kik (Dire Maul)
    { 0, "positioning", "Ansturm mit Rückstoß; mit Frostöl in der Falle umgehbar", "Charge with knockback; skip him with frost oil in the trap" },
    { 8269, "tank", "Bei 50% 60% schnellere Angriffe und Hilferuf", "At 50% attacks 60% faster and calls help" },
  },
  [14324] = { -- Cho'Rush the Observer (Dire Maul)
    { 0, "interrupt", "Heilt sich und König Gordok; unterbrechen, zuerst töten", "Heals himself and King Gordok; interrupt and kill him first" },
    { 0, "survive", "Furcht auf Spieler im Umkreis von 8 Metern", "Fears players within 8 yards" },
  },
  [14325] = { -- Captain Kromcrush (Dire Maul)
    { 0, "survive", "Lässt Spieler in der Nähe 6 Sek. fliehen", "Fears nearby players for 6 sec" },
    { 0, "adds", "Ruft zwei Gordok-Häscher; kontrollieren oder schnell töten", "Summons two Gordok Reavers; crowd control or kill fast" },
    { 0, "tank", "Ab 25% 8 Sek. Vergeltung gegen Nahkampf; Nahkämpfer pausieren", "At 25% strikes back at melee for 8 sec; melee pause" },
  },
  [14326] = { -- Guard Mol'dar (Dire Maul)
    { 11972, "survive", "Unterbricht Zauberer im Nahkampf für 3 Sek.", "Interrupts casters in melee range for 3 sec" },
    { 0, "adds", "Bei 50% Raserei, ruft Hunde in der Nähe; diese vorher räumen", "At 50% frenzies and calls nearby dogs; clear them first" },
  },
  [14327] = { -- Lethtendris (Dire Maul)
    { 22709, "interrupt", "Starker Schattenblitz auf ein Ziel; unterbrechen", "Heavy shadow bolt on one target; interrupt it" },
    { 13338, "dispel", "Fluch halbiert Zaubertempo; bei Zauberern und Heilern entfluchen", "Curse halves casting speed; decurse casters and healers" },
    { 22710, "adds", "Stärkt ihren Wichtel Pimgib; den schwachen Wichtel zuerst töten", "Buffs her imp Pimgib; kill the frail imp first" },
  },
  [14354] = { -- Pusillin (Dire Maul)
    { 17145, "avoid", "Feuernova um ihn verlangsamt; Fernkämpfer nicht in Nahkampfreichweite", "Fire nova around him slows; ranged stay out of melee range" },
    { 22735, "survive", "Wächst am Ende und reflektiert Zauber; Nahkampf und physischer Schaden sicherer", "Grows and reflects spells at the end; melee and physical damage are safer" },
  },
  [14507] = { -- High Priest Venoxis (Zul'Gurub)
    { 23860, "interrupt", "Heiliges Feuer auf Spieler; unterbrechen oder bannen", "Holy Fire on a player; interrupt or dispel" },
    { 23861, "avoid", "Schlangenphase Giftwolken; herausgehen", "Snake phase poison clouds; move out" },
    { 23865, "adds", "Kleine Schlangen greifen an; per AoE töten", "Small snakes attack players; AoE them down" },
  },
  [14509] = { -- High Priest Thekal (Zul'Gurub)
    { 24208, "interrupt", "Heilt; unterbrechen; alle drei Priester fast gleichzeitig töten", "Heals; interrupt; kill all three priests near together" },
    { 24183, "adds", "Tigerphase ruft Wächter; weg tanken", "Tiger phase calls guardians; tank them away" },
    { 21060, "survive", "Blendet einen Spieler eine Zeit lang", "Blinds a player for a while" },
  },
  [14510] = { -- High Priestess Mar'li (Zul'Gurub)
    { 24083, "adds", "Brütet Spinneneier aus; Spinnen vor dem Wachsen töten", "Hatches spider eggs; kill spiders before they grow" },
    { 24111, "dispel", "Gift auf Spielern; Gift heilen", "Poison on players; cure poison" },
    { 24300, "interrupt", "Saugt Leben von Spieler; unterbrechen", "Drains life from a player; interrupt" },
  },
  [14515] = { -- High Priestess Arlokk (Zul'Gurub)
    { 24210, "adds", "Panther jagen den Markierten; schützen oder kiten", "Panthers hunt the marked player; protect or kite" },
    { 24212, "dispel", "Schatten-DoT; Magie bannen", "Shadow DoT; dispel magic" },
  },
  [14516] = { -- Death Knight Darkreaver (Scholomance)
    { 0, "adds", "Beschwörung: Geisterwellen töten, bevor er erscheint", "Summoning event: kill the spirit waves before he appears" },
    { 7645, "interrupt", "Kann Spieler übernehmen; unterbrechen oder kontrollieren", "Can mind-control a player; interrupt or crowd-control" },
  },
  [14517] = { -- High Priestess Jeklik (Zul'Gurub)
    { 23954, "interrupt", "Heilt sich selbst; jeden Zauber unterbrechen", "Heals herself; interrupt every cast" },
    { 23918, "survive", "Flächenstille um sie herum", "AoE silence around her" },
    { 22884, "survive", "Fürchtet Spieler in ihrer Nähe", "Fears players close to her" },
  },
  [14601] = { -- Ebonroc (Blackwing Lair)
    { 23340, "tank", "Heilt ihn bei Treffern auf verfluchten Tank; Tanks wechseln", "Heals him when he hits the cursed tank; swap tanks" },
    { 22539, "tank", "Schattenflamme nach vorn; Tank braucht Onyxiaschuppenumhang", "Frontal shadowflame; tank needs Onyxia Scale Cloak" },
    { 23339, "tank", "Rückstoß senkt Bedrohung", "Knocks back and drops threat" },
  },
  [14834] = { -- Hakkar (Zul'Gurub)
    { 24324, "survive", "Saugt den Raid aus; Giftblut verhindert seine Heilung", "Drains the raid; carry Poisonous Blood to avoid it healing" },
    { 24328, "positioning", "Sich ausbreitender Blut-DoT; verteilt stehen", "Spreading blood DoT; stay spread out" },
    { 24327, "dispel", "Übernimmt einen Spieler; kontrollieren oder bannen", "Mind-controls a player; crowd-control or dispel" },
  },
  [14861] = { -- Blood Steward of Kirtonos (Scholomance)
    { 22371, "dispel", "Flüche entfernen; er lässt das Blut der Unschuldigen fallen", "Remove his curses; he drops the Blood of Innocents" },
  },
  [15082] = { -- Gri'lek (Zul'Gurub)
    { 24646, "positioning", "Wächst und jagt zufälligen Spieler; dieser kitet", "Grows and chases a random player; that player kites" },
    { 24648, "dispel", "Wurzelt Spieler fest; Magie bannen", "Roots players; dispel magic" },
  },
  [15083] = { -- Hazza'rah (Zul'Gurub)
    { 24728, "adds", "Illusionen erscheinen; schnell töten", "Illusions spawn; kill them quickly" },
    { 24664, "dispel", "Schläfert Spieler ein; Magie bannen", "Puts players to sleep; dispel magic" },
    { 24684, "survive", "Kettenmanabrand auf Zauberer", "Chained mana burn on casters" },
  },
  [15084] = { -- Renataki (Zul'Gurub)
    { 24699, "tank", "Verschwindet, taucht bei jemandem auf; Tank holt ihn", "Vanishes and reappears on someone; tank re-picks him" },
    { 24649, "survive", "Klingenwirbel auf nahe Spieler", "Blade flurry on nearby players" },
  },
  [15085] = { -- Wushoolay (Zul'Gurub)
    { 24683, "avoid", "Blitzwolke am Boden; heraustreten", "Lightning cloud on the ground; step out" },
    { 24680, "positioning", "Kettenblitz springt; verteilen", "Chain lightning jumps; spread out" },
  },
  [15114] = { -- Gahz'ranka (Zul'Gurub)
    { 22421, "survive", "Schleudert Spieler hoch; Fallschaden", "Throws players into the air; fall damage hurts" },
    { 16099, "positioning", "Frostatem nach vorn; seitlich stehen", "Frontal frost breath; stand at his sides" },
  },
  [16042] = { -- Lord Valthalak (Upper Blackrock Spire)
    { 0, "adds", "Geister-Attentäter sofort töten, sonst verwandeln sie", "Kill the spectral assassins at once or they turn players" },
    { 0, "survive", "Springender Entzug wird stärker; verteilen", "Chaining drain gains damage per jump; spread out" },
    { 27383, "survive", "Ab 40 % Schattenblitzsalven; schnell töten", "From 40% he volleys shadow bolts; burn him fast" },
  },
  [16080] = { -- Mor Grayhoof (Lower Blackrock Spire)
    { 27527, "interrupt", "Große Selbstheilung; immer unterbrechen", "Big self heal; always interrupt it" },
    { 27532, "dispel", "Seine Heilung über Zeit reinigen", "Purge his heal-over-time buff" },
    { 27530, "avoid", "Kanalisierter Sturm um ihn; herauslaufen", "Channeled storm around him; move out of it" },
  },
  [16118] = { -- Kormok (Scholomance)
    { 27688, "positioning", "Knochenschild wirft Schaden auf Nahkämpfer zurück; pausieren", "Bone shield reflects damage to melee; melee pause" },
    { 27687, "adds", "Beschwört Skelettdiener und -magier; töten", "Summons skeleton minions and mages; kill them" },
  },
}
