# wow-statistics

Useful WoW addon (compatible with WoW Forever) to show statistics.

## LevelTimer

Shows statistics in a small, movable window, either for your **current level** or your **current session** (switch with the "Level | Session" tabs at the top):

- **Play time**: on this level synced with the server (`/played`), for the session since login; both counted up live.
- **XP per hour** and the estimated play time until the next level.
- **Kills**, split into:
  - **PvE**: every kill that granted experience, including group kills. Grey mobs and kills at max level don't count.
  - **PvP**: honorable kills.
- **Deaths**, with time spent dead or as a ghost and kills per death.
- **XP sources**: share of XP from kills, quests and other sources (exploration, professions, ...).
- **Rested XP**: bonus XP gained from rest and its share of the XP.
- **Quests** turned in.
- **Income**: money earned (loot, quests, sales, mail); spending is not subtracted.

Every line can be switched on or off in the settings. Level statistics restart on level-up. A session runs from login to logout; a `/reload` or a short break (up to 5 minutes) continues it.

Statistics are recorded separately for every character. They are stored account-wide, so you can look at all your characters from any of them.

### History and evaluation

The history window shows, per character:

- **Levels**: play time, XP/h, kills, deaths, quests and income of every finished level, saved on level-up.
- **Sessions**: start, duration, level range, XP/h, kills, deaths, quests and income of every past session.

The running level or session is highlighted at the top, a **Total** row at the bottom sums everything up. Switch characters with the arrows. Open it with Shift-left-click on the minimap button, the button in the settings, or `/lt history`.

Works across several game versions (Retail, Classic Era, Anniversary, ...) from a single `.toc`. Features a client doesn't support stay off silently. German and English UI.

### Minimap button and settings

- Left-click the minimap button (pocket watch) to open the settings, Shift-left-click for the history, right-click to show or hide the window, drag to move it around the minimap.
- On Retail, LevelTimer also shows up in the addon compartment menu.
- Settings: language (Deutsch / English), font size, background opacity, lock window, show window, show minimap button, and a toggle per statistic.

### Chat commands

| Command | Effect |
|---|---|
| `/lt` or `/lt config` | Open settings |
| `/lt history` | Open the history |
| `/lt lock` / `/lt unlock` | Lock or unlock the window position |
| `/lt show` / `/lt hide` | Show or hide the window |
| `/lt sync` | Re-sync play time with the server |
| `/lt minimap` | Toggle the minimap button |

`/leveltimer` works as an alias for `/lt`.

## Installation

Requirements: [Go](https://go.dev/) 1.23+ and `make`.

```sh
make install    # interactive wizard
```

The wizard finds your WoW folder, lists the installed game versions, shows what it will copy, update or remove, and asks for confirmation. It only writes to `Interface/AddOns/LevelTimer`. Your settings (`WTF/` SavedVariables) are never touched. Older manual installs are migrated automatically.

Other targets:

```sh
make update     # update every game version that already has the addon, no prompts
make dry-run    # only show what would happen
make test       # run all tests (addon scenarios + installer)
```

Extra options go through `ARGS`, e.g. `make install ARGS="-flavors retail,classic_era"` or `ARGS="-wow 'D:/Games/World of Warcraft'"`. You can also set `WOW_DIR`.

After installing: restart the WoW client if the addon is new or its file list changed, otherwise `/reload` is enough.

Manual install: copy the `.toc` and the `.lua` files it lists into `<WoW>/_<version>_/Interface/AddOns/LevelTimer/`. The folder must be named `LevelTimer`.

## Development

```sh
make test         # addon scenarios + installer tests
make test-addon   # only the addon scenarios
```

The addon tests run without the game: `tests/wow_stub.lua` fakes the parts of the WoW API the addon uses, and each `tests/*_test.lua` plays through one scenario (login, kills, deaths, level-up, ...) in a fresh Lua 5.1 state. They check the logic, not the rendering, so a quick check in game is still worthwhile.
