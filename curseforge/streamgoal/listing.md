# CurseForge listing: Stream Goal

Values for the CurseForge project form.

## General

- **Project name:** Stream Goal
- **Logo:** `logo.png` (512x512, own artwork, no Blizzard assets; regenerate with `make artwork`)
- **Summary:** Set goals for your stream (level, kills, loot, battleground wins) and show them as live cards on screen, with a history. Needs Level Time.
- **Class:** Addons
- **Primary category:** Miscellaneous
- **Additional categories:** Quests & Leveling, PvP

## Description

Content of `description.md`.

## Relations

- **Required dependency:** Level Time (the CurseForge project of this repository). Matches `## Dependencies: LevelTimer` in `StreamGoal.toc`.

## License

Apache License 2.0 (same as `LICENSE` in the repository).

## Game versions

Pick the versions listed under `## Interface:` in `StreamGoal/StreamGoal.toc`.

## After approval

Uploads run on `v*` tags once the release pipeline for this addon is set up (still open). Meanwhile:

1. Put the project ID into `StreamGoal/StreamGoal.toc`: `## X-Curse-Project-ID: <id>`
2. For the first upload use `make package` and upload `dist/StreamGoal-<version>.zip` by hand.
