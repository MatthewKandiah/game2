package main

import "core:fmt"
import "core:log"
import "core:math"

PlayingViewAction :: struct {
  type: PlayingViewActionType,
  data: PlayingViewActionData,
}

PlayingViewActionType :: enum {
  None,
  EntityClick,
  GridClick,
  LookClick,
  RecentreClick,
  ExitClick,
  ZoomInClick,
  ZoomOutClick,
  ResetZoomClick,
  ShowAllClick,
  HideAllClick,
  SpawnMonsterClick,
  WaitClick,
}

PlayingViewActionData :: union {
  GridClickData,
  EntityClickData,
}

GridClickData :: struct {
  pos:       GridPos,
  tile_type: GridTileType,
}

EntityClickData :: struct {
  id:     EntityId,
  tile:   GridTile,
  to_pos: GridPos,
}

playing_view :: proc(game: ^Game) {
  action: PlayingViewAction = {
    type = .None,
    data = {},
  }

  minimap_pixel_scale: f32 = 5
  minimap_dim := Dim {
    w = GRID_WIDTH * minimap_pixel_scale,
    h = GRID_HEIGHT * minimap_pixel_scale,
  }
  minimap_pos := Pos {
    x = gc.screen_dim.w - minimap_dim.w,
    y = gc.screen_dim.h - minimap_dim.h,
  }
  minimap(
    game,
    Pos{x = minimap_pos.x, y = minimap_pos.y},
    Dim{w = minimap_dim.w, h = minimap_dim.h},
    minimap_pos,
    minimap_dim,
    minimap_pixel_scale,
  )

  button_dim := Dim {
    w = 300,
    h = 70,
  }
  buttons_column_pos_bot_left := Pos {
    x = gc.screen_dim.w - button_dim.w,
    y = 0,
  }
  buttons_column_action := buttons_column(game, buttons_column_pos_bot_left, button_dim)
  if buttons_column_action.type != .None {action = buttons_column_action}

  top_bar_height: f32 = 30
  bot_bar_height: f32 = 30
  grid_ui_dim := Dim {
    w = gc.screen_dim.w - button_dim.w,
    h = gc.screen_dim.h - bot_bar_height - top_bar_height,
  }
  grid_ui_pos_bot_left := Pos {
    x = 0,
    y = bot_bar_height,
  }
  grid_button_dim := Dim {
    w = FONT_MEDIUM * game.zoom_level,
    h = FONT_MEDIUM * game.zoom_level,
  }
  font_size := FONT_MEDIUM * game.zoom_level
  grid_action := grid(game, grid_ui_pos_bot_left, grid_ui_dim, grid_button_dim, font_size)
  if grid_action.type != .None {action = grid_action}
  {   // bottom bar
    ui_pos := Pos {
      x = 0,
      y = 0,
    }
    draw_rect(Pos{x = 0, y = 0}, 0.2, Dim{w = grid_ui_dim.w, h = bot_bar_height}, GREY)
    draw_fmt_string(
      "%d/%d",
      FONTS[.UbuntuMono],
      ui_pos,
      0.3,
      bot_bar_height,
      BLACK,
      game.player.health,
      game.player.max_health,
    )
  }

  {   // top bar
    ui_pos := Pos {
      x = 0,
      y = grid_ui_pos_bot_left.y + grid_ui_dim.h,
    }
    draw_rect(ui_pos, 0.2, Dim{w = grid_ui_dim.w, h = top_bar_height}, GREY)
    draw_fmt_string("%8.0f", FONTS[.UbuntuMono], ui_pos, 0.3, top_bar_height, BLACK, game.time)
  }

  handle_view_action(game, action)
}

