package main

import "core:fmt"

Drawable :: struct {
  pos:             Pos,
  z:               f32,
  dim:             Dim,
  texture_data:    TextureData,
  override_colour: bool,
  colour:          Colour,
}

Trim :: struct {
  left:  f32,
  right: f32,
  top:   f32,
  bot:   f32,
}

SPRITE_DRAWABLES_SIZE :: 100_000
MASK_DRAWABLES_SIZE :: 100_000
SPRITE_DRAWABLES_COUNT := 0
MASK_DRAWABLES_COUNT := 0
SPRITE_DRAWABLES := [SPRITE_DRAWABLES_SIZE]Drawable{}
MASK_DRAWABLES := [MASK_DRAWABLES_SIZE]Drawable{}

push_drawable :: proc(d: Drawable) {
  switch (d.texture_data.type) {
  case .Sprite:
    {
      SPRITE_DRAWABLES[SPRITE_DRAWABLES_COUNT] = d
      SPRITE_DRAWABLES_COUNT += 1
    }
  case .Mask:
    {
      MASK_DRAWABLES[MASK_DRAWABLES_COUNT] = d
      MASK_DRAWABLES_COUNT += 1
    }
  }
}

drawable_dim_to_screen_dim :: proc(dim: Dim) -> Dim {
  return Dim{w = 2 * dim.w / gc.screen_dim.w, h = 2 * dim.h / gc.screen_dim.h}
}

drawable_pos_to_screen_pos :: proc(pos: Pos) -> Pos {
  return Pos{x = (2 * pos.x) / gc.screen_dim.w - 1, y = 1 - (2 * pos.y) / gc.screen_dim.h}
}

generate_graphics_primitives :: proc(drawables: []Drawable, drawables_already_generated: int) {
  for drawable, idx in drawables {
    vertex_base_idx := (drawables_already_generated + idx) * VERTICES_PER_DRAWABLE
    index_base_idx := (drawables_already_generated + idx) * INDICES_PER_DRAWABLE
    alpha: f32 = 1 if drawable.override_colour else 0

    pos := drawable_pos_to_screen_pos(drawable.pos)
    dim := drawable_dim_to_screen_dim(drawable.dim)

    VERTEX_BUFFER[vertex_base_idx + 0] = {
      {pos.x, pos.y, drawable.z},
      {drawable.colour.r, drawable.colour.g, drawable.colour.b, alpha},
      {drawable.texture_data.base.x, drawable.texture_data.base.y},
      drawable.texture_data.tex_idx,
    }
    VERTEX_BUFFER[vertex_base_idx + 1] = {
      {pos.x, pos.y - dim.h, drawable.z},
      {drawable.colour.r, drawable.colour.g, drawable.colour.b, alpha},
      {drawable.texture_data.base.x, drawable.texture_data.base.y - drawable.texture_data.dim.h},
      drawable.texture_data.tex_idx,
    }
    VERTEX_BUFFER[vertex_base_idx + 2] = {
      {pos.x + dim.w, pos.y, drawable.z},
      {drawable.colour.r, drawable.colour.g, drawable.colour.b, alpha},
      {drawable.texture_data.base.x + drawable.texture_data.dim.w, drawable.texture_data.base.y},
      drawable.texture_data.tex_idx,
    }
    VERTEX_BUFFER[vertex_base_idx + 3] = {
      {pos.x + dim.w, pos.y - dim.h, drawable.z},
      {drawable.colour.r, drawable.colour.g, drawable.colour.b, alpha},
      {
        drawable.texture_data.base.x + drawable.texture_data.dim.w,
        drawable.texture_data.base.y - drawable.texture_data.dim.h,
      },
      drawable.texture_data.tex_idx,
    }

    INDEX_BUFFER[index_base_idx + 0] = cast(u32)(vertex_base_idx + 0)
    INDEX_BUFFER[index_base_idx + 1] = cast(u32)(vertex_base_idx + 1)
    INDEX_BUFFER[index_base_idx + 2] = cast(u32)(vertex_base_idx + 2)
    INDEX_BUFFER[index_base_idx + 3] = cast(u32)(vertex_base_idx + 2)
    INDEX_BUFFER[index_base_idx + 4] = cast(u32)(vertex_base_idx + 1)
    INDEX_BUFFER[index_base_idx + 5] = cast(u32)(vertex_base_idx + 3)
  }
}

draw_drawables :: proc() {
  generate_graphics_primitives(SPRITE_DRAWABLES[:SPRITE_DRAWABLES_COUNT], 0)
  generate_graphics_primitives(MASK_DRAWABLES[:MASK_DRAWABLES_COUNT], SPRITE_DRAWABLES_COUNT)
  SPRITE_DRAWABLES_COUNT = 0
  MASK_DRAWABLES_COUNT = 0
}

