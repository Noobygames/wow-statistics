local _, ns = ...

ns.languages = {
  { code = "deDE", name = "Deutsch" },
  { code = "enUS", name = "English" },
}

ns.locales = {
  deDE = {
    -- Allgemein und Befehle
    TIME_ON_LEVEL = "Zeit auf Level %d",
    LOCKED = "fixiert",
    UNLOCKED = "verschiebbar",
    HELP = "/lt [config] | history | lock | unlock | sync | show | hide | minimap",
    MINIMAP_HIDDEN = "Minimap-Button versteckt. Mit /lt minimap wieder einblenden.",

    -- Einstellungen
    SETTINGS = "Einstellungen",
    LANGUAGE = "Sprache",
    FONT_SIZE = "Schriftgröße",
    BG_OPACITY = "Hintergrund-Deckkraft",
    LOCK_FRAME = "Fenster fixieren",
    SHOW_TIMER = "Fenster anzeigen",
    SHOW_MINIMAP = "Minimap-Button anzeigen",
    STATISTICS = "Statistiken",

    -- Schalter der Stat-Zeilen
    STAT_XP_RATE = "XP pro Stunde",
    STAT_KILLS = "Kills",
    STAT_DEATHS = "Tode",
    STAT_XP_SOURCES = "XP-Quellen",
    STAT_RESTED = "Erholungs-XP",
    STAT_QUESTS = "Quests",
    STAT_MONEY = "Gold",

    -- Stat-Zeilen im Fenster
    XP_RATE = "XP/h: %s, Level-Up in %s",
    XP_RATE_PENDING = "XP/h: ...",
    XP_MAX_LEVEL = "XP/h: Max-Level",
    KILLS = "Kills: %d PvE / %d PvP",
    DEATHS = "Tode: %d",
    DEATHS_DETAIL = "Tode: %d (%s tot, %s Kills/Tod)",
    XP_SOURCES = "XP: %s Kills, %s Quests, %s Sonstige",
    XP_SOURCES_NONE = "XP: -",
    RESTED_XP = "Erholt: %s XP (%s)",
    QUESTS = "Quests: %d",
    MONEY = "Einnahmen: %s",

    -- Level-Historie
    HISTORY = "Level-Historie",
    HISTORY_LEVEL = "Level",
    HISTORY_TIME = "Zeit",
    HISTORY_XP_RATE = "XP/h",
    HISTORY_PVE = "PvE",
    HISTORY_PVP = "PvP",
    HISTORY_DEATHS = "Tode",
    HISTORY_QUESTS = "Quests",
    HISTORY_GOLD = "Gold",

    -- Minimap-Tooltip
    TOOLTIP_LEFT = "Linksklick: Einstellungen",
    TOOLTIP_SHIFT_LEFT = "Shift-Linksklick: Level-Historie",
    TOOLTIP_RIGHT = "Rechtsklick: Fenster ein/aus",
    TOOLTIP_DRAG = "Ziehen: Button verschieben",
  },
  enUS = {
    -- General and commands
    TIME_ON_LEVEL = "Time on level %d",
    LOCKED = "locked",
    UNLOCKED = "unlocked",
    HELP = "/lt [config] | history | lock | unlock | sync | show | hide | minimap",
    MINIMAP_HIDDEN = "Minimap button hidden. Use /lt minimap to show it again.",

    -- Settings
    SETTINGS = "Settings",
    LANGUAGE = "Language",
    FONT_SIZE = "Font size",
    BG_OPACITY = "Background opacity",
    LOCK_FRAME = "Lock window",
    SHOW_TIMER = "Show window",
    SHOW_MINIMAP = "Show minimap button",
    STATISTICS = "Statistics",

    -- Stat line toggles
    STAT_XP_RATE = "XP per hour",
    STAT_KILLS = "Kills",
    STAT_DEATHS = "Deaths",
    STAT_XP_SOURCES = "XP sources",
    STAT_RESTED = "Rested XP",
    STAT_QUESTS = "Quests",
    STAT_MONEY = "Gold",

    -- Stat lines in the window
    XP_RATE = "XP/h: %s, level up in %s",
    XP_RATE_PENDING = "XP/h: ...",
    XP_MAX_LEVEL = "XP/h: max level",
    KILLS = "Kills: %d PvE / %d PvP",
    DEATHS = "Deaths: %d",
    DEATHS_DETAIL = "Deaths: %d (%s dead, %s kills/death)",
    XP_SOURCES = "XP: %s kills, %s quests, %s other",
    XP_SOURCES_NONE = "XP: -",
    RESTED_XP = "Rested: %s XP (%s)",
    QUESTS = "Quests: %d",
    MONEY = "Income: %s",

    -- Level history
    HISTORY = "Level history",
    HISTORY_LEVEL = "Level",
    HISTORY_TIME = "Time",
    HISTORY_XP_RATE = "XP/h",
    HISTORY_PVE = "PvE",
    HISTORY_PVP = "PvP",
    HISTORY_DEATHS = "Deaths",
    HISTORY_QUESTS = "Quests",
    HISTORY_GOLD = "Gold",

    -- Minimap tooltip
    TOOLTIP_LEFT = "Left-click: settings",
    TOOLTIP_SHIFT_LEFT = "Shift-left-click: level history",
    TOOLTIP_RIGHT = "Right-click: toggle window",
    TOOLTIP_DRAG = "Drag: move button",
  },
}

function ns.DefaultLanguage()
  return GetLocale() == "deDE" and "deDE" or "enUS"
end

-- L.KEY liefert den Text in der eingestellten Sprache, Fallback Englisch
ns.L = setmetatable({}, {
  __index = function(_, key)
    local lang = (ns.db and ns.db.language) or ns.DefaultLanguage()
    local strings = ns.locales[lang] or ns.locales.enUS
    return strings[key] or ns.locales.enUS[key] or key
  end,
})
