# GAME 2

# TODO - preliminary refactoring
- refactor stuff like Pos and Dim to improve ergonomics e.g. want nicer arithmetic operations (split out arithmetic.odin? define add, sub, mul, div, etc. for these types)
- refactor renderer so texture assets and loading is less-hardcoded and more extensible
- make screen resizing behaviour nicer
- can renderer be made nicer making more use of dynamic rendering?
- container-child layout algorithm -> position rectangles within each other more nicely
- combine Entity and Drawable from Flectris into a single layer
- how do we test these things? do I care?
- more useful logger? option to dump logs to file, or just to console, with levels
- track memory usage & frame timing for performance checking
- experiment with package core:prof/spall
