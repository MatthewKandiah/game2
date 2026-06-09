package main

import "core:fmt"
import "core:math"
import "core:testing"

// N: max size of our path (to avoid heap allocation)
// populate path_buf with each tile that a line from the middle of start to the middle of end would pass through
// populate entry_buf with the points where that line enters each tile
// path includes start and end
supercover :: proc($N: i32, start, end: GridPos) -> (path_buf: [N]GridPos, entry_buf: [N]Pos, count: i32) {
  start_pos: Pos = Pos {
    x = cast(f32)start.x + 0.5,
    y = cast(f32)start.y + 0.5,
  }
  pos := start_pos
  entry_pos: Pos = start_pos
  path_buf[0] = start
  entry_buf[0] = entry_pos
  count = 1

  dx := cast(f32)end.x - cast(f32)start.x
  dy := cast(f32)end.y - cast(f32)start.y

  nx := abs(dx)
  sign_x: f32 = 1 if dx >= 0 else -1
  ny := abs(dy)
  sign_y: f32 = 1 if dy >= 0 else -1

  ix: f32 = 0
  iy: f32 = 0

  for (ix < abs(dx) || iy < abs(dy)) {
    assert(count < N, "buffer size too small, next iteration will overflow")
    decision := (1 + 2 * ix) * ny - (1 + 2 * iy) * nx
    step_hor := decision < 0
    step_ver := decision > 0
    step_diag := decision == 0
    if step_hor {
      x_edge := start_pos.x + (ix + 0.5) * sign_x
      y_edge := start_pos.y + (x_edge - start_pos.x) * dy / dx
      entry_pos = {
        x = x_edge,
        y = y_edge,
      }
      pos.x += sign_x
      ix += 1
    }
    if step_ver {
      y_edge := start_pos.y + (iy + 0.5) * sign_y
      x_edge := start_pos.x + (y_edge - start_pos.y) * dx / dy
      entry_pos = {
        x = x_edge,
        y = y_edge,
      }
      pos.y += sign_y
      iy += 1
    }
    if step_diag {
      x_edge := start_pos.x + (ix + 0.5) * sign_x
      y_edge := start_pos.y + (iy + 0.5) * sign_y
      entry_pos = {
        x = x_edge,
        y = y_edge,
      }
      pos.x += sign_x
      ix += 1
      pos.y += sign_y
      iy += 1
    }
    path_buf[count] = GridPos {
      x = cast(i32)math.floor(pos.x),
      y = cast(i32)math.floor(pos.y),
    }
    entry_buf[count] = entry_pos
    count += 1
  }

  return path_buf, entry_buf, count
}

@(test)
supercover_horizontal_right :: proc(t: ^testing.T) {
  start := GridPos {
    x = 5,
    y = 7,
  }
  end := GridPos {
    x = 10,
    y = 7,
  }

  path, _, path_count := supercover(6, start, end)

  testing.expect_value(t, path_count, end.x - start.x + 1)
  testing.expect_value(t, path[0], GridPos{x = start.x + 0, y = start.y})
  testing.expect_value(t, path[1], GridPos{x = start.x + 1, y = start.y})
  testing.expect_value(t, path[2], GridPos{x = start.x + 2, y = start.y})
  testing.expect_value(t, path[3], GridPos{x = start.x + 3, y = start.y})
  testing.expect_value(t, path[4], GridPos{x = start.x + 4, y = start.y})
  testing.expect_value(t, path[5], GridPos{x = start.x + 5, y = start.y})
}

@(test)
supercover_horizontal_left :: proc(t: ^testing.T) {
  start := GridPos {
    x = -3,
    y = -2,
  }
  end := GridPos {
    x = -5,
    y = -2,
  }

  path, _, path_count := supercover(3, start, end)

  testing.expect_value(t, path_count, start.x - end.x + 1)
  testing.expect_value(t, path[0], GridPos{x = start.x - 0, y = start.y})
  testing.expect_value(t, path[1], GridPos{x = start.x - 1, y = start.y})
  testing.expect_value(t, path[2], GridPos{x = start.x - 2, y = start.y})
}

@(test)
supercover_vertical_up :: proc(t: ^testing.T) {
  start := GridPos {
    x = 0,
    y = 4,
  }
  end := GridPos {
    x = 0,
    y = 7,
  }

  path, _, path_count := supercover(4, start, end)

  testing.expect_value(t, path_count, end.y - start.y + 1)
  testing.expect_value(t, path[0], GridPos{x = start.x, y = start.y + 0})
  testing.expect_value(t, path[1], GridPos{x = start.x, y = start.y + 1})
  testing.expect_value(t, path[2], GridPos{x = start.x, y = start.y + 2})
  testing.expect_value(t, path[3], GridPos{x = start.x, y = start.y + 3})
}

@(test)
supercover_vertical_down :: proc(t: ^testing.T) {
  start := GridPos {
    x = 0,
    y = 7,
  }
  end := GridPos {
    x = 0,
    y = 5,
  }

  path, _, path_count := supercover(10, start, end)

  testing.expect_value(t, path_count, start.y - end.y + 1)
  testing.expect_value(t, path[0], GridPos{x = start.x, y = start.y - 0})
  testing.expect_value(t, path[1], GridPos{x = start.x, y = start.y - 1})
  testing.expect_value(t, path[2], GridPos{x = start.x, y = start.y - 2})
}

