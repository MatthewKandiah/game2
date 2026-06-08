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

// TODO - blocking LOS
// for now just say player can see all tiles up to a set distance
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

  // TODO - instead of checking if each tile is visible, walk a path from the centre to each square on the edge and mark any tile we can reach before hitting a wall as visible
  // scales linearly in PLAYER_VIEW_RADIUS instead of quadratically
  // we could add more logic to this (like is looking through diagonal crack going to look too weird, we could let you "peek" through it but not see as far as normal)
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

// TODO - this makes corners less visible than I'd like, we'll need to tweak. Just "does this line cross a wall" is too strict
is_visible :: proc(grid: []GridTile, check_pos, player_pos: GridPos) -> bool {
  if grid_distance(check_pos, player_pos) > PLAYER_VIEW_RADIUS {
    return false
  }

  path, path_count := supercover(GRID_WIDTH + GRID_HEIGHT, player_pos, check_pos)

  for path_pos in path[0:path_count - 1] {
    path_tile := grid_get(grid, path_pos)
    if path_tile.type == .Wall {
      return false
    }
  }

  return true
}
