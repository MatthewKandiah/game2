package main

import "core:fmt"
import "core:math"

PlayingViewAction :: struct {
  type: PlayingViewActionType,
  data: PlayingViewActionData,
}

PlayingViewActionType :: enum {
  None,
  PlayerClick,
  GridClick,
  LookClick,
  RecentreClick,
  ExitClick,
  ZoomInClick,
  ZoomOutClick,
  ResetZoomClick,
}

PlayingViewActionData :: union {
  GridClickData,
}

GridClickData :: struct {
  pos:       GridPos,
  tile_type: GridTileType,
}

playing_view :: proc(game: ^Game) {
  action: PlayingViewAction = {
    type = .None,
    data = {},
  }

  button_dim := Dim {
    w = 300,
    h = 100,
  }
  gap: f32 = 10
  ui_pos_top_left := Pos {
    x = gc.screen_dim.w - 2 * gap - button_dim.w,
    y = gc.screen_dim.h,
  }
  buttons_column_action := buttons_column(game, ui_pos_top_left, gap, button_dim)
  if buttons_column_action.type != .None {action = buttons_column_action}

  grid_ui_border: f32 = 30
  grid_ui_dim := Dim {
    w = gc.screen_dim.w - button_dim.w - 2 * gap - 2 * grid_ui_border,
    h = gc.screen_dim.h - 2 * grid_ui_border,
  }
  grid_ui_pos_bot_left := Pos {
    x = grid_ui_border,
    y = grid_ui_border,
  }
  grid_button_dim := Dim {
    w = FONT_MEDIUM * game.zoom_level,
    h = FONT_MEDIUM * game.zoom_level,
  }
  font_size := FONT_MEDIUM * game.zoom_level
  grid_action := grid(game, grid_ui_pos_bot_left, grid_ui_dim, grid_button_dim, font_size)
  if grid_action.type != .None {action = grid_action}

  handle_action(game, action)
}

grid_tile_screen_pos :: proc(
  tile_grid_pos: GridPos,
  centre_grid_pos: GridPos,
  grid_ui_pos: Pos,
  grid_ui_dim: Dim,
  tile_dim: Dim,
) -> Pos {
  grid_centre_ui_pos := Pos {
    x = grid_ui_pos.x + grid_ui_dim.w / 2,
    y = grid_ui_pos.y + grid_ui_dim.h / 2,
  }

  return Pos {
    x = grid_centre_ui_pos.x + (cast(f32)tile_grid_pos.x - cast(f32)centre_grid_pos.x - 0.5) * tile_dim.w,
    y = grid_centre_ui_pos.y + (cast(f32)tile_grid_pos.y - cast(f32)centre_grid_pos.y - 0.5) * tile_dim.h,
  }
}

buttons_column :: proc(game: ^Game, ui_pos_top_left: Pos, gap: f32, button_dim: Dim) -> (action: PlayingViewAction) {
  ui_pos := Pos {
    x = ui_pos_top_left.x + gap,
    y = ui_pos_top_left.y - gap - button_dim.h,
  }
  if text_button(get_uid(), ui_pos, button_dim, 0.1, "Look", FONT_MEDIUM, .Ubuntu) {
    action = {
      type = .LookClick,
    }
  }
  ui_pos.y -= button_dim.h
  ui_pos.y -= gap
  if text_button(get_uid(), ui_pos, button_dim, 0.1, "Play", FONT_MEDIUM, .Ubuntu) {
    action = {
      type = .RecentreClick,
    }
  }
  ui_pos.y -= button_dim.h
  ui_pos.y -= gap

  {   // zoom button row
    button_count: f32 = 2
    zoom_button_dim := Dim {
      w = button_dim.w / button_count,
      h = button_dim.h,
    }
    zoom_button_pos := ui_pos
    if text_button(get_uid(), zoom_button_pos, zoom_button_dim, 0.1, "+", FONT_MEDIUM, .Ubuntu) {
      action = {
        type = .ZoomInClick,
      }
    }
    zoom_button_pos.x += zoom_button_dim.w
    if text_button(get_uid(), zoom_button_pos, zoom_button_dim, 0.1, "-", FONT_MEDIUM, .Ubuntu) {
      action = {
        type = .ZoomOutClick,
      }
    }
    zoom_button_pos.x += zoom_button_dim.w
  }
  ui_pos.y -= button_dim.h
  ui_pos.y -= gap

  if text_button(get_uid(), ui_pos, button_dim, 0.1, "Reset Zoom", FONT_MEDIUM, .Ubuntu) {
    action = {
      type = .ResetZoomClick,
    }
  }
  ui_pos.y -= button_dim.h
  ui_pos.y -= gap

  if game.is_looking {
    button_count: f32 = 4
    viewport_button_dim := Dim {
      w = button_dim.w / button_count,
      h = button_dim.h,
    }
    viewport_button_pos := ui_pos
    if text_button(get_uid(), viewport_button_pos, viewport_button_dim, 0.1, "Left", FONT_SMALL, .Ubuntu) {
      grid_pos := GridPos {
        x = max(0, game.viewport_centre.x - 1),
        y = game.viewport_centre.y,
      }
      tile := grid_get(game.grid, grid_pos)
      action = {
        type = .GridClick,
        data = GridClickData{pos = grid_pos, tile_type = tile.type},
      }
    }
    viewport_button_pos.x += viewport_button_dim.w
    if text_button(get_uid(), viewport_button_pos, viewport_button_dim, 0.1, "Down", FONT_SMALL, .Ubuntu) {
      grid_pos := GridPos {
        x = game.viewport_centre.x,
        y = max(0, game.viewport_centre.y - 1),
      }
      tile := grid_get(game.grid[:], grid_pos)
      action = {
        type = .GridClick,
        data = GridClickData{pos = grid_pos, tile_type = tile.type},
      }
    }
    viewport_button_pos.x += viewport_button_dim.w
    if text_button(get_uid(), viewport_button_pos, viewport_button_dim, 0.1, "Up", FONT_SMALL, .Ubuntu) {
      grid_pos := GridPos {
        x = game.viewport_centre.x,
        y = min(GRID_HEIGHT - 1, game.viewport_centre.y + 1),
      }
      tile := grid_get(game.grid[:], grid_pos)
      action = {
        type = .GridClick,
        data = GridClickData{pos = grid_pos, tile_type = tile.type},
      }}
    viewport_button_pos.x += viewport_button_dim.w
    if text_button(
      get_uid(),
      viewport_button_pos,
      viewport_button_dim,
      0.1,
      "Right",
      FONT_SMALL,
      .Ubuntu,
    ) {
      grid_pos := GridPos {
        x = min(GRID_WIDTH - 1, game.viewport_centre.x + 1),
        y = game.viewport_centre.y,
      }
      tile := grid_get(game.grid[:], grid_pos)
      action = {
        type = .GridClick,
        data = GridClickData{pos = grid_pos, tile_type = tile.type},
      }}
    viewport_button_pos.x += viewport_button_dim.w

    ui_pos.y -= button_dim.h
    ui_pos.y -= gap
  }

  if text_button(get_uid(), ui_pos, button_dim, 0.1, "Exit", FONT_MEDIUM, .Ubuntu) {
    action = {
      type = .ExitClick,
    }
  }
  return action
}

