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

## Home-screen widget

A native widget (Android and iOS) shows the in-game kitten with her wool ball.
Tapping anywhere on it opens `mypetcat://game/home?source=widget`, which skips
the splash and start screen and lands in the playable Home room. The start
screen sits underneath, so Back still reaches the menu. Normal launches from
the app icon are unchanged.

**How it works**

- **No extra Flutter packages.** Two small method channels:
  `my_pet_cat/launch` delivers launch links and `my_pet_cat/widget` sends a
  tiny payload. Flutter's built-in deep linking is switched off on both
  platforms, so a link can't open a second, duplicate route.
- **Dart:**
  - `lib/navigation/`: `AppLaunchRouter` validates links (anything except the
    exact widget link falls back to the normal start), plus the link channel
    and the named routes.
  - `main.dart` reads the cold-start link before the first frame and handles
    warm links without duplicating screens. A tap while the game is open just
    returns it to Home.
- **Widget payload** (`lib/home_widget/`): the last finished activity's label
  and the current location. It's recorded during play and sent only when the
  app goes to the background or the game closes, so widget reloads stay rare.
- **Android** (`android/app/src/main/kotlin/.../widget/`):
  - `RemoteViews` providers for small (2×2), medium (4×2) and large (4×4).
    Glance would need a Compose toolchain this project doesn't have.
  - The kitten animates through a `ViewFlipper` that the launcher cross-fades
    by itself every 1.8 s. The app is never woken to animate it, and
    `updatePeriodMillis` is 0.
  - `MainActivity` (`singleTop`) passes cold-start and new-intent links on to
    Dart. Android 12+ gets live preview layouts and the system corner radius.
- **iOS** (`ios/PetWidget/`):
  - A WidgetKit/SwiftUI extension with small, medium and large sizes. Its
    timeline shows a new pre-rendered pose roughly every 20 minutes, cross-
    fading on iOS 17+. iOS decides the exact timing.
  - `widgetURL` opens the app. `Runner/LaunchLinkPlugin.swift` receives the URL
    through Flutter's scene-lifecycle plugin hooks for both cold and warm
    starts.
  - The payload is shared through the App Group
    `group.com.thelazybearClub.myPetCat`.
- **Art** (`tool/widget_assets/`): the pose frames (idle, blink, tail up and
  down, looking at the ball, reaching, tapping, happy, resting), plus the
  paper, rug, bowl, wool ball and picker previews, are rendered from the
  game's own painters. Re-render with
  `flutter test tool/widget_assets/render_widget_assets_test.dart`.
- **Xcode target:** added by `tool/ios/add_widget_extension.rb`
  (idempotent; uses CocoaPods' bundled `xcodeproj` gem).

**Device setup (iOS):** in Xcode, make sure your team (`DU52BN5JF2`) can sign
both `Runner` and `PetWidget`. Then enable the App Groups capability with
`group.com.thelazybearClub.myPetCat` for both targets in the Apple Developer
portal. Without it the widget still works and launches the game, but shows
the default greeting instead of the last activity.

**Limits:** neither OS guarantees continuous widget animation.
- Some Android launchers pause the flipper while it's off screen.
- On iOS, poses change on the system's schedule, not at a fixed interval.

## App icon

The master artwork is `branding/app_icon_source.png`. To regenerate every
platform's icons after changing it, run
`python3 branding/make_icons.py . /tmp/adaptive_preview.png` (needs Pillow):

- **Android:** legacy icons, plus an adaptive icon on a paper background.
- **iOS:** opaque icons.
- **macOS, Windows and web:** transparent corners.

## Locations and activities

Switch locations with the bottom navigation bar (a 340 ms fade).
Navigation and all action buttons are disabled while an activity runs.

| Home | Bathroom | Garden |
| --- | --- | --- |
| **Feed**: bowl, walk, eat, pop, return | **Bath Time**: foam, hop into tub, bubbles, hop out | **Catch Bird**: bird hops, kitten pounces, bird flies away safely |
| **Play**: wool ball rolls a fixed path, swipes | **Brush Fur**: brush strokes along the back, sparkles | **Climb Tree**: trunk, low branch, high branch, look around, climb down |
| **Catch Mice**: mouse sniffs, scurries A→B→C, pounce, escapes into its hole | **Towel Dry**: towel rubs, shake, droplets | **Butterflies**: butterfly loops, two swats, flutters away |

**Kitchen** (`controllers/kitchen_activities.dart`, `widgets/kitchen_background.dart`, `widgets/kitchen_props.dart`):

- **Glass**: the kitten climbs the cabinets onto the counter, taps a glass
  twice and it falls along a fixed path. It lands with a soft bonk and a puff
  (no shards), then the kitten looks innocent with a "?".
- **Treat**: sniffs and scratches a cabinet three times until the door opens,
  a fish biscuit pops out, and she eats it happily.
- **Fish**: she smells the fish cooking, watches from a safe spot while it goes
  from raw to golden in three steps (steam, heat marks and a timer doodle),
  then eats it from a plate moved to the floor. She never goes near the
  stove.

All kitchen positions are in `KitchenPositions` and all timings in the Kitchen
block of `GameTimings`. Idle in the kitchen includes sniffing the air.

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
