# LevelTimer

See how your leveling is really going. LevelTimer tracks your play time, XP per hour, kills, deaths, quests and income for your **current level** and your **current session**, and keeps a history of every finished level and every past session for all of your characters.

## Features

### Live window

A small, movable window shows either your current level or your current session. Switch with the **Level | Session** tabs.

- **Play time**: on this level (synced with the server's `/played`) or in this session, counted up live
- **XP per hour** and the estimated play time until the next level
- **Kills**, split into **PvE** (every kill that granted experience, including group kills) and **PvP** (honorable kills)
- **Deaths**, with time spent dead or as a ghost and kills per death
- **XP sources**: share of XP from kills, quests and everything else (exploration, professions, ...)
- **Rested XP**: bonus XP gained from rest and its share of your XP
- **Quests** turned in
- **Income**: money earned from loot, quests, sales and mail

Every line can be switched on or off.

### History and evaluation

- **Levels**: play time, XP/h, kills, deaths, quests and gold of every finished level, saved automatically on level-up
- **Sessions**: start, duration, level range, XP/h, kills, deaths, quests and gold of every past session
- A **Total** row sums everything up
- Browse **all your characters** from any character

A session runs from login to logout. A `/reload` or a short break (up to 5 minutes) continues it.

### Settings

- Language: English or German
- Font size and background opacity
- Lock the window, show or hide the window and the minimap button
- One toggle per statistic

## Usage

- **Minimap button**: left-click opens the settings, Shift-left-click the history, right-click shows or hides the window, drag to move the button
- On Retail, LevelTimer also appears in the addon compartment menu

| Command | Effect |
|---|---|
| `/lt` or `/lt config` | Open settings |
| `/lt history` | Open the history |
| `/lt lock` / `/lt unlock` | Lock or unlock the window position |
| `/lt show` / `/lt hide` | Show or hide the window |
| `/lt sync` | Re-sync play time with the server |
| `/lt minimap` | Toggle the minimap button |

`/leveltimer` works as an alias for `/lt`.

## Good to know

- Statistics are recorded separately for every character and stored account-wide, so the history can show all of them.
- Level statistics start counting when the addon is installed. Play time and XP per hour use the server's values, so they are correct for the whole level right away.
- PvE kills count kills that gave you experience. Grey mobs and kills at max level don't count.
- LevelTimer supports several game versions from one download. Features a game version doesn't provide stay off quietly.

## Feedback

Bugs and ideas: [GitHub issues](https://github.com/Noobygames/wow-statistics/issues)
