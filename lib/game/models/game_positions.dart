import 'dart:math' as math;
import 'dart:ui';

/// Every gameplay coordinate lives in this file so scenes can be tuned
/// without touching the animation logic.
///
/// All values are normalized to the game stage: x is a fraction of the stage
/// width, y a fraction of the stage height. Character and prop positions are
/// the bottom-center (feet / base) of the sprite.
abstract final class SceneMetrics {
  /// y of the ground baseline shared by all locations.
  static const groundLine = 0.63;

  /// Bottom of the shaded floor / grass area.
  static const groundBottom = 0.795;

  /// Top of the control panel (action buttons and navigation).
  static const controlsTop = 0.815;
  static const actionRowY = 0.858;
  static const navBarY = 0.952;
}

abstract final class HomePositions {
  static const idlePositionA = Offset(0.34, 0.715);
  static const idlePositionB = Offset(0.52, 0.725);
  static const idlePositionC = Offset(0.66, 0.715);
  static const returnPosition = idlePositionB;

  // Feed.
  static const feedingPosition = Offset(0.37, 0.725);
  static const bowlPosition = Offset(0.29, 0.755);

  // Play with wool.
  static const playPosition = Offset(0.40, 0.725);
  static const chasePosition = Offset(0.47, 0.725);
  static const yarnStartPosition = Offset(0.60, 0.755);
  static const yarnWaypoints = [Offset(0.75, 0.755), Offset(0.635, 0.755)];
  static const yarnEndPosition = Offset(0.70, 0.755);

  // Catch mice. The mouse pops out of the hole beside the sofa and darts
  // back in.
  static const mouseHolePosition = Offset(0.675, SceneMetrics.groundLine);
  static const mouseSpawnPosition = Offset(0.645, 0.672);
  static const catMouseApproachPosition = Offset(0.34, 0.725);
  static const mouseWaypointA = Offset(0.55, 0.745);
  static const mouseWaypointB = Offset(0.66, 0.772);
  static const mouseWaypointC = Offset(0.57, 0.775);
  static const catMousePursuitPositions = [Offset(0.38, 0.73), Offset(0.41, 0.735)];
  static const catMousePounceTarget = Offset(0.50, 0.745);
  static const mouseFinalPosition = Offset(0.675, 0.636);
  static const catMouseReturnPosition = idlePositionB;

  // Resting props: part of the room, hidden while their activity runs.
  static const restingBowlPosition = Offset(0.12, 0.775);
  static const restingYarnPosition = Offset(0.86, 0.787);
  static const toyMousePosition = Offset(0.885, 0.712);
}

abstract final class KitchenPositions {
  // Static furniture, shared with the kitchen painter so props line up with
  // the drawing exactly.
  static const counterTop = 0.44;
  static const counterRight = 0.50;
  static const counterFrontBottom = 0.465;
  static const cabinetDoors = [
    Rect.fromLTRB(0.015, 0.477, 0.165, 0.615),
    Rect.fromLTRB(0.18, 0.477, 0.33, 0.615),
    Rect.fromLTRB(0.345, 0.477, 0.49, 0.615),
  ];
  static const stoveLeft = 0.51;
  static const stoveRight = 0.73;
  static const fridgeLeft = 0.76;
  static const fishPanPosition = Offset(0.62, counterTop);

  static const idlePositionA = Offset(0.30, 0.715);
  static const idlePositionB = Offset(0.44, 0.728);
  static const idlePositionC = Offset(0.60, 0.715);

  // Glass trouble: up the cabinets, onto the counter, nudge, oops.
  static const glassCatStartPosition = idlePositionB;
  static const glassCounterApproachPosition = Offset(0.24, 0.73);
  static const glassClimbPositionA = Offset(0.17, 0.62);
  static const glassClimbPositionB = Offset(0.15, 0.50);
  static const glassCounterIdlePosition = Offset(0.17, counterTop - 0.002);
  static const glassSpawnPosition = Offset(0.29, counterTop);
  static const glassPawReachPosition = Offset(0.305, counterTop);
  static const glassEdgePosition = Offset(0.33, counterTop);
  static const glassFallWaypointA = Offset(0.355, 0.47);
  static const glassFallWaypointB = Offset(0.375, 0.62);
  static const glassLandingPosition = Offset(0.385, 0.765);
  static const glassCatReactionPosition = glassCounterIdlePosition;
  static const glassHopDownPosition = Offset(0.26, 0.735);
  static const glassCatReturnPosition = idlePositionB;

