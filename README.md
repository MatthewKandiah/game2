# GAME 2

# Notes

# In progress - how do we want to handle UI layout
- Avoid overcomplicating this, I don't need a full flexbox implementation. But I do want something that's easier to read/write than just explicitly calculating every pos and dim every time.
- [ ] container-child layout algorithm -> position rectangles within each other more nicely
- [ ] draw a string of characters like proper text (using advance, left-side-bearing, and kerning)
- [ ] draw a grid of characters
- [ ] implement mouse interactions - onMouseDown, onMouseUp, onHover, etc. If we get this right, we'll save a lot of effort later!
- [ ] draw a grid of interactive cells with a button layered over the top of it. Everything should handle hover, mouse down, and mouse up. If we can do that, I think we've got everything covered that we'll need for the game

# References
- A bunch of Casey Muratori's old blogs look useful. This series of blogs explains starting with a simple component which handles layout very explicitly, and walks through how he refactored and extended it. 
  - https://caseymuratori.com/blog_0015
  - https://caseymuratori.com/blog_0016
  - https://caseymuratori.com/blog_0017
  - https://caseymuratori.com/blog_0018
  - https://caseymuratori.com/blog_0019
  - https://caseymuratori.com/blog_0020
  - https://caseymuratori.com/blog_0021
  - https://caseymuratori.com/blog_0022
  - https://caseymuratori.com/blog_0023
  - https://caseymuratori.com/blog_0024
- Tangentially related - how to use a bad API https://caseymuratori.com/blog_0025
- More Casey simping - Handmade Hero Day 265 "Cleaning up the UI Layout Code" https://guide.handmadehero.org/code/day265/

# TODO - preliminary refactoring
- tinting - I think we'll get a lot of use out of this. Add a tint vertex attribute. Multiply the current pixel colour by it (possibly weighted by the tint's alpha? so we can tweak the amount of tinting to get it looking nice). Allow us to flash an enemy red, or highlight the hovered button, etc.
- track memory usage & frame timing for performance checking & experiment with package core:prof/spall