grid_tile_screen_pos :: proc(
  tile_grid_pos: GridPos,
  centre_grid_pos: GridPos,
  grid_ui_pos: Pos,
  grid_ui_dim: Dim,
  tile_dim: Dim,
) -> Pos {
  grid_centre_ui_pos := Pos {
    x = grid_ui_pos.x + grid_ui_dim.w / 2,
    y = grid_ui_pos.y + grid_ui_dim.h / 2,
  }

  return Pos {
    x = grid_centre_ui_pos.x + (cast(f32)tile_grid_pos.x - cast(f32)centre_grid_pos.x - 0.5) * tile_dim.w,
    y = grid_centre_ui_pos.y + (cast(f32)tile_grid_pos.y - cast(f32)centre_grid_pos.y - 0.5) * tile_dim.h,
  }
}

grid_tile_trim :: proc(grid_ui_pos_bot_left: Pos, grid_ui_dim: Dim, ui_pos: Pos, grid_button_dim: Dim) -> Trim {
  return Trim {
    left = max(0, grid_ui_pos_bot_left.x - ui_pos.x),
    right = max(0, ui_pos.x + grid_button_dim.w - grid_ui_pos_bot_left.x - grid_ui_dim.w),
    top = max(0, ui_pos.y + grid_button_dim.h - grid_ui_pos_bot_left.y - grid_ui_dim.h),
    bot = max(0, grid_ui_pos_bot_left.y - ui_pos.y),
  }
}

buttons_column :: proc(game: ^Game, ui_pos_bot_left: Pos, button_dim: Dim) -> (action: PlayingViewAction) {
  ui_pos := Pos {
    x = ui_pos_bot_left.x,
    y = ui_pos_bot_left.y,
  }

  if text_button(get_uid(), true, ui_pos, button_dim, 0.1, "Exit", FONT_MEDIUM, .Ubuntu) {
    action = {
      type = .ExitClick,
    }
  }
  ui_pos.y += button_dim.h

  if text_button(get_uid(), true, ui_pos, button_dim, 0.1, "Reset Zoom", FONT_MEDIUM, .Ubuntu) {
    action = {
      type = .ResetZoomClick,
    }
  }
  ui_pos.y += button_dim.h

  {   // zoom button row
    button_count: f32 = 2
    zoom_button_dim := Dim {
      w = button_dim.w / button_count,
      h = button_dim.h,
    }
    zoom_button_pos := ui_pos
    if text_button(get_uid(), true, zoom_button_pos, zoom_button_dim, 0.1, "+", FONT_MEDIUM, .Ubuntu) {
      action = {
        type = .ZoomInClick,
      }
    }
    zoom_button_pos.x += zoom_button_dim.w
    if text_button(get_uid(), true, zoom_button_pos, zoom_button_dim, 0.1, "-", FONT_MEDIUM, .Ubuntu) {
      action = {
        type = .ZoomOutClick,
      }
    }
    zoom_button_pos.x += zoom_button_dim.w
  }
  ui_pos.y += button_dim.h

  if text_button(get_uid(), true, ui_pos, button_dim, 0.1, "Play", FONT_MEDIUM, .Ubuntu) {
    action = {
      type = .RecentreClick,
    }
  }
  ui_pos.y += button_dim.h

  if text_button(get_uid(), true, ui_pos, button_dim, 0.1, "Look", FONT_MEDIUM, .Ubuntu) {
    action = {
      type = .LookClick,
    }
  }
  ui_pos.y += button_dim.h

  if text_button(get_uid(), true, ui_pos, button_dim, 0.1, "See all", FONT_MEDIUM, .Ubuntu) {
    action = {
      type = .ShowAllClick,
    }
  }
  ui_pos.y += button_dim.h

  if text_button(get_uid(), true, ui_pos, button_dim, 0.1, "Hide all", FONT_MEDIUM, .Ubuntu) {
    action = {
      type = .HideAllClick,
    }
  }
  ui_pos.y += button_dim.h

  if text_button(
    get_uid(),
    game_player_active(game) && !game.animation_in_progress,
    ui_pos,
    button_dim,
    0.1,
    "Spawn",
    FONT_MEDIUM,
    .Ubuntu,
  ) {
    action = {
      type = .SpawnMonsterClick,
    }
  }
  ui_pos.y += button_dim.h

  if text_button(
    get_uid(),
    game_player_active(game) && !game.animation_in_progress,
    ui_pos,
    button_dim,
    0.1,
    "Wait",
    FONT_MEDIUM,
    .Ubuntu,
  ) {
    action = {
      type = .WaitClick,
    }
  }

  return action
}

