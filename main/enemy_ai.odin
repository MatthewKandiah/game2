package main

import "core:fmt"
import "core:log"

enemy_ai :: proc(game: ^Game, id: EntityId) -> (acts_again: bool, next_action_time: f32) {
  entity_ok, enemy := entity_manager_get(&game.entity_manager, id)
  if !entity_ok {
    log.info("enemy_ai - entity not found", id)
    return
  }
  if enemy.type == .Player {
    log.error("enemy_ai - expected enemy, got player", id)
    panic("Unreachable")
  }

  can_see_player := enemy.floor == game.player.floor && is_visible(game.grid, game.player.pos, enemy.pos, enemy.floor)
  switch enemy.type {
  case .Player:
    {unreachable()}
  case .Rat:
    {
      switch enemy.status {
      case .INACTIVE:
        {
          if can_see_player {
            fmt.println("Rat sees player", id)
            entity_manager_set_status(&game.entity_manager, id, .ACTIVE)
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
                fmt.println("Rat bites player", id)
                moved_successfully = true
                break
              }
              is_wall := grid_get(game.grid, move_candidate, enemy.floor).type == .Wall
              if is_wall {continue}
              is_enemy := false
              entity_iter := entity_iter_init(&game.entity_manager, false)
              for entity in entity_iter_next(&entity_iter) {
                if entity.type == .Player {
                  panic("Should have been handled separately and early returnd earlier")
                }
                if entity.pos == move_candidate {
                  is_enemy = true
                  break
                }
              }
              if is_enemy {continue}
              fmt.println("Rat steps towards player", id)
              entity_manager_set_pos(&game.entity_manager, id, move_candidate)
              moved_successfully = true
              break
            }
            if !moved_successfully {
              fmt.println("Rat snarls angrily", id)
            }
          } else {
            fmt.println("Rat forgets player", id)
            entity_manager_set_status(&game.entity_manager, id, .INACTIVE)
          }
        }
      }
      return true, game.time + enemy.move_time
    }
  }
  panic("Unreachable")
}
