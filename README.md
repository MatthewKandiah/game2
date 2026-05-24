# GAME 2

# Notes - rough LLM-assisted plan, not confirmed carefully with the docs yet
- Need to add a second graphics pipeline -> spritePipeline and maskPipeline
- For best performance, you want to dump all the vertices and indices into a single big buffer, and use offsets into those buffers for drawing them with the correct pipeline (i.e. all sprite vertices and indices grouped, then all font data grouped) - this looks easy to do, the draw calls take offset arguments
- Probably use the exact same Vertex data structure and vertex shader for both pipelines
- Both pipelines write to the same colour attachment and depth attachment, so we'll need a pipeline barrier between the two draws to synchronise resource use. We don't want to start drawing font primitives before the sprite draws have finished writing to the depth attachment

LLM's summary diagram:
[Start Dynamic Rendering]
         │
         ▼
 1. Bind Sprite Pipeline ──► 2. Draw Sprite Indices (Offset 0)
         │
         ▼
 3. Pipeline Barrier (Wait for depth writes to finish)
         │
         ▼
 4. Bind Font Pipeline   ──► 5. Draw Font Indices (Offset X)
         │
         ▼
[End Dynamic Rendering]

# In progress - experiment with better font rendering
- [x] use stb_truetype to rasterize characters from ttf file and generate font atlas
- [x] create texture resources for these font atlases
- [x] update shaders to allow font drawing - want to be able to draw a character in any colour with transparent background (don't think we need to set a background colour / font, it seems unlikely that we'll ever want to texture the background of a character's bounding box, we probably want to set a background around a larger area which we can already do with another quad at a lower z-value)
- [ ] draw a character without stretching it terribly
- [ ] draw a string of characters like proper text (using advance, left-side-bearing, and kerning)

# TODO - preliminary refactoring
- container-child layout algorithm -> position rectangles within each other more nicely
- track memory usage & frame timing for performance checking & experiment with package core:prof/spall
