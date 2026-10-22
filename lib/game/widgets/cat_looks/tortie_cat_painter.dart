import 'package:flutter/widgets.dart';

import '../../sketch/sketch.dart';
import 'cat_anatomy.dart';

/// Pepper: a calico that is mostly white (about 60%), with big orange
/// patches (about 30%), a few light-brown spots (about 10%) and amber eyes.
/// Her patches are fixed blobs (same seeds every frame), clipped to the body
/// and head.
class TortieCatPainter extends CatAnatomy {
  TortieCatPainter({required super.frame, required super.facing});

  static const _orange = Color(0xFFEE9442);
  static const _lightBrown = Color(0xFFC49A72);

  static const _coat = CatCoat(
    fur: Color(0xFFFFFBF4),
    farFur: Color(0xFFF1EBE2),
    line: Color(0xFF4A3B33),
    shade: Color(0xFFB8A898),
  );

  /// Body patches: centre as fractions of the body box, size, tilt,
  /// colour, seed. Pairs overlap so they read as irregular patches.
  static const _bodyPatches = [
    (0.3, 0.22, 22.0, 12.0, -0.3, _orange, 81),
    (0.44, 0.3, 14.0, 9.0, 0.4, _orange, 82),
    (0.8, 0.3, 16.0, 12.0, 0.2, _orange, 83),
    (0.62, 0.62, 7.0, 5.0, 0.1, _lightBrown, 84),
    (0.16, 0.6, 8.0, 6.0, -0.5, _lightBrown, 85),
  ];

  @override
  CatCoat get coat => _coat;

  @override
  CatEyes get eyes => const CatEyes(iris: Color(0xFFE3922A), glow: Color(0xFFF8D06E));

  void _blob(SketchPen pen, Offset c, double w, double h, Color color, int seed, {double tilt = 0}) {
    final oval = ovalPath(
      Offset.zero,
      w,
      h,
    ).transform((Matrix4.translationValues(c.dx, c.dy, 0)..rotateZ(tilt)).storage);
    final blob = pen.wobbly(oval, amplitude: 1.6, seed: seed);
    pen.fill(blob, color.withValues(alpha: 0.92));
    pen.hatch(
      blob,
      const Color(0xFFB8641E).withValues(alpha: 0.35),
      spacing: 1.1,
      angle: -0.9,
      width: 0.35,
      seed: seed,
    );
  }

  @override
  void paintBodyMarks(SketchPen pen, Rect body) {
    for (final (fx, fy, w, h, tilt, color, seed) in _bodyPatches) {
      _blob(pen, Offset(body.left + body.width * fx, body.top + body.height * fy), w, h, color, seed, tilt: tilt);
    }
  }

  @override
  void paintHeadInside(SketchPen pen, Offset hc) {
    // The classic calico face: orange over one eye, a light-brown spot on
    // the other side of the crown, white muzzle.
    _blob(pen, hc + const Offset(-11, -9), 17, 13, _orange, 86, tilt: 0.3);
    _blob(pen, hc + const Offset(12, -13), 9, 6, _lightBrown, 87, tilt: -0.2);
  }

  @override
  void paintTailMarks(SketchPen pen, Path tail) {
    // Orange rings along the tail, with the odd light-brown one.
    final metric = tail.computeMetrics().first;
    for (var i = 0; i < 14; i++) {
      final t = metric.getTangentForOffset(metric.length * (0.18 + i * 0.058))!;
      final n = Offset(-t.vector.dy, t.vector.dx) * (i.isEven ? 1.1 : -0.9);
      final along = t.vector * 1.4;
      pen.line(
        t.position + n - along,
        t.position + n + along,
        i % 4 == 3 ? _lightBrown : _orange,
        width: 1.3,
        sketchy: false,
        wobble: 0,
      );
    }
  }

  @override
  void paintLegMarks(SketchPen pen, int i, Offset hip, Offset foot, {required bool far}) {
    if (far || i != 0) return;
    // One orange patch high on a front leg.
    pen.fill(ovalPath(Offset.lerp(hip, foot, 0.3)!, 5.2, 6), _orange);
  }
}
