package main

import "core:fmt"
import "core:log"

enemy_ai :: proc(game: ^Game, enemy_gen_idx: GenerationalIndex) -> (acts_again: bool, next_action_time: f32) {
  enemy_ok, enemy := enemy_manager_get_enemy(&game.enemy_manager, enemy_gen_idx)
  if !enemy_ok {
    log.info("enemy_ai - enemy not found", enemy_gen_idx)
    return
  }

  switch enemy.type {
  case .Rat:
    {
      switch enemy.status {
      case .INACTIVE:
        {
          if enemy.floor == game.player.floor && is_visible(game.grid, game.player.pos, enemy.pos, enemy.floor) {
            fmt.println("Rat sees player", enemy_gen_idx)
	    enemy_manager_set_enemy_status(&game.enemy_manager, enemy_gen_idx, .ACTIVE)
          }
	  return true, game.time + enemy.move_time
        }
      case .ACTIVE:
        {
          if enemy_manager_delete_enemy(&game.enemy_manager, enemy_gen_idx) {
            fmt.println("Rat dies", enemy_gen_idx)
	  }
	  return false, {}
        }
      }
    }
  }
  panic("Unreachable")
}
