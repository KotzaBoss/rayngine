package rigid_body

import "core:math/linalg"

import rl "vendor:raylib"


Rigid_Body :: struct {
	position: rl.Vector3,
	velocity: rl.Vector3,
}

axis_thickness :: 10
axis_center_radius :: axis_thickness / 2 + 3

// TODO: Draw reference axis at some corner of the screen, propably should be a separate raylib util
gui :: proc(rb: Rigid_Body, camera: rl.Camera, dt: f32 /* Should we read it or be passed in? */, tex: rl.RenderTexture) {
	assert(rl.IsWindowReady())

	rl.BeginTextureMode(tex)
		rl.ClearBackground(rl.BLANK)

		rl.BeginMode3D(camera)
		{
			x, y, z := rigid_body_axis(rb.position, rb.velocity)

			rl.DrawSphere(rb.position, 1, rl.WHITE)

			cylinder_slices :: 10	// Essentially smoothness

			// Axis
			cylinder_thickness :: 0.5
			rl.DrawCylinderEx(rb.position, x, cylinder_thickness, cylinder_thickness, cylinder_slices, rl.RED)
			rl.DrawCylinderEx(rb.position, y, cylinder_thickness, cylinder_thickness, cylinder_slices, rl.GREEN)
			rl.DrawCylinderEx(rb.position, z, cylinder_thickness, cylinder_thickness, cylinder_slices, rl.BLUE)

			// "Arrow"
			arrow_length :: 5
			rl.DrawCylinderEx(x, x + {5, 0, 0}, cylinder_thickness + 1, 0, cylinder_slices, rl.RED)
			rl.DrawCylinderEx(y, y + {0, 5, 0}, cylinder_thickness + 1, 0, cylinder_slices, rl.GREEN)
			rl.DrawCylinderEx(z, z + {0, 0, 5}, cylinder_thickness + 1, 0, cylinder_slices, rl.BLUE)
		}
		rl.EndMode3D()

	rl.EndTextureMode()


}

@private
rigid_body_axis :: proc(center, forward: rl.Vector3) -> (x, y, z: rl.Vector3) {
	scale :f32 = 10
	x = forward
	y = linalg.orthogonal(-x) * scale
	z = linalg.normalize(linalg.cross(-x, -y)) * scale
	return
}

////////////////////////////////////////////////////////////


import "core:testing"

@test
draw :: proc(t: ^testing.T) {
	rl.InitWindow(1280, 1024, "Rigid body")

	Entity :: struct {
		rigid_body: Rigid_Body,
		cube_size: rl.Vector3,
	}

	entt := Entity{rigid_body={ {0, 0, 0}, {10, 0, 0} }, cube_size={10, 10, 10}}

	entt_center_clicked := false

	camera := rl.Camera3D{
		position={0, 70, 70},
		target={0, 0, 0},
		up={0, 1, 0},
		fovy=60.0,
		projection=.PERSPECTIVE
	}

	rl.SetTargetFPS(60)

	foreground := rl.LoadRenderTexture(rl.GetScreenWidth(), rl.GetScreenHeight())

	for !rl.WindowShouldClose() {
		rl.UpdateCamera(&camera, .FREE)

		gui(entt.rigid_body, camera, rl.GetFrameTime(), foreground)

		rl.BeginDrawing()

		rl.ClearBackground(rl.DARKGRAY)
		rl.BeginMode3D(camera)
			rl.DrawGrid(100, 10)

			rl.DrawCubeV(entt.rigid_body.position, entt.cube_size, rl.GRAY)
			rl.DrawCubeWiresV(entt.rigid_body.position, entt.cube_size, rl.BLACK)

		rl.EndMode3D()

		rl.DrawTextureRec(foreground.texture, {0, 0, auto_cast rl.GetScreenWidth(), auto_cast -rl.GetScreenHeight()}, {0, 0}, rl.WHITE)

		rl.EndDrawing()
	}

	rl.CloseWindow()
}