grid :: proc(
  game: ^Game,
  grid_ui_pos_bot_left: Pos,
  grid_ui_dim: Dim,
  grid_button_dim: Dim,
  font_size: f32,
) -> (
  action: PlayingViewAction,
) {
  max_tiles_wide := cast(i32)math.ceil(grid_ui_dim.w / grid_button_dim.w) + 2
  max_tiles_high := cast(i32)math.ceil(grid_ui_dim.h / grid_button_dim.h) + 2
  row_idx_lower := max(0, game.viewport_centre.y - max_tiles_high / 2)
  row_idx_upper := min(GRID_HEIGHT, game.viewport_centre.y + max_tiles_high / 2)
  col_idx_lower := max(0, game.viewport_centre.x - max_tiles_wide / 2)
  col_idx_upper := min(GRID_WIDTH, game.viewport_centre.x + max_tiles_wide / 2)
  for row_idx in row_idx_lower ..< row_idx_upper {
    for col_idx in col_idx_lower ..< col_idx_upper {
      d := cast(u32)(row_idx * GRID_WIDTH + col_idx)
      grid_pos := GridPos {
        x = cast(i32)col_idx,
        y = cast(i32)row_idx,
      }
      ui_pos := grid_tile_screen_pos(
        grid_pos,
        game.viewport_centre,
        grid_ui_pos_bot_left,
        grid_ui_dim,
        grid_button_dim,
      )
      if !overlaps(ui_pos, grid_button_dim, grid_ui_pos_bot_left, grid_ui_dim) {
        continue
      }
      trim := grid_tile_trim(grid_ui_pos_bot_left, grid_ui_dim, ui_pos, grid_button_dim)
      tile := grid_get(game.grid, grid_pos, game.player.floor)
      if tile.visibility != .Unknown {
        draw_info := grid_tile_draw_info[tile.type]
        if grid_button(
          get_uid(d),
          game_player_active(game) && !game.animation_in_progress,
          ui_pos,
          grid_button_dim,
          0.05,
          draw_info.char,
          font_size,
          .UbuntuMono,
          draw_info.colour if tile.visibility == .Visible else DARK_GREY,
          trim,
        ) {
          action = {
            type = .GridClick,
            data = GridClickData{pos = grid_pos, tile_type = tile.type},
          }
        }
      }
    }
  }

  {   // draw entities
    iter := entity_iter_init(&game.entity_manager)
    for entity in entity_iter_next(&iter) {
      ui_pos := grid_tile_screen_pos(
        entity.pos,
        game.viewport_centre,
        grid_ui_pos_bot_left,
        grid_ui_dim,
        grid_button_dim,
      )
      if overlaps(ui_pos, grid_button_dim, grid_ui_pos_bot_left, grid_ui_dim) {
        trim := grid_tile_trim(grid_ui_pos_bot_left, grid_ui_dim, ui_pos, grid_button_dim)
        tile := grid_get(game.grid, entity.pos, entity.floor)
        draw_info := entity_draw_info[entity.type]
        show_indicator :=
          game.active_entity == entity.id && game.animation_in_progress && entity.floor == game.player.floor
        if show_indicator {
          indicator_colour := RED if game.current_action.type == .Attack else TEAL
          triangle_corners: [3]Pos
          third_width := grid_button_dim.w / 3
          third_height := grid_button_dim.h / 3
          half_width := grid_button_dim.w / 2
          half_height := grid_button_dim.h / 2
          switch game.current_action.indicator_position {
          case .MID:
            {
              triangle_corners[0] = Pos {
                x = ui_pos.x + third_width,
                y = ui_pos.y + 2 * third_height,
              }
              triangle_corners[1] = Pos {
                x = ui_pos.x + 2 * third_width,
                y = ui_pos.y + 2 * third_height,
              }
              triangle_corners[2] = Pos {
                x = ui_pos.x + half_width,
                y = ui_pos.y + third_height,
              }
            }
          case .N:
            {
              triangle_corners[0] = Pos {
                x = ui_pos.x + third_width,
                y = ui_pos.y + 2 * third_height,
              }
              triangle_corners[1] = Pos {
                x = ui_pos.x + half_width,
                y = ui_pos.y + grid_button_dim.h,
              }
              triangle_corners[2] = Pos {
                x = ui_pos.x + 2 * third_width,
                y = ui_pos.y + 2 * third_height,
              }
            }
          case .E:
            {
              triangle_corners[0] = Pos {
                x = ui_pos.x + 2 * third_width,
                y = ui_pos.y + 2 * third_height,
              }
              triangle_corners[1] = Pos {
                x = ui_pos.x + grid_button_dim.w,
                y = ui_pos.y + half_height,
              }
              triangle_corners[2] = Pos {
                x = ui_pos.x + 2 * third_width,
                y = ui_pos.y + third_height,
              }
            }
          case .S:
            {
              triangle_corners[0] = Pos {
                x = ui_pos.x + third_width,
                y = ui_pos.y + third_height,
              }
              triangle_corners[1] = Pos {
                x = ui_pos.x + 2 * third_width,
                y = ui_pos.y + third_height,
              }
              triangle_corners[2] = Pos {
                x = ui_pos.x + half_width,
                y = ui_pos.y,
              }
            }
          case .W:
            {
              triangle_corners[0] = Pos {
                x = ui_pos.x + third_width,
                y = ui_pos.y + third_height,
              }
              triangle_corners[1] = Pos {
                x = ui_pos.x,
                y = ui_pos.y + half_height,
              }
              triangle_corners[2] = Pos {
                x = ui_pos.x + third_width,
                y = ui_pos.y + 2 * third_height,
              }
            }
          case .NE:
            {
              triangle_corners[0] = Pos {
                x = ui_pos.x + 2 * third_width,
                y = ui_pos.y + grid_button_dim.h,
              }
              triangle_corners[1] = Pos {
                x = ui_pos.x + grid_button_dim.w,
                y = ui_pos.y + grid_button_dim.h,
              }
              triangle_corners[2] = Pos {
                x = ui_pos.x + grid_button_dim.w,
                y = ui_pos.y + 2 * third_height,
              }
            }
          case .SE:
            {
              triangle_corners[0] = Pos {
                x = ui_pos.x + grid_button_dim.w,
                y = ui_pos.y + third_height,
              }
              triangle_corners[1] = Pos {
                x = ui_pos.x + grid_button_dim.w,
                y = ui_pos.y,
              }
              triangle_corners[2] = Pos {
                x = ui_pos.x + 2 * third_width,
                y = ui_pos.y,
              }
            }
          case .SW:
            {
              triangle_corners[0] = Pos {
                x = ui_pos.x,
                y = ui_pos.y + third_height,
              }
              triangle_corners[1] = Pos {
                x = ui_pos.x + third_width,
                y = ui_pos.y,
              }
              triangle_corners[2] = Pos {
                x = ui_pos.x,
                y = ui_pos.y,
              }
	    }
          case .NW:
            {
              triangle_corners[0] = Pos {
                x = ui_pos.x,
                y = ui_pos.y + 2 * third_height,
              }
              triangle_corners[1] = Pos {
                x = ui_pos.x,
                y = ui_pos.y + grid_button_dim.h,
              }
              triangle_corners[2] = Pos {
                x = ui_pos.x + third_width,
                y = ui_pos.y + grid_button_dim.h,
              }
	    }
          }
          draw_triangle(triangle_corners[0], triangle_corners[1], triangle_corners[2], 0.07, indicator_colour)
        }
        if entity.floor == game.player.floor &&
           tile.visibility == .Visible &&
           grid_button(
             get_uid(cast(u32)entity.id.idx),
             game_player_active(game) && !game.animation_in_progress,
             ui_pos,
             grid_button_dim,
             0.06,
             draw_info.char,
             font_size,
             .UbuntuMono,
             draw_info.colour,
             trim,
           ) {
          action = {
            type = .EntityClick,
            data = EntityClickData{id = entity.id, tile = tile, to_pos = entity.pos},
          }
        }
      }
    }
  }
  return action
}

