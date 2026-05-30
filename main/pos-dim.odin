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

XY :: struct {x, y: f32}
Pos :: struct #raw_union {
  v:       Vec2f `fmt:"[2]f32"`, 
  using xy : XY,
}

add_pos :: proc(l, r: Pos) -> Pos {
    return Pos{v = l.v + r.v}
}
sub_pos :: proc(l, r: Pos) -> Pos {
    return Pos{v = l.v - r.v}
}
mul_pos :: proc(s: f32, vec: Pos) -> Pos {
    return Pos{v = vec.v * s}
}
div_pos :: proc(s: f32, vec: Pos) -> Pos {
    return Pos{v = vec.v / s}
}

Dim :: struct #raw_union {
    v:       Vec2f,
    using _: struct {
        w, h: f32,
    },
}

add_dim :: proc(l, r: Dim) -> Dim {
    return Dim{v = l.v + r.v}
}
sub_dim :: proc(l, r: Dim) -> Dim {
    return Dim{v = l.v - r.v}
}
mul_dim :: proc(s: f32, vec: Dim) -> Dim {
    return Dim{v = vec.v * s}
}
div_dim :: proc(s: f32, vec: Dim) -> Dim {
    return Dim{v = vec.v / s}
}

GridPos :: struct #raw_union {
    v:       Vec2i,
    using _: struct {
        x, y: i32,
    },
}

add_grid_pos :: proc(l, r: GridPos) -> GridPos {
    return GridPos{v = l.v + r.v}
}
sub_grid_pos :: proc(l, r: GridPos) -> GridPos {
    return GridPos{v = l.v - r.v}
}
mul_grid_pos :: proc(s: i32, vec: GridPos) -> GridPos {
    return GridPos{v = vec.v * s}
}
div_grid_pos :: proc(s: i32, vec: GridPos) -> GridPos {
    return GridPos{v = vec.v / s}
}

GridDim :: struct #raw_union {
    v:       Vec2i,
    using _: struct {
        w, h: i32,
    },
}

add_grid_dim :: proc(l, r: GridDim) -> GridDim {
    return GridDim{v = l.v + r.v}
}
sub_grid_dim :: proc(l, r: GridDim) -> GridDim {
    return GridDim{v = l.v - r.v}
}
mul_grid_dim :: proc(s: i32, vec: GridDim) -> GridDim {
    return GridDim{v = vec.v * s}
}
div_grid_dim :: proc(s: i32, vec: GridDim) -> GridDim {
    return GridDim{v = vec.v / s}
}

extent_to_dim :: proc(extent: vulkan.Extent2D) -> Dim {
    return Dim{v = {cast(f32)extent.width, cast(f32)extent.height}}
}

add :: proc {
    add_pos,
    add_dim,
    add_grid_pos,
    add_grid_dim,
}
sub :: proc {
    sub_pos,
    sub_dim,
    sub_grid_pos,
    sub_grid_dim,
}
mul :: proc {
    mul_pos,
    mul_dim,
    mul_grid_pos,
    mul_grid_dim,
}
div :: proc {
    div_pos,
    div_dim,
    div_grid_pos,
    div_grid_dim,
}
