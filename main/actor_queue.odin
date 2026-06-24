package main

import "core:fmt"
import "core:log"
import "core:testing"

ActorQueue :: struct {
  heap_data:  []Actor,
  heap_count: i32,
}

Actor :: struct {
  id: EntityId,
  next_active: f32,
}

actor_queue_heap_left_child_idx :: proc(idx: i32) -> i32 {
  return idx * 2 + 1
}

actor_queue_heap_right_child_idx :: proc(idx: i32) -> i32 {
  return idx * 2 + 2
}

actor_queue_heap_parent_idx :: proc(idx: i32) -> i32 {
  return max(0, (idx - 1) / 2)
}

actor_queue_insert :: proc(actor_queue: ^ActorQueue, actor: Actor) {
  log.info("actor_queue_insert", actor)
  actor_queue.heap_data[actor_queue.heap_count] = actor
  cmp_child_idx := actor_queue.heap_count
  cmp_parent_idx := actor_queue_heap_parent_idx(cmp_child_idx)
  actor_queue.heap_count += 1

  for actor_queue.heap_data[cmp_parent_idx].next_active > actor_queue.heap_data[cmp_child_idx].next_active {
    actor_queue.heap_data[cmp_child_idx], actor_queue.heap_data[cmp_parent_idx] =
      actor_queue.heap_data[cmp_parent_idx], actor_queue.heap_data[cmp_child_idx]
    cmp_child_idx = cmp_parent_idx
    cmp_parent_idx = actor_queue_heap_parent_idx(cmp_child_idx)
  }
}

actor_queue_peek_min :: proc(actor_queue: ActorQueue) -> Actor {
  return actor_queue.heap_data[0]
}

actor_queue_pop_min :: proc(actor_queue: ^ActorQueue) -> Actor {
  res := actor_queue.heap_data[0]
  log.info("actor_queue_pop_min", res)
  actor_queue.heap_data[0] = actor_queue.heap_data[actor_queue.heap_count - 1]
  actor_queue.heap_count -= 1

  check_idx: i32 = 0
  for actor_queue_heap_left_child_idx(check_idx) < actor_queue.heap_count {
    has_right_child := actor_queue_heap_right_child_idx(check_idx) < actor_queue.heap_count
    if has_right_child {
      left_idx := actor_queue_heap_left_child_idx(check_idx)
      right_idx := actor_queue_heap_right_child_idx(check_idx)
      left_child_is_smaller :=
        actor_queue.heap_data[left_idx].next_active < actor_queue.heap_data[right_idx].next_active
      if left_child_is_smaller {
        if actor_queue.heap_data[check_idx].next_active > actor_queue.heap_data[left_idx].next_active {
          actor_queue.heap_data[check_idx], actor_queue.heap_data[left_idx] =
            actor_queue.heap_data[left_idx], actor_queue.heap_data[check_idx]
          check_idx = left_idx
        } else {
          break
        }
      } else {   // right_child_is_smaller or equal
        if actor_queue.heap_data[check_idx].next_active > actor_queue.heap_data[right_idx].next_active {
          actor_queue.heap_data[check_idx], actor_queue.heap_data[right_idx] =
            actor_queue.heap_data[right_idx], actor_queue.heap_data[check_idx]
          check_idx = right_idx
        } else {
          break
        }
      }
    } else {
      left_idx := actor_queue_heap_left_child_idx(check_idx)
      if actor_queue.heap_data[check_idx].next_active > actor_queue.heap_data[left_idx].next_active {
        actor_queue.heap_data[check_idx], actor_queue.heap_data[left_idx] =
          actor_queue.heap_data[left_idx], actor_queue.heap_data[check_idx]
        check_idx = left_idx
      } else {
        break
      }
    }
  }

  return res
}

actor_queue_get_next_active :: proc(actor_queue: ActorQueue, id: EntityId) -> (found: bool, next_active: f32) {
  for actor in actor_queue.heap_data[0:actor_queue.heap_count] {
    if actor.id == id {
      return true, actor.next_active
    }
  }
  return false, {}
}

@(test)
should_be_able_to_insert_and_pop_a_single_element_repeatedly :: proc(t: ^testing.T) {
  buf := [10]Actor{}
  actor_queue := ActorQueue {
    heap_data = buf[:],
  }

  a := Actor {
    id        = PLAYER_ENTITY_ID,
    next_active = 1,
  }
  for i in 0 ..< 100 {
    actor_queue_insert(&actor_queue, a)
    testing.expect_value(t, actor_queue.heap_count, 1)

    val := actor_queue_pop_min(&actor_queue)
    testing.expect_value(t, actor_queue.heap_count, 0)
    testing.expect_value(t, val, a)

    a.next_active += 1
  }
}

@(test)
should_be_able_to_insert_and_pop_multiple_values :: proc(t: ^testing.T) {
  buf := [10]Actor{}
  actor_queue := ActorQueue {
    heap_data = buf[:],
  }

  for i in 0 ..< 5 {
    a := Actor {
      next_active = cast(f32)i * 100,
    }
    actor_queue_insert(&actor_queue, a)
  } // [0, 100, 200, 300, 400]
  testing.expect_value(t, actor_queue.heap_count, 5)

  p1 := actor_queue_pop_min(&actor_queue).next_active
  p2 := actor_queue_pop_min(&actor_queue).next_active
  testing.expect_value(t, actor_queue.heap_count, 3)
  testing.expect_value(t, p1, 0)
  testing.expect_value(t, p2, 100)

  for i in 0 ..< 3 {
    a := Actor {
      next_active = 350 - cast(f32)i * 50,
    }
    actor_queue_insert(&actor_queue, a)
  } // [200, 250, 300, 300, 350, 400]
  testing.expect_value(t, actor_queue.heap_count, 6)

  p3 := actor_queue_pop_min(&actor_queue).next_active
  p4 := actor_queue_pop_min(&actor_queue).next_active
  p5 := actor_queue_pop_min(&actor_queue).next_active
  p6 := actor_queue_pop_min(&actor_queue).next_active
  p7 := actor_queue_pop_min(&actor_queue).next_active
  p8 := actor_queue_pop_min(&actor_queue).next_active

  testing.expect_value(t, actor_queue.heap_count, 0)
  testing.expect_value(t, p3, 200)
  testing.expect_value(t, p4, 250)
  testing.expect_value(t, p5, 300)
  testing.expect_value(t, p6, 300)
  testing.expect_value(t, p7, 350)
  testing.expect_value(t, p8, 400)
}

@(test)
should_be_able_to_add_and_pop_lots_of_values :: proc(t: ^testing.T) {
  size :: 1000
  buf := [size]Actor{}
  actor_queue := ActorQueue {
    heap_data = buf[:],
  }

  for idx in 0 ..< size {
    a := Actor {
      next_active = cast(f32)idx,
    }
    actor_queue_insert(&actor_queue, a)
  }
  testing.expect_value(t, actor_queue.heap_count, size)

  for idx in 0 ..< size {
    a := actor_queue_pop_min(&actor_queue)
    testing.expect_value(t, a.next_active, cast(f32)idx)
  }
  testing.expect_value(t, actor_queue.heap_count, 0)
}
