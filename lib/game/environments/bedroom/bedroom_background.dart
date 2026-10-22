import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../models/game_positions.dart';
import '../../sketch/sketch.dart';
import '../../widgets/scene_background.dart';

/// The girl's bedroom: a sunny window with curtains, bunting, a cat poster,
/// a cosy bed with a heart quilt, the wall socket, and a round rug. The
/// wardrobe, pillow, cable and the girl herself are animated props drawn on
/// top.
class BedroomPainter extends SceneBackgroundPainter {
  BedroomPainter(super.unit, {super.phase});

  static const _lilac = Color(0xFFE6DCF7);
  static const _lilacDeep = Color(0xFF9C86D6);

  @override
  void paintScene(Canvas canvas, SketchPen pen, double w, double h) {
    void place(double x, double y, void Function() draw) =>
        SceneBackgroundPainter.place(canvas, Offset(x * w, y * h), draw);

    woodFloor(pen, w, h);
    _bunting(pen, w, h);
    place(0.35, 0.13, () => _window(pen));
    place(0.70, 0.30, () => _poster(pen));
    place(0.47, 0.745, () => _rug(pen));
    place(BedroomPositions.socketPosition.dx, BedroomPositions.socketPosition.dy, () => _socket(pen));
    place(0.56, 0.0, () => _bed(pen, w, h));
  }

  void _bunting(SketchPen pen, double w, double h) {
    final y = h * 0.055;
    final string = Path()
      ..moveTo(-1, y)
      ..quadraticBezierTo(w / 2, y + 7, w + 1, y);
    pen.stroke(string, SketchColors.ink, width: 0.6, seed: 401);
    const colors = [SketchColors.pink, SketchColors.sun, SketchColors.inkWash, _lilac];
    for (var i = 0; i < 9; i++) {
      final x = 6 + i * (w - 12) / 8;
      final t = x / w;
      final top = y + 14 * t * (1 - t) - 0.5;
      final flag = polygon([Offset(x - 3, top), Offset(x + 3, top), Offset(x, top + 6)]);
      pen.fill(flag, colors[i % 4]);
      pen.stroke(flag, SketchColors.ink, width: 0.5, sketchy: false, wobble: 0.15);
    }
  }

  void _window(SketchPen pen) {
    const width = 22.0, height = 30.0;
    final glass = rectPath(0, 0, width, height);
    windowSky(pen, const Rect.fromLTRB(0, 0, width, height), seed: 402);
    pen.stroke(glass, SketchColors.ink, width: 1.0, seed: 404);
    pen.line(const Offset(width / 2, 0), const Offset(width / 2, height), SketchColors.ink, width: 0.7);
    pen.line(const Offset(0, height / 2), const Offset(width, height / 2), SketchColors.ink, width: 0.7);
    final sill = rectPath(-2, height, width + 2, height + 2);
    pen.fill(sill, SketchColors.white);
    pen.stroke(sill, SketchColors.ink, width: 0.7, seed: 405);
    // Pink curtains tied back on both sides.
    for (final (i, side) in const [-1.0, 1.0].indexed) {
      final edge = side < 0 ? -1.0 : width + 1;
      final curtain = Path()
        ..moveTo(edge, -2)
        ..lineTo(edge - side * 5, -2)
        ..quadraticBezierTo(edge - side * 6, height * 0.5, edge - side * 3, height + 4)
        ..quadraticBezierTo(edge + side * 1.2, height * 0.6, edge + side * 2, -2)
        ..close();
      pen.fill(curtain, SketchColors.pink.withValues(alpha: 0.75));
      pen.hatch(curtain, SketchColors.pinkDeep, spacing: 1.3, angle: 1.4, width: 0.4, seed: 406 + i);
      pen.stroke(curtain, SketchColors.pinkDeep, width: 0.7, seed: 408 + i);
    }
    pen.line(const Offset(-8, -2), const Offset(width + 8, -2), SketchColors.wood, width: 1.4, sketchy: false);
  }

  /// A framed doodle of a cat, above the bed.
  void _poster(SketchPen pen) {
    final frame = rectPath(0, 0, 16, 12);
    pen.fill(frame, SketchColors.white);
    pen.stroke(frame, SketchColors.wood, width: 1.3, seed: 410);
    final head = ovalPath(const Offset(8, 7), 7, 5.6);
    pen.stroke(head, SketchColors.ink, width: 0.6, sketchy: false, wobble: 0.2);
    pen.stroke(
      polygon(const [Offset(5, 5.2), Offset(5.4, 2.6), Offset(7, 4.4)]),
      SketchColors.ink,
      width: 0.6,
      sketchy: false,
    );
    pen.stroke(
      polygon(const [Offset(9, 4.4), Offset(10.6, 2.6), Offset(11, 5.2)]),
      SketchColors.ink,
      width: 0.6,
      sketchy: false,
    );
    pen.fill(ovalPath(const Offset(6.6, 6.8), 0.9, 1.1), SketchColors.ink);
    pen.fill(ovalPath(const Offset(9.4, 6.8), 0.9, 1.1), SketchColors.ink);
    pen.star(const Offset(13.4, 3), 1.2, SketchColors.sunEdge, width: 0.5);
  }

