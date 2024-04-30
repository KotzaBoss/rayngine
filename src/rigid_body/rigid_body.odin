package rigid_body

import "core:math"
import "core:math/linalg"
import "core:slice"
import "core:fmt"

import rl "vendor:raylib"

Rigid_Body :: struct {
	position: rl.Vector3,
	rotation: rl.Vector3,	// In degrees
	scale: f32,
}

Transform :: #row_major matrix[4, 4]f32

translation :: proc(rb: Rigid_Body) -> Transform {
	using rb
	return rl.MatrixTranslate(position.x, position.y, position.z)
}

rotation :: proc(rb: Rigid_Body) -> Transform {
	using rb
	return rl.MatrixRotateXYZ({math.to_radians(rotation.x), math.to_radians(rotation.y), math.to_radians(rotation.z)})
}

scale :: proc(rb: Rigid_Body) -> Transform {
	return rl.MatrixScale(rb.scale, rb.scale, rb.scale)
}

transform :: proc(rb: Rigid_Body) -> Transform {
	return translation(rb) * rotation(rb) * scale(rb)
}


centroid :: proc(rbs: []Rigid_Body) -> rl.Vector3 {
	sum := slice.reduce(rbs, rl.Vector3{}, proc(sum: rl.Vector3, rb: Rigid_Body) -> rl.Vector3 {
			return sum + rb.position
		})
	return sum / auto_cast len(rbs)
}

/////////////////////////////////////// Gui


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
direction_length_scale :: 10

// TODO: Draw reference axis at some corner of the screen, propably should be a separate raylib util
gui :: proc(
		rb: Rigid_Body,
		camera: rl.Camera,
		dt: f32 /* Should we read it or be passed in? */,
		tex: rl.RenderTexture,
		activation_key: rl.KeyboardKey = .KEY_NULL	// Default value means always
	) -> (projection: Rigid_Body)
{
	assert(rl.IsWindowReady())

	projection = rb

	// Everything will be drawn onto the texture
	rl.BeginTextureMode(tex)
	defer rl.EndTextureMode()

	rl.ClearBackground(rl.BLANK)

	@static dragged_component: Axis_Component

	if !rl.IsKeyDown(activation_key) {
		dragged_component = .None
		return
	}

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
					axis_colors[axis],
				)
		}

		// Direction
		//{
		//	direction_end := rb.position + rb.direction * direction_length_scale
		//	rl.DrawCylinderEx(
		//			rb.position, direction_end,
		//			axis_cylinder_thickness, axis_cylinder_thickness,
		//			axis_cylinder_slices,
		//			rl.ORANGE
		//		)

		//	tip_end := direction_end + rb.direction * arrow_length
		//	rl.DrawCylinderEx(
		//			direction_end, tip_end,
		//			axis_cylinder_thickness + 1, 0,
		//			axis_cylinder_slices,
		//			rl.ORANGE,
		//		)
		//}

	rl.EndMode3D()

	// Click and drag
	mouse_pos := rl.GetMousePosition()
	mouse_ray := rl.GetScreenToWorldRay(mouse_pos, camera)

	axis_component_under_mouse := draw_axis_bounding_boxes_and_check_mouse_collision(rb, mouse_ray, camera)

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

	return
}


@private
draw_axis_bounding_boxes_and_check_mouse_collision :: proc(rb: Rigid_Body, mouse_ray: rl.Ray, camera: rl.Camera) -> Axis_Component {
	rl.BeginMode3D(camera)
	defer rl.EndMode3D()

	sphere_collision := rl.GetRayCollisionSphere(mouse_ray, rb.position, axis_center_radius)

	if sphere_collision.hit {
		rl.DrawSphereWires(rb.position, axis_center_radius + 1, 3, 6, rl.WHITE)
		return .Center
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
			return axis
		}
	}

	return .None
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
		model: rl.Model,
	}

	entt := Entity{
			rigid_body={ {0, 0, 0}, {}, 1 },
			model=rl.LoadModelFromMesh(rl.GenMeshCube(10, 30, 90))
		}

	entt_center_clicked := false

	camera := rl.Camera3D{
		position={20, 70, 70},
		target=entt.rigid_body.position,
		up={0, 1, 0},
		fovy=60.0,
		projection=.PERSPECTIVE
	}

	rl.SetTargetFPS(60)

	foreground := rl.LoadRenderTexture(rl.GetScreenWidth(), rl.GetScreenHeight())

	for !rl.WindowShouldClose() {

		entt.rigid_body = gui(entt.rigid_body, camera, rl.GetFrameTime(), foreground, activation_key=.LEFT_ALT)

		if rl.IsKeyDown(.A) do entt.rigid_body.rotation.y += 1
		if rl.IsKeyDown(.D) do entt.rigid_body.position.y += 1
		entt.model.transform = transform(entt.rigid_body)

		rl.BeginDrawing()

		rl.ClearBackground(rl.DARKGRAY)
		rl.BeginMode3D(camera)
			rl.DrawSphere({0, 0, 0}, 1, rl.BLACK)
			rl.DrawGrid(100, 10)

			rl.DrawSphere(entt.rigid_body.position, 10, rl.BLUE)

			color := rl.WHITE
			for i in 0..<entt.model.meshCount {
				collision := rl.GetRayCollisionMesh(
						rl.GetScreenToWorldRay(rl.GetMousePosition(), camera),
						entt.model.meshes[i],
						entt.model.transform
					)
				if collision.hit {
					color = rl.RED
				}
			}

			rl.DrawModel(entt.model, entt.rigid_body.position, 1, color)
			rl.DrawModelWires(entt.model, entt.rigid_body.position, 1, rl.BLACK)
		rl.EndMode3D()

		rl.DrawTextureRec(foreground.texture, {0, 0, auto_cast rl.GetScreenWidth(), auto_cast -rl.GetScreenHeight()}, {0, 0}, rl.WHITE)

		rl.DrawText("Press LEFT_ALT to activate rigid_body gui mode", 10, 10, 42, rl.WHITE)

		rl.DrawText(rl.TextFormat("{}", transform(entt.rigid_body)), 0, 50, 42, rl.WHITE)

		rl.EndDrawing()
	}

	rl.UnloadModel(entt.model)

	rl.CloseWindow()
}
