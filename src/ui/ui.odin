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


Context :: struct($Entity: typeid) where
	intr.type_field_type(Entity, "rigid_body") == rb.Rigid_Body,
	intr.type_field_type(Entity, "model") == rl.Model,
	intr.type_field_type(Entity, "ui") == Entity_Info
{
	mouse: Mouse,
	selected: [dynamic]Entity,	// TODO: Tweak to hold a pointer?
}

// Entities should already be filtered down to subset that are on screen
update_context :: proc(ui: ^Context($Entity), entities: #soa []Entity, camera: rl.Camera) {
	update(&ui.mouse, camera)

	switch s in ui.mouse.selection {
		case rl.Rectangle:
			// TODO: Make it a bit more sophisticated when things start to get settled
			clear(&ui.selected)
			for e in entities {
				screen_pos := rl.GetWorldToScreen(e.rigid_body.position, camera)
				if rl.CheckCollisionPointRec(screen_pos, s) {
					append(&ui.selected, e)
				}
			}
		case rl.Ray:
			clear(&ui.selected)
			for e in entities {
				if rlu.ray_model_collide(s, e.model, rb.transform(e.rigid_body)) {
					append(&ui.selected, e)
					// TODO: Resolve depth
					break
				}
			}
	}
}

draw :: proc(ui: Context($Entity), camera: rl.Camera) {
	if s, is_rect := ui.mouse.selection.(rl.Rectangle); is_rect {
		rl.DrawRectangleLinesEx(s, 1, rl.BLUE)
	}

	for e in ui.selected {
		screen_pos := rl.GetWorldToScreen(e.rigid_body.position, camera)
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

	// Private
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
// Alt + mouse: Rotate
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


update :: proc{
	update_context,
	update_mouse,
	update_camera,
}
