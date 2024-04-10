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
arrow_tip_offsets := #partial [Axis_Component]rl.Vector3{
		.X = {arrow_length, 0, 0},
		.Y = {0, arrow_length, 0},
		.Z = {0, 0, arrow_length},
	}
axis_colors := #partial [Axis_Component]rl.Color {
		.X = rl.RED,
		.Y = rl.GREEN,
		.Z = rl.BLUE
	}
axis_component_masks := [Axis_Component]rl.Vector3 {
		.None = {},
		.X = {1, 0, 0}, .Y = {0, 1, 0}, .Z = {0, 0, 1},
		.Center = {1, 1, 1},
	}
axes :: []Axis_Component{ .X, .Y, .Z }


// TODO: Draw reference axis at some corner of the screen, propably should be a separate raylib util
gui :: proc(rb: Rigid_Body, camera: rl.Camera, dt: f32 /* Should we read it or be passed in? */, tex: rl.RenderTexture) -> Rigid_Body {
	assert(rl.IsWindowReady())

	rl.BeginTextureMode(tex)
		rl.ClearBackground(rl.BLANK)

		rl.BeginMode3D(camera)
			// Center
			rl.DrawSphere(rb.position, axis_center_radius, rl.WHITE)


			// Axis
			for axis in axes {
				// Cylinder
				axis_end := rb.position + axis_component_masks[axis] * axis_cylinder_length_scale
				rl.DrawCylinderEx(
						rb.position, axis_end,
						axis_cylinder_thickness, axis_cylinder_thickness,
						axis_cylinder_slices,
						axis_colors[axis]
					)

				// "Arrow"
				tip_end := axis_end + arrow_tip_offsets[axis]
				rl.DrawCylinderEx(
						axis_end, tip_end,
						axis_cylinder_thickness + 1, 0,
						axis_cylinder_slices,
						axis_colors[axis]
					)
			}


		// Prepare return value
		projection := rb


		// Click and drag
		@static dragged_component: Axis_Component

		mouse_pos := rl.GetMousePosition()
		mouse_ray := rl.GetMouseRay(mouse_pos, camera)

		axis_component_under_mouse := click_drag(rb, mouse_ray)
		rl.EndMode3D()

		if rl.IsMouseButtonPressed(.LEFT) {
			assert(dragged_component == .None)
			dragged_component = axis_component_under_mouse
		}
		else if rl.IsMouseButtonDown(.LEFT) && dragged_component != .None {
			draw_click_drag_ui(mouse_pos, dragged_component)

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
	rl.EndTextureMode()

	return projection
}


@private
click_drag :: proc(rb: Rigid_Body, mouse_ray: rl.Ray) -> (component: Axis_Component) {
	sphere_collision := rl.GetRayCollisionSphere(mouse_ray, rb.position, axis_center_radius)

	if sphere_collision.hit {
		rl.DrawSphereWires(rb.position, axis_center_radius + 1, 3, 6, rl.WHITE)
		component = .Center
	}

	for axis in axes {
		bb_corner_offset :: 1
		bb := rl.BoundingBox{
			min = rb.position - axis_cylinder_thickness - bb_corner_offset,
			max = rb.position + axis_component_masks[axis] * axis_cylinder_length_scale + arrow_tip_offsets[axis] + axis_cylinder_thickness + bb_corner_offset
		}

		axis_collision := rl.GetRayCollisionBox(mouse_ray, bb)
		if axis_collision.hit {
			rl.DrawBoundingBox(bb, axis_colors[axis])
			component = axis
			break
		}
	}

	return
}


@private
draw_click_drag_ui :: proc(mouse_pos: rl.Vector2, dragged_component: Axis_Component) {
	font_size :: 32
	font_size_extra :: 10
	text_offset := [2]f32 { auto_cast mouse_pos.x + 75, auto_cast mouse_pos.y - 75 + font_size_extra}

	// Guiding line from mouse to prompt
	rl.DrawLineV({mouse_pos.x + 2, mouse_pos.y - 2}, {text_offset.x - 2, text_offset.y + font_size}, rl.WHITE)

	prompt :: "< decrease | increase >"
	component := rl.TextFormat(" {}", dragged_component)
	rl.DrawText(prompt,
			auto_cast text_offset.x, auto_cast text_offset.y,
			font_size, rl.WHITE
		)

	rl.DrawText(component,
			auto_cast text_offset.x + rl.MeasureText(prompt, font_size), auto_cast text_offset.y - font_size_extra,
			font_size + font_size_extra,
			axis_colors[dragged_component]
		)

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
