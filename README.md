# My Pet Cat

A hand-drawn notebook-doodle virtual kitten, built with Flutter only (no game
engine, no extra packages, fully offline).

## Screens

1. **Splash**: the kitten hops happily while the title fades in, then the
   start screen fades in after 2.4 s (tap to skip). The Android launch theme
   uses the same paper color, so there's no white flash.
2. **Start screen**: the title, the kitten on her rug, and **Play** and
   **How to Play**.
3. **How to Play**: five illustrated tips and a "Got it!" button.
4. **Game**: the back arrow (top-left) returns to the start screen.

## Locations and activities

Switch locations with the bottom navigation bar (a 340 ms fade).
Navigation and all action buttons are disabled while an activity runs.

| Home | Bathroom | Garden |
| --- | --- | --- |
| **Feed**: bowl, walk, eat, pop, return | **Bath Time**: foam, hop into tub, bubbles, hop out | **Catch Bird**: bird hops, kitten pounces, bird flies away safely |
| **Play**: wool ball rolls a fixed path, swipes | **Brush Fur**: brush strokes along the back, sparkles | **Climb Tree**: trunk, low branch, high branch, look around, climb down |
| **Catch Mice**: mouse sniffs, scurries A→B→C, pounce, escapes into its hole | **Towel Dry**: towel rubs, shake, droplets | **Butterflies**: butterfly loops, two swats, flutters away |

The Home room has a sofa, a round rug on a wooden floor, a window, a portrait,
a shelf, drawers, plants, a cat tree and a mouse hole. It also has a resting
food bowl, wool ball and wind-up toy mouse. The bowl and ball fade out while
their own activity shows the animated version, so there are never two of them.
A small greeting sits at the top. Settings (top-right) toggles idle wandering.
Buttons give a light haptic tick when tapped.

## Art

All art is drawn procedurally with `CustomPainter` through a small sketch
toolkit (`lib/game/sketch/sketch.dart`): seeded wobbly double ink lines plus
colored-pencil hatching. There are **no image assets**, so nothing can be
missing at runtime, and the kitten is one painter whose poses (idle, walk,
lick, eat, play, happy, crouch, pounce, surprised, sit, relax, shake, climb,
look-up, swat) all share the exact same face, markings and anchor.

To swap in real artwork later, replace a painter. Positions, sizes and
sequences don't change:

| Artwork | Painter |
| --- | --- |
| Backgrounds | `HomeRoomPainter`, `BathroomPainter`, `GardenPainter` |
| Kitten | `CatPainter` (pose data in `animations/cat_animations.dart`) |
| Props / critters | `FoodBowlPainter`, `WoolBallPainter`, `MousePainter`, `BirdPainter`, `ButterflyPainter`, `BrushPainter`, `TowelPainter`, `BathTubPainter` |
| Effects | `SceneEffectsPainter` (bubbles, splash, sparkles, droplets, leaves, puff) |

## Structure

```
lib/game/
  cat_game_screen.dart          layers: paper, scene (background + playfield), controls
lib/screens/                    splash, start, how-to-play, fade route, title
  controllers/
    cat_game_controller.dart    the single state machine, game clock, shared steps
    home_activities.dart        Feed, Play, Catch Mice
    bath_activities.dart        Bath Time, Brush Fur, Towel Dry
    outdoor_activities.dart     Catch Bird, Climb Tree, Chase Butterflies
  models/
    game_location.dart          per-location config: idle spots, walk area, actions
    activity_definition.dart    CatActivity + button labels
    game_positions.dart         every named, normalized coordinate and size
    game_timings.dart           every duration and speed
    cat_game_state.dart         CatGameState, CatPose, SpawnedObject, SceneEffect
  animations/                   pose -> CatFrame, spawn/pop curves
  widgets/                      backgrounds, cat, props, effects, buttons, navigation
```

Tune a scene in `game_positions.dart` and `game_timings.dart`. Positions are
normalized (0..1) to the stage and anchored at each sprite's bottom-center.

## How sequencing works

One `Ticker` drives a clamped game clock. Each activity is an async function
built from shared steps (`_walkTo`, `_moveCat`, `_pounce`, `_appear`,
`_moveObject`, `_popAway`, `_wait`, effects). Each step resolves to `false` if
a newer sequence or disposal superseded it, so stale code never touches newer
state. A `try/finally` always clears props and effects, and if anything fails
it puts the cat back on safe ground, so the game can't lock up or strand the
kitten in a tree. Stopping the ticker when the app is backgrounded freezes
everything, including waits. The cat always moves from its current rendered
position and snaps exactly onto fixed targets, so repeated activities never
drift.

## Tests

`flutter test` runs all nine activities twice in their locations and checks
for clean endings and no drift. It also checks the mouse, bird, butterfly and
tree waypoints, location switching and locking, rejected cross-location
actions, background/resume, a short wide screen, and disposal mid-animation.
