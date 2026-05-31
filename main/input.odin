package main

import "core:fmt"
import "vendor:glfw"

INPUT_EVENTS_SIZE :: 10
INPUT_EVENTS := [INPUT_EVENTS_SIZE]InputEvent{}
INPUT_EVENTS_COUNT := 0

push_input_event :: proc(e: InputEvent) {
  INPUT_EVENTS[INPUT_EVENTS_COUNT] = e
  INPUT_EVENTS_COUNT += 1
}

flush_input_events :: proc() {
  for event in INPUT_EVENTS[:INPUT_EVENTS_COUNT] {
    switch (event) {
    case .MouseLeftDown:
      {
        if gc.ui.hot_id != 0 {gc.ui.active_id = gc.ui.hot_id}
      }
    case .MouseLeftUp:
      {
        if gc.ui.hot_id == gc.ui.active_id {
          gc.ui.triggered_id = gc.ui.active_id
        }
        gc.ui.active_id = 0
      }
    }
  }

  INPUT_EVENTS_COUNT = 0
}

InputEvent :: enum {
  MouseLeftDown,
  MouseLeftUp,
}

InputState :: struct {
  cursor_pos: Pos,
}

is_cursor_inside :: proc(pos: Pos, dim: Dim) -> bool {
  cursor := gc.input.cursor_pos
  return cursor.x >= pos.x && cursor.x <= pos.x + dim.w && cursor.y >= pos.y && cursor.y <= pos.y + dim.h
}
