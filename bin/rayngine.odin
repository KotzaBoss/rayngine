package rayngine

import "core:math"
import "core:log"	// Why doesnt it work?
import "core:fmt"
import "core:slice"
import "core:strings"
import "core:os"
import "core:path/filepath"
import "core:mem"

import rl "vendor:raylib"

import rg "rayngine:raygui"

Animation_State :: enum {
	Idle,
	Walking,
}

// Name matches GirlSample file name for simplicity
Animation_Direction :: enum {
	Left,
	UpLeft,
	Up,
	UpRight,
	Right,
	DownRight,
	Down,
	DownLeft,
}

position_offset_coeff :: 0.1
// Values empirically tested and appear to be the following axis:
//
//              y+
//              |    z-
//              |   /
//         /----|--/-------/
//        /     | /       /
//       /      |/       /
// -----/-------+-------/-------> x+
//     /       /:      /
//    /       / :     /
//   /-------/-------/
//          /   |
// 			    |
//
// where z- is pointing "forward" from the viewer.
//
position_offsets := [Animation_Direction]rl.Vector3 {
	.Left		= rl.Vector3{ -1,  0,  0 } * position_offset_coeff,
	.UpLeft		= rl.Vector3{ -1,  0, -1 } * position_offset_coeff,
	.Up			= rl.Vector3{  0,  0, -1 } * position_offset_coeff,
	.UpRight	= rl.Vector3{ +1,  0, -1 } * position_offset_coeff,
	.Right		= rl.Vector3{ +1,  0,  0 } * position_offset_coeff,
	.DownRight	= rl.Vector3{ +1,  0, +1 } * position_offset_coeff,
	.Down		= rl.Vector3{  0,  0, +1 } * position_offset_coeff,
	.DownLeft	= rl.Vector3{ -1,  0, +1 } * position_offset_coeff,
}


Player :: struct {
	pos: rl.Vector3,
	state: Animation_State,
	direction: Animation_Direction
}


