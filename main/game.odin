package main

import "core:fmt"
import "core:log"
import "core:math/rand"

GRID_WIDTH :: 50
GRID_HEIGHT :: 50
GRID_DEPTH :: 10
ROOM_COUNT :: 4
ROOM_MAX_DIM :: 7
ROOM_MIN_DIM :: 3
START_FLOOR :: 4
DOWN_STAIRS_PER_FLOOR :: 3

Game :: struct {
  mode:               GameMode,
  grid:               []GridTile,
  floor_dijkstra_map: []i32,
  entity_manager:     EntityManager,
  actor_queue:        ActorQueue,
  viewport_centre:    GridPos,
  is_looking:         bool,
  zoom_level:         f32,
  time:               f32,
  process_actors:     bool,
  player:             ^Entity,
}

GameMode :: enum {
  MainMenu,
  Playing,
  GameOver,
}

PLAYER_VIEW_RADIUS :: 7

game_player_move :: proc(game: ^Game, to: GridPos) {
  from := game.player.pos
  log.info("game_player_move", from, "to", to)
  game.player.pos = to
  game.viewport_centre = to

  indicator := Indicator {
    colour = TEAL,
    sector = indicator_direction(from, to),
    timer_nanos = 1_000_000_000,
  }
  entity_manager_set_indicator(&game.entity_manager, PLAYER_ENTITY_ID, indicator)

  clear_visibility(game.grid, from, game.player.floor)
  update_visibility(game.grid, to, game.player.floor)
  update_floor_dijkstra_map(game)

  actor := Actor {
    id          = PLAYER_ENTITY_ID,
    next_active = game.time + game.player.move_time,
  }
  actor_queue_insert(&game.actor_queue, actor)
  game.process_actors = true
}

clear_visibility :: proc(grid: []GridTile, player_pos: GridPos, floor: i32) {
  for row_idx in -PLAYER_VIEW_RADIUS ..= PLAYER_VIEW_RADIUS {
    for col_idx in -PLAYER_VIEW_RADIUS ..= PLAYER_VIEW_RADIUS {
      check_pos := GridPos {
        x = player_pos.x + cast(i32)col_idx,
        y = player_pos.y + cast(i32)row_idx,
      }
      if check_pos.x < 0 || check_pos.x >= GRID_WIDTH || check_pos.y < 0 || check_pos.y >= GRID_HEIGHT {continue}
      current := grid_get(grid, check_pos, floor)
      switch current.visibility {
      case .Known:
      case .Visible:
        grid_set_visibility(grid, check_pos, floor, .Known)
      case .Unknown:
      // NOOP
      }
    }
  }
}

update_visibility :: proc(grid: []GridTile, player_pos: GridPos, floor: i32) {
  for row_idx in -PLAYER_VIEW_RADIUS ..= PLAYER_VIEW_RADIUS {
    for col_idx in -PLAYER_VIEW_RADIUS ..= PLAYER_VIEW_RADIUS {
      check_pos := GridPos {
        x = player_pos.x + cast(i32)col_idx,
        y = player_pos.y + cast(i32)row_idx,
      }
      if check_pos.x < 0 || check_pos.x >= GRID_WIDTH || check_pos.y < 0 || check_pos.y >= GRID_HEIGHT {continue}
      if is_visible(grid, check_pos, player_pos, floor) {
        grid_set_visibility(grid, check_pos, floor, .Visible)
      }
    }
  }
}

is_visible :: proc(grid: []GridTile, check_pos, player_pos: GridPos, floor: i32) -> bool {
  switch grid_distance(check_pos, player_pos) {
  case 0:
    return true
  case PLAYER_VIEW_RADIUS ..< max(i32):
    return false
  }

  path, entries, path_count := supercover(GRID_WIDTH + GRID_HEIGHT, player_pos, check_pos)

  for idx in 1 ..< path_count - 1 {
    path_pos := path[idx]
    entry_pos := entries[idx]
    exit_pos := entries[idx + 1]
    path_tile := grid_get(grid, path_pos, floor)
    if path_tile.type == .Wall {
      vert1, vert2, hor1, hor2 := wall_check_lines(grid, path_pos, floor)
      vision_line := Line {
        p1 = entry_pos,
        p2 = exit_pos,
      }
      if lines_intersect(vision_line, vert1) ||
         lines_intersect(vision_line, vert2) ||
         lines_intersect(vision_line, hor1) ||
         lines_intersect(vision_line, hor2) {
        return false
      }
    }
  }
  return true
}

