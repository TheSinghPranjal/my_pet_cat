/// Fixed timings so every activity plays out identically.
abstract final class GameTimings {
  static const objectAppear = Duration(milliseconds: 450);
  static const objectPop = Duration(milliseconds: 420);
  static const turn = Duration(milliseconds: 240);
  static const happy = Duration(milliseconds: 900);
  static const lick = Duration(milliseconds: 2400);
  static const effectFade = Duration(milliseconds: 350);
  static const puff = Duration(milliseconds: 450);

  // Location change: fade out + fade in (340 ms total).
  static const sceneFadeOut = Duration(milliseconds: 160);
  static const sceneFadeIn = Duration(milliseconds: 180);

  // Home.
  static const eating = Duration(seconds: 4);
  static const yarnRollOut = Duration(milliseconds: 1000);
  static const yarnRollBack = Duration(milliseconds: 800);
  static const pawSwipe = Duration(milliseconds: 450);
  static const yarnSettle = Duration(milliseconds: 700);
  static const mouseSniff = Duration(milliseconds: 900);
  static const pounce = Duration(milliseconds: 550);

  // Bath.
  static const foam = Duration(milliseconds: 450);
  static const tubHop = Duration(milliseconds: 600);
  static const bath = Duration(seconds: 5);
  static const brushStroke = Duration(milliseconds: 450);
  static const brushStrokes = 8;
  static const towelRub = Duration(milliseconds: 300);
  static const towelRubs = 8;
  static const shake = Duration(milliseconds: 1200);

  // Outdoors.
  static const climbSegment = Duration(milliseconds: 850);

  /// Walking speed in normalized stage widths per second.
  static const walkSpeed = 0.17;
  static const minWalkSeconds = 0.3;

  /// Leg cycle speed in radians per second while walking or climbing.
  static const stepRate = 11.0;

  /// Longest time step a single frame may advance the game clock. Keeps a
  /// hitch (or a resume from background) from skipping animations.
  static const maxFrameStep = 0.05;
}
