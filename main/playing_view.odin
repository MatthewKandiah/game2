package main

import "core:fmt"

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

  grid_ui_dim := Dim {
    w = gc.screen_dim.w - button_dim.w - 2 * gap,
    h = gc.screen_dim.h,
  }
  grid_ui_pos_bot_left := Pos {
    x = 0,
    y = 0,
  }
  grid_button_dim := Dim {
    w = FONT_MEDIUM,
    h = FONT_MEDIUM,
  }
  // layout debugging
  draw_rect(grid_ui_pos_bot_left, 0, grid_ui_dim, GREEN)
  // TODO - move this somewhere reasonable
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

  {   // draw grid
    for row_idx in 0 ..< GRID_HEIGHT {
      for col_idx in 0 ..< GRID_WIDTH {
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
	// TODO - nicer to have partially included buttons trim, instead of excluding them entirely
        if !contains(ui_pos, grid_button_dim, grid_ui_pos_bot_left, grid_ui_dim) {
          continue
        }
	left_trim := min(grid_ui_pos_bot_left.x - ui_pos.x, 0)
	right_trim := min(ui_pos.x + grid_button_dim.w - grid_ui_pos_bot_left.x - grid_ui_dim.w, 0)
	bot_trim := min(grid_ui_pos_bot_left.y - ui_pos.y, 0)
	top_trim := min(ui_pos.y + grid_button_dim.h - grid_ui_pos_bot_left.y - grid_ui_dim.h, 0)
        if grid_pos == game.player_pos {
          draw_info := grid_tile_draw_info[.Player]
          if grid_button(
            get_uid(#file, #line), // get an ID collision with floor tile 0 21
            ui_pos,
            grid_button_dim,
            0.06,
            draw_info.char,
            FONT_MEDIUM,
            .UbuntuMono,
            draw_info.colour,
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
        fmt.println("Move to", data.pos.x, data.pos.y)
      } else {
        fmt.println("Can't move to", data.tile, data.pos.x, data.pos.y)
      }

    }
  case .PlayerClick:
    {
      fmt.printfln("clicked player: %d %d", game.player_pos.x, game.player_pos.y)
    }
  }
}
