import 'dart:math' as math;

import 'package:flutter/animation.dart';

import '../models/cat_game_state.dart';
import '../models/game_timings.dart';

enum CatMouth { smile, open, chew, tongue }

/// Everything the cat painter needs for one frame, in the cat's own 100x85
/// drawing units (facing right; the painter mirrors it for left).
class CatFrame {
  const CatFrame({
    this.breath = 1,
    this.bodyLift = 0,
    this.headOffset = Offset.zero,
    this.headTilt = 0,
    this.feet = _still,
    this.raisedPaw,
    this.tailAngle = 0,
    this.eyeOpen = 1,
    this.happyEyes = false,
    this.mouth = CatMouth.smile,
    this.gaze = 0,
    this.motionMarks = false,
    this.eatMarks = 0,
    this.sparkle = 0,
  });

  static const _still = [Offset.zero, Offset.zero, Offset.zero, Offset.zero];

  /// Vertical scale of the body (breathing).
  final double breath;

  /// Vertical offset of everything except the shadow; negative is up.
  final double bodyLift;
  final Offset headOffset;
  final double headTilt;

  /// Foot offsets: far back, near back, far front, near front.
  final List<Offset> feet;

  /// When set, the near front paw is lifted to this point.
  final Offset? raisedPaw;
  final double tailAngle;
  final double eyeOpen;
  final bool happyEyes;
  final CatMouth mouth;

  /// -1..1, where the pupils look (positive = the way the cat faces).
  final double gaze;
  final bool motionMarks;
  final double eatMarks;
  final double sparkle;
}

/// Resting spot of the near front paw, matching the painter's leg layout.
const nearFrontPawRest = Offset(65, 83.5);

double _ease(double t) => Curves.easeInOut.transform(t.clamp(0.0, 1.0));

/// Builds the cat's frame from the current pose and the game clock.
///
/// Ambient life (breathing, blinking, tail flicks) is derived from [time] so
/// it never needs its own timers.
CatFrame catFrameFor({
  required CatPose pose,
  required double time,
  required double poseTime,
  required double walkPhase,
  required double gaze,
  required double swipe,
}) {
  final breath = 1 + 0.022 * math.sin(time * 2.6);
  final blinkT = time % 3.8;
  final eyeOpen = blinkT < 0.16 ? 1 - math.sin(blinkT / 0.16 * math.pi) : 1.0;
  final flickT = time % 5.5;
  final flick = flickT < 0.6 ? math.sin(flickT / 0.6 * math.pi * 2) * 0.35 : 0.0;
  final tail = math.sin(time * 1.7) * 0.12 + flick;

  switch (pose) {
    case CatPose.idle:
      return CatFrame(
        breath: breath,
        headTilt: math.sin(time * 0.7) * 0.03,
        tailAngle: tail,
        eyeOpen: eyeOpen,
        gaze: gaze,
      );

    case CatPose.walk:
      final s = math.sin(walkPhase);
      final c = math.cos(walkPhase);
      final a = Offset(s * 4.5, -math.max(0, c) * 3);
      final b = Offset(-s * 4.5, -math.max(0, -c) * 3);
      return CatFrame(
        breath: breath,
        bodyLift: -(1 - math.cos(walkPhase * 2)) * 0.6,
        headOffset: Offset(0, s.abs() * 0.6),
        feet: [a, b, b, a],
        tailAngle: math.sin(walkPhase * 0.5) * 0.18 + 0.1,
        eyeOpen: eyeOpen,
        mouth: CatMouth.open,
        gaze: gaze,
        motionMarks: true,
      );

    case CatPose.lick:
      final total = GameTimings.lick.inMilliseconds / 1000;
      final raise = _ease(math.min(poseTime / 0.35, (total - poseTime) / 0.35));
      final lap = math.sin(poseTime * 12);
      return CatFrame(
        breath: breath,
        headOffset: Offset(1.5, 3) * raise,
        headTilt: 0.15 * raise,
        raisedPaw: Offset.lerp(nearFrontPawRest, const Offset(74, 55), raise)! +
            Offset(0, lap * 1.2 * raise),
        tailAngle: tail,
        eyeOpen: eyeOpen,
        happyEyes: raise > 0.5,
        mouth: raise > 0.5 && lap > 0 ? CatMouth.tongue : CatMouth.smile,
      );

    case CatPose.eat:
      final dip = _ease(poseTime / 0.4);
      final chew = math.sin(poseTime * 13);
      return CatFrame(
        breath: breath,
        headOffset: Offset(6 * dip, 18 * dip + chew * 1.0 * dip),
        headTilt: 0.22 * dip,
        tailAngle: math.sin(time * 2.2) * 0.2,
        happyEyes: dip > 0.5,
        mouth: chew > 0 ? CatMouth.chew : CatMouth.smile,
        eatMarks: dip * ((poseTime * 2) % 1 < 0.5 ? 1 : 0),
      );

    case CatPose.play:
      return CatFrame(
        breath: breath,
        bodyLift: 1.5,
        headOffset: const Offset(1, 1.5),
        raisedPaw: swipe > 0.01
            ? Offset.lerp(nearFrontPawRest, const Offset(86, 67), swipe)!
            : null,
        tailAngle: math.sin(time * 5) * 0.25,
        eyeOpen: eyeOpen,
        mouth: CatMouth.open,
        gaze: gaze,
      );

    case CatPose.happy:
      final hop = math.sin(poseTime * 8).abs() * 5 * math.max(0, 1 - poseTime / 1.2);
      return CatFrame(
        breath: breath,
        bodyLift: -hop,
        tailAngle: 0.35 + math.sin(poseTime * 10) * 0.2,
        happyEyes: true,
        mouth: CatMouth.tongue,
        sparkle: poseTime,
      );
  }
}
