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
}

PlayingViewActionData :: union {
  PlayerClickData,
  GridClickData,
}

PlayerClickData :: struct {}

GridClickData :: struct {
  pos:  GridPos,
  tile: GridTile,
}

playing_view :: proc(game: ^Game) {
  action: PlayingViewAction = {
    type = .None,
  }

  button_dim := Dim {
    w = 300,
    h = 100,
  }
  gap: f32 = 10

  {   // draw button column
    ui_pos_top_left := Pos {
      x = gc.screen_dim.w - 2 * gap - button_dim.w,
      y = gc.screen_dim.h,
    }
    ui_pos := Pos {
      x = ui_pos_top_left.x + gap,
      y = ui_pos_top_left.y - gap - button_dim.h,
    }
    if text_button(get_uid(#file, #line), ui_pos, button_dim, 0.1, "fun", FONT_SMALL, .UbuntuMono) {
      fmt.println("Having fun?")
    }
    ui_pos.y -= button_dim.h
    ui_pos.y -= gap
    if text_button(get_uid(#file, #line), ui_pos, button_dim, 0.1, "exit", FONT_SMALL, .UbuntuMono) {
      game.mode = .MainMenu
    }
  }

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
    w = FONT_MEDIUM,
    h = FONT_MEDIUM,
  }

  {   // draw grid
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
            get_uid(#file, #line),
            ui_pos,
            grid_button_dim,
            0.06,
            draw_info.char,
            FONT_MEDIUM,
            .UbuntuMono,
            draw_info.colour,
            trim,
          ) {
            action = {
              type = .PlayerClick,
            }
          }
        } else {
          tile := grid_get(game.grid[:], grid_pos)
          draw_info := grid_tile_draw_info[tile]
          if grid_button(
            get_uid(#file, #line, d),
            ui_pos,
            grid_button_dim,
            0.05,
            draw_info.char,
            FONT_MEDIUM,
            .UbuntuMono,
            draw_info.colour,
            trim,
          ) {
            action = {
              type = .GridClick,
              data = GridClickData{pos = grid_pos, tile = tile},
            }
          }
        }
      }
    }
  }

  handle_action(game, action)
}

handle_action :: proc(game: ^Game, action: PlayingViewAction) {
  switch (action.type) {
  case .None:
    return
  case .GridClick:
    {
      data := action.data.(GridClickData)
      if data.tile == .Floor &&
         (abs(data.pos.x - game.player_pos.x) <= 1) &&
         (abs(data.pos.y - game.player_pos.y) <= 1) {
        game.player_pos = {
          x = data.pos.x,
          y = data.pos.y,
        }
        game.viewport_centre = game.player_pos
        //fmt.println("Move to", data.pos.x, data.pos.y)
      } else {
        //fmt.println("Can't move to", data.tile, data.pos.x, data.pos.y)
      }

    }
  case .PlayerClick:
    {
      //fmt.printfln("clicked player: %d %d", game.player_pos.x, game.player_pos.y)
    }
  }
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
