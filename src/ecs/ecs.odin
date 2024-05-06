package ecs

import "core:math"
import "core:math/linalg"
import "core:fmt"

import rb "rayngine:rigid_body"
import "rayngine:ui"

import rl "vendor:raylib"
import rlu "rayngine:raylibutil"

import intr "base:intrinsics"

Entity :: struct {
	name: string,
	rigid_body: rb.Rigid_Body,
	model: rlu.Model,
	ui: ui.Entity_Info,
	target: union{ rl.Vector3 },
}

update_one :: proc(e: #soa^ #soa[]Entity) {
	if target, ok := e.target.?; ok {
		e.rigid_body.rotation = linalg.normalize(
				linalg.quaternion_slerp(
					e.rigid_body.rotation,
					linalg.quaternion_look_at(e.rigid_body.position, target, rl.Vector3{0, 1, 0}),
					rl.GetFrameTime() * 3
				)
			)
	}
	e.model.raylib.transform = rb.transform(e.rigid_body) * rl.MatrixRotateXYZ(e.model.offsets.rotation * math.RAD_PER_DEG)
}

update_slice :: proc(es: #soa []Entity) {
	es := es
	for _, i in es {
		update_one(&es[i])
	}
}

update :: proc{
	update_one,
	update_slice,
}

draw_one :: proc(e: Entity) {
	rl.DrawModel(e.model.raylib, 0, 1, rl.WHITE)
}

draw_slice :: proc(es: #soa []Entity) {
	for e in es {
		draw_one(e)
	}
}

draw :: proc{
	draw_one,
	draw_slice,
}

collides :: proc(using e: Entity, ray: rl.Ray) -> bool {
	for i in 0 ..< model.raylib.meshCount {
		collision := rl.GetRayCollisionMesh(ray, model.raylib.meshes[i], rb.transform(rigid_body))
		if collision.hit {
			return true
		}
	}
	return false
}

// TODO: Deprecate this when the following compiles:
//
//       entities: #soa [dynamic]Entity
//       process_rigid_bodies(entities.rigid_bodies[:])
//
slices :: proc(es: #soa [dynamic]Entity) -> $SOA_Entity_Slices {
	return soa_unzip(es[:])
}


////////////////////////////////////////////


import "core:testing"

