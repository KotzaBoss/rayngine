package raylibutil

import "core:math/linalg"

import rl "vendor:raylib"

Model :: struct {
	raylib: rl.Model,
	offsets: struct {
		rotation: [3]f32,	// In degrees TODO: Add a odinutil Degrees :: f32
	}
}

mouse_ray :: proc(camera: rl.Camera) -> rl.Ray {
	return rl.GetScreenToWorldRay(rl.GetMousePosition(), camera)
}

ray_model_collide :: proc(ray: rl.Ray, model: rl.Model, transform: #row_major matrix[4, 4]f32) -> bool {
	for i in 0 ..< model.meshCount {
		collision := rl.GetRayCollisionMesh(ray, model.meshes[i], transform)
		if collision.hit {
			return true
		}
	}
	return false
}

camera_target_distance :: proc(camera: rl.Camera) -> f32 {
	return linalg.distance(camera.position, camera.target)
}

simple_ray_xzplane_collision :: proc(ray: rl.Ray, y: f32, size: f32 = 10_000_000) -> rl.RayCollision {
	quad := [4]rl.Vector3 {
		{ -size, y, -size },
		{ -size, y,  size },
		{  size, y,  size },
		{  size, y, -size },
	}
	return rl.GetRayCollisionQuad(ray, quad[0], quad[1], quad[2], quad[3])
}

freeze_mouse :: proc() -> (delta: rl.Vector2) {
	delta = rl.GetMouseDelta()
	old_pos := rl.GetMousePosition() - delta
	rl.SetMousePosition(auto_cast old_pos.x, auto_cast old_pos.y)
	return
}
