package main

import "core:fmt"
import "core:log"
import "core:math/rand"

enemy_ai :: proc(game: ^Game, enemy: Entity) -> (action: Action) {
  can_see_player := enemy.floor == game.player.floor && is_visible(game.grid, game.player.pos, enemy.pos, enemy.floor)
  switch enemy.type {
  case .Player:
    {panic("Unreachable: enemy_ai should not be called with the player id")}
  case .Rat:
    {
      switch enemy.status {
      case .INACTIVE:
        {
          if can_see_player {
            fmt.println("Rat sees player", enemy.id)
            indicator := Indicator {
              sector      = .MID,
              colour      = PINK,
              timer_nanos = 1_000_000_000,
            }
            entity_manager_set_indicator(&game.entity_manager, enemy.id, indicator)
            return activate_action(enemy.id, entity_move_time[.Rat])
          }
        }
      case .ACTIVE:
        {
          if can_see_player {
            move_candidates_buf, move_candidates_count := dijkstra_map_move_toward_player_candidates(
              game.floor_dijkstra_map,
              enemy.pos,
              enemy.asked_to_move,
            )
            moved_successfully := false
            asked_to_move := enemy.asked_to_move
            entity_manager_set_asked_to_move(&game.entity_manager, enemy.id, false)
            obstacle_enemies := [8]Entity{}
            obstacle_enemy_count := 0
            for move_candidate in move_candidates_buf[0:move_candidates_count] {
              if move_candidate == game.player.pos {
                if asked_to_move {
                  fmt.println("Rat chooses not to bite the player", enemy.id)
                  continue
                } else {
		  return attack_action(enemy.id, PLAYER_ENTITY_ID, entity_move_time[.Rat])
                }
              }
              is_wall := grid_get(game.grid, move_candidate, enemy.floor).type == .Wall
              if is_wall {continue}
              is_enemy := false
              entity_iter := entity_iter_init(&game.entity_manager, false)
              for entity in entity_iter_next(&entity_iter) {
                if entity.pos == move_candidate {
                  is_enemy = true
                  obstacle_enemies[obstacle_enemy_count] = entity
                  obstacle_enemy_count += 1
                  break
                }
              }
              if is_enemy {continue}
              fmt.println("Rat steps towards player", enemy.id)
              indicator := Indicator {
                sector      = indicator_direction(enemy.pos, move_candidate),
                colour      = TEAL,
                timer_nanos = 1_000_000_000,
              }
              entity_manager_set_indicator(&game.entity_manager, enemy.id, indicator)
	      return move_action(enemy.id, move_candidate, entity_move_time[.Rat])
            }
            if !moved_successfully {
              if obstacle_enemy_count > 0 {
                // TODO - very naive idea, if can't move, nudge a random enemy to see if they can slide out of the way. I think we'll need to rework this logic significantly to make it really play well. Probably need to plan the design out a bit first.
                enemy_idx := rand.int32_range(0, cast(i32)obstacle_enemy_count)
                entity_manager_set_asked_to_move(&game.entity_manager, obstacle_enemies[enemy_idx].id, true)
              }
              fmt.println("Rat snarls angrily", enemy.id)
              indicator := Indicator {
                sector      = .MID,
                colour      = TEAL,
                timer_nanos = 1_000_000_000,
              }
              entity_manager_set_indicator(&game.entity_manager, enemy.id, indicator)
	      return wait_action(enemy.id, entity_move_time[.Rat])
            }
          } else {
            fmt.println("Rat forgets player", enemy.id)
            indicator := Indicator {
              sector      = .MID,
              colour      = YELLOW,
              timer_nanos = 1_000_000_000,
            }
            entity_manager_set_indicator(&game.entity_manager, enemy.id, indicator)
	    return deactivate_action(enemy.id, entity_move_time[.Rat])
          }
        }
      }
    }
  }
  panic("Unreachable")
}
