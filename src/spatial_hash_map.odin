package spatial_hash_map

import "core:fmt"
import "core:math"
import "core:slice"

import rl "vendor:raylib"


Spatial_Grid_Map :: struct($Entity: typeid) {
	cell_size: uint,
	grid: map[rl.Vector3][dynamic]Entity
}


make :: proc($Entity: typeid, cell_size: uint) -> Spatial_Grid_Map(Entity) {
	return {
		cell_size,
		{},
	}
}


add :: proc(m: ^Spatial_Grid_Map($Entity), bb: rl.BoundingBox, e: Entity) {
	assert(m.cell_size > 0)

	for_each_cell(m, bb, e, proc(m: ^Spatial_Grid_Map(Entity), cell: rl.Vector3, e: Entity) -> For_Each_Policy {
		if !(cell in m.grid) {
			m.grid[cell] = {}
		}

		bucket := &m.grid[cell]

		if slice.contains(bucket[:], e) {
			return .Continue
		}

		append(&m.grid[cell], e)

		return .Continue
	})
}


remove :: proc(m: ^Spatial_Grid_Map($Entity), bb: rl.BoundingBox, e: Entity) {
	assert(m.cell_size > 0)

	for_each_cell(m, bb, e, proc(m: ^Spatial_Grid_Map(Entity), cell: rl.Vector3, e: Entity) -> For_Each_Policy {
		entities, ok := &m.grid[cell]
		if ok {
			i, found := slice.linear_search(entities[:], e)
			if found {
				unordered_remove(entities, i)
			}
		}
		return .Continue
	})
}


delete_empty :: proc(m: ^Spatial_Grid_Map($Entity)) {
	assert(m.cell_size > 0)

	for k, entities in m.grid {
		if len(entities) == 0 {
			delete_key(&m.grid, k)
		}
	}
}


contains :: proc(m: ^Spatial_Grid_Map($Entity), bb: rl.BoundingBox, e: Entity) -> bool {
	assert(m.cell_size > 0)

	is_contained := false

	for_each_cell(m, bb, e, &is_contained, proc(m: ^Spatial_Grid_Map(Entity), cell: rl.Vector3, e: Entity, out: ^bool) -> For_Each_Policy {
		entities, ok := &m.grid[cell]
		if ok {
			ok := slice.contains(entities[:], e)
			if ok {
				out^ = true
				return .Return
			}
		}
		return .Continue
	})

	return is_contained
}


count :: proc(m: ^Spatial_Grid_Map($Entity), bb: rl.BoundingBox, e: Entity) -> uint {
	assert(m.cell_size > 0)

	count: uint = 0

	for_each_cell(m, bb, e, &count, proc(m: ^Spatial_Grid_Map(Entity), cell: rl.Vector3, e: Entity, out: ^uint) -> For_Each_Policy {
		entities, ok := &m.grid[cell]
		if ok {
			ok := slice.contains(entities[:], e)
			if ok {
				out^ += 1
			}
		}
		return .Continue
	})

	return count

}


bounding_box_of_overlapping_cells :: proc(cell_size: uint, bb: rl.BoundingBox) -> rl.BoundingBox {
	assert(cell_size > 0)

	hashed := bb

	// Divide all floats with cell_size
	{
		array_view := transmute(^[6]f32) &hashed
		array_view^ /= auto_cast cell_size
	}

	for &f in hashed.min {
		f = math.floor(f)
	}

	for &f in hashed.max {
		f = math.ceil(f)
	}

	//for &f in array_view^ {
	//	int, frac := math.modf(f)
	//	f = int
	//	if frac != 0 {	// I live dangerously
	//		f += math.copy_sign(f32(1.0), f)
	//	}
	//}

	return hashed
}


gui :: proc{
	gui_simple,
	gui_entities,
}

gui_simple :: proc(m: Spatial_Grid_Map($Entity), camera: rl.Camera) {
	assert(rl.IsWindowReady())

	cell_size := f32(m.cell_size)

	rl.BeginMode3D(camera)
		// Some visual point of reference
		rl.DrawSphere({0, 0, 0}, 0.5, rl.WHITE)
		rl.DrawGrid(100, cell_size)

		for pos_grid, eids in m.grid {
			if len(eids) == 0 do continue

			rl.DrawSphere({cell_size, cell_size, cell_size} * pos_grid, 0.25, rl.BLUE)
		}
	rl.EndMode3D()
}

gui_entities :: proc(
	m: Spatial_Grid_Map($Entity),
	camera: rl.Camera,
	bbs: []rl.BoundingBox,
	entities: []Entity
) {
	assert(rl.IsWindowReady())
	assert(len(bbs) == len(entities),
		`The slices bbs and entities are parallel arrays,
		 hence they must both have the same length for each index of bb/entity pair`
	)

	cell_size := f32(m.cell_size)

	gui_simple(m, camera)

	rl.BeginMode3D(camera)
		for bb in bbs {
			rl.DrawBoundingBox(bb, rl.WHITE)
		}
	rl.EndMode3D()

	for soa in soa_zip(bb=bbs, e=entities) {
		bb_pos := rl.GetWorldToScreen(soa.bb.min, camera)
		text := rl.TextFormat("{} {}", soa.e, soa.bb.min)
		font_size := i32(14)
		rl.DrawText(text, auto_cast bb_pos.x - rl.MeasureText(text, font_size)/2, auto_cast bb_pos.y, font_size, rl.BLACK)

		bb_pos = rl.GetWorldToScreen(soa.bb.max, camera)
		text = rl.TextFormat("{} {}", soa.e, soa.bb.max)
		rl.DrawText(text, auto_cast bb_pos.x - rl.MeasureText(text, font_size)/2, auto_cast bb_pos.y, font_size, rl.BLACK)
	}
}


