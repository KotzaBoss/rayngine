package ecs

make :: proc() {}


////////////////////////////////////////////


import "core:testing"

@test
some :: proc(t: ^testing.T) {
	testing.expect(t, false)
}

@test
other :: proc(t: ^testing.T) {
	testing.expect(t, false)
}
