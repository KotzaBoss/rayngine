package ui

import "base:intrinsics"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:slice"

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

gui :: proc(e: Entity, position: rl.Vector3, camera: rl.Camera) {
	//screen_pos := rl.GetWorldToScreen(position, camera)

	// Simulate having an sphere in the world and get its screen projection
	// Q: Is this reasonably performant or is there a better way?
	//scaled_rad := linalg.distance(rl.GetWorldToScreen(0, camera), rl.GetWorldToScreen({e.size, 0, 0}, camera))

	//collided := rl.CheckCollisionPointCircle(rl.GetMousePosition(), screen_pos, scaled_rad)

	ray := rl.GetScreenToWorldRay(rl.GetMousePosition(), camera)
	collision := rl.GetRayCollisionSphere(ray, position, e.size)

	color := rl.WHITE
	//if collided {
	if collision.hit {
		color = rl.RED
	}

	rl.DrawCircleV(0, 10, rl.RED)

	//rl.DrawCircleLinesV(screen_pos, scaled_rad, color)

	rl.BeginMode3D(camera)
	rl.DrawSphereWires(position, e.size, 7, 7, color)
	rl.EndMode3D()
}
