package mouse


import rlu "hootools:raylib"
import rl "vendor:raylib"


Mouse :: struct {
	selection: union{ rl.Rectangle, rl.Ray },

	anchor: rl.Vector2,
	rect: rl.Rectangle,
}

update :: proc(m: ^Mouse, camera: rl.Camera) {
	if rl.IsMouseButtonPressed(.LEFT) {
		m.selection = rl.Rectangle{}
		m.anchor = rl.GetMousePosition()
		m.rect = {}
	}
	else if m.selection != nil {	// To confirm the "press" update step has occured. TODO: Necessary?
		if rl.IsMouseButtonDown(.LEFT) {
			pos := rl.GetMousePosition()

			m.rect = rl.Rectangle{
				x = m.anchor.x,
				y = m.anchor.y,
				width = abs(pos.x - m.anchor.x),
				height = abs(pos.y - m.anchor.y),
			}

			if pos.x < m.anchor.x do m.rect.x = pos.x
			if pos.y < m.anchor.y do m.rect.y = pos.y

			m.selection = m.rect
		}
		else if rl.IsMouseButtonReleased(.LEFT) {
			if m.rect.width == 0 && m.rect.height == 0 {
				m.selection = rlu.mouse_ray(camera)
			}
		}
		else {
			m.selection = nil
		}
	}
}

draw :: proc(m: Mouse, camera: rl.Camera) {
	if s, is_rect := m.selection.(rl.Rectangle); is_rect {
		rl.DrawRectangleLinesEx(s, 1, rl.BLUE)
	}
}

