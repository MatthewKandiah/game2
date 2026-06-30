package main

import "core:time"

now :: proc() -> i64 {
  return time.now()._nsec
}
