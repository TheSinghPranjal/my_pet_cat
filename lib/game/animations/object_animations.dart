import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import '../sketch/sketch.dart';

/// Shared spawn / disappear curves for every prop and critter.
abstract final class ObjectAnimations {
  /// Scale while appearing: grows with a small overshoot.
  static double appearScale(double t) =>
      t >= 1 ? 1 : Curves.easeOutBack.transform(t.clamp(0.0, 1.0));

  /// Little hop while appearing, as a fraction of the prop height (up is -).
  static double appearLift(double t) => -math.sin(t.clamp(0.0, 1.0) * math.pi) * 0.25;

  /// Scale while popping: puffs up briefly, then shrinks to nothing.
  static double popScale(double t) {
    if (t <= 0) return 1;
    if (t < 0.25) return 1 + 0.18 * (t / 0.25);
    return 1.18 * (1 - Curves.easeIn.transform(((t - 0.25) / 0.75).clamp(0.0, 1.0)));
  }

  static double popOpacity(double t) => (1 - t * t).clamp(0.0, 1.0);
}

/// Paints a sprite drawn in a [boxWidth]-unit-wide box (facing right),
/// applying the shared appear/pop scale around its bottom-center, mirroring
/// for [facing], and drawing pop marks around [popCenter].
void paintSpawned(
  Canvas canvas,
  Size size, {
  required double boxWidth,
  required double appear,
  required double pop,
  required Offset popCenter,
  required double popRadius,
  required void Function(SketchPen pen) draw,
  double facing = 1,
  Color popColor = SketchColors.ink,
}) {
  final s = size.width / boxWidth;
  final boxHeight = size.height / s;
  final pen = SketchPen(canvas, pxPerUnit: s);
  canvas.save();
  canvas.scale(s);
  final scale = ObjectAnimations.appearScale(appear) * ObjectAnimations.popScale(pop);
  if (scale > 0.01) {
    canvas.save();
    canvas.translate(boxWidth / 2, boxHeight * (1 + ObjectAnimations.appearLift(appear)));
    canvas.scale(scale * (facing < 0 ? -1 : 1), scale);
    canvas.translate(-boxWidth / 2, -boxHeight);
    draw(pen);
    canvas.restore();
  }
  pen.popMarks(popCenter, popRadius, pop, popColor, width: boxWidth / 55);
  canvas.restore();
}