  // Treat time: scratch the right-hand cabinet until it opens.
  static const treatCatStartPosition = idlePositionB;
  static const treatCabinetDoorRect = Rect.fromLTRB(0.345, 0.477, 0.49, 0.615);
  static const treatCabinetDoorPosition = Offset(0.4175, 0.615);
  static const treatCabinetApproachPosition = Offset(0.53, 0.735);
  static const treatScratchPosition = Offset(0.49, 0.735);
  static const treatSpawnPosition = Offset(0.41, 0.605);
  static const treatRevealPosition = Offset(0.365, 0.668);
  static const treatEatingPosition = Offset(0.47, 0.735);
  static const treatServePosition = Offset(0.395, 0.752);
  static const treatCatReturnPosition = idlePositionB;

  // Fishy surprise: smell it, watch it cook, eat it from a plate on the floor.
  static const fishCatStartPosition = idlePositionB;
  static const fishCatSniffPosition = Offset(0.52, 0.73);
  static const fishCatWatchPosition = Offset(0.42, 0.732);
  static const fishRawSpawnPosition = Offset(0.62, 0.36);
  static const fishCookingPosition = Offset(0.62, counterTop - 0.003);
  static const fishAromaPosition = Offset(0.62, 0.415);
  static const fishTimerPosition = Offset(0.70, 0.355);
  static const fishServingSpawnPosition = Offset(0.44, counterTop);
  static const fishServingMoveWaypoint = Offset(0.38, 0.60);
  static const fishServingPosition = Offset(0.30, 0.765);
  static const fishCatEatingPosition = Offset(0.39, 0.738);
  static const fishCatReturnPosition = idlePositionB;
}

abstract final class BathPositions {
  static const idlePositionA = Offset(0.52, 0.725);
  static const idlePositionB = Offset(0.64, 0.735);
  static const idlePositionC = Offset(0.78, 0.725);

  // Bath time. The tub is a scene prop drawn in front of the cat.
  static const bathTubPosition = Offset(0.23, 0.70);
  static const catBathEntryPosition = Offset(0.50, 0.73);
  static const catBathPosition = Offset(0.24, 0.642);
  static const bathBubbleSpawnPosition = Offset(0.24, 0.575);
  static const catBathReturnPosition = idlePositionB;

  // Brush fur. The cat faces left; its back is on the right.
  static const brushSpawnPosition = Offset(0.46, 0.70);
  static const catBrushPosition = Offset(0.64, 0.735);
  static const brushStrokeStart = Offset(0.735, 0.694);
  static const brushStrokeEnd = Offset(0.69, 0.69);
  static const brushSparklePosition = Offset(0.70, 0.665);
  static const catBrushReturnPosition = idlePositionB;

  // Towel dry. The cat faces right; the towel rubs over its head.
  static const catDryPosition = Offset(0.64, 0.735);
  static const towelSpawnPosition = Offset(0.68, 0.60);
  static const towelRubPositions = [Offset(0.685, 0.668), Offset(0.675, 0.69)];
  static const dropletsPosition = Offset(0.66, 0.68);
  static const catDryReturnPosition = idlePositionB;
}

abstract final class OutdoorPositions {
  static const idlePositionA = Offset(0.44, 0.715);
  static const idlePositionB = Offset(0.58, 0.725);
  static const idlePositionC = Offset(0.70, 0.715);

  // Tree geometry, shared with the garden painter so the cat sits exactly on
  // the drawn branches.
  static const trunkLeft = 0.08;
  static const trunkRight = 0.20;
  static const lowBranchStart = Offset(0.19, 0.505);
  static const lowBranchEnd = Offset(0.45, 0.49);
  static const highBranchStart = Offset(0.18, 0.375);
  static const highBranchEnd = Offset(0.41, 0.36);

