package rigid_body

import intr "base:intrinsics"

import "core:math"
import "core:math/linalg"
import "core:slice"
import "core:fmt"

import rl "vendor:raylib"

// TODO: For now this "rigid body" is just a transform. I assume the "rigid body" will contain a transform and other stuff?
Rigid_Body :: struct {
	position: rl.Vector3,
	rotation: rl.Quaternion,	// x=pitch y=yaw z=roll
	scale: f32,
}

Transform :: #row_major matrix[4, 4]f32

translation :: proc(rb: Rigid_Body) -> Transform {
	using rb
	return rl.MatrixTranslate(position.x, position.y, position.z)
}

rotation :: proc(rb: Rigid_Body) -> Transform {
	return rl.QuaternionToMatrix(1/rb.rotation)
}

scale :: proc(rb: Rigid_Body) -> Transform {
	return rl.MatrixScale(rb.scale, rb.scale, rb.scale)
}

transform :: proc(rb: Rigid_Body) -> Transform {
	return translation(rb) * rotation(rb) * scale(rb)
}


centroid_slice :: proc(rbs: []Rigid_Body) -> rl.Vector3 {
	sum := slice.reduce(rbs, rl.Vector3{}, proc(sum: rl.Vector3, rb: Rigid_Body) -> rl.Vector3 {
			return sum + rb.position
		})
	return sum / auto_cast len(rbs)
}

centroid_ptr_soa :: proc(es: []#soa ^#soa[]$Entity) -> rl.Vector3 where
	intr.type_field_type(Entity, "rigid_body") == Rigid_Body
{
	sum := slice.reduce(es, rl.Vector3{}, proc(sum: rl.Vector3, e: Entity) -> rl.Vector3 {
			return sum + e.rigid_body.position
		})
	return sum / auto_cast len(es)
}

centroid :: proc{
	centroid_slice,
	centroid_ptr_soa,
}

