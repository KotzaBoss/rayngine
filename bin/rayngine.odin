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
			for &e in UI.unit_selection.entities {
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

			ui.draw(UI, filtered_entities)

			rl.DrawFPS(10, 10)

        rl.EndDrawing()
    }

    rl.CloseWindow()
}

