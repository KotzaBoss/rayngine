package rayngine

import rl "vendor:raylib"
import "src:ecs"

main :: proc() {
	ecs.make()

	rl.InitWindow(800, 450, "raylib [core] example - basic window")

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
            rl.ClearBackground(rl.GRAY)
            rl.DrawText(#config(RAYNGINE_BUILD_TYPE, "?"), 190, 200, 20, rl.BLACK)
        rl.EndDrawing()
    }

    rl.CloseWindow()

}