  void _rug(SketchPen pen) {
    final outer = ovalPath(Offset.zero, 50, 11);
    final inner = ovalPath(Offset.zero, 36, 7);
    pen.fill(outer, _lilac);
    pen.hatch(Path.combine(PathOperation.difference, outer, inner), _lilacDeep, spacing: 1.0, angle: -0.5, seed: 411);
    pen.fill(inner, SketchColors.coralLight);
    pen.hatch(inner, SketchColors.pink, spacing: 1.3, seed: 412, cross: true);
    pen.stroke(outer, _lilacDeep, width: 0.8, seed: 413);
  }

  void _socket(SketchPen pen) {
    final plate = Path()..addRRect(RRect.fromLTRBR(-2.4, -2.4, 2.4, 3.4, const Radius.circular(0.8)));
    pen.fill(plate, SketchColors.white);
    pen.stroke(plate, SketchColors.ink, width: 0.6, sketchy: false, wobble: 0.1);
  }

  /// The bed, from its low footboard on the left to the tall headboard on
  /// the right, with the mattress top where the cat walks and the pillow
  /// (an animated prop) rests.
  void _bed(SketchPen pen, double w, double h) {
    final floor = h * SceneMetrics.groundLine + 0.5;
    final top = h * BedroomPositions.catOnBed.dy + 0.4;
    final right = w * (0.995 - 0.56);
    // Headboard.
    final headboard = Path()..addRRect(RRect.fromLTRBR(right - 6, h * 0.44, right, floor, const Radius.circular(3)));
    pen.fill(headboard, SketchColors.woodLight);
    pen.hatch(headboard, SketchColors.wood, spacing: 1.3, angle: -1.2, seed: 420);
    pen.stroke(headboard, SketchColors.ink, width: 0.9, seed: 421);
    // Mattress and the base under it.
    final base = rectPath(0, top + 7, right - 5, floor - 2);
    pen.fill(base, SketchColors.wood);
    pen.hatch(base, SketchColors.kibbleDark.withValues(alpha: 0.5), spacing: 1.1, seed: 422);
    pen.stroke(base, SketchColors.ink, width: 0.8, seed: 423);
    for (final x in [2.0, right - 9]) {
      final leg = rectPath(x, floor - 2.2, x + 2.4, floor + 0.6);
      pen.fill(leg, SketchColors.kibbleDark);
    }
    final mattress = Path()..addRRect(RRect.fromLTRBR(1, top, right - 5, top + 7.5, const Radius.circular(2.5)));
    pen.fill(mattress, SketchColors.white);
    pen.stroke(mattress, SketchColors.ink, width: 0.8, seed: 424);
    // Quilt draped over the foot end, with a hem and hearts.
    final quiltRight = right * 0.72;
    final quilt = Path()
      ..moveTo(-0.5, top - 0.6)
      ..lineTo(quiltRight, top - 0.6)
      ..quadraticBezierTo(quiltRight + 2, top + 5, quiltRight, top + 11.5)
      ..lineTo(-0.5, top + 11.5)
      ..close();
    pen.fill(quilt, _lilac);
    pen.hatch(quilt, _lilacDeep.withValues(alpha: 0.7), spacing: 1.3, angle: -0.7, seed: 425);
    final rnd = math.Random(426);
    for (var i = 0; i < 5; i++) {
      final c = Offset(3 + i * quiltRight / 5 + rnd.nextDouble() * 2, top + 4 + (i.isEven ? 0 : 3));
      final heart = Path()
        ..moveTo(c.dx, c.dy + 1.4)
        ..cubicTo(c.dx - 2, c.dy, c.dx - 1.2, c.dy - 1.6, c.dx, c.dy - 0.6)
        ..cubicTo(c.dx + 1.2, c.dy - 1.6, c.dx + 2, c.dy, c.dx, c.dy + 1.4)
        ..close();
      pen.fill(heart, SketchColors.pinkDeep.withValues(alpha: 0.75));
    }
    pen.stroke(quilt, SketchColors.ink, width: 0.9, seed: 427);
    pen.line(Offset(-0.5, top + 10), Offset(quiltRight + 0.6, top + 10), _lilacDeep, width: 0.6, sketchy: false);
    // Low footboard.
    final footboard = Path()..addRRect(RRect.fromLTRBR(-2.5, top - 2.5, 1, floor, const Radius.circular(1.2)));
    pen.fill(footboard, SketchColors.woodLight);
    pen.hatch(footboard, SketchColors.wood, spacing: 1.2, angle: -1.2, seed: 428);
    pen.stroke(footboard, SketchColors.ink, width: 0.8, seed: 429);
  }
}
