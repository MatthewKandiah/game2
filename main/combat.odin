package main

import "core:fmt"
import "core:log"

attack :: proc(game: ^Game, attacker_id, defender_id: EntityId) {
  attacker_ok, attacker := entity_manager_get(&game.entity_manager, attacker_id)
  defender_ok, defender := entity_manager_get(&game.entity_manager, defender_id)
  assert(attacker_ok, "Should never have a non-existent attacker attacking")
  assert(defender_ok, "Should never be attacking a non-existent defender")
  fmt.println(attacker_id, "attacks", defender_id)

  updated_health := defender.health - 1
  indicator := Indicator {
    sector      = indicator_direction(attacker.pos, defender.pos),
    colour      = RED,
    timer_nanos = 1_000_000_000,
  }
  entity_manager_set_indicator(&game.entity_manager, attacker.id, indicator)
  if updated_health <= 0 {
    if defender.id == PLAYER_ENTITY_ID {
      fmt.println("you die, game over")
      game.mode = .GameOver
    } else {
      fmt.println("enemy dies", defender_id)
      entity_manager_delete(&game.entity_manager, defender.id)
    }
  } else {
    entity_manager_set_health(&game.entity_manager, defender.id, updated_health)
  }
}
