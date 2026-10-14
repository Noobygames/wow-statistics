-- WoW Forever: Das Level-Up-Banner ist ein Toast des EventToastManager; er wird nur ausgeblendet, wenn er kurz nach
-- dem Level-Up erscheint und die neue Stufe im Titel trägt. Andere Toasts bleiben unberührt.
Enum = { EventToastDisplayType = { NormalTitleAndSubTitle = 2, NormalSingleLine = 0 } }
local manager = CreateFrame("Frame", "EventToastManagerFrame", UIParent)

wow.login({ level = 3 })
local gains = { health = 90, strength = 3 }

local function showToast(info)
  manager.currentDisplayingToast = { toastInfo = info }
  manager:Show()
end

-- Toast ohne vorheriges Level-Up bleibt sichtbar
showToast({ displayType = 2, title = "Stufe 4" })
expect("ohne Level-Up: sichtbar", manager:GetAlpha(), 1)
manager:Hide()

wow.levelUp(4, nil, gains)
-- anderer Toast kurz nach dem Level-Up (andere Art): bleibt
showToast({ displayType = 0, title = "Stufe 4" })
expect("andere Art: sichtbar", manager:GetAlpha(), 1)
manager:Hide()
-- Level-Up-Toast: unsichtbar, nach dem Ausblenden wieder normal
showToast({ displayType = 2, title = "Stufe 4" })
expect("Level-Up-Toast: ausgeblendet", manager:GetAlpha(), 0)
manager:Hide()
expect("nach dem Ausblenden zurückgesetzt", manager:GetAlpha(), 1)

-- Einstellung aus: Blizzards Toast bleibt
addon.Set("levelUpHideBlizzard", false)
showToast({ displayType = 2, title = "Stufe 4" })
expect("Einstellung aus: sichtbar", manager:GetAlpha(), 1)
manager:Hide()
addon.Set("levelUpHideBlizzard", true)

-- zu spät nach dem Level-Up: kein Level-Up-Banner mehr
wow.advance(6)
showToast({ displayType = 2, title = "Stufe 4" })
expect("zu spät: sichtbar", manager:GetAlpha(), 1)

-- Fenster an: keine zusätzliche Alert-Karte
manager:Hide()
addon.Set("alertLevelUp", true)
addon.Alerts.Clear()
wow.levelUp(5, nil, gains)
wow.runTimers()
expect("Fenster ersetzt die Karte", LevelTimerNotice:IsShown(), false)
