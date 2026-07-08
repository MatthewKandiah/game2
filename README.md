# GAME 2

# TODO
- [x] Add player -> enemy attacks and enemy -> player attacks
- [x] Game over state when health hits zero
- [x] Nice `draw_int` and `draw_float` helpers
  - Health and time UI good places to do it
- [x] Click to move the player more than one tile, set a target position and process moves along that path
- [x] Option to show indicator on each enemy action instead of just jumping to next player action
  - [x] draw_triangle helper
- [ ] Message console for communicating in-game info (instead of console logging to terminal)
- [ ] Serialise actions to buffer / file
  - undo and redo would be useful for reviewing behaviours
- [ ] Rendering bug - seemingly randomly we get this glitch where a thing stretches, it looks like it stretches to the bottom left corner, guessing we're giving an incorrect index count and reading into zeroed data

# NOTES
- temporary allocator freed each frame + tprintf for string formatting => much easier to draw ints and floats!
- showing each enemy action with a visible indicator means an action may last multiple frames now. We effectively need the world's simplest animation system.
  - surprisingly knotty rework, took me a while to make a reasonable plan, not honestly super happy with the current state of it
  - have to handle unanimated and animated action handling with the current plan, and the player fits in awkwardly because they become active before we can know what they are going to do because we're waiting for user input
  - unanimated player actions aren't supported
- I think I've done a messy job of this. Combination of interrupted week and a poor mental picture of the required change at the outset. Might reset to an earlier commit and rewrite on a separate branch to see if I land somewhere significantly neater now I've got my head around the problem better
