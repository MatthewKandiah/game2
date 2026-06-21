package main

import "core:fmt"
import "core:log"

GenerationalIndex :: struct {
  idx:        i32,
  generation: i32,
}

Enemy :: struct {
  type:       EnemyType,
  status:     EnemyStatus,
  pos:        GridPos,
  floor:      i32,
  health:     i32,
  max_health: i32,
  move_time:  f32,
}

EnemyType :: enum {
  Rat,
}

EnemyStatus :: enum {
  INACTIVE,
  ACTIVE,
}

enemy_draw_info := [EnemyType]GridTileDrawInfo {
  .Rat = GridTileDrawInfo{char = 'R', colour = BROWN},
}

ENEMIES_BUFFER_SIZE :: 1_000
EnemyManager :: struct {
  buffer:              [ENEMIES_BUFFER_SIZE]Enemy,
  active_indices:      [ENEMIES_BUFFER_SIZE]bool,
  current_generations: [ENEMIES_BUFFER_SIZE]i32,
}

enemy_manager_get_valid_insert_index :: proc(enemy_manager: EnemyManager) -> (ok: bool, idx: GenerationalIndex) {
  for is_active, idx in enemy_manager.active_indices {
    if !is_active {
      generation := enemy_manager.current_generations[idx] + 1
      return true, GenerationalIndex{idx = cast(i32)idx, generation = generation}
    }
  }
  return false, {}
}

enemy_manager_add_enemy :: proc(
  enemy_manager: ^EnemyManager,
  type: EnemyType,
  status: EnemyStatus,
  pos: GridPos,
  floor: i32,
) -> GenerationalIndex {
  insert_ok, gen_idx := enemy_manager_get_valid_insert_index(enemy_manager^)
  if !insert_ok {
    // probably indicates buggy tidy-up logic or runaway logic spawning endlessly
    panic("Couldn't insert enemy")
  }
  enemy_manager.buffer[gen_idx.idx] = Enemy {
    type       = type,
    status     = status,
    pos        = pos,
    floor      = floor,
    health     = 10,
    max_health = 10,
    move_time  = 25,
  }
  enemy_manager.active_indices[gen_idx.idx] = true
  enemy_manager.current_generations[gen_idx.idx] = gen_idx.generation

  log.info("enemy_manager_add_enemy", gen_idx)
  return gen_idx
}

enemy_manager_get_enemy :: proc(enemy_manager: ^EnemyManager, index: GenerationalIndex) -> (ok: bool, enemy: Enemy) {
  if enemy_manager.active_indices[index.idx] && enemy_manager.current_generations[index.idx] == index.generation {
    return true, enemy_manager.buffer[index.idx]
  } else {
    return false, {}
  }
}

enemy_manager_set_enemy_pos :: proc(enemy_manager: ^EnemyManager, index: GenerationalIndex, pos: GridPos) {
  if enemy_manager.active_indices[index.idx] && enemy_manager.current_generations[index.idx] == index.generation {
    enemy_manager.buffer[index.idx].pos = pos
  }
}

enemy_manager_set_enemy_status :: proc(enemy_manager: ^EnemyManager, index: GenerationalIndex, status: EnemyStatus) {
  if enemy_manager.active_indices[index.idx] && enemy_manager.current_generations[index.idx] == index.generation {
    enemy_manager.buffer[index.idx].status = status
  }
}

enemy_manager_delete_enemy :: proc(enemy_manager: ^EnemyManager, index: GenerationalIndex) -> (deleted: bool) {
  if enemy_manager.active_indices[index.idx] && enemy_manager.current_generations[index.idx] == index.generation {
    enemy_manager.active_indices[index.idx] = false
    deleted = true
  } else {
    deleted = false
  }
  log.info("enemy_manager_delete_enemy", index, deleted)
  return deleted
}

enemy_manager_get_next :: proc(
  enemy_manager: EnemyManager,
  first_index: i32,
) -> (
  found: bool,
  enemy_index: GenerationalIndex,
  enemy: Enemy,
) {
  if first_index >= ENEMIES_BUFFER_SIZE {
    return false, {}, {}
  }
  idx := first_index
  searching := true
  for searching {
    if enemy_manager.active_indices[idx] {
      return true,
        GenerationalIndex{idx = idx, generation = enemy_manager.current_generations[idx]},
        enemy_manager.buffer[idx]
    } else {
      idx += 1
      if idx >= ENEMIES_BUFFER_SIZE {
        searching = false
      }
    }
  }
  return false, {}, {}
}
