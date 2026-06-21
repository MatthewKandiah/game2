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
            move_candidates_buf, move_candidates_count := dijkstra_map_move_toward_player_candidates(
              game.floor_dijkstra_map,
              enemy.pos,
            )
            moved_successfully := false
            for move_candidate in move_candidates_buf[0:move_candidates_count] {
              if move_candidate == game.player.pos {
                fmt.println("Rat bites player", enemy_gen_idx)
                return
              }
              is_wall := grid_get(game.grid, move_candidate, enemy.floor).type == .Wall
              if is_wall {continue}
              is_enemy := false
              got_enemy, enemy_iter_idx, enemy := enemy_manager_get_next(game.enemy_manager, 0)
              for got_enemy {
                if enemy.pos == move_candidate {
                  is_enemy = true
                  break
                }
                got_enemy, enemy_iter_idx, enemy = enemy_manager_get_next(game.enemy_manager, enemy_iter_idx.idx + 1)
              }
              if is_enemy {continue}
              fmt.println("Rat steps towards player", enemy_gen_idx)
              enemy_manager_set_enemy_pos(&game.enemy_manager, enemy_gen_idx, move_candidate)
              moved_successfully = true
              break
            }
            if !moved_successfully {
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
