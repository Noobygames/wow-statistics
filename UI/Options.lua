-- Einstellungsfenster mit Reitern: Allgemein (Fenster, Sprache), Statistiken, Hinweise, Komfort, Stream, Speedrun, Profile.
-- Darunter auf allen Reitern: Neue Session, Zusammenfassung, Historie.
-- Nur der Inhalt; Aufbau, Tooltips, Breite und Aktualisierung übernimmt Lib/OptionsBuilder.lua.
local _, ns = ...
local L = ns.L
local Widgets = ns.Widgets
local TimerWindow = ns.TimerWindow
local Builder = ns.OptionsBuilder

local MAX_PROFILE_ROWS = 6     -- so viele Profile listet der Reiter "Profile"
local ROW_PROFILE = 20
local PROFILE_NAME_WIDTH = 160
local PROFILE_SAVE_WIDTH = 120
local DELETE_PROFILE_POPUP = "LEVELTIMER_DELETE_PROFILE"

local builder = Builder.New({
  name = "LevelTimerOptions",
  alpha = 0.95,
  title = function() return ns.DISPLAY_NAME .. " - " .. L.SETTINGS end,
})
local addPage, finishPage, addSection, addSlider = builder.AddPage, builder.FinishPage, builder.AddSection, builder.AddSlider
local addToggles, addButton, addFooterButton = builder.AddToggles, builder.AddButton, builder.AddFooterButton
local addChooser, addHint = builder.AddChooser, builder.AddHint
local toggle, localized = Builder.Toggle, Builder.Localized

-- Sprachnamen stehen immer in der eigenen Sprache
local function addLanguageChooser()
  local choices = {}
  for i, language in ipairs(ns.languages) do
    choices[i] = { value = language.code, name = function() return language.name end }
  end
  addChooser({ label = "LANGUAGE", setting = "language", choices = choices })
end

-- Vergleich der Splits; ein fester Charakter wird per /lt compare Name gewählt
local function addSplitComparisonChooser()
  local Splits = ns.Splits
  addChooser({ label = "SPLIT_COMPARISON", setting = "splitComparison", choices = {
    { value = Splits.BEST, name = localized("COMPARE_CHOICE_BEST") },
    { value = Splits.PERSONAL_BEST, name = localized("COMPARE_CHOICE_PB") },
    { value = Splits.RUN, name = localized("COMPARE_CHOICE_RUN") },
  } })
end

-- Speedrun-Rekorde: schnellster Lauf insgesamt oder der eigenen Klasse
local function addWorldRecordScopeChooser()
  local WorldRecords = ns.WorldRecords
  addChooser({ label = "WORLD_RECORD_SCOPE", setting = "worldRecordScope", choices = {
    { value = WorldRecords.CLASS, name = localized("WORLD_RECORD_OWN_CLASS") },
    { value = WorldRecords.OVERALL, name = localized("WORLD_RECORD_ALL_CLASSES") },
  } })
end

-- Level-Up-Ansage: aus, Gruppe oder Gilde
local function addAnnounceChooser()
  local Summary = ns.LevelUpSummary
  addChooser({ label = "LEVEL_UP_ANNOUNCE", setting = "levelUpAnnounce", choices = {
    { value = Summary.ANNOUNCE_OFF, name = localized("ANNOUNCE_OFF") },
    { value = Summary.ANNOUNCE_PARTY, name = localized("ANNOUNCE_PARTY") },
    { value = Summary.ANNOUNCE_GUILD, name = localized("ANNOUNCE_GUILD") },
  } })
end

-- Hintergrund des Fensters: Standard oder Chroma-Farbe für Streams
local function addBackgroundChooser()
  addChooser({ label = "WINDOW_BACKGROUND", setting = "windowBackground", choices = {
    { value = TimerWindow.BACKGROUND_DEFAULT, name = localized("BACKGROUND_DEFAULT") },
    { value = "green", name = localized("BACKGROUND_GREEN") },
    { value = "magenta", name = localized("BACKGROUND_MAGENTA") },
  } })
end

