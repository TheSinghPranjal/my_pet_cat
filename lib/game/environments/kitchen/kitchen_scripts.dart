import 'dart:math' as math;

import 'package:flutter/animation.dart';

import '../../animations/cat_animations.dart';
import '../../cats/cat_needs.dart';
import '../../models/cat_game_state.dart';
import '../../models/game_positions.dart';
import '../../models/game_timings.dart';
import '../../scripting/scene_state.dart';
import '../../scripting/script_step.dart';

/// The 1.x Kitchen activities (the kitchen's glass, treat jar and stove).
abstract final class KitchenScripts {
  static void _tapWobble(SpawnedObject glass, PropStart _, double t) => glass.rotation = math.sin(t * math.pi) * 0.25;
  static void _tipOver(SpawnedObject glass, PropStart _, double t) => glass.rotation = 0.35 * t;
  static void _tumble(SpawnedObject glass, PropStart _, double t) => glass.rotation = 0.35 + 1.2 * t;
  static void _land(SpawnedObject glass, PropStart _, double t) => glass.rotation = 1.55 + 0.05 * t;
  static void _eat(SpawnedObject food, PropStart _, double t) => food.fill = 1 - t;
  static void _cook(SpawnedObject fish, PropStart _, double t) => fish.progress = t;

  static double _rattle(double t) => math.sin(t * math.pi * 6).abs() * 0.04;
  static double _doorOpen(double t) => Curves.easeOut.transform(t);
  static double _doorClose(double t) => 1 - t;

  static final glassTrouble = () {
    final fall = sec(GameTimings.glassFall);
    final tap = sec(GameTimings.glassTap);
    return ActivityScript(
      firstPhase: CatGameState.glassTrouble,
      needs: const {Need.fun: 15},
      steps: [
        const Spawn('glass', ObjectKind.glass, KitchenPositions.glassSpawnPosition),

        // A. Notice the counter, trot over and look up.
        const TurnToward(KitchenPositions.glassCounterApproachPosition),
        const Pose(CatPose.lookUp),
        const Mark(CatMark.exclaim, 0.7),
        const WalkTo(KitchenPositions.glassCounterApproachPosition, endFacing: -1, endPose: CatPose.lookUp),
        const Wait(0.5),

        // B. Up the cabinet front and onto the counter.
        const Phase(CatGameState.glassClimbing),
        const Pose(CatPose.climb),
        const MoveCat(KitchenPositions.glassClimbPositionA, 0.6),
        const MoveCat(KitchenPositions.glassClimbPositionB, 0.6),
        const Turn(1),
        const Pounce(KitchenPositions.glassCounterIdlePosition, height: 6, seconds: 0.4),
        const Pose(CatPose.idle),

        // C. A glass! Look, lean in, tap it twice.
        const Phase(CatGameState.glassInvestigating),
        const Focus('glass'),
        const Appear('glass'),
        const Pose(CatPose.sniff, 0.8),
        const Pose(CatPose.swat),
        Parallel([const SwipePaw(), after(0.2, PropAnim('glass', 'wobble', tap, _tapWobble))]),
        Parallel([
          const SwipePaw(),
          after(0.2, MoveProp('glass', KitchenPositions.glassEdgePosition, tap, faceMovement: false)),
          after(0.2, PropAnim('glass', 'tip', tap, _tipOver)),
        ]),

        // D. Over the edge along a fixed path, a soft bonk, and a puff.
        const Phase(CatGameState.glassFalling),
        const Pose(CatPose.lookDown),
        MoveProp('glass', KitchenPositions.glassFallWaypointA, fall * 0.25, faceMovement: false),
        Parallel([
          MoveProp(
            'glass',
            KitchenPositions.glassFallWaypointB,
            fall * 0.35,
            curve: Curves.easeIn,
            faceMovement: false,
          ),
          PropAnim('glass', 'tumble', fall * 0.35, _tumble),
        ]),
        Parallel([
          MoveProp(
            'glass',
            KitchenPositions.glassLandingPosition,
            fall * 0.4,
            curve: Curves.easeIn,
            faceMovement: false,
          ),
          PropAnim('glass', 'land', fall * 0.4, _land),
        ]),
        const Effect(EffectKind.impact, KitchenPositions.glassLandingPosition, duration: 0.6),
        const Phase(CatGameState.glassReaction),
        const Pose(CatPose.surprised),
        // A harmless little bounce, then it vanishes in a puff (no shards).
        const MoveProp('glass', KitchenPositions.glassLandingPosition, 0.3, arc: 0.02, faceMovement: false),
        const Puff(KitchenPositions.glassLandingPosition),
        const PopAway('glass'),
        const Pose(CatPose.lookDown, 0.6),

        // E. Who, me?
        const Pose(CatPose.innocent, 1.6),
        const Phase(CatGameState.returningToIdle),
        const Turn(-1),
        const Pounce(KitchenPositions.glassHopDownPosition, height: 14),
        const Pose(CatPose.idle),
        const WalkTo(KitchenPositions.glassCatReturnPosition),
      ],
    );
  }();

