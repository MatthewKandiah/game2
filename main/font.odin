package main

import "core:math"
import "core:os"
import "core:fmt"
import "core:log"
import "core:strings"
import stbtt "vendor:stb/truetype"
import "img"
import "tt"

GlyphInfo :: struct {
  bounding_box: GridRect,
  advance_width: i32,
  left_side_bearing: i32,
}

FontAtlas :: struct {
  font_size_pixels: f32,
  ascent: i32,
  descent: i32,
  linegap: i32,
  image_dim: GridDim,
  image: []u8,
  char_map : map[rune]GlyphInfo,
  font_info: stbtt.fontinfo,
  font_file_data: []u8,
}

create_font_atlas :: proc(path: string, size_pixels: f32, chars: string, output_width: i32, output_height: i32) -> (atlas: FontAtlas) {
  local_fatal :: proc(args: ..any) {
    log.fatal(..args)
    panic("FATAL - Font atlas error")
  }

  atlas.font_size_pixels = size_pixels
  atlas.image_dim = GridDim{v = {output_width, output_height}}
  atlas.char_map = make(map[rune]GlyphInfo)

  file_data, err := os.read_entire_file(path, context.allocator)
  if err != nil {
    local_fatal("Failed to read file", path)
  }
  atlas.font_file_data = file_data
  
  if !stbtt.InitFont(&atlas.font_info, raw_data(file_data), 0) {
    local_fatal("Failed to initialise font", path)
  }

  bytes_per_pixel :: 1
  atlas.image = make([]u8, output_width * output_height * bytes_per_pixel)
  
  scale := stbtt.ScaleForPixelHeight(&atlas.font_info, size_pixels)

  raw_ascent, raw_descent, raw_linegap := tt.get_font_v_metrics(&atlas.font_info)
  atlas.ascent = scale_int(raw_ascent, scale)
  atlas.descent = scale_int(raw_descent, scale)
  atlas.linegap = scale_int(raw_linegap, scale)

  x: i32 = 0
  base_y: i32 = 0
  for c, i in chars {
    advance_width, left_side_bearing := tt.get_font_h_metrics(&atlas.font_info, c)
    advance_width = scale_int(advance_width, scale)
    left_side_bearing = scale_int(left_side_bearing, scale)
    
    x1, y1, x2, y2 := tt.get_font_bitmap_box(&atlas.font_info, c, scale)
    if x + left_side_bearing + (x2 - x1) >= output_width {
      x = 0
      base_y += atlas.ascent - atlas.descent + atlas.linegap
    }

    y := base_y + atlas.ascent + y1
    byte_offset := x + left_side_bearing + (y * output_width)
    stbtt.MakeCodepointBitmap(&atlas.font_info, &atlas.image[byte_offset], x2 - x1, y2 - y1, output_width, scale, scale, c)
    atlas.char_map[c] = GlyphInfo {
      bounding_box = GridRect{
	dim = GridDim{v = {x2 - x1, y2 - y1}},
	pos = GridPos{v = {x, y}},
      },
      advance_width = advance_width,
      left_side_bearing = left_side_bearing,
    }

    x += advance_width
  }
  return
}

scale_int :: proc(v: i32, s: f32) -> (scaled_v: i32) {
  return cast(i32)math.floor(cast(f32)v * s)
}
