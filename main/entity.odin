package main

import "core:fmt"
import "core:log"

PLAYER_ENTITY_ID :: EntityId {
  idx        = 0,
  generation = 0,
}

Entity :: struct {
  id:         EntityId,
  type:       EntityType,
  status:     EntityStatus,
  pos:        GridPos,
  floor:      i32,
  health:     i32,
  max_health: i32,
  move_time:  f32,
  asked_to_move: bool,
}

EntityId :: struct {
  idx:        i32,
  generation: i32,
}

EntityType :: enum {
  Player,
  Rat,
}

entity_draw_info := [EntityType]GridTileDrawInfo {
  .Player = GridTileDrawInfo{char = '@', colour = YELLOW},
  .Rat = GridTileDrawInfo{char = 'R', colour = BROWN},
}

EntityStatus :: enum {
  INACTIVE,
  ACTIVE,
}

ENTITY_BUFFER_SIZE :: 1000
EntityManager :: struct {
  buf:            [ENTITY_BUFFER_SIZE]Entity,
  idx_is_active:  [ENTITY_BUFFER_SIZE]bool,
  idx_generation: [ENTITY_BUFFER_SIZE]i32,
}

entity_manager_get_valid_insert_id :: proc(entity_manager: EntityManager) -> (ok: bool, entity_id: EntityId) {
  for is_active, idx in entity_manager.idx_is_active {
    if !is_active {
      generation := entity_manager.idx_generation[idx] + 1
      return true, EntityId{idx = cast(i32)idx, generation = generation}
    }
  }
  return false, {}
}

entity_move_time := [EntityType]f32 {
  .Player = 10,
  .Rat    = 25,
}

entity_max_health := [EntityType]i32 {
  .Player = 10,
  .Rat    = 3,
}

entity_manager_get_player :: proc(em: ^EntityManager) -> ^Entity {
  return &em.buf[PLAYER_ENTITY_ID.idx]
}

entity_manager_add_player :: proc(em: ^EntityManager, pos: GridPos, floor: i32) {
  em.buf[PLAYER_ENTITY_ID.idx] = Entity {
    id         = PLAYER_ENTITY_ID,
    type       = .Player,
    status     = .ACTIVE,
    pos        = pos,
    floor      = floor,
    health     = entity_max_health[.Player],
    max_health = entity_max_health[.Player],
    move_time  = entity_move_time[.Player],
  }
  em.idx_is_active[PLAYER_ENTITY_ID.idx] = true
  em.idx_generation[PLAYER_ENTITY_ID.idx] = PLAYER_ENTITY_ID.generation
}

entity_manager_add :: proc(
  em: ^EntityManager,
  type: EntityType,
  status: EntityStatus,
  pos: GridPos,
  floor: i32,
) -> (
  ok: bool,
  id: EntityId,
) {
  for is_active, idx in em.idx_is_active {
    if !is_active {
      generation := em.idx_generation[idx] + 1
      ok = true
      id = EntityId {
        idx        = cast(i32)idx,
        generation = generation,
      }
      break
    }
  }
  if !ok {return}

  em.buf[id.idx] = Entity {
    id         = id,
    type       = type,
    status     = status,
    pos        = pos,
    floor      = floor,
    health     = entity_max_health[type],
    max_health = entity_max_health[type],
    move_time  = entity_move_time[type],
  }
  em.idx_is_active[id.idx] = true
  em.idx_generation[id.idx] = id.generation

  log.info("entity_manager_add", id)
  return ok, id
}

entity_manager_id_valid :: proc(em: ^EntityManager, id: EntityId) -> bool {
  return em.idx_is_active[id.idx] && em.idx_generation[id.idx] == id.generation
}

entity_manager_get :: proc(em: ^EntityManager, id: EntityId) -> (ok: bool, entity: Entity) {
  if entity_manager_id_valid(em, id) {
    return true, em.buf[id.idx]
  } else {
    return false, {}
  }
}

entity_manager_set_pos :: proc(em: ^EntityManager, id: EntityId, pos: GridPos) -> (ok: bool) {
  if entity_manager_id_valid(em, id) {
    em.buf[id.idx].pos = pos
    return true
  } else {
    return false
  }
}

entity_manager_set_status :: proc(em: ^EntityManager, id: EntityId, status: EntityStatus) -> (ok: bool) {
  if entity_manager_id_valid(em, id) {
    em.buf[id.idx].status = status
    return true
  } else {
    return false
  }
}

entity_manager_set_health :: proc(em: ^EntityManager, id: EntityId, health: i32) -> (ok: bool) {
  if entity_manager_id_valid(em, id) {
    em.buf[id.idx].health = health
    return true
  } else {
    return false
  }
}

entity_manager_set_asked_to_move :: proc(em: ^EntityManager, id: EntityId, value: bool) -> (ok: bool) {
  if entity_manager_id_valid(em, id) {
    em.buf[id.idx].asked_to_move = value
    return true
  } else {
    return false
  }
}

entity_manager_delete :: proc(em: ^EntityManager, id: EntityId) -> (deleted: bool) {
  if entity_manager_id_valid(em, id) {
    em.idx_is_active[id.idx] = false
    deleted = true
  } else {
    deleted = false
  }
  log.info("entity_manager.delete", id)
  return
}

EntityIter :: struct {
  using em: ^EntityManager,
  idx:      i32,
}

entity_iter_init :: proc(em: ^EntityManager, includes_player: bool = true) -> (iter: EntityIter) {
  #assert(PLAYER_ENTITY_ID.idx == 0)
  return {em = em, idx = 0 if includes_player else 1}
}

entity_iter_next :: proc(iter: ^EntityIter) -> (entity: Entity, found: bool) {
  for iter.idx < ENTITY_BUFFER_SIZE {
    if iter.idx_is_active[iter.idx] {
      id := EntityId {
        idx        = iter.idx,
        generation = iter.idx_generation[iter.idx],
      }
      found = true
      entity = iter.buf[id.idx]
    }
    iter.idx += 1
    if found {return}
  }
  return {}, false
}
