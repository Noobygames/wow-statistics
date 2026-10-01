local _, ns = ...

ns.languages = {
  { code = "deDE", name = "Deutsch" },
  { code = "enUS", name = "English" },
}

ns.locales = {
  deDE = {
    TIME_ON_LEVEL = "Zeit auf Level %d",
    LOCKED = "fixiert",
    UNLOCKED = "verschiebbar",
    HELP = "/lt [config] | lock | unlock | sync | show | hide | minimap",
    SETTINGS = "Einstellungen",
    LANGUAGE = "Sprache",
    FONT_SIZE = "Schriftgröße",
    BG_OPACITY = "Hintergrund-Deckkraft",
    LOCK_FRAME = "Fenster fixieren",
    SHOW_TIMER = "Timer anzeigen",
    SHOW_KILLS = "Kills anzeigen",
    SHOW_DEATHS = "Tode anzeigen",
    DEATHS = "Tode: %d",
    KILLS = "Kills: %d PvE / %d PvP",
    SHOW_MINIMAP = "Minimap-Button anzeigen",
    TOOLTIP_LEFT = "Linksklick: Einstellungen",
    TOOLTIP_RIGHT = "Rechtsklick: Timer ein/aus",
    TOOLTIP_DRAG = "Ziehen: Button verschieben",
    MINIMAP_HIDDEN = "Minimap-Button versteckt. Mit /lt minimap wieder einblenden.",
  },
  enUS = {
    TIME_ON_LEVEL = "Time on level %d",
    LOCKED = "locked",
    UNLOCKED = "unlocked",
    HELP = "/lt [config] | lock | unlock | sync | show | hide | minimap",
    SETTINGS = "Settings",
    LANGUAGE = "Language",
    FONT_SIZE = "Font size",
    BG_OPACITY = "Background opacity",
    LOCK_FRAME = "Lock window",
    SHOW_TIMER = "Show timer",
    SHOW_KILLS = "Show kills",
    SHOW_DEATHS = "Show deaths",
    DEATHS = "Deaths: %d",
    KILLS = "Kills: %d PvE / %d PvP",
    SHOW_MINIMAP = "Show minimap button",
    TOOLTIP_LEFT = "Left-click: settings",
    TOOLTIP_RIGHT = "Right-click: toggle timer",
    TOOLTIP_DRAG = "Drag: move button",
    MINIMAP_HIDDEN = "Minimap button hidden. Use /lt minimap to show it again.",
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