minimap :: proc(
  game: ^Game,
  background_pos: Pos,
  background_dim: Dim,
  minimap_pos: Pos,
  minimap_dim: Dim,
  pixel_scale: f32,
) {
  draw_rect(background_pos, 0.1, background_dim, DARK_GREY)
  ui_pos := Pos {
    x = minimap_pos.x,
    y = minimap_pos.y,
  }
  for row_idx in 0 ..< GRID_HEIGHT {
    ui_pos.x = minimap_pos.x
    for col_idx in 0 ..< GRID_WIDTH {
      grid_pos := GridPos {
        x = cast(i32)col_idx,
        y = cast(i32)row_idx,
      }
      tile := grid_get(game.grid, grid_pos, game.player.floor)
      if tile.visibility != .Unknown {
        colour: Colour
        if grid_pos == game.player.pos {
          colour = YELLOW
        } else {
          switch tile.type {
          case .Wall:
            colour = GREY
          case .Floor:
            colour = BLACK
          case .DownStair:
            colour = PINK
          case .UpStair:
            colour = TEAL
          }
        }
        draw_rect(ui_pos, 0.2, Dim{w = pixel_scale, h = pixel_scale}, colour)
      }
      ui_pos.x += pixel_scale
    }
    ui_pos.y += pixel_scale
  }
}

