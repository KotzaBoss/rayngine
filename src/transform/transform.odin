package transform

import intr "base:intrinsics"

import "core:math"
import "core:math/linalg"
import "core:slice"
import "core:fmt"

import rl "vendor:raylib"

translation :: proc(t: rl.Transform) -> rl.Matrix {
	using t
	return rl.MatrixTranslate(translation.x, translation.y, translation.z)
}

rotation :: proc(t: rl.Transform) -> rl.Matrix {
	return rl.QuaternionToMatrix(1/t.rotation)
}

scale :: proc(t: rl.Transform) -> rl.Matrix {
	return rl.MatrixScale(t.scale.x, t.scale.y, t.scale.z)
}

to_matrix :: proc(t: rl.Transform) -> rl.Matrix {
	return translation(t) * rotation(t) * scale(t)
}


centroid :: proc(es: []#soa ^#soa[]$Entity) -> rl.Vector3 where
	intr.type_field_type(Entity, "transform") == rl.Transform
{
	sum := slice.reduce(es, rl.Vector3{}, proc(sum: rl.Vector3, e: ecs.Entity) -> rl.Vector3 {
			return sum + e.transform.translation
		})
	return sum / auto_cast len(es)
}

