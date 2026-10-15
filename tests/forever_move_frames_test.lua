-- WoW Forever: Fenster, die der UIParentPanelManager selbst anordnet (UIPanelWindows), werden nicht verschiebbar
-- gemacht; Positionen dort ließen Aktionsleisten und Castbar verrutschen. Freie Fenster bleiben verschiebbar.
UIPanelWindows = { CharacterFrame = { area = "left" } }
local managed = CreateFrame("Frame", "CharacterFrame")
local free = CreateFrame("Frame", "PlayerTalentFrame")

wow.login({ level = 10 })
addon.Set("moveFrames", true)
expect("verwaltetes Fenster: nichts eingehängt", managed._scripts.OnDragStart, nil)
expectTrue("freies Fenster: Ziehen eingehängt", free._scripts.OnDragStart ~= nil)
