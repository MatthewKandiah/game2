package main

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:os"
import "core:time"
import "vendor:glfw"
import "vendor:vulkan"
import "vk"
import stbtt "vendor:stb/truetype"

WINDOW_WIDTH :: 640
WINDOW_HEIGHT :: 480
MIN_WINDOW_WIDTH :: 640
MIN_WINDOW_HEIGHT :: 480
APP_NAME :: "Game2"

GlobalContext :: struct {
  window:         glfw.WindowHandle,
  window_resized: bool,
  vk_surface:     vulkan.SurfaceKHR,
  vk_instance:    vulkan.Instance,
  surface_extent: vulkan.Extent2D,
  cursor_pos:     Pos,
  logger:         runtime.Logger,
}
gc: GlobalContext

main :: proc() {
  console_logger := log.create_console_logger(lowest = .Error)
  log_file, log_file_err := os.create("./build/game2_logs.txt")
  if log_file_err != nil {
    log.fatal(log_file_err)
    panic("Failed to create log file")
  }
  file_logger := log.create_file_logger(log_file, lowest = .Info)
  gc.logger = log.create_multi_logger(file_logger, console_logger)
  context.logger = gc.logger

  {   // glfw init
    glfw.SetErrorCallback(error_callback)

    ok := glfw.Init()
    if !ok {
      panic("glfw.Init failed")
    }
  }
  defer glfw.Terminate()

  {   // create window
    glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
    glfw.WindowHint(glfw.RESIZABLE, true)
    gc.window = glfw.CreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, APP_NAME, nil, nil)
    if gc.window == nil {
      panic("glfw.CreateWindow failed")
    }
    glfw.SetWindowSizeLimits(gc.window, MIN_WINDOW_WIDTH, MIN_WINDOW_HEIGHT, glfw.DONT_CARE, glfw.DONT_CARE)
  }
  defer {
    glfw.DestroyWindow(gc.window)
    gc.window = nil
  }

  glfw.SetWindowSizeCallback(gc.window, window_size_callback)

  {   // initialise Vulkan instance
    vulkan.load_proc_addresses(get_proc_address)
    application_info := vulkan.ApplicationInfo {
      sType              = .APPLICATION_INFO,
      pApplicationName   = APP_NAME,
      applicationVersion = vulkan.MAKE_VERSION(1, 0, 0),
      pEngineName        = "None",
      engineVersion      = vulkan.MAKE_VERSION(1, 0, 0),
      apiVersion         = vulkan.API_VERSION_1_4,
    }
    glfw_required_instance_extensions := glfw.GetRequiredInstanceExtensions()
    if len(glfw_required_instance_extensions) == 0 {
      panic("get required instance extensions failed - can't present to a window surface on this system")
    }
    instance_create_info := vulkan.InstanceCreateInfo {
      sType                   = .INSTANCE_CREATE_INFO,
      pApplicationInfo        = &application_info,
      enabledExtensionCount   = cast(u32)len(glfw_required_instance_extensions),
      ppEnabledExtensionNames = raw_data(glfw_required_instance_extensions),
      enabledLayerCount       = cast(u32)len(ENABLED_LAYERS),
      ppEnabledLayerNames     = raw_data(ENABLED_LAYERS),
    }
    if res := vulkan.CreateInstance(&instance_create_info, nil, &gc.vk_instance); vk.not_success(res) {
      vk.fatal("create instance failed", res)
    }
  }

  {   // create Vulkan WSI surface
    res := glfw.CreateWindowSurface(gc.vk_instance, gc.window, nil, &gc.vk_surface)
    if vk.not_success(res) {
      vk.fatal("create vk khr window surface failed", res)
    }
  }

  chars := " 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ@!#%"
  init_fonts(chars)
  renderer := init_renderer()
  stopwatch := time.Stopwatch{}

  // main loop
  for !glfw.WindowShouldClose(gc.window) {
    time.stopwatch_start(&stopwatch)
    glfw.PollEvents()

    hello_world := "Hello World! lglglg"
    // bottom - with kerning
    draw_string(hello_world, .UbuntuMono, Pos{v = {100, 150}}, 0.8, true)
    // top - without kerning
    draw_string(hello_world, .UbuntuMono, Pos{v = {100, 350}}, 0.8, false)
    render_frame(&renderer)

    h, m, s, nanos := time.precise_clock_from_stopwatch(stopwatch)
    for nanos < 16_666_000 {
      h, m, s, nanos = time.precise_clock_from_stopwatch(stopwatch)
    }
    time.stopwatch_reset(&stopwatch)
  }
}

error_callback :: proc "c" (error: i32, description: cstring) {
  context = runtime.default_context()
  fmt.eprintln("glfw error", error, description)
}

window_size_callback :: proc "c" (window: glfw.WindowHandle, width: i32, height: i32) {
  context = runtime.default_context()
  context.logger = gc.logger
  log.info("glfw - window resize")
}

get_proc_address :: proc(p: rawptr, name: cstring) {
  (cast(^rawptr)p)^ = glfw.GetInstanceProcAddress(gc.vk_instance, name)
}

/* TODO
 * - should this take in a box, and just draw as much text as fits inside that box? or should it take text and a position, and report back its height and width?
 * - kerning seems to be doing nothing? maybe I've made a mistake and called it wrong? tempting to drop it, then we don't need to hold on to the fontinfo data past initialisation either
 * - scaling up/down by a lot looks (predictably) bad, do we just live with this for now? Other options are move to linear interpolation instead of nearest neighbour filtering, or creating small/medium/large textures for fonts to avoid up-/down-scaling too much
 * - draw a box directly beneath the string position. is the position defining the bottom of the max-descent, so our characters float above that box? or is it the baseline, so our characters descend below that and intersect with the box?
 */

draw_string :: proc(chars: string, font: FontTexture, pos: Pos, scale: f32, with_kerning: bool) {
  font_atlas := FONTS[font]
  x := pos.x
  prev_c: rune
  for c, i in chars {
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
    if with_kerning && prev_c != 0 {
      kern := stbtt.GetCodepointKernAdvance(&font_atlas.font_info, prev_c, c)
      fmt.println(prev_c, c, kern)
      x += cast(f32)kern
    }
    char_drawable: Drawable = {
      colour = BLACK,
      dim = mul(scale, glyph_info.bounding_box.dim),
      pos = Pos{v = {x + scale * cast(f32)glyph_info.left_side_bearing, pos.y - scale * cast(f32)glyph_info.descent}},
      z = 0.5,
      override_colour = false,
      texture_data = char_texture_data,
    }
    push_drawable(char_drawable)
    x += scale * cast(f32)glyph_info.advance_width
    prev_c = c
  }
}
