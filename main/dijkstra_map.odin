package main

import "core:fmt"

// leave space for arithmetic without overflowing
DIJKSTRA_MAP_SENTINEL :: cast(i32)max(i16)

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
      fmt.println(count)
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
