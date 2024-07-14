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

import game "hootools:game"
import ecs "hootools:ecs"
import rlu "hootools:raylib"

import "rayngine:ui"

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

	// Logging
	context.logger = log.create_console_logger()
	defer log.destroy_console_logger(context.logger)


	//////////////////////////////////////////////////////////////////////////////////


	rl.InitWindow(rl.GetScreenWidth(), rl.GetScreenHeight(), "raylib [core] example - basic window")

	rl.rlSetClipPlanes(rl.RL_CULL_DISTANCE_NEAR, 100000)

	ECS := ecs.make(100)
	defer ecs.delete(ECS)

	ecs.register(&ECS, rl.Model)
	ecs.register(&ECS, game.Transform)

	entities := make([dynamic]ecs.Entity, 0, 100)
	entities.allocator = mem.panic_allocator()

	{
		// TODO: Make a "paths" file for all the predefined paths
		mini :: #config(RAYNGINE_MINI_SPACE_PACK_DIR, "")
		fd, ok1 := os.open(mini)
		defer os.close(fd)
		fmt.assertf(ok1 == 0, "Error opening: {}", mini)	// Is this idiomatic? what if multiplefunctions return the same error type?

		files, ok2 := os.read_dir(fd, 0)
		defer delete(files)
		assert(ok2 == 0)

		files = slice.filter(files, proc(f: os.File_Info) -> bool { return filepath.ext(f.name) == ".glb" })

		for f, i in files {
			e, ok := ecs.create(&ECS)
			assert(ok)

			{
				ecs.compose(&ECS, e, game.Transform)
				transform, _ := ecs.component(ECS, e, game.Transform)
				transform^ = {
						translation = {-100 + auto_cast i * 50, 0, 0},
						forward = {0, 0, 1},
						scale = 1
					}
			}

			{
				ecs.compose(&ECS, e, rl.Model)
				model, _ := ecs.component(ECS, e, rl.Model)
				fullpath := strings.clone_to_cstring(f.fullpath)
				defer delete(fullpath)

				model^ = rl.LoadModel(fullpath)

				transform, _ := ecs.component(ECS, e, game.Transform)
				model.transform = game.to_matrix(transform^)
			}

			append(&entities, e)
		}
	}
	defer {
		entities.allocator = context.allocator
		delete(entities)
	}

	UI := ui.make(
			rl.Camera3D{
				position={0, 50, 50},
				target=0,
				up={0, 1, 0},
				fovy=60.0,
				projection=.PERSPECTIVE
			}
		)

	rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
		ui.update(&UI, ECS)

        rl.BeginDrawing()
            rl.ClearBackground(rl.DARKGRAY)

			rl.BeginMode3D(UI.camera)
				rl.DrawGrid(1000, 1000)

				rl.DrawLine3D({0, 0, 0}, {3000, 0, 0}, rl.RED)
				rl.DrawLine3D({0, 0, 0}, {0, 3000, 0}, rl.GREEN)
				rl.DrawLine3D({0, 0, 0}, {0, 0, 3000}, rl.BLUE)

				for e in entities {
					model, err := ecs.component(ECS, e, rl.Model)
					assert(err == .None)
					rl.DrawModel(model^, 0, 1, rl.WHITE)
				}
			rl.EndMode3D()

			ui.draw(UI, ECS)

			rl.DrawFPS(10, 10)

        rl.EndDrawing()
    }

    rl.CloseWindow()
}

