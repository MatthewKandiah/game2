package main

GenerationalIndex :: struct {
  idx: i32,
  generation: i32,
}

Enemy :: struct {
  type:  EnemyType,
  pos:   GridPos,
  floor: i32,
}

EnemyType :: enum {
  Rat,
}

enemy_draw_info := [EnemyType]GridTileDrawInfo {
  .Rat = GridTileDrawInfo{char = 'R', colour = BROWN},
}
