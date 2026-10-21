import 'dart:ui';

/// The single authoritative gameplay state.
///
/// Feed and Play are only accepted while the game is [idle].
enum CatGameState {
  idle,
  walkingToFood,
  eating,
  returningFromFood,
  walkingToToy,
  playing,
  returningFromPlay,
}

/// Which animation set the kitten is currently showing.
enum CatPose { idle, walk, lick, eat, play, happy }

/// A temporary prop in the room (the food bowl or the wool ball).
///
/// Positions are normalized (0..1) and anchored at the bottom-center of the
/// prop. [appear] and [pop] are 0..1 progress values for the spawn and
/// disappear animations.
class SpawnedObject {
  SpawnedObject(this.position);

  Offset position;
  double appear = 0;
  double pop = 0;
  double rotation = 0;

  /// How full the bowl is (unused for the wool ball).
  double fill = 1;
}