  static final treatTime = () {
    final door = sec(GameTimings.cabinetDoor);
    final satisfied = sec(GameTimings.satisfied);
    const scratchMarks = 'scratchMarks';
    return ActivityScript(
      firstPhase: CatGameState.treatTime,
      needs: const {Need.hunger: -15, Need.fun: 8},
      steps: [
        // A. Sniff out the right cabinet.
        const WalkTo(KitchenPositions.treatCabinetApproachPosition, endFacing: -1, endPose: CatPose.sniff),
        Effect(
          EffectKind.aroma,
          KitchenPositions.treatCabinetDoorPosition + const Offset(0.05, -0.07),
          duration: sec(GameTimings.sniff),
        ),
        Wait(sec(GameTimings.sniff)),
        const Pose(CatPose.idle),
        const Mark(CatMark.exclaim, 0.5),

        // B. Scratch, sniff, scratch; the cabinet rattles a little.
        const Phase(CatGameState.treatScratching),
        const WalkTo(KitchenPositions.treatScratchPosition, endFacing: -1),
        Repeat(
          GameTimings.scratchBursts,
          (i) => Sequence([
            const Pose(CatPose.scratch),
            Effect(
              EffectKind.scratches,
              KitchenPositions.treatCabinetDoorPosition + const Offset(0.02, -0.07),
              id: scratchMarks,
            ),
            SceneValue(SceneKeys.cabinetOpen, sec(GameTimings.scratchBurst), _rattle),
            const RemoveEffects(ids: [scratchMarks]),
            if (i < GameTimings.scratchBursts - 1) const Pose(CatPose.sniff, 0.5),
          ]),
        ),

        // C. The door creaks open and a treat pops out.
        const Phase(CatGameState.treatRevealing),
        const Pose(CatPose.idle),
        SceneValue(SceneKeys.cabinetOpen, door, _doorOpen),
        const Spawn('treat', ObjectKind.treat, KitchenPositions.treatSpawnPosition, layerBias: 0.02, focus: true),
        const Appear('treat'),
        const MoveProp('treat', KitchenPositions.treatRevealPosition, 0.5, arc: 0.03, faceMovement: false),
        Effect(EffectKind.sparkles, KitchenPositions.treatRevealPosition + const Offset(0, -0.02)),
        const Pose(CatPose.surprised),
        const Effect(EffectKind.hearts, Offset(0.02, -0.13), nearCat: true, duration: 1.0),
        const Wait(0.8),

        // D. Nom.
        const Phase(CatGameState.treatEating),
        const Parallel([
          WalkTo(KitchenPositions.treatEatingPosition, endFacing: -1),
          MoveProp('treat', KitchenPositions.treatServePosition, 0.5, faceMovement: false),
        ]),
        const Pose(CatPose.eat),
        PropAnim('treat', 'eat', sec(GameTimings.treatEating), _eat),
        const Remove('treat'),
        const RemoveEffects(all: true),
        const Pose(CatPose.satisfied),
        Effect(EffectKind.hearts, const Offset(0, -0.13), nearCat: true, duration: satisfied),
        Wait(satisfied),

        // E. Close up and head back.
        const Phase(CatGameState.returningToIdle),
        SceneValue(SceneKeys.cabinetOpen, door, _doorClose),
        const WalkTo(KitchenPositions.treatCatReturnPosition),
      ],
    );
  }();

