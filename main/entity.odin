package main

ENTITIES_SIZE :: 10_000
ENTITIES_COUNT := 0
ENTITIES := [ENTITIES_SIZE]Entity{}

push_entity :: proc(e: Entity) {
  ENTITIES[ENTITIES_COUNT] = e
  ENTITIES_COUNT += 1
}

/*
 * Thinking anything that exists on the screen (visible and/or interactive) gets an Entity
 * We'll have a separate "game state" for information about the game that does not need to know about the screen space and interactions
 */
Entity :: struct {
  id:   u64,
  type: EntityType,
  data: EntityData,
  pos:  Pos,
  z:    f32,
  dim:  Dim,
}

EntityType :: enum {}

EntityData :: union {}
