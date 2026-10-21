import 'package:flutter/animation.dart';

import '../../cats/cat_needs.dart';
import '../../models/cat_game_state.dart';
import '../../models/game_positions.dart';
import '../../models/game_timings.dart';
import '../../scripting/script_step.dart';

/// The 1.x Home activities (the living area's first three things).
abstract final class HomeScripts {
  static void _eatFromBowl(SpawnedObject bowl, PropStart _, double t) => bowl.fill = 1 - 0.8 * t;

  static ScriptStep _rollYarn(Offset to, Duration duration) => MoveProp(
    'yarn',
    to,
    sec(duration),
    curve: Curves.easeOutCubic,
    faceMovement: false,
    rollRadius: GameSizes.yarnRadiusNormalized,
  );

  static final feed = ActivityScript(
    firstPhase: CatGameState.walkingToFood,
    needs: const {Need.hunger: -35, Need.affection: 3},
    steps: [
      const Spawn('bowl', ObjectKind.bowl, HomePositions.bowlPosition),
      const Appear('bowl'),
      const WalkTo(HomePositions.feedingPosition, endFacing: -1),
      const Phase(CatGameState.eating),
      const Pose(CatPose.eat),
      PropAnim('bowl', 'eat', sec(GameTimings.eating), _eatFromBowl),
      const Pose(CatPose.happy),
      Parallel([Wait(sec(GameTimings.happy)), const PopAway('bowl')]),
      const Phase(CatGameState.returningFromFood),
      const WalkTo(HomePositions.returnPosition),
    ],
  );

  static final play = ActivityScript(
    firstPhase: CatGameState.walkingToToy,
    needs: const {Need.fun: 20, Need.energy: -5},
    steps: [
      const Spawn('yarn', ObjectKind.yarn, HomePositions.yarnStartPosition, focus: true),
      const Appear('yarn'),
      const WalkTo(HomePositions.playPosition, endFacing: 1, endPose: CatPose.play),
      const Phase(CatGameState.playing),
      // 1. The ball rolls away to the right while the kitten watches it.
      _rollYarn(HomePositions.yarnWaypoints[0], GameTimings.yarnRollOut),
      // 2. The kitten scoots after it.
      const WalkTo(HomePositions.chasePosition, endPose: CatPose.play),
      // 3. The ball rolls a little way back.
      _rollYarn(HomePositions.yarnWaypoints[1], GameTimings.yarnRollBack),
      // 4. Two paw swipes; the second bats the ball to its resting spot.
      const SwipePaw(),
      Parallel([const SwipePaw(), _rollYarn(HomePositions.yarnEndPosition, GameTimings.yarnSettle)]),
      const Pose(CatPose.happy),
      Parallel([Wait(sec(GameTimings.happy)), const PopAway('yarn')]),
      const Phase(CatGameState.returningFromPlay),
      const WalkTo(HomePositions.returnPosition),
    ],
  );

  static final catchMouse = ActivityScript(
    firstPhase: CatGameState.catchingMouse,
    needs: const {Need.fun: 20, Need.energy: -8},
    steps: [
      // The mouse peeks out of its hole and sniffs around.
      const Spawn('mouse', ObjectKind.mouse, HomePositions.mouseSpawnPosition, focus: true),
      const Puff(HomePositions.mouseSpawnPosition),
      const Appear('mouse'),
      Wait(sec(GameTimings.mouseSniff)),

      // The kitten sneaks closer and crouches.
      const WalkTo(HomePositions.catMouseApproachPosition, endFacing: -1, endPose: CatPose.crouch),
      const Wait(0.6),

      // The mouse scurries A -> B -> C; the kitten follows fixed pursuit spots.
      const MoveProp('mouse', HomePositions.mouseWaypointA, 0.5),
      Parallel([
        const MoveProp('mouse', HomePositions.mouseWaypointB, 0.55),
        WalkTo(HomePositions.catMousePursuitPositions[0], endFacing: -1, endPose: CatPose.crouch),
      ]),
      Parallel([
        const MoveProp('mouse', HomePositions.mouseWaypointC, 0.5),
        WalkTo(HomePositions.catMousePursuitPositions[1], endFacing: -1, endPose: CatPose.crouch),
      ]),
      const Wait(0.35),

      // Pounce! The mouse darts home just in time.
      Parallel([
        const Pounce(HomePositions.catMousePounceTarget),
        after(0.12, const MoveProp('mouse', HomePositions.mouseFinalPosition, 0.4, curve: Curves.easeIn)),
      ]),
      const Puff(HomePositions.mouseFinalPosition),
      const Pose(CatPose.surprised),
      const PopAway('mouse'),

      // Where did it go? Look around and blink.
      const Wait(0.3),
      const Turn(1),
      const Wait(0.45),
      const Turn(-1),
      const Wait(0.5),

      const Phase(CatGameState.returningToIdle),
      const WalkTo(HomePositions.catMouseReturnPosition),
    ],
  );
}
