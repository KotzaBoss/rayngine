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


UI :: struct($Entt: typeid) where
	intr.type_field_type(Entt, "rigid_body") == rb.Rigid_Body,
	intr.type_field_type(Entt, "ui") == Entity	// TODO: Remove this requirement and find a simpler way to produce ui rectangles etc
{
	selection: Mouse_Selection,
	selected: [dynamic]Entt,	// TODO: Tweak to hold a pointer?
}

delete :: proc(ui: UI($Entity)) {
	runtime.delete(ui.selected)
}

update :: proc(ui: ^UI($Entity), entities: #soa []Entity, camera: rl.Camera) {
	ui.selection = mouse(camera)

	// TODO: Make it a bit more sophisticated when things start to get settled
	clear(&ui.selected)

	switch s in ui.selection {
		case rl.Rectangle:
			for e in entities {
				screen_pos := rl.GetWorldToScreen(e.rigid_body.position, camera)
				if rl.CheckCollisionPointRec(screen_pos, s) {
					append(&ui.selected, e)
				}
			}
		case rl.Ray:
	}
}

draw :: proc(ui: UI($Entity), camera: rl.Camera) {
	switch s in ui.selection {
		case rl.Rectangle:
			rl.DrawRectangleLinesEx(s, 1, rl.BLUE)
			for e in ui.selected {
				screen_pos := rl.GetWorldToScreen(e.rigid_body.position, camera)
				rl.DrawRectangleLines(
					auto_cast (screen_pos.x - e.ui.size / 2), auto_cast (screen_pos.y - e.ui.size / 2),
					auto_cast e.ui.size, auto_cast e.ui.size,
					rl.GREEN
				)
			}
		case rl.Ray:
	}
}

// Collection of data to be embedded in "game entities" to track information related to the ui.
Entity :: struct {
	size: f32,
	// Any length, ex from a model bounding box, that we will consider the radius of
	// the "selection bounding sphere" in the actual 3D world that will be projected on the screen
	min, max: f32,
}

make :: proc(bb: rl.BoundingBox, min, max: f32) -> Entity {
	x := bb.max - bb.min
	m := slice.min(x[:])
	return { linalg.distance(bb.max, bb.min), min, max, }
}

Mouse_Selection :: union{ rl.Rectangle, rl.Ray }

mouse :: proc(camera: rl.Camera) -> (selection: Mouse_Selection) {
	@static anchor: rl.Vector2
	@static rect: rl.Rectangle

	if rl.IsMouseButtonPressed(.LEFT) {
		anchor = rl.GetMousePosition()
		rect = {}
	}
	else if rl.IsMouseButtonDown(.LEFT) {
		pos := rl.GetMousePosition()

		rect = rl.Rectangle{
			x = anchor.x,
			y = anchor.y,
			width = abs(pos.x - anchor.x),
			height = abs(pos.y - anchor.y),
		}

		if pos.x < anchor.x do rect.x = pos.x
		if pos.y < anchor.y do rect.y = pos.y

		selection = rect
	}
	else if rl.IsMouseButtonReleased(.LEFT) {
		if rect.width == 0 && rect.height == 0 {
			selection = rlu.mouse_ray(camera)
		}
	}

	return
}

