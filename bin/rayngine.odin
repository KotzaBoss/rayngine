package rayngine

import "core:math"
import "core:math/linalg"
import "core:log"	// Why doesnt it work?
import "core:fmt"
import "core:slice"
import "core:strings"
import "core:os"
import "core:path/filepath"
import "core:mem"

import rl "vendor:raylib"

import rg "rayngine:raygui"
import shm "rayngine:spatial_hash_map"
import tr "rayngine:transform"
import ecs "rayngine:ecs"
import rlu "rayngine:raylibutil"

import "rayngine:ui"

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


	rl.InitWindow(rl.GetScreenWidth(), rl.GetScreenHeight(), "raylib [core] example - basic window")

	rl.rlSetClipPlanes(rl.RL_CULL_DISTANCE_NEAR, 100000)

	entities := make_soa(#soa [dynamic]ecs.Entity, 0, 100)
	entities.allocator = mem.panic_allocator()

	{
		// TODO: Make a "paths" file for all the predefined paths
		mini :: #config(RAYNGINE_MINI_SPACE_PACK_DIR, "")
		fd, ok1 := os.open(mini)
		defer os.close(fd)
		assert(ok1 == 0)	// Is this idiomatic? what if multiplefunctions return the same error type?

		files, ok2 := os.read_dir(fd, 0)
		defer delete(files)
		assert(ok2 == 0)

		files = slice.filter(files, proc(f: os.File_Info) -> bool { return filepath.ext(f.name) == ".glb" })

		for f, i in files {
			fullpath := strings.clone_to_cstring(f.fullpath)
			defer delete(fullpath)

			model := rl.LoadModel(fullpath)

			append_soa(&entities, ecs.Entity{
					name=f.name,
					transform={
							translation = {-100 + auto_cast i * 50, 0, 0},
							forward = {0, 0, 1},
							scale = 1
						},
					model={raylib=model, offsets={ rotation={0, 180, 0} }},
					ui=ui.make_info(rl.GetModelBoundingBox(model))
				})
		}
	}
	defer {
		entities.allocator = context.allocator
		delete(entities)
	}

	UI := ui.make_context(ecs.Entity,
			rl.Camera3D{
				position={0, 50, 50},
				target=0,
				up={0, 1, 0},
				fovy=60.0,
				projection=.PERSPECTIVE
			}
		)
	defer ui.delete_context(UI)

	rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
		filtered_entities := entities[:]

		move_order_target := ui.update(&UI, &filtered_entities, camera={ move_speed=5.0, rotation_speed=0.01, scroll_speed=10 })

		if target, ok := move_order_target.?; ok {
			for &e in UI.selection.entities {
				e.target = target
			}
		}

		ecs.update(filtered_entities)

        rl.BeginDrawing()
            rl.ClearBackground(rl.DARKGRAY)

			rl.BeginMode3D(UI.camera)
				rl.DrawGrid(1000, 1000)

				rl.DrawLine3D({0, 0, 0}, {3000, 0, 0}, rl.RED)
				rl.DrawLine3D({0, 0, 0}, {0, 3000, 0}, rl.GREEN)
				rl.DrawLine3D({0, 0, 0}, {0, 0, 3000}, rl.BLUE)

				ecs.draw(filtered_entities)
			rl.EndMode3D()

			ui.draw(UI)

			rl.DrawFPS(10, 10)

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