grid :: proc(
  game: ^Game,
  grid_ui_pos_bot_left: Pos,
  grid_ui_dim: Dim,
  grid_button_dim: Dim,
  font_size: f32,
) -> (
  action: PlayingViewAction,
) {
  max_tiles_wide := cast(i32)math.ceil(grid_ui_dim.w / grid_button_dim.w) + 2
  max_tiles_high := cast(i32)math.ceil(grid_ui_dim.h / grid_button_dim.h) + 2
  row_idx_lower := max(0, game.viewport_centre.y - max_tiles_high / 2)
  row_idx_upper := min(GRID_HEIGHT, game.viewport_centre.y + max_tiles_high / 2)
  col_idx_lower := max(0, game.viewport_centre.x - max_tiles_wide / 2)
  col_idx_upper := min(GRID_WIDTH, game.viewport_centre.x + max_tiles_wide / 2)
  for row_idx in row_idx_lower ..< row_idx_upper {
    for col_idx in col_idx_lower ..< col_idx_upper {
      d := cast(u32)(row_idx * GRID_WIDTH + col_idx)
      grid_pos := GridPos {
        x = cast(i32)col_idx,
        y = cast(i32)row_idx,
      }
      ui_pos := grid_tile_screen_pos(
        grid_pos,
        game.viewport_centre,
        grid_ui_pos_bot_left,
        grid_ui_dim,
        grid_button_dim,
      )
      trim := Trim {
        left  = max(0, grid_ui_pos_bot_left.x - ui_pos.x),
        right = max(0, ui_pos.x + grid_button_dim.w - grid_ui_pos_bot_left.x - grid_ui_dim.w),
        top   = max(0, ui_pos.y + grid_button_dim.h - grid_ui_pos_bot_left.y - grid_ui_dim.h),
        bot   = max(0, grid_ui_pos_bot_left.y - ui_pos.y),
      }

      if !overlaps(ui_pos, grid_button_dim, grid_ui_pos_bot_left, grid_ui_dim) {
        continue
      }

      if grid_pos == game.player_pos {
        draw_info := grid_tile_draw_info[.Player]
        if grid_button(
          get_uid(),
          ui_pos,
          grid_button_dim,
          0.06,
          draw_info.char,
          font_size,
          .UbuntuMono,
          draw_info.colour,
          trim,
        ) {
          action = {
            type = .PlayerClick,
          }
        }
      } else {
        tile := grid_get(game.grid, grid_pos)
        if tile.is_known {
          draw_info := grid_tile_draw_info[tile.type]
          if grid_button(
            get_uid(d),
            ui_pos,
            grid_button_dim,
            0.05,
            draw_info.char,
            font_size,
            .UbuntuMono,
            draw_info.colour if tile.is_visible else DARK_GREY,
            trim,
          ) {
            action = {
              type = .GridClick,
              data = GridClickData{pos = grid_pos, tile_type = tile.type},
            }
          }
        }
      }
    }
  }
  return action
}

handle_action :: proc(game: ^Game, action: PlayingViewAction) {
  switch (action.type) {
  case .None:
    return
  case .LookClick:
    {
      game.is_looking = true
    }
  case .RecentreClick:
    {
      game.is_looking = false
      game.viewport_centre = game.player_pos
    }
  case .ZoomInClick:
    {
      game.zoom_level += 0.2
    }
  case .ZoomOutClick:
    {
      game.zoom_level = max(0.6, game.zoom_level - 0.2)
    }
  case .ResetZoomClick:
    {
      game.zoom_level = 1
    }
  case .ExitClick:
    {
      game.mode = .MainMenu
    }
  case .GridClick:
    {
      data := action.data.(GridClickData)
      if game.is_looking {
        game.viewport_centre = data.pos
      } else {
        if data.tile_type == .Floor &&
           (abs(data.pos.x - game.player_pos.x) <= 1) &&
           (abs(data.pos.y - game.player_pos.y) <= 1) {
          game_player_move(game, data.pos)
        }
      }
    }
  case .PlayerClick:
    {
      game.viewport_centre = game.player_pos
      fmt.printfln("clicked player: %d %d", game.player_pos.x, game.player_pos.y)
    }
  }
}
