import 'dart:math' as math;

import 'package:flutter/animation.dart';

import '../../animations/cat_animations.dart';
import '../../cats/cat_needs.dart';
import '../../cats/reaction.dart';
import '../../models/cat_game_state.dart';
import '../../models/game_positions.dart';
import '../../scripting/scene_state.dart';
import '../../scripting/script_step.dart';
import 'bedroom_keys.dart';
import 'girl_painter.dart';

/// The bedroom's three things: hide-and-seek in the wardrobe, a cheeky
/// chew on the charger cable, and bouncing on the pillow. The girl who
/// lives here joins in every one.
abstract final class BedroomScripts {
  static ScriptStep _mood(GirlMood mood) => SetValue(BedroomKeys.girlMood, BedroomKeys.mood(mood));
  static ScriptStep _gait(GirlGait gait) => SetValue(BedroomKeys.girlGait, BedroomKeys.gait(gait));
  static ScriptStep _face(double facing) => SetValue(BedroomKeys.girlFacing, facing);

  /// The girl walks (or runs) to [x] (offset from her spot), facing that way.
  static ScriptStep _girlTo(double x, double seconds, {required double facing, GirlGait gait = GirlGait.walk}) =>
      Sequence([_face(facing), _gait(gait), TweenValue(BedroomKeys.girlX, x, seconds), _gait(GirlGait.stand)]);

  static ScriptStep _door(double to, double seconds) =>
      TweenValue(BedroomKeys.wardrobeDoor, to, seconds, curve: Curves.easeOut);

  /// A little hop on the spot.
  static ScriptStep _hop(Offset at, {double height = 9}) => MoveCat(at, 0.38, curve: Curves.linear, arc: height);

  static double _squish(double t) => math.sin(t * math.pi) * 0.8;

  static final wardrobeHide = ActivityScript(
    firstPhase: CatGameState.busy,
    needs: const {Need.fun: 18, Need.affection: 6},
    steps: [
      // In she goes: the door swings open and she hops into the dark.
      const WalkTo(BedroomPositions.catWardrobeFront, endFacing: -1, endPose: CatPose.lookUp),
      _door(1, 0.5),
      const Pounce(BedroomPositions.catInWardrobe, height: 12, seconds: 0.5),
      const SetValue(SceneKeys.catHidden, 1),
      const SetValue(BedroomKeys.wardrobeEyes, 1),
      _door(0.55, 0.4),
      const Wait(0.5),

      // Where's kitty? The girl looks by the bed, then back the other way.
      _mood(GirlMood.searching),
      _girlTo(BedroomPositions.girlAtBed, 1.4, facing: 1),
      const Wait(0.7),
      _face(-1),
      const Wait(0.6),
      _girlTo(0, 1.1, facing: -1),
      _face(0),
      const Wait(0.6),

      // Those eyes in the wardrobe! She tiptoes over and opens the door.
      _face(-1),
      const Wait(0.5),
      _girlTo(BedroomPositions.girlAtWardrobe, 0.7, facing: -1),
      _door(1, 0.35),

      // Boo! Out jumps the cat.
      const SetValue(BedroomKeys.wardrobeEyes, 0),
      const SetValue(SceneKeys.catHidden, 0),
      _mood(GirlMood.surprised),
      const Pounce(BedroomPositions.catWardrobeJumpOut, height: 16, seconds: 0.55),
      const Turn(-1),
      const Effect(EffectKind.sparkles, Offset(0, -0.1), nearCat: true, duration: 1.2),
      Parallel([
        const Pose(CatPose.happy, 1.2),
        Sequence([const Wait(0.3), _mood(GirlMood.laughing)]),
      ]),

      // Close up and back to normal.
      const Phase(CatGameState.returningToIdle),
      _mood(GirlMood.happy),
      Parallel([_door(0, 0.4), _girlTo(0, 0.7, facing: 1)]),
      _face(0),
      const WalkTo(BedroomPositions.returnPosition),
    ],
  );

