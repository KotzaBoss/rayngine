package ui

import intr "base:intrinsics"
import "base:runtime"

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:slice"

import tr "rayngine:transform"
import rlu "rayngine:raylibutil"

import rl "vendor:raylib"

Selection :: struct($Entity: typeid) {
	entities: [dynamic]#soa ^#soa []Entity,		// TODO: Tweak to hold a pointer?
	centroid: rl.Vector3,
}

Move_Order :: struct {
	point: rl.Vector3,
	radius, height: f32,
}

Context :: struct($Entity: typeid) where
	intr.type_field_type(Entity, "transform") == tr.Transform,
	intr.type_field_type(Entity, "model") == rlu.Model,
	intr.type_field_type(Entity, "ui") == Entity_Info
{
	camera: Camera,
	mouse: Mouse,
	selection: Selection(Entity),
	move_order: union{ Move_Order }
}

make_context :: proc($Entity: typeid, camera: rl.Camera) -> Context(Entity) {
	return {
		camera = Camera{ raylib=camera, rotated_since_right_mouse_button_pressed=false, focus=nil },
		mouse = Mouse{},
		move_order = nil,
	}
}

// Entities should already be filtered down to subset that are on screen
@require_results
update :: proc(ui: ^Context($Entity),
		entities: ^#soa []Entity,
		camera: struct { move_speed, rotation_speed, scroll_speed: f32, }
	) -> (confirmed_move_order: union{ rl.Vector3 })
{
	update_camera(&ui.camera, camera.move_speed, camera.rotation_speed, camera.scroll_speed)


	if ui.move_order == nil {
		entities := entities	// Just to make the pointers taken work

		update_mouse(&ui.mouse, ui.camera.raylib)
		switch s in ui.mouse.selection {
			case rl.Rectangle:
				// TODO: Make it a bit more sophisticated when things start to get settled
				clear(&ui.selection.entities)
				for e, i in entities {
					screen_pos := rl.GetWorldToScreen(e.transform.translation, ui.camera.raylib)
					if rl.CheckCollisionPointRec(screen_pos, s) {
						append(&ui.selection.entities, &entities[i])
					}
				}
			case rl.Ray:
				clear(&ui.selection.entities)
				for &e, i in entities {
					if rlu.ray_model_collide(s, e.model.raylib, tr.to_matrix(e.transform)) {
						append(&ui.selection.entities, &entities[i])
						// TODO: Resolve depth
						break
					}
				}
		}
	}


	// Camera focus

	// rl.IsMouseButtonReleased(.LEFT) is true here
	// If multi-selection with LEFT_ALT, make camera target the centroid of selected entities
	if ui.mouse.selection != nil && len(ui.selection.entities) > 0 {
		// FIXME: Make the tr.centroid(^[]#soa^ #soa[]ecs.Entity) work
		ui.selection.centroid = 0
		for e in ui.selection.entities {
			ui.selection.centroid += e.transform.translation
		}
		ui.selection.centroid /= auto_cast len(ui.selection.entities)

		if rl.IsKeyDown(.LEFT_ALT) {
			ui.camera.focus = Camera_Focus{
				target = ui.selection.centroid,
				position = ui.camera.position + (ui.selection.centroid - ui.camera.target),
				distance = rlu.camera_target_distance(ui.camera.raylib)
			}
		}
	}
	else if ui.camera.focus != nil {
		focus := ui.camera.focus.(Camera_Focus)

		speed :: 15
		weight := speed * rl.GetFrameTime()

		ui.camera.target = math.lerp(ui.camera.target, focus.target, weight)
		ui.camera.position = math.lerp(ui.camera.position, focus.position, weight)

		// TODO: Stop if player uses the camera in any way.
		if rlu.camera_target_distance(ui.camera) < focus.distance + 5 && ui.camera.target == focus.target {
			ui.camera.focus = nil
		}
	}


	// Move Order

	mo, pending := ui.move_order.?

	if !pending {	// Detect move order
		if rl.IsMouseButtonReleased(.RIGHT) && len(ui.selection.entities) > 0 && !ui.camera.rotated_since_right_mouse_button_pressed {
			c := rlu.simple_ray_xzplane_collision(rlu.mouse_ray(ui.camera.raylib), ui.selection.centroid.y)
			ui.move_order = Move_Order{point = c.point, radius = 0, height = 0}
		}
	}
	else if rl.IsMouseButtonPressed(.LEFT) {	// Move order confirmed
		confirmed_move_order = ui.move_order.?.point
		ui.move_order = nil
	}
	else if rl.IsMouseButtonReleased(.RIGHT) && !ui.camera.rotated_since_right_mouse_button_pressed	{	// Cancel move order
		ui.move_order = nil
	}
	else {	// Calculate move order
		assert(len(ui.selection.entities) > 0)

		if rl.IsKeyDown(.LEFT_SHIFT) {
			pos := rl.GetMousePosition()
			delta := rl.GetMouseDelta()
			old_pos := pos - delta
			rl.SetMousePosition(auto_cast old_pos.x, rl.GetMouseY())
			// FIXME: Fix the flickering and add height to move order
		}

		c := rlu.simple_ray_xzplane_collision(rlu.mouse_ray(ui.camera.raylib), ui.selection.centroid.y)

		if c.hit {
			mo.point = c.point
		}
		mo.radius = linalg.distance(ui.selection.centroid, mo.point)
		ui.move_order = mo
	}


	return
}

