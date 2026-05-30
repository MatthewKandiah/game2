package main

import "vendor:glfw"
import "core:fmt"

INPUT_EVENTS_SIZE :: 10
INPUT_EVENTS := [INPUT_EVENTS_SIZE]InputEvent{}
INPUT_EVENTS_COUNT := 0

push_input_event :: proc(e: InputEvent) {
  INPUT_EVENTS[INPUT_EVENTS_COUNT] = e
  INPUT_EVENTS_COUNT += 1
}

flush_input_events :: proc() {
  for event in INPUT_EVENTS[:INPUT_EVENTS_COUNT] {
    switch(event) {
    case .MouseLeftDown: fmt.println("MouseLeftDown")
    case .MouseLeftUp: fmt.println("MouseLeftUp")
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
