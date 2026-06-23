# GAME 2

# TODO
- [x] EnemyManager
  - [x] test by adding a button to spawn enemies near the player, and delete them on click
- [x] Add unintelligent enemies that just approach the player if they can see them
  - [x] needs an in-game time system
  - [x] needs an actor ordering system
  - [x] stick time in the UI somewhere
  - [x] needs enemies to have ALERT and NOT_ALERT modes that drive their behaviour
- [x] Add player health
  - [x] stick health in the UI somewhere
- [ ] Add player -> enemy attacks and enemy -> player attacks
  - [ ] Game over state when health hits zero
- [ ] Nice `draw_int` and `draw_float` helpers
  - Health and time UI good places to do it
- [ ] Path finding
  - ~~Current just hacked in based on vision code~~
  - Use "dijkstra map" to give all enemies reasonable paths to the player https://www.roguebasin.com/index.php/The_Incredible_Power_of_Dijkstra_Maps
  - Should enable clicking to move the player more than one tile too, set a target position and process moves along that path
- [ ] Message console for communicating in-game info (instead of console logging to terminal)

# NOTES
- neat EntityIter custom iterator returning a trailing conditional was new to me
- making Player an Entity seems neater, will see if that pays off in the long run
