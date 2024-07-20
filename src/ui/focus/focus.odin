package focus

import "base:builtin"

import "hootools:game"

import rl "vendor:raylib"

// TODO: rename to Selection
Focus :: struct {
	transforms: [dynamic]game.Transform,	// TODO: Save only transforms?
	centroid: rl.Vector3,
}

set :: proc(f: ^Focus, ts: []game.Transform) {
	resize(&f.transforms, len(ts))
	copy(f.transforms[:], ts)
	f.centroid = game.centroid(f.transforms[:])
}

clear :: proc(f: ^Focus) {
	builtin.clear(&f.transforms)
	f.centroid = 0
}
