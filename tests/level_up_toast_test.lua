-- WoW Forever: Das Level-Up-Banner ist ein Toast des EventToastManager; er wird nur geschlossen, wenn er kurz nach
-- dem Level-Up erscheint und die neue Stufe im Titel trägt. Andere Toasts bleiben unberührt; das Frame selbst auch.
Enum = { EventToastDisplayType = { NormalTitleAndSubTitle = 2, NormalSingleLine = 0 } }
local manager = CreateFrame("Frame", "EventToastManagerFrame", UIParent)
local closed = 0
function manager:CloseActiveToasts() closed = closed + 1 end

wow.login({ level = 3 })
local gains = { health = 90, strength = 3 }

local function showToast(info)
  manager.currentDisplayingToast = { toastInfo = info }
  manager:Show()
  manager:Hide()
end

showToast({ displayType = 2, title = "Stufe 4" })
expect("ohne Level-Up: bleibt", closed, 0)

wow.levelUp(4, nil, gains)
showToast({ displayType = 0, title = "Stufe 4" })
expect("andere Art: bleibt", closed, 0)
showToast({ displayType = 2, title = "Stufe 9" })
expect("andere Stufe: bleibt", closed, 0)
showToast({ displayType = 2, title = "Stufe 4" })
expect("Level-Up-Toast: geschlossen", closed, 1)
expect("Frame selbst unangetastet", manager:GetAlpha(), 1)

addon.Set("levelUpHideBlizzard", false)
showToast({ displayType = 2, title = "Stufe 4" })
expect("Einstellung aus: bleibt", closed, 1)
addon.Set("levelUpHideBlizzard", true)

wow.advance(6)
showToast({ displayType = 2, title = "Stufe 4" })
expect("zu spät: bleibt", closed, 1)