main :: proc() {
	// Track leaks: https://odin-lang.org/docs/overview/#when-statements
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}


	//////////////////////////////////////////////////////////////////////////////////


	rl.InitWindow(1024, 768, "raylib [core] example - basic window")

	models: [dynamic]rl.Model
	model_names: [dynamic]cstring

	{
		// TODO: Make a "paths" file for all the predefined paths
		fd, ok1 := os.open("res/KayKit_Prototype_Bits_1.0")
		defer os.close(fd)
		assert(ok1 == 0)	// Is this idiomatic? what if multiplefunctions return the same error type?

		files, ok2 := os.read_dir(fd, 0)
		defer delete(files)
		assert(ok2 == 0)

		files = slice.filter(files, proc(f: os.File_Info) -> bool { return filepath.ext(f.name) == ".obj" })

		reserve(&models, len(files))

		for f in files {
			// No slice.transform(...)?
			append(&model_names, strings.clone_to_cstring(f.name))

			// TODO: how to work with such simple and fragmenting allocations
			//       context.temp_allocator?
			fullpath := strings.clone_to_cstring(f.fullpath)
			defer delete(fullpath)

			append(&models, rl.LoadModel(fullpath))
		}
	}
	defer {
		delete(models)

		for n in model_names do delete(n)
		delete(model_names)
	}

	dummy_rotation: f32
	dummy: [dynamic]rl.Model
	defer delete(dummy)

	for n, i in model_names {
		if strings.contains(auto_cast n, "Dummy") {
			append(&dummy, models[i])	// why slice.last(...) doesnt work?
		}
	}

	starting_camera_pos :: rl.Vector3{0, 10, 10}
	camera := rl.Camera3D{
		position=starting_camera_pos,
		target={0, 0, 0},
		up={0, 1, 0},
		fovy=60.0,
		projection=.PERSPECTIVE
	}

	//rl.DisableCursor()
	rl.SetTargetFPS(60)

	player := Player {
		direction = .Down
	}

	s := rg.InitGuiModelWindow()
    for !rl.WindowShouldClose() {
		rl.UpdateCamera(&camera, .FREE)

        rl.BeginDrawing()
            rl.ClearBackground(rl.GRAY)

			rl.BeginMode3D(camera)
				rl.DrawGrid(100, 1.0)
			rl.EndMode3D()


			if rl.IsKeyPressed(.SPACE) do camera.position = starting_camera_pos


			{
				prev_state := player.state

				if rl.IsKeyDown(.W) {
					player.state = .Walking

					if		rl.IsKeyDown(.A)	do player.direction = .UpLeft
					else if	rl.IsKeyDown(.D)	do player.direction = .UpRight
					else						do player.direction = .Up

					player.pos += position_offsets[player.direction]
					camera.position += position_offsets[player.direction]
				}
				else if rl.IsKeyDown(.A) {
					player.state = .Walking

					if		rl.IsKeyDown(.W)	do player.direction = .UpLeft
					else if	rl.IsKeyDown(.S)	do player.direction = .DownLeft
					else						do player.direction = .Left

					player.pos += position_offsets[player.direction]
					camera.position += position_offsets[player.direction]
				}
				else if rl.IsKeyDown(.S) {
					player.state = .Walking

					if		rl.IsKeyDown(.A)	do player.direction = .DownLeft
					else if	rl.IsKeyDown(.D)	do player.direction = .DownRight
					else						do player.direction = .Down

					player.pos += position_offsets[player.direction]
					camera.position += position_offsets[player.direction]
				}
				else if rl.IsKeyDown(.D) {
					player.state = .Walking

					if		rl.IsKeyDown(.W)	do player.direction = .UpRight
					else if	rl.IsKeyDown(.S)	do player.direction = .DownRight
					else						do player.direction = .Right

					player.pos += position_offsets[player.direction]
					camera.position += position_offsets[player.direction]
				}
				else {
					player.state = .Idle
				}

				camera.target = player.pos
			}


			// Draw Models
			{
				batch :: 10
				spacing_coeff :: 7.5

				// Objects
				{
					row: f32
					col: f32
					rl.BeginMode3D(camera)
						for model, i in models {
							if i % batch == 0 {
								row += 1
								col = 0
							}

							pos := rl.Vector3{row, 0, col} * spacing_coeff
							rl.DrawModel(model, pos, 1, rl.WHITE)

							bb := rl.GetModelBoundingBox(model)
							bb.min += pos
							bb.max += pos
							rl.DrawBoundingBox(bb, rl.RED)

							col += 1
						}
					rl.EndMode3D()
				}


				// Names
				{
					font_size :: 12

					row: f32
					col: f32
					for name, i in model_names {
						if i % batch == 0 {
							row += 1
							col = 0
						}

						pos := rl.Vector3{row, 0, col} * spacing_coeff
						center_2d := rl.GetWorldToScreen(pos + {0, 3, 0}, camera)

						rl.DrawText(name, auto_cast center_2d.x - rl.MeasureText(name, font_size)/2, auto_cast center_2d.y, font_size, rl.BLACK)

						col += 1
					}
				}

				// Dummy
				{
					if rl.IsKeyDown(.E) do dummy_rotation += 5
					else if rl.IsKeyDown(.Q) do dummy_rotation -= 5

					rl.BeginMode3D(camera)
						for m in dummy {
							rl.DrawModelEx(m, player.pos, {0, 1, 0}, dummy_rotation, 1, rl.WHITE)
							bb := rl.GetModelBoundingBox(m)
							bb.min += player.pos
							bb.max += player.pos
							rl.DrawBoundingBox(bb, rl.RED)
						}
					rl.EndMode3D()
				}
			}


			// Draw "Center"
			center_2d := rl.GetWorldToScreen({0, 0, 0} + {0.0, 1, 0.0}, camera)
			rl.DrawText("Center", auto_cast center_2d.x - rl.MeasureText("Center", 32)/2, auto_cast center_2d.y, 32, rl.BLACK)


			// Draw UI
			// TODO: Propably can avoid an allocation if we restrict the format of the position
			//       For example 4 digits + 2 precision
			text := fmt.caprintf("{}", player.pos)
			defer delete(text)

			rl.DrawText(text, 0, 0, 32, rl.BLACK)

			rg.GuiModelWindow(&s)

        rl.EndDrawing()
    }

    rl.CloseWindow()
}


// TODO: Save in a .odin file for reference (could be named smth like sprint/atlas.odin)

