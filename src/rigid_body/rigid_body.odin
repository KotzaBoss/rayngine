package rigid_body

import "core:math/linalg"
import "core:slice"
import "core:fmt"

import rl "vendor:raylib"


Rigid_Body :: struct {
	position: rl.Vector3,
	velocity: rl.Vector3,
}


Axis_Component :: enum {
	None,
	X, Y, Z,
	Center
}

// Constants
axis_center_radius :: 1.5
axis_thickness :: 10
axis_cylinder_slices :: 10	// Essentially smoothness
axis_cylinder_thickness :: 0.5
axis_cylinder_length_scale :: 10
arrow_length :: 3.5
arrow_tip_offsets :: []rl.Vector3{
		{arrow_length, 0, 0},
		{0, arrow_length, 0},
		{0, 0, arrow_length},
	}
axis_colors :: []rl.Color { rl.RED, rl.GREEN, rl.BLUE }
axis_component_masks := [Axis_Component]rl.Vector3 {
		.None = {},
		.X = {1, 0, 0}, .Y = {0, 1, 0}, .Z = {0, 0, 1},
		.Center = {1, 1, 1},
	}


// TODO: Draw reference axis at some corner of the screen, propably should be a separate raylib util
gui :: proc(rb: Rigid_Body, camera: rl.Camera, dt: f32 /* Should we read it or be passed in? */, tex: rl.RenderTexture) -> Rigid_Body {
	assert(rl.IsWindowReady())

	rl.BeginTextureMode(tex)
		rl.ClearBackground(rl.BLANK)

		rl.BeginMode3D(camera)

			// Center
			rl.DrawSphere(rb.position, axis_center_radius, rl.WHITE)


			// Axis
			// TODO: Can we partially use .X .Y .Z for the axes?
			axes := [3]rl.Vector3{ {1, 0, 0}, {0, 1, 0}, {0, 0, 1} }
			for zip in soa_zip(axis=axes[:], color=axis_colors, arrow_tip_offset=arrow_tip_offsets) {
				// Cylinder
				axis_end := rb.position + zip.axis * axis_cylinder_length_scale
				rl.DrawCylinderEx(
						rb.position, axis_end,
						axis_cylinder_thickness, axis_cylinder_thickness,
						axis_cylinder_slices,
						zip.color
					)

				// "Arrow"
				tip_end := axis_end + zip.arrow_tip_offset
				rl.DrawCylinderEx(
						axis_end, tip_end,
						axis_cylinder_thickness + 1, 0,
						axis_cylinder_slices,
						zip.color
					)
			}


			projection := rb


			// Click and drag
			mouse_pos := rl.GetMousePosition()
			mouse_ray := rl.GetMouseRay(mouse_pos, camera)

			@static dragged_component: Axis_Component

			axis_component_under_mouse := click_drag(rb, axes, mouse_ray, camera)

			if rl.IsMouseButtonPressed(.LEFT) {
				assert(dragged_component == .None)
				dragged_component = axis_component_under_mouse
			}
			else if rl.IsMouseButtonDown(.LEFT) && dragged_component != .None {
				#partial switch dragged_component {
					case .Center:
					case .X, .Y, .Z:
						projection.position += axis_component_masks[dragged_component] * rl.GetMouseDelta().x
					case:
						panic("Should not be here if we are not dragging")
				}
			}
			else if rl.IsMouseButtonReleased(.LEFT) && dragged_component != .None {
				dragged_component = .None
			}

		rl.EndMode3D()
	rl.EndTextureMode()

	return projection
}


@private
click_drag :: proc(rb: Rigid_Body, rigid_body_axes: [3]rl.Vector3, mouse_ray: rl.Ray, camera: rl.Camera) -> Axis_Component {
	sphere_collision := rl.GetRayCollisionSphere(mouse_ray, rb.position, axis_center_radius)

	if sphere_collision.hit {
		rl.DrawSphereWires(rb.position, axis_center_radius + 1, 3, 6, rl.WHITE)
		return .Center
	}

	rigid_body_axes := rigid_body_axes
	axes :: []Axis_Component {.X, .Y, .Z}
	for zip in soa_zip(rb_axis=rigid_body_axes[:], color=axis_colors, arrow_tip_offset=arrow_tip_offsets, axis=axes) {
		bb_corner_offset :: 1
		bb := rl.BoundingBox{
				min = rb.position - axis_cylinder_thickness - bb_corner_offset,
				max = rb.position + zip.rb_axis * axis_cylinder_length_scale + zip.arrow_tip_offset + axis_cylinder_thickness + bb_corner_offset
			}

		axis_collision := rl.GetRayCollisionBox(mouse_ray, bb)
		if axis_collision.hit {
			rl.DrawBoundingBox(bb, zip.color)
			return zip.axis
		}
	}

	return .None
}


@private
rigid_body_axes :: proc(center, forward: rl.Vector3) -> (axes: [3]rl.Vector3) {
	scale :f32 = 10
	axes.x = forward
	axes.y = linalg.orthogonal(-axes.x) * scale
	axes.z = linalg.normalize(linalg.cross(-axes.x, -axes.y)) * scale
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
		position={20, 70, 70},
		target={0, 0, 0},
		up={0, 1, 0},
		fovy=60.0,
		projection=.PERSPECTIVE
	}

	rl.SetTargetFPS(60)

	foreground := rl.LoadRenderTexture(rl.GetScreenWidth(), rl.GetScreenHeight())

	for !rl.WindowShouldClose() {
		rl.UpdateCamera(&camera, .FREE)

		entt.rigid_body = gui(entt.rigid_body, camera, rl.GetFrameTime(), foreground)

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
