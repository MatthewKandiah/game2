# GAME 2

# In progress - experiment with better font rendering
[x] use stb_truetype to rasterize characters from ttf file and generate font atlas
[] create texture resources for these font atlases
[] update shaders to allow font drawing - want to be able to draw a character in any colour with transparent background (don't think we need to set a background colour / font, it seems unlikely that we'll ever want to texture the background of a character's bounding box, we probably want to set a background around a larger area which we can already do with another quad at a lower z-value)

# TODO - preliminary refactoring
- container-child layout algorithm -> position rectangles within each other more nicely
- track memory usage & frame timing for performance checking & experiment with package core:prof/spall
