# wow-statistics

Useful WoW addon (compatible with WoW Forever) to show statistics.

## LevelTimer

Shows statistics for your current level in a small, movable window:

- **Play time on this level**, synced with the server (`/played`) and counted up live.
- **XP per hour** and the estimated play time until the next level.
- **Kills**, split into:
  - **PvE**: every kill that granted experience, including group kills. Grey mobs and kills at max level don't count.
  - **PvP**: honorable kills.
- **Deaths**, with time spent dead or as a ghost and kills per death.
- **XP sources**: share of XP from kills, quests and other sources (exploration, professions, ...).
- **Rested XP**: bonus XP gained from rest and its share of the level's XP.
- **Quests** turned in.
- **Income**: money earned (loot, quests, sales, mail); spending is not subtracted.

Every line can be switched on or off in the settings. All counters are tracked per character and reset on level-up.

### Level history

When you level up, play time, XP/h, kills, deaths, quests and income of the finished level are saved. The history window lists all finished levels, with the current level highlighted at the top. Open it with Shift-left-click on the minimap button, the button in the settings, or `/lt history`.

Works across several game versions (Retail, Classic Era, Anniversary, ...) from a single `.toc`. Features a client doesn't support stay off silently. German and English UI.

### Minimap button and settings

- Left-click the minimap button (pocket watch) to open the settings, Shift-left-click for the level history, right-click to show or hide the window, drag to move it around the minimap.
- On Retail, LevelTimer also shows up in the addon compartment menu.
- Settings: language (Deutsch / English), font size, background opacity, lock window, show window, show minimap button, and a toggle per statistic.

### Chat commands

| Command | Effect |
|---|---|
| `/lt` or `/lt config` | Open settings |
| `/lt history` | Open the level history |
| `/lt lock` / `/lt unlock` | Lock or unlock the window position |
| `/lt show` / `/lt hide` | Show or hide the window |
| `/lt sync` | Re-sync play time with the server |
| `/lt minimap` | Toggle the minimap button |

`/leveltimer` works as an alias for `/lt`.

## Installation

Requirements: [Go](https://go.dev/) 1.22+ and `make`.

```sh
make install    # interactive wizard
```

The wizard finds your WoW folder, lists the installed game versions, shows what it will copy, update or remove, and asks for confirmation. It only writes to `Interface/AddOns/LevelTimer`. Your settings (`WTF/` SavedVariables) are never touched. Older manual installs are migrated automatically.

Other targets:

```sh
make update     # update every game version that already has the addon, no prompts
make dry-run    # only show what would happen
make test       # run the installer tests
```

Extra options go through `ARGS`, e.g. `make install ARGS="-flavors retail,classic_era"` or `ARGS="-wow 'D:/Games/World of Warcraft'"`. You can also set `WOW_DIR`.

After installing: restart the WoW client if the addon is new or its file list changed, otherwise `/reload` is enough.

Manual install: copy the `.toc` and the `.lua` files it lists into `<WoW>/_<version>_/Interface/AddOns/LevelTimer/`. The folder must be named `LevelTimer`.