// Return the position on a 2d array as if we considered that array
// a 1d strip
//
// |00(0)| 01(1)| 02(2)|
// |10(3)| 11(4)| 12(5)|
// |20(6)| 21(7)| 22(8)|
//
// 5 -> (1, 2)
// 7 -> (2, 1)
//array_index_from_1d_to_2d :: proc(index: uint, width: uint) -> [2]uint {
//	assert(width > 0)
//
//	div, mod := math.floor_divmod(index, width)
//	return { mod, div }
//}
//Frame :: struct {
//	size: rl.Vector2,
//	duration: f32,
//}
//
//Animation :: struct {
//	// Must be initialized and are constant
//	atlas: struct {
//		source: rl.Texture,
//		size: [2]uint,
//		total_frames: uint
//	},
//	frame: Frame,
//
//	// Private
//	timer: f32,
//	index: uint	// Index as if the 2d atlas was a 1d array (see array_index_from_1d_to_2d)
//}
//
//Animations :: [Animation_State][Animation_Direction]Animation
//
//next :: proc(a: ^Animation, frame_time: f32) -> (source: rl.Rectangle) {
//	a.timer += frame_time
//	if a.timer > a.frame.duration {
//		a.timer = 0.0
//		a.index = (a.index + 1) % a.atlas.total_frames // why not working? math.sum(a.texture.atlas_size)
//	}
//
//	atlas_index := array_index_from_1d_to_2d(a.index, a.atlas.size.x)
//	return rl.Rectangle {
//			x = f32(atlas_index.x) * a.frame.size.x,
//			y = f32(atlas_index.y) * a.frame.size.y,
//			width = a.frame.size.x,
//			height = a.frame.size.y,
//		}
//}
//
//dest :: proc(a: ^Animation, pos: rl.Vector2) -> rl.Rectangle {
//	return rl.Rectangle {
//		x = pos.x,
//		y = pos.y,
//		width = a.frame.size.x,
//		height = a.frame.size.y,
//	}
//}
//
//reset :: proc(a: ^Animation) {
//	a.timer = 0
//	a.index = 3
//}


// Was used by GirlSample for altas based sprite animation
	//models: [len(paths)]rl.Model

	//for path, i in paths {
	//	models[i] = rl.LoadModel(path)
	//}

	//frame :: Frame{ size={256, 256}, duration=0.15 }

	//anims: Animations
	//for dir in Animation_Direction {

	//	// Walking
	//	{
	//		walk_file_fmt :: "GirlSample/GirlSample_Walk_256Update/GirlSample_Walk_{}.png"
	//		anims[.Walking][dir] = {
	//			atlas = {
	//				source = rl.LoadTexture(fmt.caprintf(walk_file_fmt, dir)),
	//				size = {4, 3},
	//				total_frames = 9,
	//			},
	//			frame = frame,
	//		}
	//	}

	//	// Idle
	//	{
	//		idle_file_fmt :: "GirlSample/GirlSampleReadyIdle/GirlSample_ReadyIdle_{}.png"
	//		anims[.Idle][dir] = {
	//			atlas = {
	//				source = rl.LoadTexture(fmt.caprintf(idle_file_fmt, dir)),
	//				size = {4, 4},
	//				total_frames = 14,
	//			},
	//			frame = frame,
	//		}
	//	}
	//}

				//center_2d := rl.GetWorldToScreen(player.pos, camera)

				//anim := &anims[player.state][player.direction]
				//if (prev_state != player.state) do reset(anim)

				//src := next(anim, rl.GetFrameTime())
				//dest := rl.Rectangle{ x=center_2d.x - frame.size.x/2, y=center_2d.y - frame.size.y/2, width=frame.size.x, height=frame.size.y }

				//assert(anim != nil && (src.width > 0 && src.height > 0))

				//rl.DrawTexturePro(anim.atlas.source, src, dest, 0, 0, rl.WHITE)
				//center_2d := rl.GetWorldToScreen(player.pos, camera)

				//anim := &anims[player.state][player.direction]
				//if (prev_state != player.state) do reset(anim)

				//src := next(anim, rl.GetFrameTime())
				//dest := rl.Rectangle{ x=center_2d.x - frame.size.x/2, y=center_2d.y - frame.size.y/2, width=frame.size.x, height=frame.size.y }

				//assert(anim != nil && (src.width > 0 && src.height > 0))

				//rl.DrawTexturePro(anim.atlas.source, src, dest, 0, 0, rl.WHITE)
