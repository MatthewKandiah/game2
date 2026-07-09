package main

import "core:fmt"
import "core:os"

menu_view :: proc(game: ^Game) {
  button_dim := Dim {
    w = 300,
    h = 100,
  }
  gap: f32 = 10
  button_count :: 2

  ui_pos_top_left := Pos {
    x = (gc.screen_dim.w - button_dim.w) / 2,
    y = (gc.screen_dim.h + button_count * button_dim.h + (button_count - 1) * gap) / 2,
  }
  ui_pos := Pos {
    x = ui_pos_top_left.x,
    y = ui_pos_top_left.y - button_dim.h,
  }

  if text_button(get_uid(), ui_pos, button_dim, 0.1, "START", FONT_LARGE, .Ubuntu) {
    game.mode = .Playing
  }
  ui_pos.x = ui_pos_top_left.x
  ui_pos.y -= gap
  ui_pos.y -= button_dim.h
  if text_button(get_uid(), ui_pos, button_dim, 0.2, "QUIT", FONT_LARGE, .Ubuntu) {
    os.exit(0)
  }
  ui_pos.y -= gap
  ui_pos.y -= button_dim.h

  draw_triangle(
    {x = ui_pos.x, y = ui_pos.y},
    {x = ui_pos.x + button_dim.w / 2, y = ui_pos.y + button_dim.h},
    {x = ui_pos.x + button_dim.w, y = ui_pos.y},
    0.3,
    PINK,
  )
  draw_triangle(
    {x = ui_pos.x, y = ui_pos.y},
    {x = ui_pos.x, y = ui_pos.y + button_dim.h},
    {x = ui_pos.x + button_dim.w, y = ui_pos.y + button_dim.h / 2},
    0.4,
    YELLOW,
  )
}
