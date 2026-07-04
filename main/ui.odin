package main

import "base:runtime"
import "core:fmt"
import "core:hash/xxhash"

UiState :: struct {
  hot_id:       u64,
  next_hot_id:  u64,
  next_hot_z:   f32,
  active_id:    u64,
  triggered_id: u64,
}

update_ui_state :: proc(id: u64, pos: Pos, dim: Dim, z: f32) {
  if (is_cursor_inside(pos, dim) && gc.ui.active_id == 0 && gc.ui.next_hot_z < z) ||
     (is_cursor_inside(pos, dim) && gc.ui.active_id == id) {
    gc.ui.next_hot_id = id
    gc.ui.next_hot_z = z
  }
}

grid_button :: proc(
  id: u64,
  is_interactive: bool,
  pos: Pos,
  dim: Dim,
  z: f32,
  char: rune,
  font_size: f32,
  font: FontTexture,
  colour: Colour,
  trim: Trim,
) -> bool {
  bg_colour: Colour
  text_colour: Colour
  if (gc.ui.active_id == id) {
    bg_colour = colour
    text_colour = BLACK
  } else if (gc.ui.hot_id == id) {
    bg_colour = DARK_GREY
    text_colour = colour
  } else {
    bg_colour = BLACK
    text_colour = colour
  }

  trimmed_pos := Pos {
    x = pos.x + trim.left,
    y = pos.y + trim.bot,
  }
  trimmed_dim := Dim {
    w = dim.w - trim.left - trim.right,
    h = dim.h - trim.top - trim.bot,
  }
  update_ui_state(id, trimmed_pos, trimmed_dim, z)

  draw_rect(trimmed_pos, z, trimmed_dim, bg_colour)
  font_atlas := FONTS[font]
  scale := font_size / font_atlas.font_size_pixels
  raw_char_dim := Dim {
    w = cast(f32)font_atlas.char_map[char].advance_width,
    h = cast(f32)(font_atlas.ascent - font_atlas.descent),
  }
  char_dim := Dim {
    w = raw_char_dim.w * scale,
    h = raw_char_dim.h * scale,
  }
  char_pos := center_within_container(char_dim, pos, dim)
  draw_trimmed_char(char, font_atlas, pos, dim, trim, font_size, z, colour)
  return is_interactive && gc.ui.triggered_id == id
}

text_button :: proc(
  id: u64,
  is_interactive: bool,
  pos: Pos,
  dim: Dim,
  z: f32,
  text: string,
  font_size: f32,
  font: FontTexture,
) -> bool {
  update_ui_state(id, pos, dim, z)
  colour: Colour
  text_colour: Colour
  if (gc.ui.active_id == id) {
    colour = WHITE
    text_colour = BLACK
  } else if (gc.ui.hot_id == id) {
    colour = DARK_GREY
    text_colour = WHITE
  } else {
    colour = BLACK
    text_colour = WHITE
  }

  border_width: f32 = 4
  draw_rect(pos, z, dim, WHITE)
  draw_rect(
    {x = pos.x + border_width, y = pos.y + border_width},
    z,
    Dim{w = dim.w - border_width * 2, h = dim.h - border_width * 2},
    colour,
  )
  if len(text) > 0 {
    text_dim := measure_text(text, font, font_size)
    text_pos := center_within_container(text_dim, pos, dim)
    draw_string(text, FONTS[font], text_pos, z, font_size, text_colour)
  }

  return is_interactive && gc.ui.triggered_id == id
}

center_within_container :: proc(dim: Dim, container_pos: Pos, container_dim: Dim) -> Pos {
  dw := container_dim.w - dim.w
  dh := container_dim.h - dim.h
  return Pos{x = container_pos.x + dw / 2, y = container_pos.y + dh / 2}
}

get_uid :: proc(d: u32 = 0, loc: runtime.Source_Code_Location = #caller_location) -> u64 {
  seed: u64 = (cast(u64)loc.line << 32) | cast(u64)d
  return xxhash.XXH3_64_with_seed(transmute([]u8)loc.file_path, seed)
}
