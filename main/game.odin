package main

Game :: struct {
  mode:       GameMode,
  game_grid:  [100]u8, // 10 x 10 grid of letters
  player_pos: GridPos,
}

GameMode :: enum {
  MainMenu,
  Playing,
}
