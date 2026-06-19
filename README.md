# GAME 2

# TODO
- [x] EnemyManager
  - [x] test by adding a button to spawn enemies near the player, and delete them on click
- [ ] Add unintelligent enemies that just approach the player if they can see them
  - [x] needs an in-game time system
  - [x] needs an actor ordering system
  - [x] stick time in the UI somewhere
  - [ ] needs enemies to have ALERT and NOT_ALERT modes that drive their behaviour
- [x] Add player health
  - [x] stick health in the UI somewhere
- [ ] Add player -> enemy attacks and enemy -> player attacks
- [ ] Nice `draw_int` and `draw_float` helpers
  - Health and time UI good places to do it

# NOTES
- originally had the actor queue size set to enemy manager buffer size + 1, thinking you can't have more actors than that. Doesn't work unless we also remove dead actors from the actor queue, which we can't do efficiently.   - set it to double the enemy count and see how we go? Unlikely that we wipe every actor out and replace them all and then have another one
- had a but in our generational index logic! Fixed by moving generation increase to ensure it happens on first run where needed
  - first actual use of the logging being useful, helped identify that it was index 0 insertions getting checked twice causing wonky generation values
  - probably would be better to be better with a debugger, I found it hard to get anywhere with gf2 because I had breakpoints in both `enemy_manager` and  `actor_queue` functions, so continuing between breakpoints changed the variables in the frame, so all my watched variables in the watch window changed too. Bet there's a way to do that which is less painful.
