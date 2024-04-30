package ui

import intr "base:intrinsics"
import "base:runtime"

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:slice"

import rb "rayngine:rigid_body"
import rlu "rayngine:raylibutil"

import rl "vendor:raylib"

Camera_Focus :: struct {
	target, position: rl.Vector3,
	distance: f32,
}

Context :: struct($Entity: typeid) where
	intr.type_field_type(Entity, "rigid_body") == rb.Rigid_Body,
	intr.type_field_type(Entity, "model") == rl.Model,
	intr.type_field_type(Entity, "ui") == Entity_Info
{
	camera: rl.Camera,
	mouse: Mouse,
	selected: #soa [dynamic]Entity,	// TODO: Tweak to hold a pointer?
	focus: union{ Camera_Focus },
}

make_context :: proc($Entity: typeid, camera: rl.Camera) -> Context(Entity) {
	return {
		camera,
		Mouse{},
		make_soa(#soa [dynamic]Entity),
		nil,
	}
}

// Entities should already be filtered down to subset that are on screen
update :: proc(ui: ^Context($Entity),
	entities: #soa []Entity,
	camera: struct {
		move_speed: f32,
		rotation_speed: f32,
		scroll_speed: f32,
	}
) {
	update_camera(&ui.camera, camera.move_speed, camera.rotation_speed, camera.scroll_speed)

	update_mouse(&ui.mouse, ui.camera)
	switch s in ui.mouse.selection {
		case rl.Rectangle:
			// TODO: Make it a bit more sophisticated when things start to get settled
			clear_soa(&ui.selected)
			for e in entities {
				screen_pos := rl.GetWorldToScreen(e.rigid_body.position, ui.camera)
				if rl.CheckCollisionPointRec(screen_pos, s) {
					append_soa(&ui.selected, e)
				}
			}
		case rl.Ray:
			clear_soa(&ui.selected)
			for e in entities {
				if rlu.ray_model_collide(s, e.model, rb.transform(e.rigid_body)) {
					append_soa(&ui.selected, e)
					// TODO: Resolve depth
					break
				}
			}
	}

	// If multi-selected with LEFT_ALT, make camera target the centroid of selected entities
	if ui.mouse.selection != nil && len(ui.selected) > 0 && rl.IsKeyDown(.LEFT_ALT) {
		// FIXME: Remove this when UI.selected.rigid_bodies[:] can compile
		_, rigid_bodies, _, _ := soa_unzip(ui.selected[:])

		// TODO: move centroid calculation to rigid_body.odin
		//       centroid :: proc(rbs: []Rigid_Body) -> rl.Vector3 {}
		sum := slice.reduce(rigid_bodies, rl.Vector3{}, proc(sum: rl.Vector3, rb: rb.Rigid_Body) -> rl.Vector3 {
				return sum + rb.position
			})

		centroid := sum / f32(len(ui.selected))

		ui.focus = Camera_Focus{
			target = centroid,
			position = ui.camera.position + (centroid - ui.camera.target),
			distance = rlu.camera_target_distance(ui.camera)
		}
	}
	else if ui.focus != nil {
		focus := ui.focus.(Camera_Focus)

		speed :: 15
		weight := speed * rl.GetFrameTime()

		ui.camera.target = math.lerp(ui.camera.target, focus.target, weight)
		ui.camera.position = math.lerp(ui.camera.position, focus.position, weight)

		// TODO: Stop if player uses the camera in any way.
		if rlu.camera_target_distance(ui.camera) < focus.distance + 5 && ui.camera.target == focus.target {
			fmt.println("done")
			ui.focus = nil
		}
	}
}

draw :: proc(ui: Context($Entity)) {
	if s, is_rect := ui.mouse.selection.(rl.Rectangle); is_rect {
		rl.DrawRectangleLinesEx(s, 1, rl.BLUE)
	}

	for e in ui.selected {
		screen_pos := rl.GetWorldToScreen(e.rigid_body.position, ui.camera)
		rl.DrawRectangleLines(
			auto_cast (screen_pos.x - e.ui.size / 2), auto_cast (screen_pos.y - e.ui.size / 2),
			auto_cast e.ui.size, auto_cast e.ui.size,
			rl.GREEN
		)
	}
}

delete_context :: proc(ui: Context($Entity)) {
	delete(ui.selected)
}


// Collection of data to be embedded in "game entities" to track information related to the ui.
Entity_Info :: struct {
	size: f32,
}

make_info :: proc(bb: rl.BoundingBox) -> Entity_Info {
	x := bb.max - bb.min
	m := slice.min(x[:])
	return { linalg.distance(bb.max, bb.min) }
}


Mouse :: struct {
	selection: union{ rl.Rectangle, rl.Ray },

	anchor: rl.Vector2,
	rect: rl.Rectangle,
}

update_mouse :: proc(m: ^Mouse, camera: rl.Camera) {
	if rl.IsMouseButtonPressed(.LEFT) {
		m.anchor = rl.GetMousePosition()
		m.rect = {}
	}
	else if rl.IsMouseButtonDown(.LEFT) {
		pos := rl.GetMousePosition()

		m.rect = rl.Rectangle{
			x = m.anchor.x,
			y = m.anchor.y,
			width = abs(pos.x - m.anchor.x),
			height = abs(pos.y - m.anchor.y),
		}

		if pos.x < m.anchor.x do m.rect.x = pos.x
		if pos.y < m.anchor.y do m.rect.y = pos.y

		m.selection = m.rect
	}
	else if rl.IsMouseButtonReleased(.LEFT) {
		if m.rect.width == 0 && m.rect.height == 0 {
			m.selection = rlu.mouse_ray(camera)
		}
	}
	else {
		m.selection = nil
	}
}


// Third person camera
//
// WASD: Move
// Middle mouse: Rotate
// Scroll: Zoom
//
update_camera :: proc(camera: ^rl.Camera, move_speed: f32, rotation_speed: f32, scroll_speed: f32) {
	if rl.IsKeyDown(.W) do rl.CameraMoveForward(camera,  move_speed, moveInWorldPlane=true);
	if rl.IsKeyDown(.A) do rl.CameraMoveRight(camera,   -move_speed, moveInWorldPlane=true);
	if rl.IsKeyDown(.S) do rl.CameraMoveForward(camera, -move_speed, moveInWorldPlane=true);
	if rl.IsKeyDown(.D) do rl.CameraMoveRight(camera,    move_speed, moveInWorldPlane=true);

	if rl.IsMouseButtonDown(.MIDDLE) {
		delta := rl.GetMouseDelta() * rotation_speed
		rl.CameraYaw(camera, delta.x, rotateAroundTarget=true)
		rl.CameraPitch(camera, delta.y, lockView=true, rotateAroundTarget=true, rotateUp=false)
	}
	else if rl.IsKeyDown(.Q) do rl.CameraYaw(camera, -rotation_speed, rotateAroundTarget=true)
	else if rl.IsKeyDown(.E) do rl.CameraYaw(camera,  rotation_speed, rotateAroundTarget=true)

	rl.CameraMoveToTarget(camera, -rl.GetMouseWheelMove() * scroll_speed)
}

