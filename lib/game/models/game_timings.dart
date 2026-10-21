/// Fixed timings so every interaction plays out identically.
abstract final class GameTimings {
  static const objectAppear = Duration(milliseconds: 450);
  static const objectPop = Duration(milliseconds: 420);
  static const turn = Duration(milliseconds: 240);
  static const eating = Duration(seconds: 4);
  static const happy = Duration(milliseconds: 900);
  static const lick = Duration(milliseconds: 2400);

  // Play choreography.
  static const yarnRollOut = Duration(milliseconds: 1000);
  static const yarnRollBack = Duration(milliseconds: 800);
  static const pawSwipe = Duration(milliseconds: 450);
  static const yarnSettle = Duration(milliseconds: 700);

  /// Walking speed in normalized stage widths per second.
  static const walkSpeed = 0.17;
  static const minWalkSeconds = 0.3;

  /// Leg cycle speed in radians per second while walking.
  static const stepRate = 11.0;

  /// Longest time step a single frame may advance the game clock. Keeps a
  /// hitch (or a resume from background) from skipping animations.
  static const maxFrameStep = 0.05;
}
