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

  chars := " 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ@!#%,."
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

  game := Game {
    mode = .MainMenu,
  }

  // main loop
  for !glfw.WindowShouldClose(gc.window) {
    time.stopwatch_start(&stopwatch)
    glfw.PollEvents()

    gc.ui.triggered_id = 0
    flush_input_events()

    gc.ui.hot_id = gc.ui.next_hot_id
    gc.ui.next_hot_id = 0
    gc.ui.next_hot_z = 0

    button_dim := Dim {
      w = 300,
      h = 100,
    }

    switch game.mode {
    case .MainMenu:
      {
        ui_pos := Pos {
          x = 100,
          y = 500,
        }
        if button(get_uid(#file, #line), ui_pos, button_dim, 0.1, "START", FONT_LARGE, .Ubuntu) {
          fmt.println("START")
          game.mode = .Playing
        }
        ui_pos.x += button_dim.w
        ui_pos.x += 10
        if button(get_uid(#file, #line), ui_pos, button_dim, 0.2, "QUIT", FONT_LARGE, .Ubuntu) {
          fmt.println("QUIT")
          os.exit(0)
        }

        ui_pos.x -= 250
        ui_pos.y -= 80
        if button(get_uid(#file, #line), ui_pos, button_dim, 0.3, "TEST", FONT_MEDIUM, .Ubuntu) {
          fmt.println("Top button pressed")
        }
      }
    case .Playing:
      {
        ui_pos := Pos {
          x = 100,
          y = 500,
        }
        if button(get_uid(#file, #line), ui_pos, button_dim, 0.1, "fun", FONT_SMALL, .UbuntuMono) {
          fmt.println("Having fun")
        }
        ui_pos.y -= 2 * button_dim.h
        if button(get_uid(#file, #line), ui_pos, button_dim, 0.1, "exit", FONT_SMALL, .UbuntuMono) {
          fmt.println("EXIT")
          game.mode = .MainMenu
        }

        ui_pos = Pos {
          x = 100,
          y = 500,
        }
        square_button_dim := Dim {
          w = 200,
          h = 200,
        }
        for row_idx in 0 ..< 3 {
          for col_idx in 0 ..< 3 {
            d: u64 = cast(u64)row_idx << 8 | cast(u64)col_idx
            if button(get_uid(#file, #line, d), ui_pos, square_button_dim, 0.05, "", {}, {}) {
              fmt.println("clicked grid button", row_idx, col_idx)
            }
            ui_pos.x += square_button_dim.w + 10
          }
          ui_pos.x = 100
          ui_pos.y -= square_button_dim.h + 10
        }
      }
    }

    render_frame(&renderer)

    when PRINT_FPS {
      h, m, s, nanos := time.precise_clock_from_stopwatch(stopwatch)
      fmt.println("Frame:", cast(f32)(nanos) / 1_000_000, "millis")
      /*
    // Throttle frame rate to 60FPS
    for nanos < 16_666_000 {
      h, m, s, nanos = time.precise_clock_from_stopwatch(stopwatch)
    }'xs
    */
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
    y = cast(f32)gc.surface_extent.height - cast(f32)y,
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
