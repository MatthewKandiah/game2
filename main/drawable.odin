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

SPRITE_DRAWABLES_SIZE :: 10_000
MASK_DRAWABLES_SIZE :: 10_000
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

draw_string :: proc(chars: string, font: FontTexture, pos: Pos, z: f32, font_size_pixels: f32, colour: Colour) {
  assert(font_size_pixels >= 20, "Simple font rendering currently implemented starts visibly breaking below this size")
  font_atlas := FONTS[font]
  x := pos.x
  for c in chars {
    glyph_info, ok := font_atlas.char_map[c]
    if !ok {
      fmt.eprintln("c =", c)
      panic("Missing char")
    }
    char_texture_data: TextureData = {
      type    = .Mask,
      base    = glyph_info.bounding_box.pos,
      dim     = glyph_info.bounding_box.dim,
      tex_idx = font_texture_to_idx(font),
    }

    scale := font_size_pixels / font_atlas.font_size_pixels
    char_drawable: Drawable = {
      colour = colour,
      dim = Dim{w = scale * glyph_info.bounding_box.dim.w, h = scale * glyph_info.bounding_box.dim.h},
      pos = Pos {
        x = x + scale * cast(f32)glyph_info.left_side_bearing,
        y = pos.y - scale * cast(f32)font_atlas.descent - scale * cast(f32)glyph_info.descent,
      },
      z = z,
      override_colour = false,
      texture_data = char_texture_data,
    }
    push_drawable(char_drawable)
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
