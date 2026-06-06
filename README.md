# GAME 2

# TODO
- [x] Viewport
  - [x] Want to draw a subset of the grid, not the entire grid
  - [x] Want to be able to zoom in and out i.e. change height/width of drawn section of the grid
  - [x] Viewport should follow the player as they move
  - [x] Should be able to detach viewport from player, then recentre on player
- [ ] Generate a level of the game map - boxes and connecting corridors
- [ ] Put the player in one room
- [ ] Line of sight
- [ ] Memory of revealed tiles
- [ ] Minimap

# NOTES
- embracing the handmade hero "just write it" attitude
- trimming grid buttons at the edge of the grid took some doing, trickier than I'd naively expected
  - software rendering quads, trimming a draw is essentially trivial, at the point you're updating the output buffer, just have a predicate that lets you skip this write
  - trim is on the containing box
  - different characters are different sizes
  - trim may affect the character's position and dimensions on screen, and the uv coordinates in the texture that need to be sampled
- finding it very easy to reason about and extend
- playing_view code is already looking pretty hairy, next time we add something might be time to start compressing
  - reference https://caseymuratori.com/blog_0015