Line :: struct {
  p1, p2: Pos,
}
wall_check_lines :: proc(grid: []GridTile, grid_pos: GridPos, floor: i32) -> (vert1, vert2, hor1, hor2: Line) {
  top_tile: GridTileType =
    .Wall if grid_pos.y + 1 > GRID_HEIGHT - 1 else grid_get(grid, GridPos{x = grid_pos.x, y = grid_pos.y + 1}, floor).type
  bot_tile: GridTileType =
    .Wall if grid_pos.y - 1 < 0 else grid_get(grid, GridPos{x = grid_pos.x, y = grid_pos.y - 1}, floor).type
  left_tile: GridTileType =
    .Wall if grid_pos.x - 1 < 0 else grid_get(grid, GridPos{x = grid_pos.x - 1, y = grid_pos.y}, floor).type
  right_tile: GridTileType =
    .Wall if grid_pos.x + 1 > GRID_WIDTH - 1 else grid_get(grid, GridPos{x = grid_pos.x + 1, y = grid_pos.y}, floor).type

  pos := Pos {
    x = cast(f32)grid_pos.x + 0.5,
    y = cast(f32)grid_pos.y + 0.5,
  }

  disp: f32 = 0.05
  disconnected_size: f32 = 0.05
  connected_size: f32 = 0.5

  vert1 = {
    p1 = Pos{x = pos.x + disp, y = pos.y - connected_size} if bot_tile == .Wall else Pos{x = pos.x + disp, y = pos.y - disconnected_size},
    p2 = Pos{x = pos.x + disp, y = pos.y + connected_size} if top_tile == .Wall else Pos{x = pos.x + disp, y = pos.y + disconnected_size},
  }
  vert2 = {
    p1 = Pos{x = pos.x - disp, y = pos.y - connected_size} if bot_tile == .Wall else Pos{x = pos.x - disp, y = pos.y - disconnected_size},
    p2 = Pos{x = pos.x - disp, y = pos.y + connected_size} if top_tile == .Wall else Pos{x = pos.x - disp, y = pos.y + disconnected_size},
  }
  hor1 = {
    p1 = Pos{x = pos.x - connected_size, y = pos.y + disp} if left_tile == .Wall else Pos{x = pos.x - disconnected_size, y = pos.y + disp},
    p2 = Pos{x = pos.x + connected_size, y = pos.y + disp} if right_tile == .Wall else Pos{x = pos.x + disconnected_size, y = pos.y + disp},
  }
  hor2 = {
    p1 = Pos{x = pos.x - connected_size, y = pos.y - disp} if left_tile == .Wall else Pos{x = pos.x - disconnected_size, y = pos.y - disp},
    p2 = Pos{x = pos.x + connected_size, y = pos.y - disp} if right_tile == .Wall else Pos{x = pos.x + disconnected_size, y = pos.y - disp},
  }
  return
}

lines_intersect :: proc(l1, l2: Line) -> bool {
  // https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection
  // => lines intersect if an intersection point exists within both line segments
  // => sufficient to check if the denominators in final expressions for t and u are non-zero, and values of t and u are between 0 and 1
  x1 := l1.p1.x
  x2 := l1.p2.x
  x3 := l2.p1.x
  x4 := l2.p2.x
  y1 := l1.p1.y
  y2 := l1.p2.y
  y3 := l2.p1.y
  y4 := l2.p2.y

  denom := (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
  if denom == 0 {
    // lines are parallel
    // lines may be coincident, for our collision detection I think it's fine to treat this case as a non-collision, I don't think it will make a difference to us
    return false
  }

  t_num := (x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)
  u_num := (y1 - y2) * (x1 - x3) - (x1 - x2) * (y1 - y3)
  t := t_num / denom
  u := u_num / denom
  return (t >= 0 && t <= 1) && (u >= 0 && u <= 1)
}

game_reset :: proc(game: ^Game) {
  game.actor_queue.heap_count = 0
  valid_player_pos := init_grid_tiles(game.grid)
  game.mode = .MainMenu
  game.entity_manager = EntityManager{}
  entity_manager_add_player(&game.entity_manager, valid_player_pos, 4)
  actor_queue_insert(&game.actor_queue, {id = PLAYER_ENTITY_ID, next_active = 0})
  game.player = entity_manager_get_player(&game.entity_manager)
  game.viewport_centre = valid_player_pos
  game.is_looking = false
  game.zoom_level = 1
  game.process_actors = true

  update_visibility(game.grid, valid_player_pos, game.player.floor)
  update_floor_dijkstra_map(game)
}
