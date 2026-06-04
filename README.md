# GAME 2

# Notes - frame timing for performance checking & experiment with package core:prof/spall
- [x] simple timer to print init time to console because we know it's bad
- [x] simple timer to print millis per frame to console
  - removed frame rate throttling, ~0.5 millis per frame
  - confirmed with renderdoc, ~2000 FPS
- [x] experiment with core:prof/spall
  - tried, only interesting artifacts I could spot were occasional huge spikes in render_frame duration caused by the instrumentation (actually it hit procedures at random, but the program spends most of its time in render_frame so it hit that most often)
  - probably useful to retry when we decide we actually want to improve performance somewhere, rather than something to run indiscriminately

# TODO
Some of these are halfway hacked in. Think we should delete that code and do it properly. e.g. my grid is origin top-left, not bottom-left, my grid/player graphics should be separate from my text button graphics, etc.
- [x] Draw a grid of floor and walls somewhat sensibly
  - click handler printing tile value and coordinates to confirm we've got that information easily available
- [ ] More sane action handling in render loop
  - just mutating state inside IMGUI `if button {...}` blocks is quick to do, but I think might make our logic more complex. e.g. if I add a monster, and you click to attack it, I need to have finished the player move before drawing the monster and its health bar (or I have to overdraw them or update their buffered drawables)
  - is this even true? need to get my head around the order of events
- [ ] Generate a level of the game map - boxes and connecting corridors
- [ ] Put the player in one room
- [ ] Player movement
- [ ] Line of sight
- [ ] Memory of revealed tiles
- [ ] Minimap
- [ ] Viewport
  - Want to draw a subset of the grid, not the entire grid
  - Want to be able to zoom in and out i.e. change height/width of drawn section of the grid
  - Viewport should follow the player as they move
  - Should be able to detach viewport from player, then recentre on player

# NOTES
- Need to avoid shortcuts and commit to bottom-left origin everywhere, mixing coordinate systems just makes every little thing way more difficult (hit with the grid layout in memory, the "intuitive" first version I wrote corresponded to a top-left coordinate system, but all our drawing is bottom left)
- Order of events in frame render function - flush UI interactions, update state, draw frame, etc.
- Our unique id isn't unique enough, getting id collisions
- Handmade hero Day 196 probably worth a more detailed look - implements UI like we're building
