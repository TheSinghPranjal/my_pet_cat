import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// Shared spawn / disappear curves for the bowl and the wool ball.
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
