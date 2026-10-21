# My Pet Cat

A hand-drawn notebook-doodle virtual kitten, built with Flutter only (no game
engine, no extra packages, fully offline).

- **Feed** – a bowl pops in, the kitten walks over, eats for 4 s, hops happily,
  the bowl pops away and the kitten walks back.
- **Play** – a wool ball pops in, rolls along a fixed path, the kitten chases
  and swipes at it, then the ball pops away.
- **Home** (top-left) cancels whatever is happening and calls the kitten back.
- **Settings** (top-right) toggles idle wandering.

## Art

All art is drawn procedurally with `CustomPainter` through a small sketch
toolkit (`lib/game/sketch/sketch.dart`): seeded wobbly double ink lines plus
colored-pencil hatching. There are no image assets, so every pose shares the
exact same face, proportions and anchor point. To swap in PNG art later,
replace the painter inside `CatCharacter`, `FoodBowl` or `WoolBall`; positions
and sizes stay the same.

## Structure

```
lib/game/
  cat_game_screen.dart          layers: paper, static room, playfield, controls
  controllers/cat_game_controller.dart   the single state machine + game clock
  models/cat_game_state.dart    CatGameState, CatPose, SpawnedObject
  models/game_positions.dart    every normalized position, size, wander routine
  models/game_timings.dart      every duration / speed
  animations/cat_animations.dart   pose + clock -> CatFrame (pure function)
  animations/object_animations.dart  spawn / pop curves
  widgets/                      room, cat, bowl, yarn, buttons, settings
```

Tune the scene in `game_positions.dart` and `game_timings.dart`. Positions are
normalized (0..1) and anchored at the bottom-center of each sprite.

## How sequencing works

One `Ticker` drives a clamped game clock. Sequences are async functions that
await timed steps. Each step resolves to `false` if a newer sequence, Home or
disposal superseded it, so stale code never touches newer state. Stopping the
ticker when the app is backgrounded freezes everything, including waits. The
cat always walks from its current rendered position and snaps exactly onto
its target, so repeated interactions never drift.

## Tests

`flutter test` covers both full sequences, rejected double taps, no drift over
repeated runs, background/resume, Home cancellation and disposal mid-animation.