  static final fishySurprise = () {
    final sniff = sec(GameTimings.sniff);
    final cook = sec(GameTimings.fishCooking);
    final satisfied = sec(GameTimings.satisfied);
    return ActivityScript(
      firstPhase: CatGameState.fishySurprise,
      needs: const {Need.hunger: -30, Need.affection: 5},
      steps: [
        // A. Something smells good...
        const Phase(CatGameState.fishSniffing),
        const WalkTo(KitchenPositions.fishCatStartPosition),
        const Effect(EffectKind.aroma, KitchenPositions.fishAromaPosition, id: 'aroma'),
        Pose(CatPose.sniff, sniff),
        const TurnToward(KitchenPositions.fishPanPosition),
        const Pose(CatPose.lookUp),
        const Mark(CatMark.exclaim, 0.6),
        const WalkTo(KitchenPositions.fishCatSniffPosition, endFacing: 1, endPose: CatPose.sniff),
        Wait(sniff),

        // B. Into the pan; watch from a safe spot.
        const Spawn('fish', ObjectKind.fish, KitchenPositions.fishRawSpawnPosition, focus: true),
        const Parallel([
          Appear('fish'),
          WalkTo(KitchenPositions.fishCatWatchPosition, endFacing: 1, endPose: CatPose.sit),
        ]),
        const MoveProp('fish', KitchenPositions.fishCookingPosition, 0.5, curve: Curves.easeIn, faceMovement: false),

        // C. Sizzle: steam, heat marks, a little timer; raw turns golden.
        const Phase(CatGameState.fishCooking),
        const RemoveEffects(ids: ['aroma']),
        const Effect(EffectKind.steam, KitchenPositions.fishAromaPosition, id: 'steam'),
        const Effect(EffectKind.heat, KitchenPositions.fishPanPosition, id: 'heat'),
        Effect(EffectKind.timer, KitchenPositions.fishTimerPosition, id: 'timer', duration: cook + 0.3),
        PropAnim('fish', 'cook', cook, _cook),
        const RemoveEffects(ids: ['heat', 'timer']),
        Effect(EffectKind.sparkles, KitchenPositions.fishCookingPosition + const Offset(0, -0.03)),
        const Pose(CatPose.happy, 0.6),

        // D. Onto a plate, and the plate onto the floor, away from the stove.
        const Phase(CatGameState.fishServing),
        const Spawn('plate', ObjectKind.plate, KitchenPositions.fishServingSpawnPosition, fill: 0),
        const Appear('plate'),
        const MoveProp('fish', KitchenPositions.fishServingSpawnPosition, 0.6, arc: 0.06, faceMovement: false),
        const Remove('fish'),
        const SetProp('plate', fill: 1), // The cooked fish now rides on the plate.
        const RemoveEffects(ids: ['steam'], kinds: [EffectKind.sparkles]),
        const Focus('plate'),
        const MoveProp('plate', KitchenPositions.fishServingMoveWaypoint, 0.45, faceMovement: false),
        const MoveProp('plate', KitchenPositions.fishServingPosition, 0.45, faceMovement: false),
        const Pose(CatPose.lookDown, 0.4),

        // E. Dinner.
        const Phase(CatGameState.fishEating),
        const WalkTo(KitchenPositions.fishCatEatingPosition, endFacing: -1),
        const Pose(CatPose.eat),
        PropAnim('plate', 'eat', sec(GameTimings.fishEating), _eat),
        const Pose(CatPose.satisfied),
        Effect(EffectKind.hearts, const Offset(0, -0.13), nearCat: true, duration: satisfied),
        Wait(satisfied),

        // F. One last sniff of the empty plate, a happy look, and back to idle.
        const Pose(CatPose.sniff, 0.8),
        const Pose(CatPose.happy),
        Parallel([Wait(sec(GameTimings.happy)), const PopAway('plate')]),
        const Phase(CatGameState.returningToIdle),
        const WalkTo(KitchenPositions.fishCatReturnPosition),
      ],
    );
  }();
}
