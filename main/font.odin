package main

import "core:math"
import "core:os"
import "core:fmt"
import "core:log"
import "core:strings"
import tt "vendor:stb/truetype"
import "img"

// TODO - write a wrapper for the truetype functions

FontAtlasInfo :: struct {
  size_pixels: f32,
  chars: string,
  output_width: i32,
  output_height: i32,

}

create_font_atlas :: proc(path: string, font_atlas_info: FontAtlasInfo) -> (output: []u8) {
  local_fatal :: proc(args: ..any) {
    log.fatal(..args)
    panic("FATAL - Font atlas error")
  }

  file_data, err := os.read_entire_file(path, context.allocator)
  if err != nil {
    local_fatal("Failed to read file", path)
  }
  // TODO - can we defer delete(data, context.allocator) here? Depends if we want kerning for strings in the app

  info: tt.fontinfo
  if !tt.InitFont(&info, raw_data(file_data), 0) {
    local_fatal("Failed to initialise font", path)
  }

  bytes_per_pixel :: 1
  output = make([]u8, font_atlas_info.output_width * font_atlas_info.output_height * bytes_per_pixel)
  
  line_height: i32 = 32

  scale := tt.ScaleForPixelHeight(&info, font_atlas_info.size_pixels)

  ascent, descent, linegap: i32
  tt.GetFontVMetrics(&info, &ascent, &descent, &linegap)
  ascent = cast(i32)math.round(cast(f32)ascent * scale)
  descent = cast(i32)math.round(cast(f32)descent * scale)

  x: i32 = 0
  for c, i in font_atlas_info.chars {
    advance_width, left_side_bearing: i32
    tt.GetCodepointHMetrics(&info, c, &advance_width, &left_side_bearing)
    advance_width = cast(i32)(cast(f32)advance_width * scale)
    left_side_bearing = cast(i32)(cast(f32)left_side_bearing * scale)
    
    x1, y1, x2, y2: i32
    tt.GetCodepointBitmapBox(&info, c, scale, scale, &x1, &y1, &x2, &y2)

    y := ascent + y1
    byte_offset := x + left_side_bearing + (y * font_atlas_info.output_width)
    tt.MakeCodepointBitmap(&info, &output[byte_offset], x2 - x1, y2 - y1, font_atlas_info.output_width, scale, scale, c)

    x += advance_width
  }
  return
}