@(test)
supercover_up_right :: proc(t: ^testing.T) {
  start := GridPos {
    x = 0,
    y = 0,
  }
  end := GridPos {
    x = 6,
    y = 2,
  }

  path, _, path_count := supercover(10, start, end)

  testing.expect_value(t, path_count, 7)
  testing.expect_value(t, path[0], GridPos{x = start.x + 0, y = start.y + 0})
  testing.expect_value(t, path[1], GridPos{x = start.x + 1, y = start.y + 0})
  testing.expect_value(t, path[2], GridPos{x = start.x + 2, y = start.y + 1})
  testing.expect_value(t, path[3], GridPos{x = start.x + 3, y = start.y + 1})
  testing.expect_value(t, path[4], GridPos{x = start.x + 4, y = start.y + 1})
  testing.expect_value(t, path[5], GridPos{x = start.x + 5, y = start.y + 2})
  testing.expect_value(t, path[6], GridPos{x = start.x + 6, y = start.y + 2})
}

@(test)
supercover_down_right :: proc(t: ^testing.T) {
  start := GridPos {
    x = 0,
    y = 0,
  }
  end := GridPos {
    x = 2,
    y = -5,
  }

  path, _, path_count := supercover(10, start, end)

  testing.expect_value(t, path_count, 8)
  testing.expect_value(t, path[0], GridPos{x = start.x + 0, y = start.y - 0})
  testing.expect_value(t, path[1], GridPos{x = start.x + 0, y = start.y - 1})
  testing.expect_value(t, path[2], GridPos{x = start.x + 1, y = start.y - 1})
  testing.expect_value(t, path[3], GridPos{x = start.x + 1, y = start.y - 2})
  testing.expect_value(t, path[4], GridPos{x = start.x + 1, y = start.y - 3})
  testing.expect_value(t, path[5], GridPos{x = start.x + 1, y = start.y - 4})
  testing.expect_value(t, path[6], GridPos{x = start.x + 2, y = start.y - 4})
  testing.expect_value(t, path[7], GridPos{x = start.x + 2, y = start.y - 5})
}

@(test)
supercover_down_left :: proc(t: ^testing.T) {
  start := GridPos {
    x = -1,
    y = -2,
  }
  end := GridPos {
    x = -3,
    y = -4,
  }

  path, _, path_count := supercover(10, start, end)

  testing.expect_value(t, path_count, 3)
  testing.expect_value(t, path[0], GridPos{x = start.x - 0, y = start.y - 0})
  testing.expect_value(t, path[1], GridPos{x = start.x - 1, y = start.y - 1})
  testing.expect_value(t, path[2], GridPos{x = start.x - 2, y = start.y - 2})
}

@(test)
supercover_up_left :: proc(t: ^testing.T) {
  start := GridPos {
    x = 2,
    y = 2,
  }
  end := GridPos {
    x = -3,
    y = 9,
  }

  path, _, path_count := supercover(20, start, end)

  testing.expect_value(t, path_count, 12)
  testing.expect_value(t, path[0], GridPos{x = start.x - 0, y = start.y + 0})
  testing.expect_value(t, path[1], GridPos{x = start.x - 0, y = start.y + 1})
  testing.expect_value(t, path[2], GridPos{x = start.x - 1, y = start.y + 1})
  testing.expect_value(t, path[3], GridPos{x = start.x - 1, y = start.y + 2})
  testing.expect_value(t, path[4], GridPos{x = start.x - 2, y = start.y + 2})
  testing.expect_value(t, path[5], GridPos{x = start.x - 2, y = start.y + 3})
  testing.expect_value(t, path[6], GridPos{x = start.x - 3, y = start.y + 4})
  testing.expect_value(t, path[7], GridPos{x = start.x - 3, y = start.y + 5})
  testing.expect_value(t, path[8], GridPos{x = start.x - 4, y = start.y + 5})
  testing.expect_value(t, path[9], GridPos{x = start.x - 4, y = start.y + 6})
  testing.expect_value(t, path[10], GridPos{x = start.x - 5, y = start.y + 6})
  testing.expect_value(t, path[11], GridPos{x = start.x - 5, y = start.y + 7})
}


@(test)
supercover_is_symmetric :: proc(t: ^testing.T) {
  test_points := [?]GridPos {
    GridPos{x = 0, y = 0},
    GridPos{x = -2, y = 7},
    GridPos{x = -2, y = 20},
    GridPos{x = 10, y = 7},
    GridPos{x = 5, y = 5},
    GridPos{x = 15, y = 5},
    GridPos{x = 5, y = 15},
  }

  contains :: proc(p: $T, path: []T) -> bool {
    for cmp in path {
      if p == cmp {
        return true
      }
    }
    return false
  }
  for p1 in test_points {
    for p2 in test_points {
      path1, _, path1_count := supercover(40, p1, p2)
      path2, _, path2_count := supercover(40, p2, p1)

      testing.expect_value(t, path1_count, path2_count)
      for el in path1[0:path1_count] {
        path2_slice := path2[0:path2_count]
        testing.expect(t, contains(el, path2_slice), fmt.tprintfln("Expected %v to be in %v", el, path2_slice))
      }
    }
  }
}
