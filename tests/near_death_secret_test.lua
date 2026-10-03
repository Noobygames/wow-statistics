-- Retail/WoW Forever: UnitHealth ist laut Doku immer geheim. Dann keine Beinahe-Tode, Zeile und
-- Schalter entfallen.
wow.state.interface = 16001  -- WoW Forever
wow.state.health = wow.SECRET
wow.login()
addon.Set("showNearDeaths", true)
expect("in Forever nicht verfügbar", addon.NearDeath.IsAvailable(), false)
wow.fire("UNIT_HEALTH", "player")
expect("kein Beinahe-Tod", addon.Stats.Get(addon.Stats.LEVEL, addon.Stats.NEAR_DEATHS), 0)
for _, stat in ipairs(addon.STAT_LINES) do
  if stat.setting == "showNearDeaths" then
    expect("Zeile ausgeblendet", addon.IsStatShown(stat, addon.db), false)
  end
end
wow.state.interface = 11509
expect("in Classic Era verfügbar", addon.NearDeath.IsAvailable(), true)
