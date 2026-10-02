-- Stream-Modus: Voreinstellung an, vorheriger Stand beim Ausschalten zurück, übersteht /reload.
local StreamMode = addon.StreamMode
local window = LevelTimerFrame

wow.login()
addon.Set("bgAlpha", 0.6)
addon.Set("scale", 1.2)

SlashCmdList.LEVELTIMER("stream")
expect("an", StreamMode.IsEnabled(), true)
expect("Deckkraft bleibt", LevelTimerDB.bgAlpha, 0.6)
expect("Größe bleibt", window:GetScale(), 1.2)
expect("Namen verborgen", LevelTimerDB.streamerPrivacy, true)
expect("Einblendungen an", LevelTimerDB.alertLevelUp, true)

-- /reload: bleibt an, Sicherung bleibt erhalten
wow.logout()
wow.login()
expect("nach Reload an", StreamMode.IsEnabled(), true)

-- Ausschalten über die Einstellungen stellt alles zurück
SlashCmdList.LEVELTIMER("config")
local checkbox = wow.findFrame(function(frame)
  local label = rawget(frame, "label")
  return label and label._text == addon.L.STREAM_MODE
end)
expect("Schalter zeigt an", checkbox:GetChecked(), true)
checkbox:SetChecked(false)  -- wie ein Klick: Haken weg, dann OnClick
checkbox._scripts.OnClick(checkbox)
expect("aus", StreamMode.IsEnabled(), false)
expect("Namen wieder sichtbar", LevelTimerDB.streamerPrivacy, false)
expect("Einblendungen wieder aus", LevelTimerDB.alertLevelUp, false)
expect("Sicherung entfernt", LevelTimerDB.streamBackup, nil)
