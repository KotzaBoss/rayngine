package ecs

import rb "rayngine:rigid_body"
import "rayngine:ui"

import rl "vendor:raylib"

Entity :: struct {
	name: string,
	rigid_body: rb.Rigid_Body,
	model: rl.Model,
	ui: ui.Entity,
}

draw :: proc(using e: ^Entity, color: rl.Color = rl.WHITE) {
	model.transform = rb.rotation(rigid_body)
	rl.DrawModel(model, rigid_body.position, rigid_body.scale, color)
}

collides :: proc(using e: Entity, ray: rl.Ray) -> bool {
	for i in 0..<model.meshCount {
		collision := rl.GetRayCollisionMesh(ray, model.meshes[i], rb.transform(rigid_body))
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

