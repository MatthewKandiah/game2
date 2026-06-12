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
- [ ] Tidy z handling
  - think we want to pull out constants / enums or something, possibly per view component? Something that make it easier to see the intended ordering without having to jump around and compare numbers
- [x] Revisit pos-dim
  - neater arithmetic functions? 
	- Actually not a lot of repeated operations yet, leaving for now
  - neater constructors and conversions?
	- Again not as much repeated code as I'd expected, leaving for now
  - refactor to use Rect and GridRect more widely?
    - Tried doing this everywhere, honestly just seemed to add typing. Our logic tends to care about pos and/or dim, so all our operations are at that level. Pulling values out to act on them then regrouping into Rects to conform to the next function's type signature doesn't feel like an improvement.

# NOTES