-- Profile: Liste (Klick wechselt, Rechtsklick löscht), Name + Speichern, Export und Import
StaticPopupDialogs[DELETE_PROFILE_POPUP] = {
  button1 = YES or "Yes",
  button2 = NO or "No",
  OnAccept = function(_, name)
    ns.Profiles.Delete(name)
    ns.ApplySettings()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

local function addProfileList()
  local Profiles = ns.Profiles
  for index = 1, MAX_PROFILE_ROWS do
    local tab = Widgets.CreateTab(builder.Page(), "GameFontHighlight", function(self, mouseButton)
      local name = self.profileName
      if mouseButton == "RightButton" then
        StaticPopupDialogs[DELETE_PROFILE_POPUP].text = L.PROFILE_DELETE_CONFIRM
        StaticPopup_Show(DELETE_PROFILE_POPUP, Profiles.DisplayName(name), nil, name)
      else
        Profiles.Switch(name)
      end
    end)
    tab:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    builder.AddRow(tab, ROW_PROFILE)
    builder.AddTooltip(tab, "PROFILE_LIST_TIP", function() return Profiles.DisplayName(tab.profileName) end)
    builder.OnRefresh(function()
      local name = Profiles.GetNames()[index]
      tab.profileName = name
      tab:SetShown(name ~= nil)
      if name then
        tab:SetLabel(Profiles.DisplayName(name))
        tab:SetActive(name == Profiles.GetActive())
      end
    end)
  end
end

-- Import-Fenster für Profile (auch /lt profile import); das neue Profil wird nicht sofort aktiv
function ns.ShowProfileImport()
  ns.Export.ShowImport(L.PROFILE_IMPORT, function(text)
    local name = ns.Profiles.Import(text)
    if not name then return L.PROFILE_IMPORT_INVALID, false end
    ns.ApplySettings()
    return string.format(L.PROFILE_IMPORTED, name), true
  end)
end

local function addProfileSaver()
  local page = builder.Page()
  local nameBox = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
  nameBox:SetSize(PROFILE_NAME_WIDTH, Builder.BUTTON_HEIGHT)
  nameBox:SetAutoFocus(false)
  nameBox:SetPoint("TOPLEFT", Builder.MARGIN + 6, builder.RowY())  -- Vorlage zeichnet ihren Rand links außerhalb
  local saveButton = Widgets.CreateButton(page, PROFILE_SAVE_WIDTH, Builder.BUTTON_HEIGHT, function()
    if ns.Profiles.SaveAs(nameBox:GetText()) then
      ns.Print(string.format(L.PROFILE_SAVED, nameBox:GetText()))
      nameBox:SetText("")
      ns.ApplySettings()
    end
  end)
  saveButton:SetPoint("LEFT", nameBox, "RIGHT", Builder.CHOOSER_TAB_GAP, 0)
  builder.AddTooltip(saveButton, "PROFILE_SAVE_TIP", localized("PROFILE_SAVE"))
  nameBox:SetScript("OnEnterPressed", function() saveButton:Click() end)
  nameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  builder.Advance(Builder.ROW_BUTTON)
  builder.OnRefresh(function() Widgets.SetButtonText(saveButton, L.PROFILE_SAVE, PROFILE_SAVE_WIDTH) end)
end

local function percent(value)
  return value .. "%"
end

local function toPercent(fraction)
  return math.floor(fraction * 100 + 0.5)
end

---------------------------------------------------------------------------
-- Inhalt
---------------------------------------------------------------------------

-- Allgemein: Fenster und grundlegende Einstellungen
addPage("SECTION_GENERAL")
addSection("SECTION_WINDOW")
addSlider({
  label = "WINDOW_SIZE",
  min = toPercent(TimerWindow.MIN_SCALE),
  max = toPercent(TimerWindow.MAX_SCALE),
  step = 5,
  get = function(db) return toPercent(db.scale) end,
  set = function(value) ns.Set("scale", value / 100) end,
  format = percent,
})
addSlider({
  label = "BG_OPACITY",
  min = 0,
  max = 100,
  step = 5,
  get = function(db) return toPercent(db.bgAlpha) end,
  set = function(value) ns.Set("bgAlpha", value / 100) end,
  format = percent,
})
addToggles({
  toggle("SHOW_TIMER", "showTimer"),
  toggle("LOCK_FRAME", "locked"),
  toggle("SHOW_XP_BAR", "showXpBar"),
  toggle("COMPACT_MODE", "compactMode"),
  toggle("HORIZONTAL_LAYOUT", "horizontalLayout"),
})
addButton("RESET_WINDOW", function() TimerWindow.ResetLayout() end)
addHint("OPTIONS_HINT")
addSection("SECTION_GENERAL")
addLanguageChooser()
addToggles({
  { label = "SHOW_MINIMAP", get = function(db) return not db.minimap.hide end,
    set = function(checked) ns.SetMinimapHidden(not checked) end },
})
finishPage()

-- Statistiken: ein Schalter je Stat-Zeile, direkt aus ns.STAT_LINES
addPage("STATISTICS")
addSection("STATISTICS")
local statToggles = {}
for i, line in ipairs(ns.STAT_LINES) do
  statToggles[i] = toggle(line.label, line.setting, line.available)
end
addToggles(statToggles)
addSection("SECTION_CALCULATION")
addToggles({ toggle("XP_RATE_WITHOUT_AFK", "xpRateWithoutAfk") })
finishPage()

-- Hinweise: Level-Up im Chat und Erinnerungen an Buffs
addPage("OPTIONS_TAB_NOTIFICATIONS")
addSection("SECTION_LEVEL_UP")
addToggles({ toggle("LEVEL_UP_SUMMARY_TOGGLE", "levelUpSummary") })
addAnnounceChooser()
addSection("SECTION_REMINDERS")
addToggles({
  toggle("REMIND_FOOD_TOGGLE", "remindFood"),
  toggle("REMIND_CAMP_TOGGLE", "remindCamp", ns.BuffReminder.HasCampSystem),
})
addSlider({
  label = "REMINDER_INTERVAL",
  min = ns.BuffReminder.MIN_INTERVAL,
  max = ns.BuffReminder.MAX_INTERVAL,
  step = 1,
  get = function(db) return db.reminderInterval end,
  set = function(value) ns.Set("reminderInterval", value) end,
  format = function(value) return string.format(L.MINUTES, value) end,
})
addSection("SECTION_WARNINGS")
addToggles({
  toggle("WARN_BAGS_FULL_TOGGLE", "warnBagsFull"),
  toggle("WARN_DURABILITY_TOGGLE", "warnDurability"),
  toggle("REMIND_TRAINER_TOGGLE", "remindTrainer", ns.TrainerReminder.IsAvailable),
  toggle("WARN_AMMO_TOGGLE", "warnAmmo", ns.GearWarnings.HasAmmo),
  toggle("WARN_INSTANCE_LIMIT_TOGGLE", "warnInstanceLimit"),
})
finishPage()

-- Komfort: Automatik bei Händlern, Quests und Gesprächen
addPage("OPTIONS_TAB_COMFORT")
addSection("SECTION_MERCHANT")
addToggles({
  toggle("AUTO_REPAIR", "autoRepair"),
  toggle("AUTO_REPAIR_GUILD", "autoRepairGuild", ns.Client.HasGuildBank),
  toggle("AUTO_SELL_JUNK", "autoSellJunk"),
})
addSection("SECTION_QUESTS")
addToggles({
  toggle("AUTO_ACCEPT_QUESTS", "autoAcceptQuests"),
  toggle("AUTO_ACCEPT_SHARED", "autoAcceptShared"),
  toggle("AUTO_TURN_IN", "autoTurnIn"),
  toggle("AUTO_CHOOSE_REWARD", "autoChooseReward"),
  toggle("SKIP_GOSSIP", "skipGossip"),
})
addSection("SECTION_DECLINE")
addToggles({
  toggle("DECLINE_TRADES", "declineTrades"),
  toggle("DECLINE_GROUP_INVITES", "declineGroupInvites"),
  toggle("DECLINE_GUILD_INVITES", "declineGuildInvites"),
  toggle("DECLINE_DUELS", "declineDuels"),
})
addHint("COMFORT_HINT")
finishPage()

-- Stream: alles, was nur für Streams gedacht ist (Speedrun hat einen eigenen Reiter)
addPage("OPTIONS_TAB_STREAM")
addSection("SECTION_STREAM")
addToggles({
  { label = "STREAM_MODE", get = function() return ns.StreamMode.IsEnabled() end,
    set = function(checked) ns.StreamMode.SetEnabled(checked) end },
  toggle("STREAMER_PRIVACY", "streamerPrivacy"),
  toggle("HIGHLIGHT_DEATHS", "highlightDeaths"),
})
addBackgroundChooser()
addSection("SECTION_ALERTS")
addToggles({
  toggle("ALERT_TOGGLE_LEVEL_UP", "alertLevelUp"),
  toggle("ALERT_TOGGLE_RARE", "alertRareKill"),
  toggle("ALERT_TOGGLE_ELITE", "alertEliteKill"),
  toggle("ALERT_TOGGLE_LOOT", "alertEpicLoot"),
  toggle("ALERT_TOGGLE_NEAR_DEATH", "alertNearDeath", ns.NearDeath.IsAvailable),
})
finishPage()

-- Speedrun: Splits, Split-Liste und Speedrun-Rekorde
addPage("OPTIONS_TAB_SPEEDRUN")
addSection("SECTION_SPLIT_LIST")
addToggles({
  toggle("SHOW_SPLIT_LIST", "showSplitList"),
  toggle("SHOW_SPLIT_TOTAL", "splitListShowTotal"),
  toggle("SHOW_SPLIT_PLAYED", "splitListShowPlayed"),
})
addSplitComparisonChooser()
addSlider({
  label = "SPLIT_LIST_SIZE",
  min = toPercent(TimerWindow.MIN_SCALE),
  max = toPercent(TimerWindow.MAX_SCALE),
  step = 5,
  get = function(db) return toPercent(ns.SplitList.GetScale(db)) end,
  set = function(value) ns.Set("splitListScale", value / 100) end,
  format = percent,
})
addSlider({
  label = "SPLIT_LIST_ROWS",
  min = ns.SplitList.MIN_ROWS,
  max = ns.SplitList.MAX_ROWS,
  step = 1,
  get = function(db) return db.splitListRows end,
  set = function(value) ns.Set("splitListRows", value) end,
  format = tostring,
})
addSection("SECTION_WORLD_RECORDS")
local recordToggles = {
  toggle("SHOW_WORLD_RECORDS", "showWorldRecords"),
  toggle("SHOW_RECORDS_AGE", "showRecordsAge"),
}
-- Ein Schalter je Abschnitt der Rekord-Daten (1-10, 1-20, ...)
for _, label in ipairs(ns.WorldRecords.GetBracketLabels()) do
  table.insert(recordToggles, {
    text = function() return string.format(L.WORLD_RECORD_ROW, label) end,
    tip = "RECORD_BRACKET_TIP",
    get = function(db) return db.recordBrackets[label] ~= false end,
    set = function(checked)
      ns.db.recordBrackets[label] = checked
      ns.ApplySettings()
    end,
  })
end
addToggles(recordToggles)
addWorldRecordScopeChooser()
finishPage()

-- Profile: Einstellungen benannt speichern, je Charakter wählen, als Text teilen
addPage("OPTIONS_TAB_PROFILES")
addSection("SECTION_PROFILES")
addProfileList()
addProfileSaver()
addButton("PROFILE_EXPORT", function()
  local Profiles = ns.Profiles
  ns.Export.Show(Profiles.DisplayName(Profiles.GetActive()), Profiles.Export(Profiles.GetActive()))
end)
addButton("PROFILE_IMPORT", function() ns.ShowProfileImport() end)
addHint("PROFILE_HINT")
finishPage()

addFooterButton("HISTORY", function() ns.ToggleHistory() end)
addFooterButton("RECAP_TITLE", function() ns.ToggleRecap() end)
addFooterButton("NEW_SESSION", function() ns.StartNewSession() end)

builder.Finish()
ns.RegisterApply(builder.Refresh)

function ns.ToggleOptions()
  if not ns.db then return end
  local panel = builder.panel
  if panel:IsShown() then
    panel:Hide()
  else
    builder.Refresh(ns.db)
    panel:Show()
  end
end