draw_trimmed_char :: proc(
  c: rune,
  font_atlas: FontAtlas,
  container_pos: Pos,
  container_dim: Dim,
  container_trim: Trim,
  font_size_pixels: f32,
  z: f32,
  colour: Colour,
) {
  glyph_info, ok := font_atlas.char_map[c]
  if !ok {
    fmt.eprintln("c =", c)
    panic("Missing char")
  }
  raw_char_bounding_box_pos := glyph_info.bounding_box.pos
  raw_char_bounding_box_dim := glyph_info.bounding_box.dim

  scale := font_size_pixels / font_atlas.font_size_pixels

  untrimmed_char_ui_dim := Dim {
    w = raw_char_bounding_box_dim.w * scale,
    h = raw_char_bounding_box_dim.h * scale,
  }
  untrimmed_char_ui_pos := center_within_container(untrimmed_char_ui_dim, container_pos, container_dim)

  char_trim := Trim {
    left  = max(0, container_trim.left - (untrimmed_char_ui_pos.x - container_pos.x)),
    right = max(
      0,
      container_trim.right - (container_pos.x + container_dim.w - untrimmed_char_ui_pos.x - untrimmed_char_ui_dim.w),
    ),
    top   = max(
      0,
      container_trim.top - (container_pos.y + container_dim.h - untrimmed_char_ui_pos.y - untrimmed_char_ui_dim.h),
    ),
    bot   = max(0, container_trim.bot - (untrimmed_char_ui_pos.y - container_pos.y)),
  }

  trimmed_char_ui_dim := Dim {
    w = untrimmed_char_ui_dim.w - char_trim.left - char_trim.right,
    h = untrimmed_char_ui_dim.h - char_trim.top - char_trim.bot,
  }
  trimmed_char_ui_pos := Pos {
    x = untrimmed_char_ui_pos.x + char_trim.left,
    y = untrimmed_char_ui_pos.y + char_trim.bot,
  }

  trimmed_char_texture_data := TextureData {
    type = .Mask,
    base = Pos {
      x = raw_char_bounding_box_pos.x + (char_trim.left / scale),
      y = raw_char_bounding_box_pos.y - (char_trim.bot / scale),
    },
    dim = Dim {
      w = raw_char_bounding_box_dim.w - (char_trim.left + char_trim.right) / scale,
      h = raw_char_bounding_box_dim.h - (char_trim.top + char_trim.bot) / scale,
    },
    tex_idx = font_texture_to_idx(font_atlas.font),
  }
  char_drawable: Drawable = {
    colour          = colour,
    dim             = trimmed_char_ui_dim,
    pos             = trimmed_char_ui_pos,
    z               = z,
    override_colour = false,
    texture_data    = trimmed_char_texture_data,
  }
  push_drawable(char_drawable)
}

draw_char :: proc(c: rune, font_atlas: FontAtlas, pos: Pos, z: f32, font_size_pixels: f32, colour: Colour) {
  glyph_info, ok := font_atlas.char_map[c]
  if !ok {
    fmt.eprintln("c =", c)
    panic("Missing char")
  }
  char_texture_data: TextureData = {
    type    = .Mask,
    base    = glyph_info.bounding_box.pos,
    dim     = glyph_info.bounding_box.dim,
    tex_idx = font_texture_to_idx(font_atlas.font),
  }

  scale := font_size_pixels / font_atlas.font_size_pixels
  char_drawable: Drawable = {
    colour = colour,
    dim = Dim{w = scale * glyph_info.bounding_box.dim.w, h = scale * glyph_info.bounding_box.dim.h},
    pos = Pos {
      x = pos.x + scale * cast(f32)glyph_info.left_side_bearing,
      y = pos.y - scale * cast(f32)font_atlas.descent - scale * cast(f32)glyph_info.descent,
    },
    z = z,
    override_colour = false,
    texture_data = char_texture_data,
  }
  push_drawable(char_drawable)
}

draw_fmt_string :: proc(
  fmt_str: string,
  font_atlas: FontAtlas,
  pos: Pos,
  z: f32,
  font_size_pixels: f32,
  colour: Colour,
  args: ..any,
) {
  str := fmt.tprintf(fmt_str, ..args)
  draw_string(str, font_atlas, pos, z, font_size_pixels, colour)
}

draw_string :: proc(chars: string, font_atlas: FontAtlas, pos: Pos, z: f32, font_size_pixels: f32, colour: Colour) {
  assert(font_size_pixels >= 20, "Simple font rendering currently implemented starts visibly breaking below this size")
  x := pos.x
  for c in chars {
    char_pos := Pos {
      x = x,
      y = pos.y,
    }
    draw_char(c, font_atlas, char_pos, z, font_size_pixels, colour)
    scale := font_size_pixels / font_atlas.font_size_pixels
    glyph_info := font_atlas.char_map[c]
    x += scale * cast(f32)glyph_info.advance_width
  }
}

draw_rect :: proc(pos: Pos, z: f32, dim: Dim, colour: Colour) {
  drawable: Drawable = {
    colour          = colour,
    pos             = pos,
    dim             = dim,
    override_colour = true,
    texture_data    = {},
    z               = z,
  }
  push_drawable(drawable)
}