draw :: proc(ui: Context($Entity)) {
	if s, is_rect := ui.mouse.selection.(rl.Rectangle); is_rect {
		rl.DrawRectangleLinesEx(s, 1, rl.BLUE)
	}

	for e in ui.selection.entities {
		screen_pos := rl.GetWorldToScreen(e.transform.translation, ui.camera)
		rl.DrawRectangleLines(
			auto_cast (screen_pos.x - e.ui.size / 2), auto_cast (screen_pos.y - e.ui.size / 2),
			auto_cast e.ui.size, auto_cast e.ui.size,
			rl.GREEN
		)
	}

	rl.BeginMode3D(ui.camera.raylib)
		if mo, pending := ui.move_order.?; pending {
			assert(len(ui.selection.entities) > 0)

			// Centroid to cursor circle
			//rl.DrawCylinder(ui.selection.centroid, mo.radius, mo.radius, 0, 100, rl.YELLOW)
			rl.DrawCircle3D(ui.selection.centroid, mo.radius, {1, 0, 0}, 90, rl.RED)

			// Centroid to cursor line
			rl.DrawLine3D(ui.selection.centroid, mo.point, rl.RED)

			// Cursor circle
			rl.DrawCircle3D(mo.point, 1, {1, 0, 0}, 90, rl.RED)
		}
	rl.EndMode3D()
}

delete_context :: proc(ui: Context($Entity)) {
	delete(ui.selection.entities)
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
		m.selection = rl.Rectangle{}
		m.anchor = rl.GetMousePosition()
		m.rect = {}
	}
	else if m.selection != nil {	// To confirm the "press" update step has occured
		if rl.IsMouseButtonDown(.LEFT) {
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
}


Camera :: struct {
	using raylib: rl.Camera,
	rotated_since_right_mouse_button_pressed: bool,
	focus: union{ Camera_Focus }
}

Camera_Focus  :: struct {
	target, position: rl.Vector3,
	distance: f32,
}


// Third person camera
//
// WASD: Move
// Right: Rotate
// Scroll: Zoom
//
update_camera :: proc(c: ^Camera, move_speed: f32, rotation_speed: f32, scroll_speed: f32) {
	if rl.IsKeyDown(.W) do rl.CameraMoveForward(&c.raylib,  move_speed, moveInWorldPlane=true);
	if rl.IsKeyDown(.A) do rl.CameraMoveRight(&c.raylib,   -move_speed, moveInWorldPlane=true);
	if rl.IsKeyDown(.S) do rl.CameraMoveForward(&c.raylib, -move_speed, moveInWorldPlane=true);
	if rl.IsKeyDown(.D) do rl.CameraMoveRight(&c.raylib,    move_speed, moveInWorldPlane=true);


	if rl.IsMouseButtonPressed(.RIGHT) {
		c.rotated_since_right_mouse_button_pressed = false
	}
	if rl.IsMouseButtonDown(.RIGHT) {
		delta := rl.GetMouseDelta()

		if delta != 0 {
			c.rotated_since_right_mouse_button_pressed = true
		}

		// Hide and "freeze" mouse to allow for unlimited rotation
		rl.HideCursor()
		old_pos := rl.GetMousePosition() - delta
		rl.SetMousePosition(auto_cast old_pos.x, auto_cast old_pos.y)

		rl.CameraYaw(&c.raylib, delta.x * rotation_speed, rotateAroundTarget=true)
		rl.CameraPitch(&c.raylib, delta.y * rotation_speed, lockView=true, rotateAroundTarget=true, rotateUp=false)

	}
	else if rl.IsMouseButtonReleased(.RIGHT) {
		rl.ShowCursor()
	}

	rl.CameraMoveToTarget(&c.raylib, -rl.GetMouseWheelMove() * scroll_speed)
}

