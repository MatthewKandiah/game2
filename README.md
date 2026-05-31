# GAME 2

# Notes - frame timing for performance checking & experiment with package core:prof/spall
- [x] simple timer to print init time to console because we know it's bad
- [x] simple timer to print millis per frame to console
  - removed frame rate throttling, ~0.5 millis per frame
  - confirmed with renderdoc, ~2000 FPS
- [x] experiment with core:prof/spall
  - tried, only interesting artifacts I could spot were occasional huge spikes in render_frame duration caused by the instrumentation (actually it hit procedures at random, but the program spends most of its time in render_frame so it hit that most often)
  - probably useful to retry when we decide we actually want to improve performance somewhere, rather than something to run indiscriminately
