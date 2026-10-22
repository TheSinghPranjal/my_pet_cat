import 'package:flutter/animation.dart';

import '../../animations/cat_animations.dart';
import '../../cats/cat_needs.dart';
import '../../cats/reaction.dart';
import '../../models/cat_game_state.dart';
import '../../models/game_positions.dart';
import '../../scripting/script_step.dart';
import 'park_keys.dart';

/// The park's three things: a duck that quacks too loud, a big leaf pile,
/// and a pigeon on the bench. Every bird swims or flies off happily.
abstract final class ParkScripts {
  static final duckPond = ActivityScript(
    firstPhase: CatGameState.busy,
    needs: const {Need.fun: 16},
    steps: [
      // Crouched at the water's edge, watching...
      const WalkTo(ParkPositions.catAtPond, endFacing: 1, endPose: CatPose.crouch),
      const Spawn('duck', ObjectKind.duck, ParkPositions.duckSpawn, facing: -1, focus: true),
      const Appear('duck'),
      const MoveProp('duck', ParkPositions.duckNear, 2.4, curve: Curves.easeOut),
      const Wait(0.5),

      // QUACK! The cat leaps back, startled.
      const SetProp('duck', progress: 1),
      const Effect(EffectKind.quack, ParkPositions.quackAt, duration: 0.9),
      Parallel([
        const React(1.0, outcome: ReactionOutcome.nope),
        Sequence([
          const Pose(CatPose.surprised),
          const MoveCat(ParkPositions.catStartled, 0.45, curve: Curves.easeOut, arc: 12),
        ]),
      ]),
      const SetProp('duck', progress: 0),
      const Wait(0.4),
      const SetProp('duck', progress: 1),
      const Effect(EffectKind.quack, ParkPositions.quackAt, duration: 0.7),
      const Wait(0.35),
      const SetProp('duck', progress: 0),

      // The duck paddles off, happy as anything.
      const MoveProp('duck', ParkPositions.duckExit, 2.2, curve: Curves.easeIn),
      const Remove('duck'),
      const Pose(CatPose.sit, 0.8),
      const Mark(CatMark.question, 0.8),

      const Phase(CatGameState.returningToIdle),
      const WalkTo(ParkPositions.returnPosition),
    ],
  );

  static final leafPile = ActivityScript(
    firstPhase: CatGameState.busy,
    needs: const {Need.fun: 20, Need.cleanliness: -6},
    steps: [
      const WalkTo(ParkPositions.catLeafRunStart, endFacing: -1, endPose: CatPose.crouch),
      const Pose(CatPose.crouch, 0.5),
      // A run-up and a big leap into the pile!
      const Pose(CatPose.walk),
      const MoveCat(ParkPositions.catOutOfLeaves, 0.35),
      const Pounce(ParkPositions.catInLeaves, height: 22, seconds: 0.55),
      const SetValue(ParkKeys.leafScatter, 1),
      const Effect(EffectKind.leafBurst, Offset(0.15, 0.75), duration: 2.6),
      const Effect(EffectKind.sparkles, Offset(0, -0.1), nearCat: true, duration: 1.4),
      const Pose(CatPose.happy, 1.4),
      const Turn(1),
      const Pounce(ParkPositions.catOutOfLeaves, height: 12, seconds: 0.5),
      const Pose(CatPose.idle),

      const Phase(CatGameState.returningToIdle),
      // The leaves settle back into a pile.
      const Parallel([TweenValue(ParkKeys.leafScatter, 0, 1.2), WalkTo(ParkPositions.returnPosition)]),
    ],
  );

  static final benchPigeon = ActivityScript(
    firstPhase: CatGameState.busy,
    needs: const {Need.fun: 16, Need.energy: -6},
    steps: [
      const Spawn('pigeon', ObjectKind.pigeon, ParkPositions.pigeonOnBench, focus: true),
      const Appear('pigeon'),
      // Sneaking up, low and slow...
      const WalkTo(ParkPositions.catSneakStart, endFacing: -1, endPose: CatPose.crouch),
      const Wait(0.5),
      const MoveCat(ParkPositions.catSneakEnd, 1.8, curve: Curves.easeInOutSine),
      const Wait(0.5),

      // Pounce onto the bench! The pigeon flutters away, coo-coo.
      Parallel([
        const Pounce(ParkPositions.catOnBench, height: 14, seconds: 0.55),
        after(
          0.2,
          const Sequence([
            SetProp('pigeon', airborne: true),
            MoveProp('pigeon', ParkPositions.pigeonExit, 1.5, curve: Curves.easeIn),
          ]),
        ),
      ]),
      const Pose(CatPose.lookUp, 1.0),
      const Remove('pigeon'),
      const Pose(CatPose.sit, 0.8),
      const Turn(1),
      const Pounce(ParkPositions.catSneakEnd, height: 8, seconds: 0.45),

      const Phase(CatGameState.returningToIdle),
      const WalkTo(ParkPositions.returnPosition),
    ],
  );
}
