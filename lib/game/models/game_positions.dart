import 'dart:math' as math;
import 'dart:ui';

/// Every gameplay coordinate lives here so the scene can be tuned without
/// touching the animation logic.
///
/// All values are normalized to the game stage: x is a fraction of the stage
/// width, y a fraction of the stage height. Character and prop positions are
/// the bottom-center (feet / base) of the sprite.
abstract final class GamePositions {
  /// y of the blue floor baseline drawn in the room.
  static const floorLine = 0.68;

  /// Bottom of the shaded floor area.
  static const floorBottom = 0.845;

  static const idlePositionA = Offset(0.32, 0.765);
  static const idlePositionB = Offset(0.50, 0.775);
  static const idlePositionC = Offset(0.64, 0.765);

  /// The cat stands here facing left, with its head over the bowl.
  static const feedingPosition = Offset(0.37, 0.775);
  static const bowlPosition = Offset(0.29, 0.805);

  /// The cat waits here facing right while the yarn spawns.
  static const playPosition = Offset(0.40, 0.775);

  /// Where the cat scoots to after the first roll of the ball.
  static const chasePosition = Offset(0.47, 0.775);
  static const yarnStartPosition = Offset(0.60, 0.805);

  /// Fixed rolling path: out to the right, then back towards the cat.
  static const yarnWaypoints = [Offset(0.75, 0.805), Offset(0.635, 0.805)];
  static const yarnEndPosition = Offset(0.70, 0.805);

  static const returnPosition = idlePositionB;

  /// Deterministic idle routine. It starts (and restarts after every
  /// interaction) at [returnPosition].
  static const wanderRoutine = <WanderStep>[
    WanderStep.pause(2.2),
    WanderStep.lick(),
    WanderStep.walk(idlePositionA),
    WanderStep.pause(1.8),
    WanderStep.walk(idlePositionB),
    WanderStep.pause(1.4),
    WanderStep.walk(idlePositionC),
    WanderStep.pause(2.0),
    WanderStep.lick(),
    WanderStep.walk(idlePositionB),
  ];

  /// Index of the "walk back to B" step, used when the cat is called home.
  static const homeWanderIndex = 9;
}

/// Sprite sizes as fractions of [GameLayout.unit].
abstract final class GameSizes {
  static const cat = 0.25;
  static const bowl = 0.17;
  static const yarn = 0.085;
  static const actionButtonWidth = 0.31;
  static const actionButtonHeight = 0.14;
  static const cornerButton = 0.13;

  /// Ball radius in normalized stage-width units, used to derive spin from
  /// distance rolled (exact on a 9:16 stage, close enough elsewhere).
  static const yarnRadiusNormalized = yarn / 2;
}

/// Maps the normalized coordinates onto the pixels of the current stage.
class GameLayout {
  GameLayout(this.size) : unit = math.min(size.width, size.height * 9 / 16);

  final Size size;

  /// Scale reference: the width of an ideal 9:16 stage that fits. Sizes use
  /// this so nothing stretches on unusual aspect ratios.
  final double unit;

  Offset toPixels(Offset normalized) =>
      Offset(normalized.dx * size.width, normalized.dy * size.height);
}

enum WanderAction { pause, lick, walk }

class WanderStep {
  const WanderStep.pause(this.seconds)
      : action = WanderAction.pause,
        target = null;
  const WanderStep.lick()
      : action = WanderAction.lick,
        seconds = 0,
        target = null;
  const WanderStep.walk(Offset this.target)
      : action = WanderAction.walk,
        seconds = 0;

  final WanderAction action;
  final double seconds;
  final Offset? target;
}
