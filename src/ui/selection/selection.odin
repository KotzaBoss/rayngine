package selection

import "base:builtin"

import "hootools:game"

import rl "vendor:raylib"

// TODO: rename to Selection
Selection :: struct {
	transforms: [dynamic]game.Transform,	// TODO: Save only transforms?
	centroid: rl.Vector3,
}

set :: proc(f: ^Selection, ts: []game.Transform) {
	resize(&f.transforms, len(ts))
	copy(f.transforms[:], ts)
	f.centroid = game.centroid(f.transforms[:])
}

clear :: proc(f: ^Selection) {
	builtin.clear(&f.transforms)
	f.centroid = 0
}
