-- Einstellungen: Reiter vorhanden und klickbar, Forever-Optionen nur in WoW Forever.
local L = addon.L

wow.login()
SlashCmdList.LEVELTIMER("config")

for _, tab in ipairs({ "SECTION_GENERAL", "STATISTICS", "OPTIONS_TAB_NOTIFICATIONS", "OPTIONS_TAB_STREAM" }) do
  expectTrue("Reiter " .. tab, wow.click(L[tab]))
end

local function hasToggle(labelKey)
  return wow.findFrame(function(frame)
    local label = rawget(frame, "label")
    return label and label._text == L[labelKey] and frame._scripts.OnClick ~= nil
  end) ~= nil
end

-- Stub-Client ist Retail (Interface 120100): kein Camp-System
expect("Retail ist nicht Forever", addon.Client.IsForever(), false)
expectTrue("Food-Hinweis überall", hasToggle("REMIND_FOOD_TOGGLE"))
expect("Camp-Hinweis nur in Forever", hasToggle("REMIND_CAMP_TOGGLE"), false)

wow.state.interface = 16001
expect("16001 ist Forever", addon.Client.IsForever(), true)
