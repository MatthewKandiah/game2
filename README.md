# GAME 2

# TODO
- [x] Generate a level of the game map - boxes and connecting corridors
- [x] Put the player in one room
- [x] Line of sight
  - [x] Line drawing on a grid
  - [x] For each tile in the vision range, draw a line from the player and check if it hits a wall
  - [x] Naive middle to middle paths blocked by first wall doesn't look right, it's too strict. What can we tweak?
- [x] Memory of revealed tiles
- [ ] Minimap
- [ ] Flip png data to use bottom left origin consistently

# NOTES
- Line of sight is going to need a method for drawing a line in grid tiles from point A to B
  - Reference for Bresenham http://members.chello.at/easyfilter/bresenham.html
  - Much simpler suggestion using linear interpolation and rounding to grid cells https://www.redblobgames.com/grids/line-drawing/
    - Specifically calls out that "Bresenham is the fastest line drawing algorithm" is accepted knowledge from a long time ago. Optimizing compilers are much more sophisticated now, and tend to handle simple code much more efficiently. Floating point operations used to be much more expensive that integer operations, that's not really true anymore (I think individual operations may still be slightly more expensive, but CPU micro-op pipelining and out-of-order execution minimises impact of that on throughput when doing a block of operations)
	- Maybe worth writing both and profiling? Or just use the simplest one, and profile if it turns out that it's not fast enough?
  - LERP reference mentions you can optimise that simple algorithm into DDA https://en.wikipedia.org/wiki/Digital_differential_analyzer_(graphics_algorithm)
- Bunch of different methods for line of sight calculations (including some fast approximate methods which may be useful later when we need to calculate this for lots of monsters!) https://www.roguebasin.com/index.php/Field_of_Vision
