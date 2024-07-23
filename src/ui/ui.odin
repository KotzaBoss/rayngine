package ui

import intr "base:intrinsics"
import "base:runtime"

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:slice"

import rlu "hootools:raylib"

import rl "vendor:raylib"

import "rayngine:ui/mouse"
import "rayngine:ui/selection"

import "hootools:ecs"
import "hootools:game"

import "core:log"


UI :: struct {
	camera: game.Camera,
	mouse: mouse.Mouse,
	pending_selection: [dynamic]game.Transform,

	active_units, focus: selection.Selection,
	focus_group: ^selection.Selection,
}

make :: proc(c: rl.Camera) -> UI {
	return {
		camera = { raylib = c },
	}
}

update :: proc(ui: ^UI, ECS: ecs.ECS) {
	// TODO: In hootools rename the return from updated to smth like "user moved/interupted"
	camera_updated := game.update(&ui.camera, move_speed=1, rotate_speed=1, scroll_speed=1)
	
	mouse.update(&ui.mouse, ui.camera)

	// Selection
	// Per frame clear and repopulate the pending selection. When we release the left mouse button
	// copy the pending transforms to either camera focus or active units if we press left alt or not respectively.
	{{
		active_selection := rl.IsKeyDown(.LEFT_ALT)	\
			? &ui.focus	\
			: &ui.active_units

		// Collect
		switch s in ui.mouse.selection {
			case rl.Rectangle:
				clear(&ui.pending_selection)

				transforms, err := ecs.components(ECS, game.Transform)
				assert(err == .None)

				// If transform in selection rectangle
				for t, i in transforms {
					screen_pos := rl.GetWorldToScreen(t.translation, ui.camera)
					if rl.CheckCollisionPointRec(screen_pos, s) {
						append(&ui.pending_selection, t)
					}
				}

				if rl.IsMouseButtonReleased(.LEFT) {
					selection.set(active_selection, ui.pending_selection[:])
				}

			case rl.Ray:
				clear(&ui.pending_selection)

				entities := ecs.entities(ECS)

				// If mouse ray collides with model
				transforms, errt := ecs.components(ECS, game.Transform)
				assert(errt == .None)

				models, errm := ecs.components(ECS, rl.Model)
				assert(errm == .None)

				for zip, i in soa_zip(e=entities, m=models, t=transforms) {
					if rlu.ray_model_collide(s, zip.m, game.to_matrix(zip.t)) {
						append(&ui.pending_selection, zip.t)
						// TODO: Resolve depth
						break
					}
				}

				if rl.IsMouseButtonReleased(.LEFT) {
					selection.set(active_selection, ui.pending_selection[:])
				}

			case:
				clear(&ui.pending_selection)
		}
	}}

	// Focus
	{{
		if camera_updated {
			ui.focus_group = nil
		}
		else if rl.IsKeyPressed(.F) {
			ui.focus_group = &ui.active_units
		}
		else if rl.IsMouseButtonReleased(.LEFT) && rl.IsKeyDown(.LEFT_ALT) {
			ui.focus_group = &ui.focus
		}

		if ui.focus_group != nil && len(ui.focus_group.transforms) > 0 {
			game.set_focus(&ui.camera, ui.focus_group.centroid)
		}
	}}
}

draw :: proc(ui: UI, ECS: ecs.ECS) {
	mouse.draw(ui.mouse, ui.camera)

	// Selection
	{{
		// Pending
		for t in ui.pending_selection {
			size :: 70
			screen_pos := rl.GetWorldToScreen(t.translation, ui.camera)
			rl.DrawRectangleLines(
				auto_cast (screen_pos.x - size / 2), auto_cast (screen_pos.y - size / 2),
				size, size,
				rl.IsKeyDown(.LEFT_ALT) ? rl.YELLOW : rl.SKYBLUE
			)
		}

		for t in ui.active_units.transforms {
			size :: 50
			screen_pos := rl.GetWorldToScreen(t.translation, ui.camera)
			rl.DrawRectangleLines(
				auto_cast (screen_pos.x - size / 2), auto_cast (screen_pos.y - size / 2),
				size, size,
				rl.GREEN
			)
		}
	}}
}


//


