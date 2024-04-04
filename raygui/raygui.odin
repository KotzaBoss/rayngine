package raygui

import rl "vendor:raylib"

// Must be generated in the CURRENT_BINARY_DIR
foreign import gui "libraygui.a"

GuiModelWindowState :: struct{
	ModelWindowActive: bool,
	layoutRecs: [1]rl.Rectangle
}

foreign gui {
	InitGuiModelWindow :: proc() -> GuiModelWindowState ---
	GuiModelWindow :: proc(s: ^GuiModelWindowState) ---
}

