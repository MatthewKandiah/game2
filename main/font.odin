package main

import "core:math"
import "core:os"
import "core:fmt"
import "core:log"
import "core:strings"
import tt "vendor:stb/truetype"
import "img"

// TODO - write a wrapper for the truetype functions

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
  font_info: tt.fontinfo,
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
  
  if !tt.InitFont(&atlas.font_info, raw_data(file_data), 0) {
    local_fatal("Failed to initialise font", path)
  }

  bytes_per_pixel :: 1
  atlas.image = make([]u8, output_width * output_height * bytes_per_pixel)
  
  scale := tt.ScaleForPixelHeight(&atlas.font_info, size_pixels)

  raw_ascent, raw_descent: i32
  tt.GetFontVMetrics(&atlas.font_info, &raw_ascent, &raw_descent, &atlas.linegap)
  atlas.ascent = cast(i32)math.round(cast(f32)raw_ascent * scale)
  atlas.descent = cast(i32)math.round(cast(f32)raw_descent * scale)

  x: i32 = 0
  base_y: i32 = 0
  for c, i in chars {
    advance_width, left_side_bearing: i32
    tt.GetCodepointHMetrics(&atlas.font_info, c, &advance_width, &left_side_bearing)
    advance_width = cast(i32)(cast(f32)advance_width * scale)
    left_side_bearing = cast(i32)(cast(f32)left_side_bearing * scale)
    
    x1, y1, x2, y2: i32
    tt.GetCodepointBitmapBox(&atlas.font_info, c, scale, scale, &x1, &y1, &x2, &y2)

    if x + left_side_bearing + (x2 - x1) >= output_width {
      x = 0
      base_y += atlas.ascent - atlas.descent + atlas.linegap
    }

    y := base_y + atlas.ascent + y1
    byte_offset := x + left_side_bearing + (y * output_width)
    tt.MakeCodepointBitmap(&atlas.font_info, &atlas.image[byte_offset], x2 - x1, y2 - y1, output_width, scale, scale, c)
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
