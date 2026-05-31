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

// TODO - function using stbtt.GetFontBoundingBox to get minimum box needed to hold any character -> think we use this to get our character grid sizing

/*
 * Font sizes in pixel height - nothing stopping you using other values, but probably looks good to standardise on a small set of values
 */
FONT_SMALL :: 20
FONT_MEDIUM :: 32
FONT_LARGE :: 64
FONT_HUGE :: 128

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
    w = output_width,
    h = output_height,
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
    stbtt.MakeCodepointBitmap(&font_info, &atlas.image[byte_offset], x2 - x1, y2 - y1, output_width, scale, scale, c)
    bounding_box := Rect {
      dim = Dim{w = cast(f32)(x2 - x1), h = cast(f32)(y2 - y1)},
      pos = Pos{x = cast(f32)(x + left_side_bearing), y = cast(f32)(y + (y2 - y1))},
    }
    atlas.char_map[c] = GlyphInfo {
      bounding_box      = bounding_box,
      advance_width     = advance_width,
      left_side_bearing = left_side_bearing,
      descent           = y2,
    }

    x += advance_width
  }
  return
}

scale_int :: proc(v: i32, s: f32) -> (scaled_v: i32) {
  return cast(i32)math.floor(cast(f32)v * s)
}

// TODO - would be better to move this to a separate program and #load font data to include it in the compiled game's data segment
// rough plan - separate program does what this function does to assemble the bitmap, optionally writes output pngs to disk for debugging, and outputs a binary blob to be included in this program
// that binary blob needs to start with a way to lookup the offset and size of the font data in the binary blob for each font asset we need
// can probably rely on a hardcoded order while things are simple? Then just read off pairs of u64 values until you get `0 0` as a sentinel marker for start of real data?
init_fonts :: proc(chars: string) {
  for ft in FontTexture {
    atlas := create_font_atlas(FONT_TEXTURE_PATHS[ft], 256, chars, 5120, 5120)
    img.write_png(FONT_IMAGE_OUT_PATHS[ft], atlas.image_dim.w, atlas.image_dim.h, 1, atlas.image, atlas.image_dim.w)
    FONTS[ft] = atlas
  }
  return
}

measure_text :: proc(chars: string, font: FontTexture, font_size_pixels: f32) -> (d: Dim) {
  font_atlas := FONTS[font]
  scale := font_size_pixels / font_atlas.font_size_pixels
  for c in chars {
    glyph_info, ok := font_atlas.char_map[c]
    if !ok {
      fmt.eprintln("c =", c)
      panic("Missing char")
    }
    d.w += scale * cast(f32)glyph_info.advance_width
  }
  /* This leaves some vertical breathing room - it's the vertical height that is guaranteed to contain its contents, it doesn't hug the contents tightly */
  d.h = scale * cast(f32)(font_atlas.ascent - font_atlas.descent)
  return
}
