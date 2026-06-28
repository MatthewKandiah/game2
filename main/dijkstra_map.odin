package main

import "core:fmt"
import "core:log"

// leave space for arithmetic without overflowing
DIJKSTRA_MAP_SENTINEL :: cast(i32)max(i16)

dijkstra_map_move_toward_player_candidates :: proc(
  dijk: []i32,
  pos: GridPos,
  include_non_approach_moves: bool,
) -> (
  candidate_buf: [8]GridPos,
  candidate_count: i32,
) {
  candidate_value_buf := [2]i32{}
  candidate_value_buf[0] = dijkstra_map_get(dijk, pos) - 1
  candidate_value_buf[1] = candidate_value_buf[0] + 1
  candidate_values := candidate_value_buf[0:2] if include_non_approach_moves else candidate_value_buf[0:1]

  is_valid_candidate_pos :: proc(dijk: []i32, pos: GridPos, candidate_values: []i32) -> bool {
    value := dijkstra_map_get(dijk, pos)
    for candidate_value in candidate_values {
      if value == candidate_value {
        return true
      }
    }
    return false
  }

  up_pos := GridPos {
    x = pos.x,
    y = pos.y + 1,
  }
  if is_valid_candidate_pos(dijk, up_pos, candidate_values) {
    candidate_buf[candidate_count] = up_pos
    candidate_count += 1
  }

  left_pos := GridPos {
    x = pos.x - 1,
    y = pos.y,
  }
  if is_valid_candidate_pos(dijk, left_pos, candidate_values) {
    candidate_buf[candidate_count] = left_pos
    candidate_count += 1
  }

  right_pos := GridPos {
    x = pos.x + 1,
    y = pos.y,
  }
  if is_valid_candidate_pos(dijk, right_pos, candidate_values) {
    candidate_buf[candidate_count] = right_pos
    candidate_count += 1
  }

  down_pos := GridPos {
    x = pos.x,
    y = pos.y - 1,
  }
  if is_valid_candidate_pos(dijk, down_pos, candidate_values) {
    candidate_buf[candidate_count] = down_pos
    candidate_count += 1
  }

  up_left_pos := GridPos {
    x = pos.x - 1,
    y = pos.y + 1,
  }
  if is_valid_candidate_pos(dijk, up_left_pos, candidate_values) {
    candidate_buf[candidate_count] = up_left_pos
    candidate_count += 1
  }

  up_right_pos := GridPos {
    x = pos.x + 1,
    y = pos.y + 1,
  }
  if is_valid_candidate_pos(dijk, up_right_pos, candidate_values) {
    candidate_buf[candidate_count] = up_right_pos
    candidate_count += 1
  }

  down_left_pos := GridPos {
    x = pos.x - 1,
    y = pos.y - 1,
  }
  if is_valid_candidate_pos(dijk, down_left_pos, candidate_values) {
    candidate_buf[candidate_count] = down_left_pos
    candidate_count += 1
  }

  down_right_pos := GridPos {
    x = pos.x + 1,
    y = pos.y - 1,
  }
  if is_valid_candidate_pos(dijk, down_right_pos, candidate_values) {
    candidate_buf[candidate_count] = down_right_pos
    candidate_count += 1
  }

  return
}

// TODO - can this be done more sensibly? Maybe breadth-first search, starting at the player?
update_floor_dijkstra_map :: proc(game: Game) {
  for &v in game.floor_dijkstra_map {
    v = DIJKSTRA_MAP_SENTINEL
  }
  dijkstra_map_set(game.floor_dijkstra_map, game.player.pos, 0)

  count := 0
  for {
    no_changes := true
    for row_idx in 0 ..< GRID_HEIGHT {
      for col_idx in 0 ..< GRID_WIDTH {
        row_idx := cast(i32)row_idx
        col_idx := cast(i32)col_idx
        current_pos := GridPos {
          x = col_idx,
          y = row_idx,
        }
        current_tile := grid_get(game.grid, current_pos, game.player.floor)
        if current_tile.type == .Wall {
          continue
        }

        up_left := dijkstra_map_get(game.floor_dijkstra_map, GridPos{x = col_idx - 1, y = row_idx + 1})
        up := dijkstra_map_get(game.floor_dijkstra_map, GridPos{x = col_idx, y = row_idx + 1})
        up_right := dijkstra_map_get(game.floor_dijkstra_map, GridPos{x = col_idx + 1, y = row_idx + 1})
        left := dijkstra_map_get(game.floor_dijkstra_map, GridPos{x = col_idx - 1, y = row_idx})
        right := dijkstra_map_get(game.floor_dijkstra_map, GridPos{x = col_idx + 1, y = row_idx})
        down_left := dijkstra_map_get(game.floor_dijkstra_map, GridPos{x = col_idx - 1, y = row_idx - 1})
        down := dijkstra_map_get(game.floor_dijkstra_map, GridPos{x = col_idx, y = row_idx - 1})
        down_right := dijkstra_map_get(game.floor_dijkstra_map, GridPos{x = col_idx + 1, y = row_idx - 1})

        min_neighbour := min(up_left, up, up_right, left, right, down_left, down, down_right)
        current_value := dijkstra_map_get(game.floor_dijkstra_map, GridPos{x = col_idx, y = row_idx})
        if min_neighbour + 1 < current_value {
          new_value := min_neighbour + 1
          dijkstra_map_set(game.floor_dijkstra_map, GridPos{x = col_idx, y = row_idx}, new_value)
          no_changes = false
        }
      }
    }

    if no_changes {
      log.info("update_floor_dijkstra_map iteration count:", count)
      break
    }
    count += 1
  }
}

dijkstra_map_get :: proc(dijk: []i32, pos: GridPos) -> i32 {
  if pos.x < 0 || pos.x >= GRID_WIDTH {return DIJKSTRA_MAP_SENTINEL}
  if pos.y < 0 || pos.y >= GRID_HEIGHT {return DIJKSTRA_MAP_SENTINEL}
  return dijk[dijkstra_map_idx(pos)]
}

dijkstra_map_set :: proc(dijk: []i32, pos: GridPos, val: i32) {
  dijk[dijkstra_map_idx(pos)] = val
}

dijkstra_map_idx :: proc(pos: GridPos) -> i32 {
  return grid_pos_to_idx(pos, 0)
}
