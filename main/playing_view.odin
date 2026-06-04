package main

import "core:fmt"

playing_view :: proc(game: ^Game) {
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

        grid_dim := Dim {
          w = gc.screen_dim.w - 2 * gap - button_dim.w - 2 * gap,
          h = gc.screen_dim.h - 2 * gap,
        }
        grid_ui_pos_bot_left := Pos {
          x = 0,
          y = 0,
        }
        grid_button_dim := Dim {
          w = grid_dim.w / GRID_WIDTH,
          h = grid_dim.h / GRID_HEIGHT,
        }
        {   // draw grid
          for row_idx in 0 ..< GRID_HEIGHT {
            for col_idx in 0 ..< GRID_WIDTH {
              d: u64 = cast(u64)row_idx << 8 | cast(u64)col_idx
              ui_pos := Pos {
                x = grid_ui_pos_bot_left.x + gap + cast(f32)col_idx * grid_button_dim.w,
                y = grid_ui_pos_bot_left.y + gap + cast(f32)row_idx * grid_button_dim.h,
              }
              grid_pos := GridPos {
                x = cast(i32)col_idx,
                y = cast(i32)row_idx,
              }
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
                if tile == .Floor &&
                   (abs(grid_pos.x - game.player_pos.x) <= 1) &&
                  (abs(grid_pos.y - game.player_pos.y) <= 1) {
		    // TODO - need to think about order of events here, is it safe and sane to update game state in the middle of drawing it? Won't we end up with a mix of old and new values?
		    // maybe better to set an enum value saying what action happened, and have a handler run after all the UI drawing has run?
                  game.player_pos = {
                    x = grid_pos.x,
                    y = grid_pos.y,
                  }
                  fmt.println("Move to", grid_pos.x, grid_pos.y)
                } else {
                  fmt.println("Can't move to", tile, row_idx, col_idx)
                }
              }
            }
          }
        }

        {   // draw player
          ui_pos := Pos {
            x = grid_ui_pos_bot_left.x + gap + cast(f32)game.player_pos.x * grid_button_dim.w,
            y = grid_ui_pos_bot_left.y + gap + cast(f32)game.player_pos.y * grid_button_dim.h,
          }
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
            fmt.printfln("clicked player: %d %d", game.player_pos.x, game.player_pos.y)
          }
        }
      }
