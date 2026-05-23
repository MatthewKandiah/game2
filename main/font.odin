package main

import "core:math"
import "core:os"
import "core:fmt"
import "core:log"
import "core:strings"
import tt "vendor:stb/truetype"
import "img"

// TODO - write a wrapper for the truetype functions

FontAtlas :: struct {
  size_pixels: f32,
  chars: string,
  output_width: i32,
  output_height: i32,
  output: []u8,
  char_map : map[rune]GridRect,
  font_info: tt.fontinfo,
  font_file_data: []u8,
}

create_font_atlas :: proc(path: string, size_pixels: f32, chars: string, output_width: i32, output_height: i32) -> (atlas: FontAtlas) {
  local_fatal :: proc(args: ..any) {
    log.fatal(..args)
    panic("FATAL - Font atlas error")
  }

  atlas.size_pixels = size_pixels
  atlas.chars = chars
  atlas.output_width = output_width
  atlas.output_height = output_height
  atlas.char_map = make(map[rune]GridRect)

  file_data, err := os.read_entire_file(path, context.allocator)
  if err != nil {
    local_fatal("Failed to read file", path)
  }
  atlas.font_file_data = file_data
  
  if !tt.InitFont(&atlas.font_info, raw_data(file_data), 0) {
    local_fatal("Failed to initialise font", path)
  }

  bytes_per_pixel :: 1
  atlas.output = make([]u8, output_width * output_height * bytes_per_pixel)
  
  scale := tt.ScaleForPixelHeight(&atlas.font_info, size_pixels)

  ascent, descent, linegap: i32
  tt.GetFontVMetrics(&atlas.font_info, &ascent, &descent, &linegap)
  ascent = cast(i32)math.round(cast(f32)ascent * scale)
  descent = cast(i32)math.round(cast(f32)descent * scale)

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
      base_y += ascent - descent + linegap
    }

    y := base_y + ascent + y1
    byte_offset := x + left_side_bearing + (y * output_width)
    tt.MakeCodepointBitmap(&atlas.font_info, &atlas.output[byte_offset], x2 - x1, y2 - y1, output_width, scale, scale, c)
    atlas.char_map[c] = GridRect{
      dim = GridDim{v = {x2 - x1, y2 - y1}},
      pos = GridPos{v = {x, y}},
    }

    x += advance_width
  }
  return
}
