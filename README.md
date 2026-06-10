# GAME 2

# TODO
- [x] Generate a level of the game map - boxes and connecting corridors
- [x] Put the player in one room
- [x] Line of sight
  - [x] Line drawing on a grid
  - [x] For each tile in the vision range, draw a line from the player and check if it hits a wall
  - [x] Naive middle to middle paths blocked by first wall doesn't look right, it's too strict. What can we tweak?
- [x] Memory of revealed tiles
- [x] Minimap
  - non-interactive for now, just drawn
- [ ] Flip png data to use bottom left origin consistently
- [ ] Tidy z handling
  - think we want to pull out constants / enums or something, possibly per view component? Something that make it easier to see the intended ordering without having to jump around and compare numbers
- [ ] Revisit pos-dim
  - neater arithmetic functions?
  - neater constructors and conversions?
  - refactor to use Rect and GridRect more widely?

# NOTES
