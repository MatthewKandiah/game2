package main

import "vendor:vulkan"

Vec2f :: distinct [2]f32
Vec2i :: distinct [2]i32

Rect :: struct {
  pos: Pos,
  dim: Dim,
}

GridRect :: struct {
  pos: GridPos,
  dim: GridDim,
}

Pos :: struct {
  x, y: f32,
}

Dim :: struct {
  w, h: f32,
}

GridPos :: struct {
  x, y: i32,
}

GridDim :: struct {
  w, h: i32,
}

dim_to_extent :: proc(dim: Dim) -> vulkan.Extent2D {
  return vulkan.Extent2D{width = cast(u32)dim.w, height = cast(u32)dim.h}
}

extent_to_dim :: proc(extent: vulkan.Extent2D) -> Dim {
  return Dim{w = cast(f32)extent.width, h = cast(f32)extent.height}
}

is_inside :: proc(pos: Pos, container_pos: Pos, container_dim: Dim) -> bool {
  return pos.x >= container_pos.x && pos.x <= container_pos.x + container_dim.w && pos.y >= container_pos.y && pos.y <= container_pos.y + container_dim.h
}

overlaps :: proc(pos1: Pos, dim1: Dim, pos2: Pos, dim2: Dim) -> bool {
  left1 := pos1.x
  right1 := pos1.x + dim1.w
  top1 := pos1.y
  bot1 := pos1.y + dim1.h
  left2 := pos2.x
  right2 := pos2.x + dim2.w
  top2 := pos2.y
  bot2 := pos2.y + dim2.h
  return !(left1 > right2 || right1 < left2 || bot1 < top2 || top1 > bot2)
}
