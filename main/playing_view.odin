package main

import "core:fmt"
import "core:math"

PlayingViewAction :: struct {
  type: PlayingViewActionType,
  data: PlayingViewActionData,
}

PlayingViewActionType :: enum {
  None,
  PlayerClick,
  EnemyClick,
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
}

PlayingViewActionData :: union {
  GridClickData,
  PlayerClickData,
  EnemyClickData,
}

GridClickData :: struct {
  pos:       GridPos,
  tile_type: GridTileType,
}

PlayerClickData :: struct {
  tile_type: GridTileType,
}

EnemyClickData :: struct {
  enemy_idx: GenerationalIndex,
}

playing_view :: proc(game: ^Game) {
  action: PlayingViewAction = {
    type = .None,
    data = {},
  }
  gap: f32 = 10

  minimap_pixel_scale: f32 = 5
  minimap_dim := Dim {
    w = GRID_WIDTH * minimap_pixel_scale,
    h = GRID_HEIGHT * minimap_pixel_scale,
  }
  minimap_pos := Pos {
    x = gc.screen_dim.w - minimap_dim.w - gap,
    y = gc.screen_dim.h - minimap_dim.h - gap,
  }
  minimap(
    game,
    Pos{x = minimap_pos.x - gap, y = minimap_pos.y - gap},
    Dim{w = minimap_dim.w + 2 * gap, h = minimap_dim.h + 2 * gap},
    minimap_pos,
    minimap_dim,
    minimap_pixel_scale,
  )

  button_dim := Dim {
    w = 300,
    h = 70,
  }
  buttons_column_pos_bot_left := Pos {
    x = gc.screen_dim.w - 2 * gap - button_dim.w,
    y = 0,
  }
  buttons_column_action := buttons_column(game, buttons_column_pos_bot_left, gap, button_dim)
  if buttons_column_action.type != .None {action = buttons_column_action}

  grid_ui_border: f32 = 30
  grid_ui_dim := Dim {
    w = gc.screen_dim.w - button_dim.w - 2 * gap - 2 * grid_ui_border,
    h = gc.screen_dim.h - 2 * grid_ui_border,
  }
  grid_ui_pos_bot_left := Pos {
    x = grid_ui_border,
    y = grid_ui_border,
  }
  grid_button_dim := Dim {
    w = FONT_MEDIUM * game.zoom_level,
    h = FONT_MEDIUM * game.zoom_level,
  }
  font_size := FONT_MEDIUM * game.zoom_level
  grid_action := grid(game, grid_ui_pos_bot_left, grid_ui_dim, grid_button_dim, font_size)
  if grid_action.type != .None {action = grid_action}

  handle_action(game, action)
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

buttons_column :: proc(game: ^Game, ui_pos_bot_left: Pos, gap: f32, button_dim: Dim) -> (action: PlayingViewAction) {
  ui_pos := Pos {
    x = ui_pos_bot_left.x + gap,
    y = ui_pos_bot_left.y + gap,
  }

  if text_button(get_uid(), ui_pos, button_dim, 0.1, "Exit", FONT_MEDIUM, .Ubuntu) {
    action = {
      type = .ExitClick,
    }
  }
  ui_pos.y += button_dim.h
  ui_pos.y += gap

  if text_button(get_uid(), ui_pos, button_dim, 0.1, "Reset Zoom", FONT_MEDIUM, .Ubuntu) {
    action = {
      type = .ResetZoomClick,
    }
  }
  ui_pos.y += button_dim.h
  ui_pos.y += gap

  {   // zoom button row
    button_count: f32 = 2
    zoom_button_dim := Dim {
      w = button_dim.w / button_count,
      h = button_dim.h,
    }
    zoom_button_pos := ui_pos
    if text_button(get_uid(), zoom_button_pos, zoom_button_dim, 0.1, "+", FONT_MEDIUM, .Ubuntu) {
      action = {
        type = .ZoomInClick,
      }
    }
    zoom_button_pos.x += zoom_button_dim.w
    if text_button(get_uid(), zoom_button_pos, zoom_button_dim, 0.1, "-", FONT_MEDIUM, .Ubuntu) {
      action = {
        type = .ZoomOutClick,
      }
    }
    zoom_button_pos.x += zoom_button_dim.w
  }
  ui_pos.y += button_dim.h
  ui_pos.y += gap

  if text_button(get_uid(), ui_pos, button_dim, 0.1, "Play", FONT_MEDIUM, .Ubuntu) {
    action = {
      type = .RecentreClick,
    }
  }
  ui_pos.y += button_dim.h
  ui_pos.y += gap

  if text_button(get_uid(), ui_pos, button_dim, 0.1, "Look", FONT_MEDIUM, .Ubuntu) {
    action = {
      type = .LookClick,
    }
  }
  ui_pos.y += button_dim.h
  ui_pos.y += gap

  if text_button(get_uid(), ui_pos, button_dim, 0.1, "See all", FONT_MEDIUM, .Ubuntu) {
    action = {
      type = .ShowAllClick,
    }
  }
  ui_pos.y += button_dim.h
  ui_pos.y += gap

  if text_button(get_uid(), ui_pos, button_dim, 0.1, "Hide all", FONT_MEDIUM, .Ubuntu) {
    action = {
      type = .HideAllClick,
    }
  }
  ui_pos.y += button_dim.h
  ui_pos.y += gap

  if text_button(get_uid(), ui_pos, button_dim, 0.1, "Spawn", FONT_MEDIUM, .Ubuntu) {
    action = {
      type = .SpawnMonsterClick,
    }
  }
  ui_pos.y += button_dim.h
  ui_pos.y += gap

  return action
}

// TODO - refactor out copy-pasted bits
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
      trim := Trim {
        left  = max(0, grid_ui_pos_bot_left.x - ui_pos.x),
        right = max(0, ui_pos.x + grid_button_dim.w - grid_ui_pos_bot_left.x - grid_ui_dim.w),
        top   = max(0, ui_pos.y + grid_button_dim.h - grid_ui_pos_bot_left.y - grid_ui_dim.h),
        bot   = max(0, grid_ui_pos_bot_left.y - ui_pos.y),
      }

      if !overlaps(ui_pos, grid_button_dim, grid_ui_pos_bot_left, grid_ui_dim) {
        continue
      }

      tile := grid_get(game.grid, grid_pos, game.player.floor)
      if tile.visibility != .Unknown {
        draw_info := grid_tile_draw_info[tile.type]
        if grid_button(
          get_uid(d),
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

  {   // draw player
    ui_pos := grid_tile_screen_pos(
      game.player.pos,
      game.viewport_centre,
      grid_ui_pos_bot_left,
      grid_ui_dim,
      grid_button_dim,
    )
    trim := Trim {
      left  = max(0, grid_ui_pos_bot_left.x - ui_pos.x),
      right = max(0, ui_pos.x + grid_button_dim.w - grid_ui_pos_bot_left.x - grid_ui_dim.w),
      top   = max(0, ui_pos.y + grid_button_dim.h - grid_ui_pos_bot_left.y - grid_ui_dim.h),
      bot   = max(0, grid_ui_pos_bot_left.y - ui_pos.y),
    }
    tile := grid_get(game.grid, game.player.pos, game.player.floor)
    draw_info := GridTileDrawInfo {
      char   = '@',
      colour = YELLOW,
    }
    if grid_button(
      get_uid(),
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
        type = .PlayerClick,
        data = PlayerClickData{tile_type = tile.type},
      }
    }
  }

  {   // draw enemies
    found, enemy_idx := enemy_manager_get_next(game.enemy_manager, 0)
    for found {
      enemy_ok, enemy := enemy_manager_get_enemy(&game.enemy_manager, enemy_idx)
      if !enemy_ok {panic("Unexpectedly missing enemy")}
      ui_pos := grid_tile_screen_pos(
        enemy.pos,
        game.viewport_centre,
        grid_ui_pos_bot_left,
        grid_ui_dim,
        grid_button_dim,
      )
      trim := Trim {
        left  = max(0, grid_ui_pos_bot_left.x - ui_pos.x),
        right = max(0, ui_pos.x + grid_button_dim.w - grid_ui_pos_bot_left.x - grid_ui_dim.w),
        top   = max(0, ui_pos.y + grid_button_dim.h - grid_ui_pos_bot_left.y - grid_ui_dim.h),
        bot   = max(0, grid_ui_pos_bot_left.y - ui_pos.y),
      }
      tile := grid_get(game.grid, enemy.pos, enemy.floor)
      draw_info := enemy_draw_info[enemy.type]
      if enemy.floor == game.player.floor &&
         tile.visibility == .Visible &&
         grid_button(
           get_uid(cast(u32)enemy_idx.idx),
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
          type = .EnemyClick,
	  data = EnemyClickData{enemy_idx = enemy_idx},
        }
      }
      found, enemy_idx = enemy_manager_get_next(game.enemy_manager, enemy_idx.idx + 1)
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

handle_action :: proc(game: ^Game, action: PlayingViewAction) {
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
          game_player_move(game, data.pos)
        }
      }
    }
  case .PlayerClick:
    {
      if game.is_looking {
        game.viewport_centre = game.player.pos
      } else {
        data := action.data.(PlayerClickData)
        if data.tile_type == .DownStair {
          clear_visibility(game.grid, game.player.pos, game.player.floor)
          game.player.floor += 1
          update_visibility(game.grid, game.player.pos, game.player.floor)
        } else if data.tile_type == .UpStair {
          clear_visibility(game.grid, game.player.pos, game.player.floor)
          game.player.floor -= 1
          update_visibility(game.grid, game.player.pos, game.player.floor)
        }
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
  case .EnemyClick:
    {
      data := action.data.(EnemyClickData)
      enemy_manager_delete_enemy(&game.enemy_manager, data.enemy_idx)
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
        got_enemy, enemy_idx := enemy_manager_get_next(game.enemy_manager, 0)
        for got_enemy {
          enemy_ok, enemy := enemy_manager_get_enemy(&game.enemy_manager, enemy_idx)
          if !enemy_ok {panic("Unexpectedly missing enemy")}
          if enemy.pos.x == game.player.pos.x + x &&
             enemy.pos.y == game.player.pos.y + y &&
             enemy.floor == game.player.floor {
            not_enemy = false
            break
          }
          got_enemy, enemy_idx = enemy_manager_get_next(game.enemy_manager, enemy_idx.idx + 1)
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

      enemy_manager_add_enemy(&game.enemy_manager, .Rat, enemy_pos, game.player.floor)
    }
  }
}
