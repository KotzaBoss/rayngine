package rayngine

import "core:math"
import "core:log"	// Why doesnt it work?
import "core:fmt"

import rl "vendor:raylib"

// Return the position on a 2d array as if we considered that array
// a 1d strip
//
// |00(0)| 01(1)| 02(2)|
// |10(3)| 11(4)| 12(5)|
// |20(6)| 21(7)| 22(8)|
//
// 5 -> (1, 2)
// 7 -> (2, 1)
array_index_from_1d_to_2d :: proc(index: uint, width: uint) -> [2]uint {
	assert(width > 0)

	div, mod := math.floor_divmod(index, width)
	return { mod, div }
}

Animation_State :: enum {
	Idle,
	Walking,
}

Animation_Direction :: enum {
	Left,
	Up_Left,
	Up,
	Up_Right,
	Right,
	Down_Right,
	Down,
	Down_Left,
}

Frame :: struct {
	size: rl.Vector2,
	duration: f32,
}

Animation :: struct {
	// Must be initialized and are constant
	atlas: struct {
		source: rl.Texture,
		size: [2]uint,
		total_frames: uint
	},
	frame: Frame,

	// Mutable
	timer: f32,
	index: uint	// Index as if the 2d atlas was a 1d array (see array_index_from_1d_to_2d)
}

Animations :: [Animation_State][Animation_Direction]Animation

next :: proc(a: ^Animation, frame_time: f32) -> (source: rl.Rectangle) {
	a.timer += frame_time
	if a.timer > a.frame.duration {
		a.timer = 0.0
		a.index = (a.index + 1) % a.atlas.total_frames // why not working? math.sum(a.texture.atlas_size)
	}

	atlas_index := array_index_from_1d_to_2d(a.index, a.atlas.size.x)
	return rl.Rectangle {
			x = f32(atlas_index.x) * a.frame.size.x,
			y = f32(atlas_index.y) * a.frame.size.y,
			width = a.frame.size.x,
			height = a.frame.size.y,
		}
}

dest :: proc(a: ^Animation, pos: rl.Vector2) -> rl.Rectangle {
	return rl.Rectangle {
		x = pos.x,
		y = pos.y,
		width = a.frame.size.x,
		height = a.frame.size.y,
	}
}


main :: proc() {
	rl.InitWindow(1024, 768, "raylib [core] example - basic window")

	camera := rl.Camera3D{
		position={0, 10, 10},
		target={0, 0, 0},
		up={0, 1, 0},
		fovy=45.0,
		projection=.PERSPECTIVE
	}

	frame :: Frame{ size={256, 256}, duration=0.15 }

	anims := #partial Animations {
		.Idle = #partial {
			.Left = Animation {
				atlas = {
					source = rl.LoadTexture("GirlSample/GirlSampleReadyIdle/GirlSample_ReadyIdle_Left.png"),
					size = {4, 4},
					total_frames = 14,
				},
				frame = frame,
			},
		},
		.Walking = #partial {
			.Left = Animation {
				atlas = {
					source = rl.LoadTexture("GirlSample/GirlSample_Walk_256Update/GirlSample_Walk_Left.png"),
					size = {4, 3},
					total_frames = 9,
				},
				frame = frame,
			},
		}
	}

	//rl.DisableCursor()
	rl.SetTargetFPS(60)

	cube_position := rl.Vector3{0.0, 0.0, 0.0}

    for !rl.WindowShouldClose() {
		rl.UpdateCamera(&camera, .FIRST_PERSON)

		if (rl.IsKeyDown(.W)) {
			cube_position.z -= 1
			camera.position.z -= 1
		}
		if (rl.IsKeyDown(.A)) {
			cube_position.x -= 1
			camera.position.x -= 1
		}
		if (rl.IsKeyDown(.S)) {
			cube_position.z += 1
			camera.position.z += 1
		}
		if (rl.IsKeyDown(.D)) {
			cube_position.x += 1
			camera.position.x += 1
		}

		camera.target = cube_position

        rl.BeginDrawing()
            rl.ClearBackground(rl.GRAY)

			rl.BeginMode3D(camera)
				rl.DrawGrid(100, 1.0)
			rl.EndMode3D()

			dest := rl.Rectangle{ x=0, y=0, width=frame.size.x, height=frame.size.y }

			{
				// TODO: Add all walking animations (dont bother with optimizing the if-if-if)
				anim: ^Animation
				src: rl.Rectangle
				if (rl.IsKeyDown(.A)) {
					anim = &anims[.Walking][.Left]
					src = next(anim, rl.GetFrameTime())
				}
				else {
					anim = &anims[.Idle][.Left]
					src = next(anim, rl.GetFrameTime())
				}

				assert(anim != nil && (src.width > 0 && src.height > 0))
				rl.DrawTexturePro(anim.atlas.source, src, dest, 0, 0, rl.WHITE)
			}

			// Draw center
			rl.BeginMode3D(camera)
				rl.DrawSphere({0, 0, 0}, 0.01, rl.BLACK)
			rl.EndMode3D()
			cube_screen_pos := rl.GetWorldToScreen({0, 0, 0} + {0.0, 1, 0.0}, camera)
			rl.DrawText("Center", cast(i32)cube_screen_pos.x - rl.MeasureText("Center", 32)/2, cast(i32)cube_screen_pos.y, 32, rl.BLACK);

        rl.EndDrawing()
    }

    rl.CloseWindow()

}
