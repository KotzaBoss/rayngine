package raylibutil

import rl "vendor:raylib"

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
