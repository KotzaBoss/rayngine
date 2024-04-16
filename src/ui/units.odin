package ui

import "base:intrinsics"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:slice"

import rb "rayngine:rigid_body"

import rl "vendor:raylib"

Entity :: struct {
	size: f32,
	// Any length, ex from a model bounding box, that we will consider the radius of
	// the "selection bounding sphere" in the actual 3D world that will be projected on the screen
	min, max: f32,
}

make :: proc(bb: rl.BoundingBox, min, max: f32) -> Entity {
	x := bb.max - bb.min
	m := slice.min(x[:])
	return { linalg.distance(bb.max, bb.min) / 2, min, max, }
}

// Must be called towards the end to draw over the world
drag_select :: proc() -> (selection: rl.Rectangle) {
	@static anchor: rl.Vector2

	if rl.IsMouseButtonPressed(.LEFT) {
		anchor = rl.GetMousePosition()
	}
	else if rl.IsMouseButtonDown(.LEFT) {
		pos := rl.GetMousePosition()

		selection = {
			x = anchor.x,
			y = anchor.y,
			width = abs(pos.x - anchor.x),
			height = abs(pos.y - anchor.y),
		}

		if pos.x < anchor.x do selection.x = pos.x
		if pos.y < anchor.y do selection.y = pos.y

		rl.DrawRectangleLinesEx(selection, 1, rl.BLUE)
	}

	return
}

gui :: proc(es: []Entity, rigid_bodies: []rb.Rigid_Body, camera: rl.Camera, selection: rl.Rectangle = {}) {
	assert(len(es) == len(rigid_bodies))

	for soa in soa_zip(e=es, rb=rigid_bodies) {
		screen_pos := rl.GetWorldToScreen(soa.rb.position, camera)

		// Simulate having an sphere in the world and get its screen projection
		// Q: Is this reasonably performant or is there a better way?
		//scaled_rad := linalg.distance(rl.GetWorldToScreen(0, camera), rl.GetWorldToScreen({soa.e.size, 0, 0}, camera))

		//collided := rl.CheckCollisionPointCircle(rl.GetMousePosition(), screen_pos, scaled_rad)

		ray := rl.GetScreenToWorldRay(rl.GetMousePosition(), camera)
		collision := rl.GetRayCollisionSphere(ray, soa.rb.position, soa.e.size)

		color := rl.WHITE
		//if collided {
		if collision.hit {
			color = rl.RED
		}

		//rl.DrawCircleLinesV(screen_pos, scaled_rad, color)

		rl.BeginMode3D(camera)
		rl.DrawSphereWires(soa.rb.position, soa.e.size, 7, 7, color)
		rl.EndMode3D()

		// Selection
		if rl.CheckCollisionPointRec(screen_pos, selection) {
			rl.DrawRectangleLines(
				auto_cast (screen_pos.x - soa.e.size / 2), auto_cast (screen_pos.y - soa.e.size / 2),
				auto_cast soa.e.size, auto_cast soa.e.size,
				rl.YELLOW
			)
		}
	}
}