//Selection :: struct($Entity: typeid) {
//	entities: [dynamic]#soa ^#soa []Entity,		// TODO: Tweak to hold a pointer?
//	centroid: rl.Vector3,
//}
//
//Move_Order :: struct {
//	centroid, cursor: rl.Vector3,
//	y_offset: f32,
//}
//
//Context :: struct($Entity: typeid) where
//	intr.type_field_type(Entity, "transform") == tr.Transform,
//	intr.type_field_type(Entity, "model") == rlu.Model,
//	intr.type_field_type(Entity, "ui") == Entity_Info
//{
//	camera: Camera,
//	mouse: Mouse,
//	unit_selection, focus_selection: Selection(Entity),
//	move_order: union{ Move_Order }
//}
//
//make_context :: proc($Entity: typeid, camera: rl.Camera) -> Context(Entity) {
//	return {
//		camera = Camera{ raylib=camera, rotated_since_right_mouse_button_pressed=false, focus=nil },
//		mouse = Mouse{},
//		move_order = nil,
//	}
//}
//
//// Entities should already be filtered down to subset that are on screen
//@require_results
//update :: proc(ui: ^Context($Entity),
//		entities: ^#soa []Entity,
//		camera: struct { move_speed, rotation_speed, scroll_speed: f32, }
//	) -> (confirmed_move_order: union{ rl.Vector3 })
//{
//	camera_updated := update_camera(&ui.camera, camera.move_speed, camera.rotation_speed, camera.scroll_speed)
//
//
//	if ui.move_order == nil {
//		entities := entities	// Just to make the pointers taken work
//
//		update_mouse(&ui.mouse, ui.camera.raylib)
//
//		if rl.IsMouseButtonReleased(.LEFT) {
//			selection := !rl.IsKeyDown(.LEFT_ALT)	\
//				? &ui.unit_selection.entities	\
//				: &ui.focus_selection.entities
//
//			switch s in ui.mouse.selection {
//				case rl.Rectangle:
//					clear(selection)
//					// TODO: Make it a bit more sophisticated when things start to get settled
//					for e, i in entities {
//						screen_pos := rl.GetWorldToScreen(e.transform.translation, ui.camera.raylib)
//						if rl.CheckCollisionPointRec(screen_pos, s) {
//							append(selection, &entities[i])
//						}
//					}
//				case rl.Ray:
//					clear(selection)
//					for &e, i in entities {
//						if rlu.ray_model_collide(s, e.model.raylib, tr.to_matrix(e.transform)) {
//							append(selection, &entities[i])
//							// TODO: Resolve depth
//							break
//						}
//					}
//			}
//		}
//	}
//
//
//	// Unit selection centroid
//
//	if len(ui.unit_selection.entities) > 0 {
//		// FIXME: Make the tr.centroid(^[]#soa^ #soa[]ecs.Entity) work
//		ui.unit_selection.centroid = 0
//		for e in ui.unit_selection.entities {
//			ui.unit_selection.centroid += e.transform.translation
//		}
//		ui.unit_selection.centroid /= auto_cast len(ui.unit_selection.entities)
//	}
//
//
//	// Camera focus
//
//	if len(ui.focus_selection.entities) > 0 {
//		// FIXME: Make the tr.centroid(^[]#soa^ #soa[]ecs.Entity) work
//		ui.focus_selection.centroid = 0
//		for e in ui.focus_selection.entities {
//			ui.focus_selection.centroid += e.transform.translation
//		}
//		ui.focus_selection.centroid /= auto_cast len(ui.focus_selection.entities)
//	}
//
//	if focus, ok := ui.camera.focus.?; ok {
//		ui.camera.focus = make_camera_focus(ui.camera, ui.focus_selection.centroid)
//
//		speed :: 15
//		weight := speed * rl.GetFrameTime()
//
//		ui.camera.target = math.lerp(ui.camera.target, focus.target, weight)
//		ui.camera.position = math.lerp(ui.camera.position, focus.position, weight)
//
//		// TODO: Stop if player uses the camera in any way.
//		if len(ui.focus_selection.entities) == 0 || camera_updated {
//			ui.camera.focus = nil
//			clear(&ui.focus_selection.entities)
//		}
//	}
//	else if rl.IsMouseButtonReleased(.LEFT) && len(ui.focus_selection.entities) > 0 {
//		ui.camera.focus = make_camera_focus(ui.camera, ui.focus_selection.centroid)
//	}
//
//
//	// Move Order
//
//	mo, pending := ui.move_order.?
//
//	if !pending {	// Detect move order
//		if rl.IsMouseButtonReleased(.RIGHT) && len(ui.unit_selection.entities) > 0 && !ui.camera.rotated_since_right_mouse_button_pressed {
//			c := rlu.simple_ray_xzplane_collision(rlu.mouse_ray(ui.camera.raylib), ui.unit_selection.centroid.y)
//			ui.move_order = Move_Order{ centroid = ui.unit_selection.centroid, cursor = c.point, }
//		}
//	}
//	else if rl.IsMouseButtonPressed(.LEFT) {	// Move order confirmed
//		mo := ui.move_order.?
//		confirmed_move_order = mo.cursor + {0, mo.y_offset, 0}
//		ui.move_order = nil
//	}
//	else if rl.IsMouseButtonReleased(.RIGHT) && !ui.camera.rotated_since_right_mouse_button_pressed	{	// Cancel move order
//		ui.move_order = nil
//	}
//	else {	// Calculate move order
//		assert(len(ui.unit_selection.entities) > 0)
//
//		if rl.IsKeyDown(.LEFT_SHIFT) {
//			rl.HideCursor()
//			delta := rlu.freeze_mouse()
//			// Raylibs screen axes are:
//			// ^ -y
//			// |
//			// + - > +x
//			mo.y_offset += -delta.y
//		}
//		else if rl.IsKeyReleased(.LEFT_SHIFT) {
//			rl.ShowCursor()
//		}
//
//		c := rlu.simple_ray_xzplane_collision(rlu.mouse_ray(ui.camera.raylib), ui.unit_selection.centroid.y)
//		if c.hit {
//			mo.cursor = c.point
//		}
//
//		ui.move_order = mo
//	}
//
//
//	return
//}
//
//draw :: proc(ui: Context($Entity), entities: #soa []Entity) {
//	if s, is_rect := ui.mouse.selection.(rl.Rectangle); is_rect {
//		rl.DrawRectangleLinesEx(s, 1, rl.BLUE)
//	}
//
//	for e in ui.unit_selection.entities {
//		screen_pos := rl.GetWorldToScreen(e.transform.translation, ui.camera)
//		rl.DrawRectangleLines(
//			auto_cast (screen_pos.x - e.ui.size / 2), auto_cast (screen_pos.y - e.ui.size / 2),
//			auto_cast e.ui.size, auto_cast e.ui.size,
//			rl.GREEN
//		)
//	}
//
//	for e in ui.focus_selection.entities {
//		screen_pos := rl.GetWorldToScreen(e.transform.translation, ui.camera)
//		size := e.ui.size + 5
//		rl.DrawRectangleLines(
//			auto_cast (screen_pos.x - size / 2), auto_cast (screen_pos.y - size / 2),
//			auto_cast size, auto_cast size,
//			rl.SKYBLUE
//		)
//	}
//
//	// Move Order
//	{
//		rl.BeginMode3D(ui.camera.raylib)
//
//		target_radius :: 1
//
//		draw_line_end :: proc(translation: rl.Vector3, target: rl.Vector3) -> rl.Vector3 {
//			// TODO: If target is over or under translation, the end must still be on the circle.
//			//         +----
//			//        /
//			//  \    /
//			//  ===> - - - +----
//			//       \
//			//        \
//			//         +----
//			dir := linalg.normalize(target - translation)
//			length := linalg.distance(translation, target) - target_radius
//			return translation + dir * length
//		}
//
//		// Draw active move orders
//		for e in entities {
//			if target, ok := e.target.?; ok {
//				rl.DrawLine3D(e.transform.translation, draw_line_end(e.transform.translation, target), rl.GREEN)
//				rl.DrawCircle3D(target, target_radius, {1, 0, 0}, 90, rl.GREEN)
//			}
//		}
//
//		rl.EndMode3D()
//
//		// Draw pending move order
//		if mo, pending := ui.move_order.?; pending {
//			assert(len(ui.unit_selection.entities) > 0)
//
//			target := mo.cursor + {0, mo.y_offset, 0}
//
//			// Draw y_offset next to target
//			y_offset_pos := rl.GetWorldToScreen(target, ui.camera.raylib)
//			rl.DrawText(rl.TextFormat("%+f", mo.y_offset), auto_cast y_offset_pos.x, auto_cast y_offset_pos.y, 30, rl.RED)
//
//					// Draw ui to cursor
//
//			rl.BeginMode3D(ui.camera.raylib)
//
//			to_target := mo.cursor - mo.centroid
//			projection_len := linalg.length(rl.Vector3{1, 0, 1} * (mo.cursor - mo.centroid))
//
//			rl.DrawCircle3D(ui.unit_selection.centroid, projection_len, {1, 0, 0}, 90, rl.RED)
//			rl.DrawLine3D(ui.unit_selection.centroid, draw_line_end(ui.unit_selection.centroid, mo.cursor), rl.RED)
//			rl.DrawCircle3D(mo.cursor, target_radius, {1, 0, 0}, 90, rl.RED)
//
//					// Draw ui to target
//
//			rl.DrawLine3D(ui.unit_selection.centroid, draw_line_end(ui.unit_selection.centroid, target), rl.RED)
//			rl.DrawLine3D(mo.cursor, target, rl.RED)
//			rl.DrawCircle3D(target, target_radius, {1, 0, 0}, 90, rl.RED)
//
//			rl.EndMode3D()
//		}
//	}
//}
//
//delete_context :: proc(ui: Context($Entity)) {
//	delete(ui.unit_selection.entities)
//	delete(ui.focus_selection.entities)
//}
//
//
//// Collection of data to be embedded in "game entities" to track information related to the ui.
//Entity_Info :: struct {
//	size: f32,
//}
//
//make_info :: proc(bb: rl.BoundingBox) -> Entity_Info {
//	x := bb.max - bb.min
//	m := slice.min(x[:])
//	return { linalg.distance(bb.max, bb.min) }
//}
//
//
//Mouse :: struct {
//	selection: union{ rl.Rectangle, rl.Ray },
//
//	anchor: rl.Vector2,
//	rect: rl.Rectangle,
//}
//
//update_mouse :: proc(m: ^Mouse, camera: rl.Camera) {
//	if rl.IsMouseButtonPressed(.LEFT) {
//		m.selection = rl.Rectangle{}
//		m.anchor = rl.GetMousePosition()
//		m.rect = {}
//	}
//	else if m.selection != nil {	// To confirm the "press" update step has occured
//		if rl.IsMouseButtonDown(.LEFT) {
//			pos := rl.GetMousePosition()
//
//			m.rect = rl.Rectangle{
//				x = m.anchor.x,
//				y = m.anchor.y,
//				width = abs(pos.x - m.anchor.x),
//				height = abs(pos.y - m.anchor.y),
//			}
//
//			if pos.x < m.anchor.x do m.rect.x = pos.x
//			if pos.y < m.anchor.y do m.rect.y = pos.y
//
//			m.selection = m.rect
//		}
//		else if rl.IsMouseButtonReleased(.LEFT) {
//			if m.rect.width == 0 && m.rect.height == 0 {
//				m.selection = rlu.mouse_ray(camera)
//			}
//		}
//		else {
//			m.selection = nil
//		}
//	}
//}
//
//
//Camera :: struct {
//	using raylib: rl.Camera,
//	rotated_since_right_mouse_button_pressed: bool,
//	focus: union{ Camera_Focus }
//}
//
//// TODO: Can we remove any fields from this to cleanup the code?
//Camera_Focus  :: struct {
//	target, position: rl.Vector3,
//	distance: f32,
//}
//
//make_camera_focus :: proc(camera: Camera, target: rl.Vector3) -> Camera_Focus {
//	return {
//		target = target,
//		position = camera.position + (target - camera.target),
//		distance = rlu.camera_target_distance(camera.raylib),
//	}
//}
//
//// Third person camera
////
//// WASD: Move
//// Right: Rotate
//// Scroll: Zoom
////
//update_camera :: proc(c: ^Camera, move_speed: f32, rotation_speed: f32, scroll_speed: f32) -> (updated: bool) {
//	if rl.IsKeyDown(.W) {
//		rl.CameraMoveForward(&c.raylib,  move_speed, moveInWorldPlane=true);
//		updated = true
//	}
//	if rl.IsKeyDown(.A) {
//		rl.CameraMoveRight(&c.raylib,   -move_speed, moveInWorldPlane=true);
//		updated = true
//	}
//	if rl.IsKeyDown(.S) {
//		rl.CameraMoveForward(&c.raylib, -move_speed, moveInWorldPlane=true);
//		updated = true
//	}
//	if rl.IsKeyDown(.D) {
//		rl.CameraMoveRight(&c.raylib,    move_speed, moveInWorldPlane=true);
//		updated = true
//	}
//
//
//	if rl.IsMouseButtonPressed(.RIGHT) {
//		c.rotated_since_right_mouse_button_pressed = false
//	}
//	if rl.IsMouseButtonDown(.RIGHT) {
//		// Hide and "freeze" mouse to allow for unlimited rotation
//		rl.HideCursor()
//		delta := rlu.freeze_mouse()
//
//		if delta != 0 {
//			c.rotated_since_right_mouse_button_pressed = true
//		}
//
//		rl.CameraYaw(&c.raylib, delta.x * rotation_speed, rotateAroundTarget=true)
//		rl.CameraPitch(&c.raylib, delta.y * rotation_speed, lockView=true, rotateAroundTarget=true, rotateUp=false)
//	}
//	else if rl.IsMouseButtonReleased(.RIGHT) {
//		rl.ShowCursor()
//	}
//
//	rl.CameraMoveToTarget(&c.raylib, -rl.GetMouseWheelMove() * scroll_speed)
//
//	return
//}

