package main

import "core:fmt"
import "core:math/rand"

GridTileType :: enum {
  Wall,
  Floor,
  DownStair,
  UpStair,
}

GridVisibility :: enum {
  Unknown,
  Known,
  Visible,
}

GridTile :: struct {
  type:       GridTileType,
  visibility: GridVisibility,
}

GridTileDrawInfo :: struct {
  char:   rune,
  colour: Colour,
}

grid_tile_draw_info := [GridTileType]GridTileDrawInfo {
  .Floor = GridTileDrawInfo{char = '.', colour = WHITE},
  .Wall = GridTileDrawInfo{char = '#', colour = WHITE},
  .DownStair = GridTileDrawInfo{char = '>', colour = WHITE},
  .UpStair = GridTileDrawInfo{char = '<', colour = WHITE},
}

init_grid_tiles :: proc(tiles: [][]GridTile) -> (valid_player_pos: GridPos) {
  // TODO - generate all levels with stairs connecting them
  floor :: 4
  for &tile in tiles[floor] {
    tile.type = .Wall
  }

  // Place a bunch of random connected rooms
  rooms := [ROOM_COUNT]GridRect{}
  for &room in rooms {
    room = GridRect {
      pos = GridPos {
        x = rand.int32_range(1, GRID_WIDTH - ROOM_MAX_DIM - 1),
        y = rand.int32_range(1, GRID_HEIGHT - ROOM_MAX_DIM - 1),
      },
      dim = GridDim {
        w = rand.int32_range(ROOM_MIN_DIM, ROOM_MAX_DIM + 1),
        h = rand.int32_range(ROOM_MIN_DIM, ROOM_MAX_DIM + 1),
      },
    }

    for room_x in 0 ..< room.dim.w {
      for room_y in 0 ..< room.dim.h {
        grid_set(
          tiles,
          GridPos{x = room.pos.x + room_x, y = room.pos.y + room_y},
          floor,
          {type = .Floor, visibility = .Unknown},
        )
      }
    }
  }

  // Connect rooms with corridors
  prev_room := rooms[len(rooms) - 1] // first connect to last, make a ring
  for room in rooms {
    prev_room_pos := GridPos {
      x = prev_room.pos.x + rand.int32_range(0, prev_room.dim.w),
      y = prev_room.pos.y + rand.int32_range(0, prev_room.dim.h),
    }
    room_pos := GridPos {
      x = room.pos.x + rand.int32_range(0, room.dim.w),
      y = room.pos.y + rand.int32_range(0, room.dim.h),
    }
    x_len := abs(room_pos.x - prev_room_pos.x)
    y_len := abs(room_pos.y - prev_room_pos.y)
    x_min := min(room_pos.x, prev_room_pos.x)
    y_min := min(room_pos.y, prev_room_pos.y)

    if rand.float32() < 0.5 {
      // across then up
      for x in x_min ..= x_min + x_len {
        grid_set(tiles, GridPos{x = x, y = prev_room_pos.y}, floor, {type = .Floor, visibility = .Unknown})
      }
      for y in y_min ..= y_min + y_len {
        grid_set(tiles, GridPos{x = room_pos.x, y = y}, floor, {type = .Floor, visibility = .Unknown})
      }
    } else {
      // up then across
      for y in y_min ..= y_min + y_len {
        grid_set(tiles, GridPos{x = prev_room_pos.x, y = y}, floor, {type = .Floor, visibility = .Unknown})
      }
      for x in x_min ..= x_min + x_len {
        grid_set(tiles, GridPos{x = x, y = room_pos.y}, floor, {type = .Floor, visibility = .Unknown})
      }
    }

    prev_room = room
  }

  return rooms[0].pos
}

grid_pos_to_idx :: proc(pos: GridPos) -> i32 {
  return pos.x + (GRID_HEIGHT - 1 - pos.y) * GRID_WIDTH
}

grid_get :: proc(grid: [][]GridTile, pos: GridPos, floor: i32) -> GridTile {
  return grid[floor][grid_pos_to_idx(pos)]
}

grid_set :: proc(grid: [][]GridTile, pos: GridPos, floor: i32, value: GridTile) {
  grid[floor][grid_pos_to_idx(pos)] = value
}

grid_set_type :: proc(grid: [][]GridTile, pos: GridPos, floor: i32, value: GridTileType) {
  grid[floor][grid_pos_to_idx(pos)].type = value
}

grid_set_visibility :: proc(grid: [][]GridTile, pos: GridPos, floor: i32, value: GridVisibility) {
  grid[floor][grid_pos_to_idx(pos)].visibility = value
}

grid_distance :: proc(pos1, pos2: GridPos) -> i32 {
  return max(abs(pos1.x - pos2.x), abs(pos1.y - pos2.y))
}
