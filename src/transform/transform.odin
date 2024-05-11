package transform

import intr "base:intrinsics"

import "core:math"
import "core:math/linalg"
import "core:slice"
import "core:fmt"

import rl "vendor:raylib"

Transform :: struct {
	translation: rl.Vector3,
	forward: rl.Vector3,
	scale: rl.Vector3,
}

translation :: proc(using t: Transform) -> rl.Matrix {
	return rl.MatrixTranslate(translation.x, translation.y, translation.z)
}

rotation :: proc(using t: Transform) -> rl.Matrix {
	return rl.QuaternionToMatrix(
			linalg.normalize(
				linalg.quaternion_from_forward_and_up(-forward, rl.Vector3{0, 1, 0})
			)
		)
}

scale :: proc(using t: Transform) -> rl.Matrix {
	return rl.MatrixScale(scale.x, scale.y, scale.z)
}

to_matrix :: proc(t: Transform) -> rl.Matrix {
	return translation(t) * rotation(t) * scale(t)
}

draw :: proc(using t: Transform) {
	axes := [3]rl.Vector3 { {1, 0, 0}, {0, 1, 0}, {0, 0, 1} }
	colors := [3]rl.Color {  rl.RED, rl.GREEN, rl.BLUE, }

	for zip in soa_zip(axis=axes[:], color=colors[:]) {
		// Axes
		{
			length :: 10
			rl.DrawLine3D(translation, translation + zip.axis * length, zip.color)
			rl.DrawSphere(translation + zip.axis * length, 1, zip.color)
		}

		// Forward
		{
			length :: 15
			color :: rl.YELLOW
			rl.DrawLine3D(translation, translation + forward * length, color)
			rl.DrawSphere(translation + forward * length, 1, color)
		}
	}
}

// TODO: Uncomment and fix when i learn how to pass Transforms as a slice?
//centroid :: proc(es: []#soa ^#soa[]$Entity) -> rl.Vector3 where
//	intr.type_field_type(Entity, "transform") == rl.Transform
//{
//	sum := slice.reduce(es, rl.Vector3{}, proc(sum: rl.Vector3, e: ecs.Entity) -> rl.Vector3 {
//			return sum + e.transform.translation
//		})
//	return sum / auto_cast len(es)
//}

