package mw

import r "vendor:raylib"

foreign import g "build/raygui/libgui_ModelWindow.a"
GuiModelWindowState :: struct{
	ModelWindowActive: bool,
	layoutRecs: [1]r.Rectangle
}
foreign g {
	InitGuiModelWindow :: proc() -> GuiModelWindowState ---
	GuiModelWindow :: proc(s: ^GuiModelWindowState) ---
}

main :: proc() {
	r.InitWindow(1024, 768, "Some")

	s := InitGuiModelWindow()

	for !r.WindowShouldClose() {
		r.BeginDrawing()

			r.ClearBackground(r.GRAY)

			GuiModelWindow(&s)
			r.DrawText("Text", 50, 50, 32, r.BLACK)

		r.EndDrawing()
	}
	r.CloseWindow()
}

