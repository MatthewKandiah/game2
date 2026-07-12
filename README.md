# GAME 2

# TODO
- [x] Add player -> enemy attacks and enemy -> player attacks
- [x] Game over state when health hits zero
- [x] Nice `draw_int` and `draw_float` helpers
  - Health and time UI good places to do it
- [ ] Option to show indicator on each enemy action instead of just jumping to next player action
  - [x] draw_triangle helper
  - [x] show indicator, vanish after time elapsed
  - [ ] allow action to be split over multiple frames, so the player can see actions in between their turns
- [ ] Click to move the player more than one tile, set a target position and process moves along that path
- [ ] Message console for communicating in-game info (instead of console logging to terminal)
- [ ] Serialise actions to buffer / file
  - undo and redo would be useful for reviewing behaviours

# NOTES
- temporary allocator freed each frame + tprintf for string formatting => much easier to draw ints and floats!
