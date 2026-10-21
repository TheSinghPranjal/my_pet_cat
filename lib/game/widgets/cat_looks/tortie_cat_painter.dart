import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../sketch/sketch.dart';
import 'cat_anatomy.dart';

/// Pepper: a black-and-brown tortoiseshell with one bent ear and amber
/// eyes. Her patches are fixed blobs (same seeds every frame), clipped to
/// the body and head.
class TortieCatPainter extends CatAnatomy {
  TortieCatPainter({required super.frame, required super.facing});

  static const _chestnut = Color(0xFF8E522B);
  static const _caramel = Color(0xFFC47D3E);
  static const _umber = Color(0xFF5C3826);

  static const _coat = CatCoat(
    fur: Color(0xFF332829),
    farFur: Color(0xFF281F20),
    line: Color(0xFF85736A),
    faceLine: Color(0xFFAE9A8E),
    mouthLine: Color(0xFFC4AFA2),
    whisker: Color(0xFFB4A49A),
    shade: Color(0xFFA48C80),
    bodyShade: 0.5,
    headShade: 0.45,
    blush: 0.2,
    tuft: Color(0xFF6A4630),
  );

  /// Body patches: centre as fractions of the body box, size, tilt,
  /// colour, seed. Pairs overlap so they read as irregular mottling.
  static const _bodyPatches = [
    (0.3, 0.22, 20.0, 9.0, -0.3, _chestnut, 81),
    (0.42, 0.3, 12.0, 8.0, 0.4, _chestnut, 82),
    (0.7, 0.2, 14.0, 7.0, 0.2, _caramel, 83),
    (0.86, 0.6, 9.0, 14.0, 0.1, _caramel, 84),
    (0.5, 0.78, 18.0, 7.0, 0.0, _umber, 85),
    (0.14, 0.6, 9.0, 10.0, -0.5, _chestnut, 86),
  ];

  @override
  CatCoat get coat => _coat;

  @override
  CatEyes get eyes => const CatEyes(iris: Color(0xFFE3922A), glow: Color(0xFFF8D06E));

  @override
  EarStyle get earStyle => EarStyle.bent;

  void _blob(SketchPen pen, Offset c, double w, double h, Color color, int seed, {double tilt = 0}) {
    final oval = ovalPath(
      Offset.zero,
      w,
      h,
    ).transform((Matrix4.translationValues(c.dx, c.dy, 0)..rotateZ(tilt)).storage);
    final blob = pen.wobbly(oval, amplitude: 1.6, seed: seed);
    pen.fill(blob, color.withValues(alpha: 0.9));
    pen.hatch(blob, _umber.withValues(alpha: 0.45), spacing: 1.1, angle: -0.9, width: 0.35, seed: seed);
  }

  /// Short caramel pencil flecks scattered over [area] (fixed seed).
  void _flecks(SketchPen pen, Rect area, int count, int seed) {
    final rnd = math.Random(seed);
    for (var i = 0; i < count; i++) {
      final p = Offset(area.left + area.width * rnd.nextDouble(), area.top + area.height * rnd.nextDouble());
      final a = -0.9 + rnd.nextDouble() * 0.5;
      final len = 1.2 + rnd.nextDouble() * 1.6;
      pen.line(p, p + Offset(math.cos(a), math.sin(a)) * len, _caramel, width: 0.7, sketchy: false, wobble: 0);
    }
  }

  @override
  void paintBodyMarks(SketchPen pen, Rect body) {
    for (final (fx, fy, w, h, tilt, color, seed) in _bodyPatches) {
      _blob(pen, Offset(body.left + body.width * fx, body.top + body.height * fy), w, h, color, seed, tilt: tilt);
    }
    _flecks(pen, body, 26, 89);
  }

  @override
  void paintHeadInside(SketchPen pen, Offset hc) {
    // The classic split face: caramel over one eye, chestnut on the other cheek.
    _blob(pen, hc + const Offset(-10, -6), 16, 14, _caramel, 86, tilt: 0.3);
    _blob(pen, hc + const Offset(15, 4), 9, 12, _chestnut, 87, tilt: -0.2);
    _blob(pen, hc + const Offset(3, -15), 9, 5, _chestnut, 88);
    _flecks(pen, Rect.fromCenter(center: hc + const Offset(4, -6), width: 30, height: 14), 10, 90);
  }

  @override
  void paintTailMarks(SketchPen pen, Path tail) {
    // Brindled: short caramel and chestnut dashes along the tail.
    final metric = tail.computeMetrics().first;
    for (var i = 0; i < 14; i++) {
      final t = metric.getTangentForOffset(metric.length * (0.18 + i * 0.058))!;
      final n = Offset(-t.vector.dy, t.vector.dx) * (i.isEven ? 1.1 : -0.9);
      final along = t.vector * 1.4;
      pen.line(
        t.position + n - along,
        t.position + n + along,
        i % 3 == 0 ? _chestnut : _caramel,
        width: 1.3,
        sketchy: false,
        wobble: 0,
      );
    }
  }

  @override
  void paintLegMarks(SketchPen pen, int i, Offset hip, Offset foot, {required bool far}) {
    if (far || i != 3) return;
    pen.fill(ovalPath(Offset.lerp(hip, foot, 0.45)!, 5.2, 6), _caramel);
  }
}