pprint :: proc(m: Spatial_Grid_Map($Entity)) {
	fmt.println("Spatial_Grid_Map {")
	fmt.printfln("\tcell_size={}\n", m.cell_size)
	for k, v in m.grid {
		fmt.printfln("\t{}={}", k, v)
	}
	fmt.println("}")
}


@private
For_Each_Policy :: enum {
	Return,
	Continue,
}

// May be verbose to use but reduces the triple for loop code
@private
for_each_cell_pure :: proc(
	m: ^Spatial_Grid_Map($Entity),
	bb: rl.BoundingBox,
	e: Entity,
	fn: proc(m: ^Spatial_Grid_Map(Entity), cell: rl.Vector3, e: Entity) -> For_Each_Policy
) {
	assert(m.cell_size > 0)

	bb := bounding_box_of_overlapping_cells(m.cell_size, bb)

	for x in bb.min.x ..= bb.max.x {
		for y in bb.min.y ..= bb.max.y {
			for z in bb.min.z ..= bb.max.z {

				if fn(m, {x, y, z}, e) == .Return do return

			}
		}
	}
}

@private
for_each_cell_out :: proc(
	m: ^Spatial_Grid_Map($Entity),
	bb: rl.BoundingBox,
	e: Entity,
	out: ^$Output,
	fn: proc(m: ^Spatial_Grid_Map(Entity), cell: rl.Vector3, e: Entity, out: ^Output) -> For_Each_Policy
) {
	assert(m.cell_size > 0)

	bb := bounding_box_of_overlapping_cells(m.cell_size, bb)

	for x in bb.min.x ..= bb.max.x {
		for y in bb.min.y ..= bb.max.y {
			for z in bb.min.z ..= bb.max.z {

				if fn(m, {x, y, z}, e, out) == .Return do return

			}
		}
	}
}

@private
for_each_cell :: proc {
	for_each_cell_pure,
	for_each_cell_out,
}


/////////////////////////////////////////////////////


import "core:testing"

@test
init_add_remove :: proc(t: ^testing.T) {
	Entity :: struct {
		id: uint,
		bb: rl.BoundingBox,
		expected: uint,
	}

	es := []Entity{
		// Fits completely in the grid with bb (0, 0, 0) -> (10, 10, 10) so
		// we expect 8, the corners of a single cube
		Entity{ 1, rl.BoundingBox{ {  0,  0,  0}, {10, 10, 10} },  8 },

		// These two are contained in 4 cells so in 3D we have 3 layers of 9 corners
		//
		//     +--+--+
		//    /  /  /|
		//   +--+--+ +
		//  /  /  /|/|
		// +--+--+ + +
		// |  |  |/|/
		// +--+--+ +
		// |  |  |/
		// +--+--+
		//       ^--- 9 '+' * 3
		//
		Entity{ 2, rl.BoundingBox{ {  0,  0,  0}, {20, 20, 20} }, 27 },
		Entity{ 3, rl.BoundingBox{ { -5, -5, -5}, { 5,  5,  5} }, 27 },
	}

	// Init
	m := make(uint, 10)

	// Add
	for e in es {
		add(&m, e.bb, e.id)
	}
	for e in es {
		testing.expect(t, contains(&m, e.bb, e.id))
	}

	// Remove
	for e in es {
		c := count(&m, e.bb, e.id)
		testing.expectf(t, c == e.expected, "{} -> {} != {}", e.bb, c, e.expected)
	}
	remove(&m, es[1].bb, es[1].id)
	testing.expect(t, !contains(&m, es[1].bb, es[1].id))
}

@test
draw :: proc(t: ^testing.T) {
	cell_size :: 10
	m := make(uint, cell_size)

	ids := []uint{ 1, 2, 3, 4, }
	bbs := []rl.BoundingBox {
		rl.BoundingBox{ {  0,  0,  0}, {10, 10, 10} },
		rl.BoundingBox{ {  0,  0,  0}, {20, 20, 20} },
		rl.BoundingBox{ { -5, -5, -5}, { 5,  5,  5} },
		rl.BoundingBox{ { -35, -35,  -35}, { -25,  -25,  -25} },
	}
	colors := []rl.Color {
		rl.GREEN,
		rl.GOLD,
		rl.DARKBROWN,
		rl.BLACK,
	}

	for soa in soa_zip(id=ids, bb=bbs) {
		add(&m, soa.bb, soa.id)
	}

	rl.InitWindow(1024, 768, "Test")
	camera := rl.Camera3D{
		position={0, 50, 50},
		target={0, 0, 0},
		up={0, 1, 0},
		fovy=60.0,
		projection=.PERSPECTIVE
	}

	rl.SetTargetFPS(60)

	for !rl.WindowShouldClose() {
		rl.UpdateCamera(&camera, .ORBITAL)

		index := 3
		bb4 := &bbs[index]
		id := ids[index]
		remove(&m, bb4^, id)
		delete_empty(&m)
		bb4.min += 0.05
		bb4.max += 0.05
		add(&m, bb4^, id)

		rl.BeginDrawing()
		rl.ClearBackground(rl.DARKGRAY)

		gui(m, camera, bbs, ids)

		rl.EndDrawing()
	}
	rl.CloseWindow()
}