  // Climb tree.
  static const treeBasePosition = Offset(0.33, 0.725);
  static const treeTrunkPosition = Offset(0.16, 0.62);
  static const treeLowBranchPosition = Offset(0.31, 0.499);
  static const treeMiddleBranchPosition = Offset(0.15, 0.46);
  static const treeHighBranchPosition = Offset(0.29, 0.369);
  static const leafFallPosition = Offset(0.24, 0.24);
  static const treeClimbReturnPosition = idlePositionB;

  // Catch bird. It starts on top of the bush and always flies away safely.
  static const birdSpawnPosition = Offset(0.83, 0.578);
  static const catBirdStartPosition = Offset(0.38, 0.73);
  static const catBirdPursuitPosition = Offset(0.45, 0.73);
  static const birdWaypointA = Offset(0.72, 0.74);
  static const birdWaypointB = Offset(0.66, 0.745);
  static const birdWaypointC = Offset(0.63, 0.74);
  static const birdFlutterPosition = Offset(0.63, 0.62);
  static const catBirdPounceTarget = Offset(0.53, 0.735);
  static const birdExitPosition = Offset(1.15, 0.15);
  static const catBirdReturnPosition = idlePositionB;

  // Chase butterflies.
  static const butterflySpawnPosition = Offset(0.72, 0.56);
  static const catButterflyStartPosition = Offset(0.40, 0.73);
  static const catButterflyPursuitPosition = Offset(0.46, 0.73);
  static const butterflyWaypointA = Offset(0.62, 0.50);
  static const butterflyWaypointB = Offset(0.53, 0.57);
  static const butterflyWaypointC = Offset(0.60, 0.625);
  static const butterflyFlutterPosition = Offset(0.58, 0.50);
  static const butterflyExitPosition = Offset(1.12, 0.12);
  static const catButterflyReturnPosition = idlePositionB;
}

abstract final class BedroomPositions {
  static const idlePositionA = Offset(0.32, 0.715);
  static const idlePositionB = Offset(0.48, 0.725);
  static const idlePositionC = Offset(0.62, 0.715);
  static const returnPosition = idlePositionB;

  // Furniture: the wardrobe stands on the left, the bed on the right.
  static const wardrobePosition = Offset(0.165, 0.638);
  static const pillowPosition = Offset(0.875, 0.578);
  static const socketPosition = Offset(0.515, 0.6);
  static const phonePosition = Offset(0.665, 0.692);

  /// Where the cable lies on the floor, and where the cat lifts it to.
  static const cableRestPoint = Offset(0.59, 0.688);
  static const cableBitePoint = Offset(0.585, 0.672);

  /// The girl stands by the back wall; scripts move her sideways by
  /// fractions of the stage width from here.
  static const girlPosition = Offset(0.44, 0.65);
  static const girlAtBed = 0.22;
  static const girlAtWardrobe = -0.09;

  // Wardrobe hide-and-seek.
  static const catWardrobeFront = Offset(0.27, 0.715);
  static const catInWardrobe = Offset(0.20, 0.62);
  static const catWardrobeJumpOut = Offset(0.34, 0.73);

  // Charger cable.
  static const catChewPosition = Offset(0.535, 0.728);

  // Bed and pillow.
  static const catBedFoot = Offset(0.60, 0.72);
  static const catOnBed = Offset(0.68, 0.572);
  static const catBedMiddle = Offset(0.76, 0.571);
  static const catOnPillow = Offset(0.86, 0.558);
  static const catBedJumpDown = Offset(0.70, 0.75);
}

abstract final class LivingRoomPositions {
  static const idlePositionA = Offset(0.42, 0.715);
  static const idlePositionB = Offset(0.52, 0.725);
  static const idlePositionC = Offset(0.64, 0.715);
  static const returnPosition = idlePositionB;

  /// The big window on the left: its glass, and the sill the cat sits on.
  static const windowGlass = Rect.fromLTRB(0.07, 0.17, 0.33, 0.455);
  static const sillY = 0.476;

  /// The long curtain right of the window, which the cat hides behind.
  static const curtainLeft = 0.325;
  static const curtainRight = 0.42;
  static const curtainTop = 0.14;

  /// The girl stands in the middle of the room.
  static const girlPosition = Offset(0.60, 0.65);

