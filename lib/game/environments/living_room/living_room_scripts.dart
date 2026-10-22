import 'dart:math' as math;

import 'package:flutter/animation.dart';

import '../../animations/cat_animations.dart';
import '../../cats/cat_needs.dart';
import '../../cats/reaction.dart';
import '../../models/cat_game_state.dart';
import '../../models/game_positions.dart';
import '../../models/game_timings.dart';
import '../../scripting/scene_state.dart';
import '../../scripting/script_step.dart';
import '../girl/girl_painter.dart';
import '../girl/girl_steps.dart';
import 'living_room_keys.dart';

/// The living room's three things: fishing in the goldfish bowl, purring
/// against the girl, and watching birds at the window.
abstract final class LivingRoomScripts {
  static double _splash(double t) => math.sin(t * math.pi);

  static final fishBowl = ActivityScript(
    firstPhase: CatGameState.busy,
    needs: const {Need.fun: 16, Need.cleanliness: -4},
    steps: [
      // A fish! She watches it swim round and round...
      const WalkTo(LivingRoomPositions.catAtBowl, endFacing: 1, endPose: CatPose.lookUp),
      const Wait(1.2),
      const Pose(CatPose.crouch, 0.6),

      // ...then dips a paw in, three times. The fish is always quicker.
      Repeat(
        3,
        (i) => Sequence([
          const Pose(CatPose.swat),
          Parallel([
            const SwipePaw(),
            after(0.15, SceneValue(LivingRoomKeys.fishSplash, 0.45, _splash)),
            after(0.1, TweenValue(LivingRoomKeys.fishDodge, i.isEven ? 1 : -0.8, 0.3, curve: Curves.easeOut)),
            const Effect(EffectKind.droplets, LivingRoomPositions.bowlSplash, duration: 0.6),
          ]),
          const Pose(CatPose.lookUp, 0.5),
          TweenValue(LivingRoomKeys.fishDodge, 0, 0.6),
        ]),
      ),

      // Wet paw! Shake it off. The girl giggles.
      Girl.mood(GirlMood.laughing),
      const Pose(CatPose.shake),
      Effect(EffectKind.droplets, const Offset(0, -0.05), nearCat: true, duration: sec(GameTimings.shake)),
      Wait(sec(GameTimings.shake)),
      Girl.mood(GirlMood.happy),
      const Pose(CatPose.sit),
      const Mark(CatMark.question, 1.0),

      const Phase(CatGameState.returningToIdle),
      const WalkTo(LivingRoomPositions.returnPosition),
    ],
  );

  /// One rub along the girl's legs, from one side to the other.
  static ScriptStep _rub(Offset to, double facing) =>
      Sequence([Turn(facing), const Pose(CatPose.walk), MoveCat(to, 1.0, curve: Curves.easeInOutSine)]);

  static final purr = ActivityScript(
    firstPhase: CatGameState.busy,
    needs: const {Need.affection: 22},
    steps: [
      const WalkTo(LivingRoomPositions.purrLeft, endFacing: 1),
      Girl.mood(GirlMood.adoring),
      const Effect(EffectKind.purr, LivingRoomPositions.purrMarks, duration: 5.6),
      const Effect(EffectKind.hearts, Offset(0.60, 0.56), duration: 5.6),
      // Back and forth against her legs, eyes closed, purring away.
      Parallel([
        const React(5.4, outcome: ReactionOutcome.lovesIt),
        Sequence([
          _rub(LivingRoomPositions.purrRight, 1),
          _rub(LivingRoomPositions.purrLeft, -1),
          _rub(LivingRoomPositions.purrRight, 1),
          _rub(LivingRoomPositions.purrLeft, -1),
          const Turn(1),
          const Pose(CatPose.sit, 1.0),
        ]),
      ]),
      const Pose(CatPose.happy, 1.0),
      Girl.mood(GirlMood.happy),

      const Phase(CatGameState.returningToIdle),
      const WalkTo(LivingRoomPositions.returnPosition),
    ],
  );

  static final windowWatch = ActivityScript(
    firstPhase: CatGameState.busy,
    needs: const {Need.fun: 14, Need.energy: -6},
    steps: [
      // Up onto the sill to see what's outside.
      const WalkTo(LivingRoomPositions.catBelowWindow, endFacing: -1, endPose: CatPose.lookUp),
      const Wait(0.4),
      const Pounce(LivingRoomPositions.catOnSill, height: 24, seconds: 0.6),
      const Pose(CatPose.lookUp, 1.4),

      // A bird swoops right past the glass!
      const Spawn('bird', ObjectKind.bird, LivingRoomPositions.birdSpawn, facing: -1, airborne: true, focus: true),
      const Appear('bird'),
      const MoveProp('bird', LivingRoomPositions.birdNearWindow, 1.3, wobble: 0.015),
      Parallel([
        const MoveProp('bird', LivingRoomPositions.birdAtCat, 0.5, curve: Curves.easeIn),
        after(0.3, const Mark(CatMark.exclaim, 0.6)),
      ]),
      const Pose(CatPose.surprised),

      // Eek! Down she jumps and dives behind the curtain, while the bird
      // flies off happily.
      Parallel([
        const React(0.8, outcome: ReactionOutcome.nope),
        Sequence([
          const Turn(1),
          const Pounce(LivingRoomPositions.catJumpDown, height: 8, seconds: 0.45),
          const Turn(-1),
          const Pose(CatPose.walk),
          const MoveCat(LivingRoomPositions.catBehindCurtain, 0.35, arc: 4),
        ]),
        const MoveProp('bird', LivingRoomPositions.birdExit, 1.6, curve: Curves.easeIn),
      ]),
      const SetValue(SceneKeys.catHidden, 1),
      const SetValue(LivingRoomKeys.curtainLump, 1),
      const Remove('bird'),
      const Wait(1.6),

      // A careful peek... all clear.
      const SetValue(LivingRoomKeys.curtainPeek, 1),
      const Wait(1.4),
      const SetValue(LivingRoomKeys.curtainPeek, 0),
      const Wait(0.6),
      const SetValue(LivingRoomKeys.curtainLump, 0),
      const SetValue(SceneKeys.catHidden, 0),
      const Turn(1),
      const MoveCat(LivingRoomPositions.catJumpDown, 0.45, arc: 6),
      const Pose(CatPose.happy, 1.0),

      const Phase(CatGameState.returningToIdle),
      const WalkTo(LivingRoomPositions.returnPosition),
    ],
  );
}
