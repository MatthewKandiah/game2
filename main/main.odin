package main

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:os"
import "core:time"
import "vendor:glfw"
import "vendor:vulkan"
import "vk"

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
  log_file, log_file_err := os.create("game2_logs.txt")
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

  chars := "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ@!#%"
  fonts := init_fonts(chars)
  renderer := init_renderer()
  stopwatch := time.Stopwatch{}

  texture_data_red := TextureData {
    base = Pos{v = {0, 32}},
    dim = Dim{v = {32, 32}},
    tex_idx = texture_to_idx(Texture.Sprite),
  }

  texture_data_green := TextureData {
    base = Pos{v = {32, 32}},
    dim = Dim{v = {32, 32}},
    tex_idx = texture_to_idx(Texture.Sprite),
  }

  a_font := FontTexture.UbuntuMono
  ubuntu_a_glyph_info, ubuntu_a_ok := fonts[a_font].char_map['a']
  if !ubuntu_a_ok {
    panic("'a' not found in font atlas")
  }
  ubuntu_a_box := ubuntu_a_glyph_info.bounding_box
  texture_data_a := TextureData {
    base = ubuntu_a_box.pos,
    dim = ubuntu_a_box.dim,
    tex_idx = font_texture_to_idx(a_font),
    type = .Mask,
  }

  b_font := FontTexture.Ubuntu
  ubuntu_b_glyph_info, ubuntu_b_ok := fonts[b_font].char_map['b']
  if !ubuntu_b_ok {
    panic("'b' not found in font atlas")
  }
  ubuntu_b_box := ubuntu_b_glyph_info.bounding_box
  texture_data_b := TextureData {
    base = ubuntu_b_box.pos,
    dim = ubuntu_b_box.dim,
    tex_idx = font_texture_to_idx(b_font),
    type = .Mask,
  }

  texture_data_yellow := TextureData {
    base = Pos{v = {0, 128}},
    dim = Dim{v = {128, 128}},
    tex_idx = texture_to_idx(Texture.Yellow),
  }

  texture_data_gradient := TextureData {
    base = Pos{v = {0, 128}},
    dim = Dim{v = {128, 128}},
    tex_idx = texture_to_idx(Texture.Gradient),
  }

  drawable_red := Drawable {
    pos = Pos{v = {0, 0}},
    z = 0.1,
    dim = Dim{v = {360, 360}},
    texture_data = texture_data_red,
    override_colour = false,
    colour = RED,
  }

  drawable_green := Drawable {
    pos = Pos{v = {360, 360}},
    z = 0.1,
    dim = Dim{v = {100, 100}},
    texture_data = texture_data_green,
    override_colour = false,
    colour = GREEN,
  }

  drawable_a := Drawable {
    pos             = drawable_red.pos,
    z               = 0.2,
    dim             = Dim{v = {drawable_red.dim.h * 7 / 9, drawable_red.dim.h}},
    texture_data    = texture_data_a,
    override_colour = false,
    colour          = BLUE,
  }

  drawable_b := Drawable {
    pos             = drawable_green.pos,
    z               = 0.2,
    dim             = Dim{v = {drawable_green.dim.h * 7 / 9, drawable_green.dim.h}},
    texture_data    = texture_data_b,
    override_colour = false,
    colour          = YELLOW,
  }

  drawable_yellow := Drawable {
    pos             = drawable_red.pos,
    z               = 0.15,
    dim             = drawable_red.dim,
    texture_data    = texture_data_yellow,
    override_colour = false,
    colour          = GREY,
  }

  drawable_gradient := Drawable {
    pos = Pos{v = {400, 0}},
    dim = Dim{v = {400, 400}},
    z = 0.3,
    texture_data = texture_data_gradient,
    override_colour = false,
    colour = WHITE,
  }


  // main loop
  for !glfw.WindowShouldClose(gc.window) {
    time.stopwatch_start(&stopwatch)
    glfw.PollEvents()

    push_drawable(drawable_a)
    push_drawable(drawable_red)
    push_drawable(drawable_green)
    push_drawable(drawable_b)
    push_drawable(drawable_yellow)
    push_drawable(drawable_gradient)
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
