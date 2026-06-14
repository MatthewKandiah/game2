package main

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
