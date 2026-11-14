# Data sources of Level Time

Level Time ships static game data (flight paths, flight times, ship and zeppelin routes, instance data, dungeon
bosses, map coordinates, speedrun records). Generated data files say in their first lines where they come from and
when they were built. This page lists all the sources.

## 1. Our own data extractor

We collect game data ourselves while playing, with a small developer addon that we use only on our own machines. It is
not part of Level Time and is never published.

- It records what the game client shows us during normal play: creatures (name, level, health, where they were seen,
  experience per kill, what they drop), quests (who starts and ends them, objectives, rewards, experience and money per
  character level, where objectives progress), items, vendors, trainers, flight masters and flight times, dungeon
  entrances, bosses, and experience per level and from exploring.
- Collection happens only through the official addon API of the game client, on our own characters; other players
  are skipped.
- We use the collected data to build and verify the data files Level Time ships. The measured flight times
  (`Assist/FlightTimesData.lua`) also come from our own flights, recorded with Level Time itself.
- A local tool (`tools/extractor`) exports the collected data to JSON and compares it with our hand-maintained
  dungeon guide; it only reports, it never changes a shipped file.

## 2. Public game data from wago.tools

Static client data (DB2 tables) comes from the public database at <https://wago.tools>, per game version (Retail,
Classic Era, Anniversary, WoW Forever). Our generator `tools/flights` (`make flights`) reads the tables and writes:

- flight paths and flight master names (`Assist/FlightPathsData/`, `Assist/FlightNamesData/`)
- ship and zeppelin routes (`Assist/TransportData/`)
- instance resets, group sizes and level ranges (`Assist/InstanceData/<flavor>.lua`)
- dungeon bosses in order (`Assist/BossData/`)
- map coordinates (`Assist/MapCoordsData/`)

Each of these files names the game build it was generated from.

## 3. Speedrun records

The world records shown by the speedrun features come from the public API of <https://www.speedrun.com>
(`tools/records`, `make records`, written to `Speedrun/SpeedrunRecords.lua`).

## Hand-maintained data

`Assist/InstanceData/forever_guide.lua` (WoW Forever dungeon level ranges, entrances, boss levels and dungeon quests)
is maintained by hand. It is being checked against, and will be replaced by, data from our own extractor.

`Tracking/ClassQuests.lua` (Classic Era / WoW Forever class quests: level, learned spell IDs, reward item IDs) is
maintained by hand from the class quest pages on warcraft.wiki.gg (Druid, Hunter, Paladin, Rogue, Shaman, Warlock,
Warrior quests); spell and item IDs checked on wowhead classic. Stand 2026-11-14; WoW Forever not checked separately.

## 4. ForeverDungeonJournal (WoW Forever bosses)

The boss encounter aliases (older and newer encounter IDs of the same boss), the missing boss name, the rare bosses and
the rare NPC IDs per dungeon and the boss-to-wing assignment of Stratholme, Dire Maul, Scarlet Monastery and Blackrock
Spire in `Assist/InstanceData/forever_guide.lua` (`encounterAliases`, `bossNames`, `rareBosses`, `rareNpcs`, `wings`)
were imported once on 2026-11-14 from the addon ForeverDungeonJournal 2.0.5 (`Data/RunLogEncounters.lua`,
`Data/Dungeons.lua`), licensed under the WTFPL. Thanks to its authors.
The boss NPC IDs for the boss portraits in `Assist/InstanceData/boss_npcs.lua` (encounter ID -> NPC ID, `portraitNpcID`
where given; matched by dungeon and boss name, else by the unique English boss name) come from the same one-time import
(2026-11-14); Classic Era uses the subset of these encounters with the same Classic NPC IDs. Maintained by hand since.

## 5. QuestieDB (WoW Forever dungeon quests)

The quest prerequisites and exclusions (`pre`, `preAny`, `excl`) and a few missing quests in the `quests` block of
`Assist/InstanceData/forever_guide.lua` were imported once on 2026-11-14 from the addon QuestieDB 1.1.0 (Forever build,
`QuestieDB_Forever.toc` metadata), licensed under the WTFPL; its data originates from Questie. Thanks to the Questie and
QuestieDB authors. Since then the data is maintained by hand.

`Assist/InstanceData/dungeon_db.lua` (`ns.DungeonDB`) is generated from the same local QuestieDB addon by
`tools/questie` (`make questie`; full JSON with names in `dist/questie/{quests,npcs,loot}.json`). The tool decodes the
"baked" TOC metadata (base64 CBOR rows, zlib-compressed ID lists, chunked values) and the zone and drop tables in
`support/Forever/`, and writes for every Classic dungeon and raid (keyed by instance map ID):

- quests with objectives, turn-in or quest sorting inside the instance, plus their complete prerequisite chain
  (`preQuestGroup`, `preQuestSingle`, breadcrumbs, `nextQuestInChain`, `exclusiveTo` alternatives) with quest giver,
  zone (uiMapID, x/y), quest level, required level, faction and class mask
- quest givers (NPC, object, item) to quest IDs
- English names of object quest givers (QuestieDB has no translations), used to recognize objects in world tooltips
  on English clients
- NPCs per instance with level range and rank (normal, elite, rare, boss)
- rare, epic and legendary drops of these NPCs, as far as QuestieDB lists them (not complete loot tables), with the
  drop chance where QuestieDB has one (quest items only). QuestieDB has no item quality; it comes from the DB2 table
  `ItemSparse` on wago.tools (WoW Forever build, Classic Era for items missing there), see section 2.

The generated file names the QuestieDB version and the wago.tools builds it was made from.

The tool also merges the boss loot of our own dungeon guide research (`docs/research/mechanics/*.json`, one file per
instance; own research of public facts, mainly warcraft.wiki.gg, each file lists its sources) into the same `loot`
table: guide bosses are matched to QuestieDB NPCs of the instance by NPC ID, else by English name; every item is
checked against `ItemSparse` (must exist, quality from `ItemSparse`, rare or better only), duplicates are skipped and
guide drops have no chance. Guide bosses and the NPCs of `Assist/InstanceData/boss_npcs.lua` get rank boss (QuestieDB
lists some end bosses as rare elite). Forever-only items stay in; Classic Era skips unknown item IDs at runtime.

## 6. Guide research (boss and trash mechanics)

`Assist/InstanceData/mechanics.lua` (`ns.Mechanics`, Classic Era and WoW Forever only) is generated by `tools/mechanics`
(`make mechanics`) from our own guide research in `docs/research/mechanics/*.json` (one file per Classic dungeon or
raid; every file present is read, new instances just add a file). Each file lists bosses, rares and trash with NPC ID
and short tips per ability (spell ID, type, English and German text); the sources used are named in each file's
`sources` field, entries marked `unverified` are less certain. Files whose German texts use
ae/oe/ue/ss instead of umlauts are corrected by an explicit word list in the tool. German clients show the German tip,
all other clients the English one (no French or Spanish tips).