handle_view_action :: proc(game: ^Game, action: PlayingViewAction) {
  switch (action.type) {
  case .None:
    return
  case .LookClick:
    {
      game.is_looking = true
    }
  case .RecentreClick:
    {
      game.is_looking = false
      game.viewport_centre = game.player.pos
    }
  case .ZoomInClick:
    {
      game.zoom_level += 0.2
    }
  case .ZoomOutClick:
    {
      game.zoom_level = max(0.6, game.zoom_level - 0.2)
    }
  case .ResetZoomClick:
    {
      game.zoom_level = 1
    }
  case .ExitClick:
    {
      game.mode = .MainMenu
    }
  case .GridClick:
    {
      data := action.data.(GridClickData)
      if game.is_looking {
        game.viewport_centre = data.pos
      } else {
        if data.tile_type != .Wall &&
           (abs(data.pos.x - game.player.pos.x) <= 1) &&
           (abs(data.pos.y - game.player.pos.y) <= 1) {
          game.active_entity = PLAYER_ENTITY_ID
          game.current_action = move_action(game.player.pos, data.pos, entity_move_time[.Player])
          game.animation_timer_nanos = DEFAULT_ANIMATION_TIME_NANOS
          //game.animation_timer_nanos = 0
          game.animation_in_progress = true // player cross frame actions only resolve if an animation is in progress, an animation is just a cross frame action, all player actions are cross frame at the moment
        }
      }
    }
  case .EntityClick:
    {
      data := action.data.(EntityClickData)
      if data.id == PLAYER_ENTITY_ID {
        if game.is_looking {
          game.viewport_centre = game.player.pos
        } else {
          if data.tile.type == .DownStair {
            game.active_entity = PLAYER_ENTITY_ID
            game.current_action = move_down_stairs_action(entity_move_time[.Player])
            game.animation_timer_nanos = DEFAULT_ANIMATION_TIME_NANOS
            game.animation_in_progress = true
          } else if data.tile.type == .UpStair {
            game.active_entity = PLAYER_ENTITY_ID
            game.current_action = move_up_stairs_action(entity_move_time[.Player])
            game.animation_timer_nanos = DEFAULT_ANIMATION_TIME_NANOS
            game.animation_in_progress = true
          }
        }
      } else {
        game.active_entity = PLAYER_ENTITY_ID
        game.current_action = attack_action(game.player.pos, data.to_pos, data.id, entity_move_time[.Player])
        game.animation_timer_nanos = DEFAULT_ANIMATION_TIME_NANOS
        game.animation_in_progress = true
      }
    }
  case .HideAllClick:
    {
      for row_idx in 0 ..< GRID_HEIGHT {
        for col_idx in 0 ..< GRID_WIDTH {
          pos := GridPos {
            x = cast(i32)col_idx,
            y = cast(i32)row_idx,
          }
          grid_set_visibility(game.grid, pos, game.player.floor, .Unknown)
        }
      }
      update_visibility(game.grid, game.player.pos, game.player.floor)
    }
  case .ShowAllClick:
    {
      for row_idx in 0 ..< GRID_HEIGHT {
        for col_idx in 0 ..< GRID_WIDTH {
          pos := GridPos {
            x = cast(i32)col_idx,
            y = cast(i32)row_idx,
          }
          grid_set_visibility(game.grid, pos, game.player.floor, .Known)
        }
      }
      update_visibility(game.grid, game.player.pos, game.player.floor)
    }
  case .SpawnMonsterClick:
    {
      enemy_pos: GridPos
      left_valid := game.player.pos.x > 1
      right_valid := game.player.pos.x < GRID_WIDTH - 1
      bot_valid := game.player.pos.y > 1
      top_valid := game.player.pos.y < GRID_HEIGHT - 1

      check :: proc(game: ^Game, x, y: i32) -> bool {
        not_wall :=
          grid_get(game.grid, GridPos{x = game.player.pos.x + x, y = game.player.pos.y + y}, game.player.floor).type !=
          .Wall
        not_enemy := true
        iter := entity_iter_init(&game.entity_manager)
        for enemy in entity_iter_next(&iter) {
          if enemy.pos.x == game.player.pos.x + x &&
             enemy.pos.y == game.player.pos.y + y &&
             enemy.floor == game.player.floor {
            not_enemy = false
            break
          }
        }
        return not_wall && not_enemy
      }

      if left_valid && top_valid && check(game, -1, 1) {
        enemy_pos.x = game.player.pos.x - 1
        enemy_pos.y = game.player.pos.y + 1
      } else if left_valid && bot_valid && check(game, -1, -1) {
        enemy_pos.x = game.player.pos.x - 1
        enemy_pos.y = game.player.pos.y - 1
      } else if left_valid && check(game, -1, 0) {
        enemy_pos.x = game.player.pos.x - 1
        enemy_pos.y = game.player.pos.y
      } else if right_valid && top_valid && check(game, 1, 1) {
        enemy_pos.x = game.player.pos.x + 1
        enemy_pos.y = game.player.pos.y + 1
      } else if right_valid && bot_valid && check(game, 1, -1) {
        enemy_pos.x = game.player.pos.x + 1
        enemy_pos.y = game.player.pos.y - 1
      } else if right_valid && check(game, 1, 0) {
        enemy_pos.x = game.player.pos.x + 1
        enemy_pos.y = game.player.pos.y
      } else if top_valid && check(game, 0, 1) {
        enemy_pos.x = game.player.pos.x
        enemy_pos.y = game.player.pos.y + 1
      } else if bot_valid && check(game, 0, -1) {
        enemy_pos.x = game.player.pos.x
        enemy_pos.y = game.player.pos.y - 1
      } else {panic("Failed to place enemy")}

      ok, enemy_id := entity_manager_add(&game.entity_manager, .Rat, .INACTIVE, enemy_pos, game.player.floor)
      actor := Actor {
        id          = enemy_id,
        next_active = game.time + 25,
      }
      if !ok {unreachable()}
      actor_queue_insert(&game.actor_queue, actor)
    }
  case .WaitClick:
    {
      actor := Actor {
        id          = PLAYER_ENTITY_ID,
        next_active = game.time + game.player.move_time,
      }
      // TODO - make this a wait action too
      actor_queue_insert(&game.actor_queue, actor)
      game.active_entity = NONE_ENTITY_ID

    }
  }
}
