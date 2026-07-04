package main

import "core:fmt"
import "core:log"

game_over_view :: proc(game: ^Game) {
  button_dim := Dim {
    w = 300,
    h = 100,
  }

  exit_button_pos := center_within_container(button_dim, Pos{x = 0, y = 0}, gc.screen_dim)
  if text_button(get_uid(), true, exit_button_pos, button_dim, 0.1, "EXIT", FONT_LARGE, .Ubuntu) {
    game.mode = .MainMenu
    game_reset(game)
  }

  text := "You died"
  text_dim := measure_text(text, .Ubuntu, FONT_LARGE)
  text_pos := center_within_container(text_dim, Pos{x = 0, y = 0}, gc.screen_dim)
  text_pos.y += button_dim.h
  draw_string(text, FONTS[.Ubuntu], text_pos, 0.1, FONT_LARGE, WHITE)
}
