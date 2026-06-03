package main

GRID_WIDTH :: 30
GRID_HEIGHT :: 30

Game :: struct {
  mode:       GameMode,
  grid:       [GRID_WIDTH * GRID_HEIGHT]GridTile,
  player_pos: GridPos,
}

GameMode :: enum {
  MainMenu,
  Playing,
}

GridTile :: enum {
  Wall,
  Floor,
}

GridTileDrawInfo :: struct {
  char:   rune,
  colour: Colour,
}

grid_tile_draw_info := [GridTile]GridTileDrawInfo {
  .Floor = GridTileDrawInfo{char = '.', colour = GREY},
  .Wall = GridTileDrawInfo{char = '#', colour = WHITE},
}

init_grid_tiles :: proc(tiles: []GridTile) {
  for &tile in tiles {
    tile = .Wall
  }

  // bottom row should be floor
  for i in 0..<GRID_WIDTH {
    grid_set(tiles, GridPos{x = cast(i32)i, y = 0}, .Floor)
  }

  // left column should be floor
  for i in 0..<GRID_HEIGHT {
    grid_set(tiles, GridPos{x = 0, y = cast(i32)i}, .Floor)
  }

  // 0-indexed (2, 3) should be floor i.e third column from the left, fourth row from the bottom
  grid_set(tiles, GridPos{x = 2, y = 3}, .Floor)
}

grid_pos_to_idx :: proc(pos: GridPos) -> i32 {
  return pos.x + (GRID_HEIGHT - 1 - pos.y) * GRID_WIDTH
}

grid_get :: proc(grid: []GridTile, pos: GridPos) -> GridTile {
  return grid[grid_pos_to_idx(pos)]
}

grid_set :: proc(grid: []GridTile, pos: GridPos, value: GridTile) {
  grid[grid_pos_to_idx(pos)] = value
}
