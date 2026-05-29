package main

import "core:fmt"
import "core:log"
import "core:math"
import "core:os"
import "core:strings"
import "img"
import "tt"
import stbtt "vendor:stb/truetype"

FONTS := [FontTexture]FontAtlas{}

FontAtlas :: struct {
  font_size_pixels: f32,
  ascent:           i32,
  descent:          i32,
  linegap:          i32,
  image_dim:        GridDim,
  image:            []u8,
  char_map:         map[rune]GlyphInfo,
}

GlyphInfo :: struct {
  bounding_box:      Rect,
  advance_width:     i32,
  left_side_bearing: i32,
  descent:           i32,
}

create_font_atlas :: proc(
  path: string,
  size_pixels: f32,
  chars: string,
  output_width: i32,
  output_height: i32,
) -> (
  atlas: FontAtlas,
) {
  local_fatal :: proc(args: ..any) {
    log.fatal(..args)
    panic("FATAL - Font atlas error")
  }

  atlas.font_size_pixels = size_pixels
  atlas.image_dim = GridDim {
    v = {output_width, output_height},
  }
  atlas.char_map = make(map[rune]GlyphInfo)

  file_data, err := os.read_entire_file(path, context.allocator)
  if err != nil {
    local_fatal("Failed to read file", path)
  }
  defer delete(file_data)
  
  font_info: stbtt.fontinfo
  if !stbtt.InitFont(&font_info, raw_data(file_data), 0) {
    local_fatal("Failed to initialise font", path)
  }

  bytes_per_pixel :: 1
  atlas.image = make([]u8, output_width * output_height * bytes_per_pixel)

  scale := stbtt.ScaleForPixelHeight(&font_info, size_pixels)

  raw_ascent, raw_descent, raw_linegap := tt.get_font_v_metrics(&font_info)
  atlas.ascent = scale_int(raw_ascent, scale)
  atlas.descent = scale_int(raw_descent, scale)
  atlas.linegap = scale_int(raw_linegap, scale)

  x: i32 = 0
  base_y: i32 = 0
  for c, i in chars {
    advance_width, left_side_bearing := tt.get_font_h_metrics(&font_info, c)
    advance_width = scale_int(advance_width, scale)
    left_side_bearing = scale_int(left_side_bearing, scale)

    x1, y1, x2, y2 := tt.get_font_bitmap_box(&font_info, c, scale)
    if x + left_side_bearing + (x2 - x1) >= output_width {
      x = 0
      base_y += atlas.ascent - atlas.descent + atlas.linegap
    }

    y := base_y + atlas.ascent + y1
    byte_offset := x + left_side_bearing + (y * output_width)
    stbtt.MakeCodepointBitmap(
      &font_info,
      &atlas.image[byte_offset],
      x2 - x1,
      y2 - y1,
      output_width,
      scale,
      scale,
      c,
    )
    bounding_box := Rect {
      dim = Dim{v = {cast(f32)(x2 - x1), cast(f32)(y2 - y1)}},
      pos = Pos{v = {cast(f32)(x + left_side_bearing), cast(f32)(y + (y2 - y1))}},
    }
    atlas.char_map[c] = GlyphInfo {
      bounding_box      = bounding_box,
      advance_width     = advance_width,
      left_side_bearing = left_side_bearing,
      descent = y2,
    }

    x += advance_width
  }
  return
}

scale_int :: proc(v: i32, s: f32) -> (scaled_v: i32) {
  return cast(i32)math.floor(cast(f32)v * s)
}

init_fonts :: proc(chars: string) {
  for ft in FontTexture {
    atlas := create_font_atlas(FONT_TEXTURE_PATHS[ft], 32, chars, 256, 256)
    img.write_png(FONT_IMAGE_OUT_PATHS[ft], atlas.image_dim.w, atlas.image_dim.h, 1, atlas.image, atlas.image_dim.w)
    FONTS[ft] = atlas
  }
  return
}
