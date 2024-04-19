package raylibutil

import rl "vendor:raylib"

mouse_ray :: proc(camera: rl.Camera) -> rl.Ray {
	return rl.GetScreenToWorldRay(rl.GetMousePosition(), camera)
}
