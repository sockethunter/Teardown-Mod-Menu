function draw()
	UiTranslate(UiCenter(), 250)
	UiAlign("center middle")

	--Title
	UiFont("bold.ttf", 48)
	UiText("Teardown-Mod-Menu keybind options")
	
	--Draw buttons
	UiTranslate(0, 200)
	UiFont("regular.ttf", 26)
	UiButtonImageBox("ui/common/box-outline-6.png", 6, 6)
	UiPush()
		UiTranslate(-110, 0)
		if GetString("savegame.mod.keybind") == "q" then
			UiPush()
				UiColor(0.5, 1, 0.5, 0.2)
				UiImageBox("ui/common/box-solid-6.png", 200, 40, 6, 6)
			UiPop()
		end
		if UiTextButton("Q", 200, 40) then
			SetString("savegame.mod.keybind", "q")
		end
		UiTranslate(220, 0)
		if GetString("savegame.mod.keybind") == "y" then
			UiPush()
				UiColor(0.5, 1, 0.5, 0.2)
				UiImageBox("ui/common/box-solid-6.png", 200, 40, 6, 6)
			UiPop()
		end
		if UiTextButton("Y", 200, 40) then
			SetString("savegame.mod.keybind", "y")
		end
	UiPop()
	
	UiTranslate(0, 100)
	if UiTextButton("Close", 200, 40) then
		Menu()
	end
end

