import 'package:flutter/animation.dart';

import '../../cats/cat_needs.dart';
import '../../models/cat_game_state.dart';
import '../../models/game_positions.dart';
import '../../models/game_timings.dart';
import '../../scripting/script_step.dart';

/// The Outdoors garden: catch a bird, climb the tree, chase butterflies.
abstract final class OutdoorScripts {
  static final catchBird = ActivityScript(
    firstPhase: CatGameState.catchingBird,
    needs: const {Need.fun: 18, Need.energy: -8},
    steps: [
      const Spawn('bird', ObjectKind.bird, OutdoorPositions.birdSpawnPosition, facing: -1, focus: true),
      const Appear('bird'),

      // The kitten notices the bird, then sneaks up.
      const TurnToward(OutdoorPositions.birdSpawnPosition),
      const Pose(CatPose.lookUp, 0.6),
      const WalkTo(OutdoorPositions.catBirdStartPosition, endFacing: 1, endPose: CatPose.crouch),

      // The bird hops along its path; the kitten follows.
      const MoveProp('bird', OutdoorPositions.birdWaypointA, 0.55, arc: 0.07),
      const Parallel([
        MoveProp('bird', OutdoorPositions.birdWaypointB, 0.4, arc: 0.025),
        WalkTo(OutdoorPositions.catBirdPursuitPosition, endFacing: 1, endPose: CatPose.crouch),
      ]),
      const MoveProp('bird', OutdoorPositions.birdWaypointC, 0.4, arc: 0.025),
      const Wait(0.3),

      // It flutters up, the kitten pounces underneath, and the bird flies
      // away safely.
      const SetProp('bird', airborne: true),
      const MoveProp('bird', OutdoorPositions.birdFlutterPosition, 0.5, faceMovement: false),
      Parallel([
        const Sequence([Pounce(OutdoorPositions.catBirdPounceTarget, height: 18), Pose(CatPose.lookUp)]),
        after(0.15, const MoveProp('bird', OutdoorPositions.birdExitPosition, 1.3, curve: Curves.easeIn)),
      ]),
      const Remove('bird'),

      const Wait(0.6),
      const Pose(CatPose.sit, 0.9),

      const Phase(CatGameState.returningToIdle),
      const WalkTo(OutdoorPositions.catBirdReturnPosition),
    ],
  );

  static final climbTree = () {
    final climb = sec(GameTimings.climbSegment);
    return ActivityScript(
      firstPhase: CatGameState.climbingTree,
      needs: const {Need.fun: 20, Need.energy: -10},
      steps: [
        const WalkTo(OutdoorPositions.treeBasePosition, endFacing: -1, endPose: CatPose.lookUp),
        const Wait(0.8),

        // Up the trunk and onto the low branch.
        const Pose(CatPose.climb),
        MoveCat(OutdoorPositions.treeTrunkPosition, climb),
        const Turn(1),
        MoveCat(OutdoorPositions.treeLowBranchPosition, climb),
        const Pose(CatPose.sit, 0.5),

        // Higher, to the top branch.
        const Turn(-1),
        const Pose(CatPose.climb),
        MoveCat(OutdoorPositions.treeMiddleBranchPosition, climb),
        const Turn(1),
        MoveCat(OutdoorPositions.treeHighBranchPosition, climb),

        // Sit, look around happily while a few leaves drift down.
        const Pose(CatPose.sit),
        const Effect(EffectKind.leaves, OutdoorPositions.leafFallPosition),
        const Wait(0.9),
        const Turn(-1),
        const Wait(0.8),
        const Turn(1),
        Pose(CatPose.happy, sec(GameTimings.happy)),
        const FadeEffects(),

        // Back down the same way.
        const Turn(-1),
        const Pose(CatPose.climb),
        MoveCat(OutdoorPositions.treeMiddleBranchPosition, climb),
        MoveCat(OutdoorPositions.treeTrunkPosition, climb),
        MoveCat(OutdoorPositions.treeBasePosition, climb * 0.8),
        const Pose(CatPose.idle),

        const Phase(CatGameState.returningToIdle),
        const WalkTo(OutdoorPositions.treeClimbReturnPosition),
      ],
    );
  }();

  static final chaseButterflies = ActivityScript(
    firstPhase: CatGameState.chasingButterflies,
    needs: const {Need.fun: 18, Need.energy: -6},
    steps: const [
      Spawn('butterfly', ObjectKind.butterfly, OutdoorPositions.butterflySpawnPosition, airborne: true, focus: true),
      Appear('butterfly'),

      TurnToward(OutdoorPositions.butterflySpawnPosition),
      Pose(CatPose.lookUp, 0.6),
      WalkTo(OutdoorPositions.catButterflyStartPosition, endFacing: 1, endPose: CatPose.lookUp),

      // A looping flight; the kitten trots after it.
      Parallel([
        MoveProp('butterfly', OutdoorPositions.butterflyWaypointA, 1.0, wobble: 0.015),
        WalkTo(OutdoorPositions.catButterflyPursuitPosition, endFacing: 1, endPose: CatPose.lookUp),
      ]),
      MoveProp('butterfly', OutdoorPositions.butterflyWaypointB, 0.8, wobble: 0.012),
      MoveProp('butterfly', OutdoorPositions.butterflyWaypointC, 0.7, wobble: 0.01),

      // Two gentle swats; it flutters just out of reach.
      Pose(CatPose.swat),
      SwipePaw(),
      Parallel([
        SwipePaw(),
        MoveProp('butterfly', OutdoorPositions.butterflyFlutterPosition, 0.6, curve: Curves.easeOut),
      ]),
      Pose(CatPose.lookUp),
      MoveProp('butterfly', OutdoorPositions.butterflyExitPosition, 1.4, wobble: 0.02, curve: Curves.easeIn),
      Remove('butterfly'),

      Pose(CatPose.relax, 1.0),

      Phase(CatGameState.returningToIdle),
      WalkTo(OutdoorPositions.catButterflyReturnPosition),
    ],
  );
}
