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

init_grid_tiles :: proc(tiles: []GridTile) -> (valid_player_pos: GridPos) {
  // Assumed grid is zero initialised to all wall

  unset_down_stair_pos_sentinel := GridPos {
    x = -1,
    y = -1,
  }
  prev_floor_down_stair_pos_list: [DOWN_STAIRS_PER_FLOOR]GridPos = unset_down_stair_pos_sentinel
  // Place a bunch of random connected rooms
  for floor in 0 ..< GRID_DEPTH {
    floor := cast(i32)floor
    rooms := [ROOM_COUNT]GridRect{}
    for &room, room_idx in rooms {
      room_dim := GridDim {
        w = rand.int32_range(ROOM_MIN_DIM, ROOM_MAX_DIM + 1),
        h = rand.int32_range(ROOM_MIN_DIM, ROOM_MAX_DIM + 1),
      }
      room_pos: GridPos
      if room_idx < DOWN_STAIRS_PER_FLOOR &&
         prev_floor_down_stair_pos_list[room_idx] != unset_down_stair_pos_sentinel {
        prev_floor_down_stair_pos := prev_floor_down_stair_pos_list[room_idx]
        room_pos = GridPos {
          x = clamp(prev_floor_down_stair_pos.x - rand.int32_range(0, room_dim.w), 1, GRID_WIDTH - room_dim.w - 1),
          y = clamp(prev_floor_down_stair_pos.y - rand.int32_range(0, room_dim.h), 1, GRID_HEIGHT - room_dim.h - 1),
        }
      } else {
        room_pos = GridPos {
          x = clamp(rand.int32_range(1, GRID_WIDTH - room_dim.w), 1, GRID_WIDTH - room_dim.w - 1),
          y = clamp(rand.int32_range(1, GRID_HEIGHT - room_dim.h), 1, GRID_HEIGHT - room_dim.h - 1),
        }
      }

      room = GridRect {
        pos = room_pos,
        dim = room_dim,
      }

      for room_x in 0 ..< room.dim.w {
        for room_y in 0 ..< room.dim.h {
          pos := GridPos {
            x = room.pos.x + room_x,
            y = room.pos.y + room_y,
          }
          grid_set(tiles, pos, floor, {type = .Floor, visibility = .Unknown})
        }
      }
      if floor == START_FLOOR {valid_player_pos = rooms[0].pos}
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

    for stair_pos in prev_floor_down_stair_pos_list {
      if stair_pos != unset_down_stair_pos_sentinel {
        grid_set_type(tiles, stair_pos, floor, .UpStair)
      }
    }

    // Place downstairs
    if floor < GRID_DEPTH - 1 {
      placed_down_stair_count := 0
      for placed_down_stair_count < DOWN_STAIRS_PER_FLOOR {
        room := rooms[rand.int32_range(0, len(rooms))]
        pos := GridPos {
          x = rand.int32_range(room.pos.x, room.pos.x + room.dim.w),
          y = rand.int32_range(room.pos.y, room.pos.y + room.dim.h),
        }
        if grid_get(tiles, pos, floor).type != .Floor {
          continue
        }

        prev_floor_down_stair_pos_list[placed_down_stair_count] = pos
        grid_set_type(tiles, pos, floor, .DownStair)
        placed_down_stair_count += 1
      }
    }
  }

  {   // check expected properties
    for floor_with_down_stairs in 0 ..< GRID_DEPTH - 1 {
      down_stairs_count := 0
      for tile in grid_floor_slice(tiles, cast(i32)floor_with_down_stairs) {
        if tile.type == .DownStair {down_stairs_count += 1}
      }
      assert(down_stairs_count == DOWN_STAIRS_PER_FLOOR)
    }

    for floor_with_up_stairs in 1 ..< GRID_DEPTH {
      up_stairs_count := 0
      for tile in grid_floor_slice(tiles, cast(i32)floor_with_up_stairs) {
        if tile.type == .UpStair {up_stairs_count += 1}
      }
      assert(up_stairs_count == DOWN_STAIRS_PER_FLOOR)
    }
  }

  return valid_player_pos
}

grid_pos_to_idx :: proc(pos: GridPos, floor: i32) -> i32 {
  return pos.x + (GRID_HEIGHT - 1 - pos.y) * GRID_WIDTH + (GRID_HEIGHT * GRID_WIDTH) * floor
}

grid_floor_slice :: proc(grid: []GridTile, floor: i32) -> []GridTile {
  floor_stride: i32 = GRID_WIDTH * GRID_HEIGHT
  return grid[floor * floor_stride:(floor + 1) * floor_stride]
}

grid_get :: proc(grid: []GridTile, pos: GridPos, floor: i32) -> GridTile {
  return grid[grid_pos_to_idx(pos, floor)]
}

grid_set :: proc(grid: []GridTile, pos: GridPos, floor: i32, value: GridTile) {
  grid[grid_pos_to_idx(pos, floor)] = value
}

grid_set_type :: proc(grid: []GridTile, pos: GridPos, floor: i32, value: GridTileType) {
  grid[grid_pos_to_idx(pos, floor)].type = value
}

grid_set_visibility :: proc(grid: []GridTile, pos: GridPos, floor: i32, value: GridVisibility) {
  grid[grid_pos_to_idx(pos, floor)].visibility = value
}

grid_distance :: proc(pos1, pos2: GridPos) -> i32 {
  return max(abs(pos1.x - pos2.x), abs(pos1.y - pos2.y))
}