  static final chewCable = ActivityScript(
    firstPhase: CatGameState.busy,
    needs: const {Need.fun: 10, Need.energy: -5},
    steps: [
      // Ooh, a wiggly string...
      const WalkTo(BedroomPositions.catChewPosition, endFacing: 1, endPose: CatPose.sniff),
      const Wait(0.8),
      const SetValue(BedroomKeys.cableBite, 1),
      const Pose(CatPose.eat, 1.6),

      // Bzzt! A silly, harmless zap: fur on end, a couple of jolts.
      const SetValue(BedroomKeys.cableZap, 1),
      const SetValue(BedroomKeys.cableBite, 0),
      const Effect(EffectKind.zap, Offset(0, -0.06), nearCat: true, duration: 1.3),
      Parallel([
        const React(1.3, outcome: ReactionOutcome.nope),
        Sequence([
          const Pose(CatPose.shake),
          _hop(BedroomPositions.catChewPosition, height: 12),
          _hop(BedroomPositions.catChewPosition, height: 7),
          const Wait(0.54),
        ]),
        Sequence([const Wait(0.4), _mood(GirlMood.laughing)]),
      ]),
      const SetValue(BedroomKeys.cableZap, 0),

      // A dazed moment, then all okay.
      const Pose(CatPose.sit),
      const Mark(CatMark.question, 1.0),
      const Wait(0.6),
      _mood(GirlMood.happy),
      const Effect(EffectKind.sparkles, Offset(0, -0.1), nearCat: true, duration: 1.0),
      const Pose(CatPose.happy, 1.0),

      const Phase(CatGameState.returningToIdle),
      const WalkTo(BedroomPositions.returnPosition),
    ],
  );

  static final pillowJump = ActivityScript(
    firstPhase: CatGameState.busy,
    needs: const {Need.fun: 20, Need.energy: -8},
    steps: [
      // Up onto the bed and over to the big fluffy pillow.
      const WalkTo(BedroomPositions.catBedFoot, endFacing: 1, endPose: CatPose.crouch),
      const Wait(0.4),
      const Pounce(BedroomPositions.catOnBed, height: 22, seconds: 0.6),
      const Pose(CatPose.idle),
      const WalkTo(BedroomPositions.catBedMiddle, endFacing: 1, endPose: CatPose.crouch),
      const Pounce(BedroomPositions.catOnPillow, height: 12, seconds: 0.45),

      // Boing, boing! Feathers everywhere.
      const Effect(EffectKind.feathers, Offset(0.875, 0.55), duration: 2.4),
      Repeat(
        3,
        (_) => Parallel([
          const Pose(CatPose.happy),
          _hop(BedroomPositions.catOnPillow, height: 10),
          SceneValue(BedroomKeys.pillowSquish, 0.38, _squish),
        ]),
      ),

      // The girl is NOT amused. She runs over; the cat skips away along
      // the bed, she runs back after it...
      _mood(GirlMood.furious),
      const Pose(CatPose.play, 0.5),
      _girlTo(0.14, 0.8, facing: 1, gait: GirlGait.run),
      const Mark(CatMark.exclaim, 0.3),
      const Turn(-1),
      Parallel([
        const Pounce(BedroomPositions.catOnBed, height: 10, seconds: 0.5),
        Sequence([const Wait(0.2), _girlTo(0.06, 0.5, facing: -1, gait: GirlGait.run)]),
      ]),
      const Turn(1),
      Parallel([
        const Pounce(BedroomPositions.catBedMiddle, height: 10, seconds: 0.45),
        Sequence([const Wait(0.2), _girlTo(0.17, 0.6, facing: 1, gait: GirlGait.run)]),
      ]),

      // ...until the cat comes down from the bed, all innocent.
      const Turn(-1),
      const Pounce(BedroomPositions.catBedJumpDown, height: 12, seconds: 0.55),
      const Pose(CatPose.innocent),
      _face(-1),
      const Wait(1.0),
      _mood(GirlMood.happy),
      const Wait(0.6),

      const Phase(CatGameState.returningToIdle),
      Parallel([
        Sequence([_girlTo(0, 0.8, facing: -1), _face(0)]),
        const WalkTo(BedroomPositions.returnPosition),
      ]),
    ],
  );
}
