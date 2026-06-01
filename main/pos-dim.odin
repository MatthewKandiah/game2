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
