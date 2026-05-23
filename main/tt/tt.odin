package tt

import stbtt "vendor:stb/truetype"

get_font_v_metrics :: proc(fontinfo: ^stbtt.fontinfo) -> (ascent, descent, linegap: i32) {
  stbtt.GetFontVMetrics(fontinfo, &ascent, &descent, &linegap)
  return
}

get_font_h_metrics :: proc(fontinfo: ^stbtt.fontinfo, codepoint: rune) -> (advance_width, left_side_bearing: i32) {
  stbtt.GetCodepointHMetrics(fontinfo, codepoint, &advance_width, &left_side_bearing)
  return
}

get_font_bitmap_box :: proc(fontinfo: ^stbtt.fontinfo, codepoint: rune, scale: f32) -> (x0, y0, x1, y1: i32) {
  stbtt.GetCodepointBitmapBox(fontinfo, codepoint, scale, scale, &x0, &y0, &x1, &y1)
  return
}
