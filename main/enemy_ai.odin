package main

import "core:fmt"
import "core:log"

enemy_ai :: proc(game: ^Game, enemy_gen_idx: GenerationalIndex) -> (acts_again: bool, next_action_time: f32) {
  enemy_ok, enemy := enemy_manager_get_enemy(&game.enemy_manager, enemy_gen_idx)
  if !enemy_ok {
    log.info("enemy_ai - enemy not found", enemy_gen_idx)
    return
  }

  can_see_player := enemy.floor == game.player.floor && is_visible(game.grid, game.player.pos, enemy.pos, enemy.floor)
  switch enemy.type {
  case .Rat:
    {
      switch enemy.status {
      case .INACTIVE:
        {
          if can_see_player {
            fmt.println("Rat sees player", enemy_gen_idx)
            enemy_manager_set_enemy_status(&game.enemy_manager, enemy_gen_idx, .ACTIVE)
          }
        }
      case .ACTIVE:
        {
          if can_see_player {
            // TODO - more sensible pathfinding using game.floor_dijkstra_map
            path_size :: 2 * PLAYER_VIEW_RADIUS
            path_buf, _, path_count := supercover(path_size, enemy.pos, game.player.pos)
            target_pos := path_buf[1]
            is_wall := grid_get(game.grid, target_pos, enemy.floor).type == .Wall
            is_enemy := false
            got_enemy, enemy_iter_idx, enemy := enemy_manager_get_next(game.enemy_manager, 0)
            for got_enemy {
              if enemy.pos == target_pos {
                is_enemy = true
                break
              }
              got_enemy, enemy_iter_idx, enemy = enemy_manager_get_next(game.enemy_manager, enemy_iter_idx.idx + 1)
            }
            if target_pos == game.player.pos {
              fmt.println("Rat bites player", enemy_gen_idx)
            } else if !is_wall && !is_enemy {
              fmt.println("Rat steps towards player", enemy_gen_idx)
              enemy_manager_set_enemy_pos(&game.enemy_manager, enemy_gen_idx, target_pos)
            } else {
              fmt.println("Rat snarls angrily", enemy_gen_idx)
            }
          } else {
            fmt.println("Rat forgets player", enemy_gen_idx)
            enemy_manager_set_enemy_status(&game.enemy_manager, enemy_gen_idx, .INACTIVE)
          }
        }
      }
      return true, game.time + enemy.move_time
    }
  }
  panic("Unreachable")
}
