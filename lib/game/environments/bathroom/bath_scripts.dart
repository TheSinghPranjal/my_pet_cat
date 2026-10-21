import 'dart:ui';

import '../../cats/cat_needs.dart';
import '../../models/cat_game_state.dart';
import '../../models/game_positions.dart';
import '../../models/game_timings.dart';
import '../../scripting/scene_state.dart';
import '../../scripting/script_step.dart';

/// The 1.x Bath activities (the bathroom's first three things).
abstract final class BathScripts {
  static double _foamIn(double t) => t;
  static double _foamOut(double t) => 1 - t;

  static ScriptStep _hop(Offset to) => Pounce(to, height: 20, seconds: sec(GameTimings.tubHop));

  static final bathTime = ActivityScript(
    firstPhase: CatGameState.walkingToBath,
    needs: const {Need.cleanliness: 35},
    steps: [
      const WalkTo(BathPositions.catBathEntryPosition, endFacing: -1),

      const Phase(CatGameState.bathing),
      // The tub fills with foam, then the kitten hops in.
      const Puff(BathPositions.bathBubbleSpawnPosition),
      SceneValue(SceneKeys.tubFoam, sec(GameTimings.foam), _foamIn),
      _hop(BathPositions.catBathPosition),

      const Pose(CatPose.relax),
      const Effect(EffectKind.bubbles, BathPositions.bathBubbleSpawnPosition),
      Effect(EffectKind.splash, BathPositions.catBathPosition + const Offset(0, -0.05)),
      Wait(sec(GameTimings.bath)),

      // Bubbles pop, the kitten hops back out.
      const Puff(BathPositions.bathBubbleSpawnPosition),
      const FadeEffects(),
      const Turn(1),
      _hop(BathPositions.catBathEntryPosition),
      const Pose(CatPose.idle),

      const Phase(CatGameState.returningToIdle),
      Parallel([
        SceneValue(SceneKeys.tubFoam, sec(GameTimings.foam), _foamOut),
        const WalkTo(BathPositions.catBathReturnPosition),
      ]),
    ],
  );

  static final brushFur = ActivityScript(
    firstPhase: CatGameState.brushing,
    needs: const {Need.cleanliness: 15, Need.affection: 8},
    steps: [
      const Spawn('brush', ObjectKind.brush, BathPositions.brushSpawnPosition, facing: -1, layerBias: 0.1),
      const Appear('brush'),

      // The kitten settles facing the brush, which hops over to its back.
      const WalkTo(BathPositions.catBrushPosition, endFacing: -1, endPose: CatPose.relax),
      const MoveProp('brush', BathPositions.brushStrokeStart, 0.6, arc: 0.06, faceMovement: false),

      const Effect(EffectKind.sparkles, BathPositions.brushSparklePosition),
      Repeat(
        GameTimings.brushStrokes,
        (i) => MoveProp(
          'brush',
          i.isEven ? BathPositions.brushStrokeEnd : BathPositions.brushStrokeStart,
          sec(GameTimings.brushStroke),
          faceMovement: false,
        ),
      ),

      const Parallel([PopAway('brush'), FadeEffects()]),
      Pose(CatPose.happy, sec(GameTimings.happy)),

      const Phase(CatGameState.returningToIdle),
      const WalkTo(BathPositions.catBrushReturnPosition),
    ],
  );

  static final towelDry = ActivityScript(
    firstPhase: CatGameState.drying,
    needs: const {Need.cleanliness: 10, Need.affection: 5},
    steps: [
      const WalkTo(BathPositions.catDryPosition, endFacing: 1, endPose: CatPose.sit),
      const Spawn('towel', ObjectKind.towel, BathPositions.towelSpawnPosition, layerBias: 0.1),
      const Appear('towel'),

      // Rub-a-dub: the towel moves up and down over the kitten's head.
      const Pose(CatPose.relax),
      Repeat(
        GameTimings.towelRubs,
        (i) =>
            MoveProp('towel', BathPositions.towelRubPositions[i % 2], sec(GameTimings.towelRub), faceMovement: false),
      ),
      const MoveProp('towel', BathPositions.towelSpawnPosition, 0.3, faceMovement: false),

      // A big shake sends droplets flying.
      const Pose(CatPose.shake),
      Effect(EffectKind.droplets, BathPositions.dropletsPosition, duration: sec(GameTimings.shake)),
      Wait(sec(GameTimings.shake)),

      const PopAway('towel'),
      Pose(CatPose.happy, sec(GameTimings.happy)),

      const Phase(CatGameState.returningToIdle),
      const WalkTo(BathPositions.catDryReturnPosition),
    ],
  );
}
