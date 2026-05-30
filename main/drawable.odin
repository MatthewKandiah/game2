package main

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
  return Dim{w = 2 * dim.w / cast(f32)gc.surface_extent.width, h = 2 * dim.h / cast(f32)gc.surface_extent.height}
}

drawable_pos_to_screen_pos :: proc(pos: Pos) -> Pos {
  return Pos {
    x = (2 * pos.x) / cast(f32)gc.surface_extent.width - 1,
    y = 1 - (2 * pos.y) / cast(f32)gc.surface_extent.height,
  }
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
