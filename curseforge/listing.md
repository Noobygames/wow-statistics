# CurseForge listing

Values for the CurseForge project form.

## General

- **Project name:** LevelTimer
- **Logo:** `logo.png` (512x512, own artwork, no Blizzard assets; regenerate with `make artwork`)
- **Summary:** Tracks play time, XP per hour, kills, deaths, quests and gold per level and per session, with a history for all your characters.
- **Class:** Addons
- **Primary category:** Quests & Leveling

## Description

Content of `description.md`.

## License

Apache License 2.0 (same as `LICENSE` in the repository).

## Game versions

Pick the versions listed under `## Interface:` in `LevelTimer.toc`.

## After approval

Uploads run automatically on every `v*` tag (see "Releasing" in the README). Once the project exists:

1. Put the project ID into `LevelTimer.toc`: `## X-Curse-Project-ID: <id>`
2. Save a CurseForge API token as GitHub secret `CF_API_KEY`.

For the very first upload before that, use `make package` and upload `dist/LevelTimer-<version>.zip` by hand.
