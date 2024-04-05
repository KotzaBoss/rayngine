package raygui

import rl "vendor:raylib"

// Must be generated in the CURRENT_BINARY_DIR
foreign import gui "libraygui.a"

GuiModelWindowState :: struct{
	ModelWindowActive: bool,
	ModelScrollPanelScrollView: rl.Rectangle,
	ModelScrollPanelScrollOffset, ModelScrollPanelBoundsOffset: rl.Vector2,
	layoutRecs: [2]rl.Rectangle,
}

foreign gui {
	InitGuiModelWindow :: proc() -> GuiModelWindowState ---
	GuiModelWindow :: proc(s: ^GuiModelWindowState) ---
}

