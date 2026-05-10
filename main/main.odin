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
}
gc: GlobalContext

main :: proc() {
    console_logger := log.create_console_logger(lowest = .Warning)
    log_file, log_file_err := os.create("game2_logs.txt")
    if log_file_err != nil {
        log.fatal(log_file_err)
        panic("Failed to create log file")
    }
    file_logger := log.create_file_logger(log_file, lowest = .Info)
    context.logger = log.create_multi_logger(file_logger, console_logger)

    {     // glfw init
        glfw.SetErrorCallback(error_callback)

        ok := glfw.Init()
        if !ok {
            panic("glfw.Init failed")
        }
    }
    defer glfw.Terminate()

    {     // create window
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

    {     // initialise Vulkan instance
        vulkan.load_proc_addresses(get_proc_address)
        application_info := vulkan.ApplicationInfo {
            sType              = .APPLICATION_INFO,
            pApplicationName   = APP_NAME,
            applicationVersion = vulkan.MAKE_VERSION(1, 0, 0),
            pEngineName        = "None",
            engineVersion      = vulkan.MAKE_VERSION(1, 0, 0),
            apiVersion         = vulkan.API_VERSION_1_3,
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

    {     // create Vulkan WSI surface
        res := glfw.CreateWindowSurface(gc.vk_instance, gc.window, nil, &gc.vk_surface)
        if vk.not_success(res) {
            vk.fatal("create vk khr window surface failed", res)
        }
    }

    renderer := init_renderer()
    stopwatch := time.Stopwatch{}

    texture_data_red := TextureData {
        base = Pos{v = {0, 32}},
        dim = Dim{v = {32, 32}},
        tex_idx = SPRITE_TEXTURE_INDEX,
    }

    texture_data_green := TextureData {
        base = Pos{v = {32, 32}},
        dim = Dim{v = {32, 32}},
        tex_idx = SPRITE_TEXTURE_INDEX,
    }

    texture_data_a := TextureData {
        base = Pos{v = {0, 16}},
        dim = Dim{v = {8, 16}},
        tex_idx = FONT_TEXTURE_INDEX,
    }

    texture_data_b := TextureData {
        base = Pos{v = {8, 16}},
        dim = Dim{v = {8, 16}},
        tex_idx = FONT_TEXTURE_INDEX,
    }

    texture_data_yellow := TextureData {
        base = Pos{v = {0, 128}},
        dim = Dim{v = {128, 128}},
        tex_idx = YELLOW_TEXTURE_INDEX,
    }

    texture_data_gradient := TextureData {
        base = Pos{v = {0, 128}},
        dim = Dim{v = {128, 128}},
        tex_idx = GRADIENT_TEXTURE_INDEX,
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
        dim             = drawable_red.dim,
        texture_data    = texture_data_a,
        override_colour = false,
        colour          = BLUE,
    }

    drawable_b := Drawable {
        pos             = drawable_green.pos,
        z               = 0.2,
        dim             = drawable_green.dim,
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

        DRAWABLES[0] = drawable_a
        DRAWABLES[1] = drawable_red
        DRAWABLES[2] = drawable_green
        DRAWABLES[3] = drawable_b
        DRAWABLES[4] = drawable_yellow
        DRAWABLES[5] = drawable_gradient
        DRAWABLES_COUNT = 6
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
    gc.window_resized = true
}

get_proc_address :: proc(p: rawptr, name: cstring) {
    (cast(^rawptr)p)^ = glfw.GetInstanceProcAddress(gc.vk_instance, name)
}
