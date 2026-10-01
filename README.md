# wow-statistics

Useful WoW addon (compatible with WoW Forever) to show statistics.

## LevelTimer

Shows statistics for your current level in a small, movable window:

- **Play time on this level**, synced with the server (`/played`) and counted up live.
- **Kills on this level**, split into:
  - **PvE**: every kill that granted experience, including group kills. Grey mobs and kills at max level don't count.
  - **PvP**: honorable kills.
- **Deaths on this level.**

All counters are tracked per character and reset on level-up.

Works across several game versions (Retail, Classic Era, Anniversary, ...) from a single `.toc`. German and English UI.

### Minimap button and settings

- Left-click the minimap button (pocket watch) to open the settings, right-click to show or hide the window, drag to move it around the minimap.
- On Retail, LevelTimer also shows up in the addon compartment menu.
- Settings: language (Deutsch / English), font size, background opacity, lock window, show timer, show kills, show deaths, show minimap button.

### Chat commands

| Command | Effect |
|---|---|
| `/lt` or `/lt config` | Open settings |
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
