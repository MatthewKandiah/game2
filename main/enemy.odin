package main

GenerationalIndex :: struct {
  idx: i32,
  generation: i32,
}

Enemy :: struct {
  type:  EnemyType,
  pos:   GridPos,
  floor: i32,
  health: i32,
  max_health: i32,
}

EnemyType :: enum {
  Rat,
}

enemy_draw_info := [EnemyType]GridTileDrawInfo {
  .Rat = GridTileDrawInfo{char = 'R', colour = BROWN},
}

ENEMIES_BUFFER_SIZE :: 1_000
EnemyManager :: struct {
  buffer:              [ENEMIES_BUFFER_SIZE]Enemy,
  active_indices:      [ENEMIES_BUFFER_SIZE]bool,
  current_generations: [ENEMIES_BUFFER_SIZE]i32,
  insert_index:        GenerationalIndex,
}

enemy_manager_set_valid_insert_index :: proc(enemy_manager: ^EnemyManager) -> (ok: bool) {
  searching := true
  start_idx := enemy_manager.insert_index.idx
  for searching {
    if enemy_manager.active_indices[enemy_manager.insert_index.idx] {
      enemy_manager.insert_index.idx += 1
      if enemy_manager.insert_index.idx == ENEMIES_BUFFER_SIZE {
        enemy_manager.insert_index.idx = 0
        enemy_manager.insert_index.generation += 1
      } else if enemy_manager.insert_index.idx > ENEMIES_BUFFER_SIZE {
        panic("Expect to step by 1 and then loop round, this should be unreachable")
      }
      if enemy_manager.insert_index.idx == start_idx {
        // we've looped back to start, couldn't insert anywhere
        return false
      }
    } else {
      searching = false
    }
  }
  return true
}

enemy_manager_add_enemy :: proc(
  enemy_manager: ^EnemyManager,
  type: EnemyType,
  pos: GridPos,
  floor: i32,
) -> GenerationalIndex {
  if !enemy_manager_set_valid_insert_index(enemy_manager) {
    // probably indicates buggy tidy-up logic or runaway logic spawning endlessly
    panic("Couldn't insert enemy")
  }
  idx := enemy_manager.insert_index.idx
  generation := enemy_manager.insert_index.generation
  enemy_manager.buffer[idx] = Enemy {
    type  = type,
    pos   = pos,
    floor = floor,
    health = 10,
    max_health = 10,
  }
  enemy_manager.active_indices[idx] = true
  enemy_manager.current_generations[idx] = generation

  return {idx = idx, generation = generation}
}

enemy_manager_get_enemy :: proc(enemy_manager: ^EnemyManager, index: GenerationalIndex) -> (ok: bool, enemy: Enemy) {
  if enemy_manager.active_indices[index.idx] && enemy_manager.current_generations[index.idx] == index.generation {
    return true, enemy_manager.buffer[index.idx]
  } else {
    return false, {}
  }
}

enemy_manager_delete_enemy :: proc(enemy_manager: ^EnemyManager, index: GenerationalIndex) -> (ok: bool) {
  if enemy_manager.active_indices[index.idx] && enemy_manager.current_generations[index.idx] == index.generation {
    enemy_manager.active_indices[index.idx] = false
  }
  return false
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
      return true, GenerationalIndex{idx = idx, generation = enemy_manager.current_generations[idx]}, enemy_manager.buffer[idx]
    } else {
      idx += 1
      if idx >= ENEMIES_BUFFER_SIZE {
        searching = false
      }
    }
  }
  return false, {}, {}
}
