package ecs

import "core:math"
import "core:math/linalg"
import "core:fmt"

import tr "rayngine:transform"
import "rayngine:ui"

import rl "vendor:raylib"
import rlu "hootools:raylibutil"

import intr "base:intrinsics"

Entity :: struct {
	name: string,
	transform: tr.Transform,
	model: rlu.Model,
	ui: ui.Entity_Info,
	target: union{ rl.Vector3 },
}

update_one :: proc(e: #soa^ #soa[]Entity) {
	// TODO: Better "target reached" algo
	if target, ok := e.target.?; ok {
		// Rotation
		to_target := linalg.normalize(target - e.transform.translation)
		if linalg.angle_between(e.transform.forward, to_target) > 0.005 {
			e.transform.forward = linalg.vector_slerp(e.transform.forward, to_target, rl.GetFrameTime() * 5)
		}

		// Move
		angle := linalg.angle_between(e.transform.forward, to_target)
		distance := linalg.distance(e.transform.translation, target)
		if angle < math.to_radians(f32(10.0)) && distance > 1 {
			e.transform.translation += e.transform.forward * rl.GetFrameTime() * 10
		}

		if angle < 0.005 && distance < 1 {
			e.target = nil
		}
		else do fmt.println(angle, distance)
	}

	e.model.raylib.transform = tr.to_matrix(e.transform)
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

draw_one :: proc(using e: Entity) {
	rl.DrawModel(e.model.raylib, 0, 1, rl.WHITE)
	tr.draw(e.transform)
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
		collision := rl.GetRayCollisionMesh(ray, model.raylib.meshes[i], tr.to_matrix(transform))
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

