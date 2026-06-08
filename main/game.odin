package main

import "core:fmt"
import "core:math/rand"

GRID_WIDTH :: 50
GRID_HEIGHT :: 50
ROOM_COUNT :: 20
ROOM_MAX_DIM :: 7
ROOM_MIN_DIM :: 3

Game :: struct {
  mode:            GameMode,
  grid:            []GridTile,
  player_pos:      GridPos,
  viewport_centre: GridPos,
  is_looking:      bool,
  zoom_level:      f32,
}

GameMode :: enum {
  MainMenu,
  Playing,
}

PLAYER_VIEW_RADIUS :: 7

game_player_move :: proc(game: ^Game, to: GridPos) {
  from := game.player_pos
  game.player_pos = to
  game.viewport_centre = to

  {   // clear visibility on tiles for player's previous position
    for row_idx in -PLAYER_VIEW_RADIUS ..= PLAYER_VIEW_RADIUS {
      for col_idx in -PLAYER_VIEW_RADIUS ..= PLAYER_VIEW_RADIUS {
        check_pos := GridPos {
          x = from.x + cast(i32)col_idx,
          y = from.y + cast(i32)row_idx,
        }
        if check_pos.x < 0 || check_pos.x >= GRID_WIDTH || check_pos.y < 0 || check_pos.y >= GRID_HEIGHT {continue}
        grid_set_visible(game.grid, check_pos, false)
      }
    }
  }

  {   // check for tiles that are now visible and/or known
    for row_idx in -PLAYER_VIEW_RADIUS ..= PLAYER_VIEW_RADIUS {
      for col_idx in -PLAYER_VIEW_RADIUS ..= PLAYER_VIEW_RADIUS {
        check_pos := GridPos {
          x = to.x + cast(i32)col_idx,
          y = from.y + cast(i32)row_idx,
        }
        if check_pos.x < 0 || check_pos.x >= GRID_WIDTH || check_pos.y < 0 || check_pos.y >= GRID_HEIGHT {continue}
        if is_visible(game.grid, check_pos, to) {
          grid_set_visible(game.grid, check_pos, true)
          grid_set_known(game.grid, check_pos, true)
        }
      }
    }
  }
}

is_visible :: proc(grid: []GridTile, check_pos, player_pos: GridPos) -> bool {
  switch grid_distance(check_pos, player_pos) {
  case 0:
    return true
  case PLAYER_VIEW_RADIUS ..< max(i32):
    return false
  }

  path, entries, path_count := supercover(GRID_WIDTH + GRID_HEIGHT, player_pos, check_pos)

  idx := 1
  previous_wall_seen := false
  for path_pos in path[1:path_count - 1] {
    path_tile := grid_get(grid, path_pos)
    if path_tile.type == .Wall {
      entry_point := entries[idx]
      entry_quadrant := get_quadrant(entry_point, path_pos)
      exit_point := entries[idx + 1]
      exit_quadrant := get_quadrant(exit_point, path_pos)

      is_left_neighbour_wall := grid_get(grid, GridPos{x = path_pos.x - 1, y = path_pos.y}).type == .Wall
      is_right_neighbour_wall := grid_get(grid, GridPos{x = path_pos.x + 1, y = path_pos.y}).type == .Wall
      is_top_neighbour_wall := grid_get(grid, GridPos{x = path_pos.x, y = path_pos.y + 1}).type == .Wall
      is_bot_neighbour_wall := grid_get(grid, GridPos{x = path_pos.x, y = path_pos.y - 1}).type == .Wall
      next_tile_on_path_is_wall := grid_get(grid, path[idx + 1]).type == .Wall

      if next_tile_on_path_is_wall {
        if previous_wall_seen {return false}
        previous_wall_seen = true
        switch entry_quadrant {
        case .BottomLeft:
          if exit_quadrant == .TopRight {return false}
        case .BottomRight:
          if exit_quadrant == .TopLeft {return false}
        case .TopLeft:
          if exit_quadrant == .BottomRight {return false}
        case .TopRight:
          if exit_quadrant == .BottomLeft {return false}
        }
      } else {
        if entry_quadrant != exit_quadrant {return false}
        switch entry_quadrant {
        case .BottomLeft:
          if (is_left_neighbour_wall || is_bot_neighbour_wall) {return false}
        case .BottomRight:
          if (is_right_neighbour_wall || is_bot_neighbour_wall) {return false}
        case .TopLeft:
          if (is_left_neighbour_wall || is_top_neighbour_wall) {return false}
        case .TopRight:
          if (is_right_neighbour_wall || is_top_neighbour_wall) {return false}
        }
      }
    }
    idx += 1
  }

  return true
}

Quadrant :: enum {
  BottomLeft,
  BottomRight,
  TopLeft,
  TopRight,
}

get_quadrant :: proc(point: Pos, tile_grid_pos: GridPos) -> Quadrant {
  dx := cast(f32)tile_grid_pos.x + 0.5 - point.x
  dy := cast(f32)tile_grid_pos.y + 0.5 - point.y
  if dx <= 0 && dy <= 0 {
    return .BottomLeft
  } else if dx <= 0 && dy > 0 {
    return .TopLeft
  } else if dx > 0 && dy <= 0 {
    return .BottomRight
  } else if dx > 0 && dy > 0 {
    return .TopRight
  } else {
    panic("Unreachable")
  }
}