  /// The goldfish bowl on its little stool, by the sofa.
  static const fishBowlPosition = Offset(0.86, 0.70);

  // Fish bowl.
  static const catAtBowl = Offset(0.745, 0.725);
  static const bowlSplash = Offset(0.85, 0.63);

  // Purr.
  static const purrLeft = Offset(0.53, 0.70);
  static const purrRight = Offset(0.67, 0.70);
  static const purrMarks = Offset(0.60, 0.62);

  // Window.
  static const catBelowWindow = Offset(0.40, 0.72);
  static const catOnSill = Offset(0.22, 0.476);
  static const catJumpDown = Offset(0.42, 0.72);
  static const catBehindCurtain = Offset(0.375, 0.642);
  static const birdSpawn = Offset(1.08, 0.22);
  static const birdNearWindow = Offset(0.44, 0.29);
  static const birdAtCat = Offset(0.31, 0.38);
  static const birdExit = Offset(1.12, 0.05);
}

abstract final class ParkPositions {
  static const idlePositionA = Offset(0.32, 0.725);
  static const idlePositionB = Offset(0.42, 0.73);
  static const idlePositionC = Offset(0.52, 0.72);
  static const returnPosition = idlePositionB;

  /// The pond on the right (centre, and half-width / half-height).
  static const pondCenter = Offset(0.80, 0.712);
  static const pondRadius = Size(0.2, 0.045);

  /// The bench at the back, and the leaf pile at the front left.
  static const benchLeft = 0.24;
  static const benchRight = 0.52;
  static const benchSeatY = 0.585;
  static const leafPilePosition = Offset(0.15, 0.768);
  static const lampPosition = Offset(0.58, 0.632);

  // Ducks.
  static const catAtPond = Offset(0.56, 0.725);
  static const catStartled = Offset(0.44, 0.73);
  static const duckSpawn = Offset(1.06, 0.705);
  static const duckNear = Offset(0.67, 0.708);
  static const duckExit = Offset(1.08, 0.715);
  static const quackAt = Offset(0.64, 0.66);

  // Leaf pile.
  static const catLeafRunStart = Offset(0.38, 0.73);
  static const catInLeaves = Offset(0.16, 0.762);
  static const catOutOfLeaves = Offset(0.28, 0.73);

  // Pigeon on the bench.
  static const pigeonOnBench = Offset(0.40, 0.585);
  static const pigeonExit = Offset(-0.12, 0.08);
  static const catSneakStart = Offset(0.56, 0.725);
  static const catSneakEnd = Offset(0.46, 0.72);
  static const catOnBench = Offset(0.36, 0.586);
}

/// Sprite sizes (widths) as fractions of [GameLayout.unit].
abstract final class GameSizes {
  static const cat = 0.25;
  static const bowl = 0.17;
  static const yarn = 0.085;
  static const mouse = 0.10;
  static const bird = 0.085;
  static const butterfly = 0.075;
  static const brush = 0.13;
  static const towel = 0.21;
  static const tub = 0.42;
  static const glass = 0.05;
  static const treat = 0.065;
  static const fish = 0.11;
  static const plate = 0.15;
  static const wardrobe = 0.27;
  static const pillow = 0.14;
  static const girl = 0.21;
  static const fishBowl = 0.22;
  static const duck = 0.11;
  static const pigeon = 0.085;
  static const leafPile = 0.22;
  static const actionButtonWidth = 0.29;
  static const actionButtonHeight = 0.14;
  static const navBarHeight = 0.145;
  static const navBarWidth = 0.88;
  static const cornerButton = 0.11;

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

enum WanderAction { pause, lick, walk, sniff }

class WanderStep {
  const WanderStep.pause(this.seconds)
      : action = WanderAction.pause,
        target = null;
  const WanderStep.lick()
      : action = WanderAction.lick,
        seconds = 0,
        target = null;
  const WanderStep.sniff(this.seconds)
      : action = WanderAction.sniff,
        target = null;
  const WanderStep.walk(Offset this.target)
      : action = WanderAction.walk,
        seconds = 0;

  final WanderAction action;
  final double seconds;
  final Offset? target;
}
