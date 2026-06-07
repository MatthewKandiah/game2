package main

import "base:runtime"
import "core:fmt"
import "core:hash/xxhash"
import "core:log"
import "core:mem"
import "core:os"
import "core:time"
import "vendor:glfw"
import stbtt "vendor:stb/truetype"
import "vendor:vulkan"
import "vk"

PRINT_FPS :: false
PRINT_GRAPHICS_PRIMITIVE_COUNTS :: false

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
  screen_dim:     Dim,
  logger:         runtime.Logger,
  input:          InputState,
  ui:             UiState,
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
  glfw.SetCursorPosCallback(gc.window, cursor_pos_callback)
  glfw.SetMouseButtonCallback(gc.window, mouse_button_callback)

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

  chars := " 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ@!#%,.$+-"
  stopwatch := time.Stopwatch{}
  {   // init fonts
    time.stopwatch_start(&stopwatch)
    init_fonts(chars)
    _, _, secs, nanos := time.precise_clock_from_stopwatch(stopwatch)
    fmt.println("init_fonts:", secs, "secs,", cast(f32)(nanos) / 1_000_000, "millis")
    time.stopwatch_reset(&stopwatch)
  }

  renderer: Renderer
  {   // init renderer
    time.stopwatch_start(&stopwatch)
    renderer = init_renderer()
    _, _, _, nanos := time.precise_clock_from_stopwatch(stopwatch)
    fmt.println("init_renderer:", cast(f32)(nanos) / 1_000_000, "millis")
    time.stopwatch_reset(&stopwatch)
  }

  game_grid_buf := make([]GridTile, GRID_WIDTH * GRID_HEIGHT)
  valid_player_pos := init_grid_tiles(game_grid_buf)
  game := Game {
    mode = .MainMenu,
    grid = game_grid_buf,
    player_pos = valid_player_pos,
    viewport_centre = valid_player_pos,
    is_looking = false,
    zoom_level = 1,
  }
  game_player_move(&game, valid_player_pos) // slightly hacky, want to update known and visible grid values

  // main loop
  for !glfw.WindowShouldClose(gc.window) {
    time.stopwatch_start(&stopwatch)
    glfw.PollEvents()

    gc.ui.triggered_id = 0
    flush_input_events()

    gc.ui.hot_id = gc.ui.next_hot_id
    gc.ui.next_hot_id = 0
    gc.ui.next_hot_z = 0

    switch game.mode {
    case .MainMenu:
      menu_view(&game)
    case .Playing:
      playing_view(&game)
    }

    when PRINT_GRAPHICS_PRIMITIVE_COUNTS {
      fmt.printf("Sprites: %d, Masks: %d\n", SPRITE_DRAWABLES_COUNT, MASK_DRAWABLES_COUNT)
    }

    render_frame(&renderer)

    when PRINT_FPS {
      h, m, s, nanos := time.precise_clock_from_stopwatch(stopwatch)
      fmt.println("Frame:", cast(f32)(nanos) / 1_000_000, "millis")
      time.stopwatch_reset(&stopwatch)
    }
  }
}

get_context :: proc() -> runtime.Context {
  ctxt := runtime.default_context()
  ctxt.logger = gc.logger
  return ctxt
}

error_callback :: proc "c" (error: i32, description: cstring) {
  context = get_context()
  fmt.eprintln("glfw error", error, description)
}

window_size_callback :: proc "c" (window: glfw.WindowHandle, width: i32, height: i32) {
  context = get_context()
  log.info("glfw - window resize")
}

cursor_pos_callback :: proc "c" (window: glfw.WindowHandle, x, y: f64) {
  context = get_context()
  // glfw uses top-left origin, we use bottom-left origin
  gc.input.cursor_pos = Pos {
    x = cast(f32)x,
    y = gc.screen_dim.h - cast(f32)y,
  }
}

mouse_button_callback :: proc "c" (window: glfw.WindowHandle, button, action, mods: i32) {
  context = get_context()
  left := button == glfw.MOUSE_BUTTON_LEFT
  down := action == glfw.PRESS
  up := action == glfw.RELEASE
  if left && down {
    push_input_event(.MouseLeftDown)
  } else if left && up {
    push_input_event(.MouseLeftUp)
  }
}

get_proc_address :: proc(p: rawptr, name: cstring) {
  (cast(^rawptr)p)^ = glfw.GetInstanceProcAddress(gc.vk_instance, name)
}
