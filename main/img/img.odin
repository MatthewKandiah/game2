package img

import "core:log"
import "vendor:stb/image"

fatal :: proc(args: ..any) {
  log.fatal(..args)
  panic("img fatal")
}

load :: proc(filepath: cstring, desired_channel_count: i32) -> (ok: bool, x, y, channels_in_file: i32, data: []u8) {
  tmp_data := image.load(filepath, &x, &y, &channels_in_file, desired_channel_count)
  if tmp_data == nil {
    ok = false
    return
  }
  byte_count := x * y * desired_channel_count
  data = tmp_data[:byte_count]
  ok = true
  return
}

write_png :: proc(filepath: cstring, width: i32, height: i32, channel_count: i32, data: []u8, stride_in_bytes: i32) {
  result := image.write_png(filepath, width, height, channel_count, raw_data(data), stride_in_bytes)
  if result == 0 {
    fatal("failed to write png", filepath)
  }
}

free :: proc(data: []u8) {
  image.image_free(raw_data(data))
}
