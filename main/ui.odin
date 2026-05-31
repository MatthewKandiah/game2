package main

UiState :: struct {
  hot_id: u64,
  next_hot_id: u64,
  next_hot_z: f32,
  active_id: u64,
  triggered_id: u64,
}

button :: proc(id: u64, pos: Pos, dim: Dim, z: f32, text: string, font_size: f32, font: FontTexture) -> bool {
  if (is_cursor_inside(pos, dim) && gc.ui.active_id == 0 && gc.ui.next_hot_z < z) || (is_cursor_inside(pos, dim) && gc.ui.active_id == id) {
    gc.ui.next_hot_id = id
    gc.ui.next_hot_z = z
  }
  colour: Colour
  if (gc.ui.active_id == id) {
    colour = DARK_GREY
  } else if (gc.ui.hot_id == id) {
    colour = GREY
  } else {
    colour = GREEN
  }
  draw_rect(pos, z, dim, colour)
  if len(text) > 0 {
    text_dim := measure_text(text, font, font_size)
    text_pos := center_within_container(text_dim, pos, dim)
    draw_string(text, font, text_pos, z, font_size, DARK_GREY)
  }

  return gc.ui.triggered_id == id
}

center_within_container :: proc(dim: Dim, container_pos: Pos, container_dim: Dim) -> Pos {
  dw := container_dim.w - dim.w
  dh := container_dim.h - dim.h
  return Pos {
    x = container_pos.x + dw/2,
    y = container_pos.y  + dh/2,
  }
}
