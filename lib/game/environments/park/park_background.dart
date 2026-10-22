import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../models/day_phase.dart';
import '../../models/game_positions.dart';
import '../../sketch/sketch.dart';
import '../../widgets/day_sky.dart';
import '../../widgets/scene_background.dart';

/// A sunny town park: open sky for the time of day, a row of trees, a path,
/// a wooden bench, a lamp post (lit in the evening and at night), and a duck
/// pond with reeds and lily pads. The leaf pile, ducks and pigeon are props.
class ParkPainter extends SceneBackgroundPainter {
  ParkPainter(super.unit, {super.phase});

  @override
  bool get outdoors => true;

  static const _water = Color(0xFFBFE2F7);
  static const _sand = Color(0xFFF3E2C0);

  @override
  void paintScene(Canvas canvas, SketchPen pen, double w, double h) {
    final groundY = h * SceneMetrics.groundLine;
    DaySky.open(pen, w, groundY, phase, seed: 70);
    _treeLine(pen, w, groundY);
    ground(pen, w, h, shade: SketchColors.leaf, line: SketchColors.leafDark, seed: 71);
    _path(pen, w, h, groundY);
    _bigTree(pen, w * 0.07, groundY);
    _bench(pen, w, h);
    _lamp(pen, w, h);
    _pond(pen, w, h);
  }

  /// Round trees and bushes along the back of the park.
  void _treeLine(SketchPen pen, double w, double groundY) {
    final rnd = math.Random(72);
    for (var x = 18.0; x < w; x += 14 + rnd.nextDouble() * 6) {
      final r = 5 + rnd.nextDouble() * 3;
      final crown = ovalPath(Offset(x, groundY - r - 2), r * 2.2, r * 2);
      pen.line(Offset(x, groundY), Offset(x, groundY - r), SketchColors.kibbleDark, width: 1.0, sketchy: false);
      pen.fill(crown, const Color(0xFFBFE3B4));
      pen.hatch(crown, SketchColors.leaf, spacing: 1.3, seed: 73 + x.toInt());
      pen.stroke(crown, SketchColors.leafDark, width: 0.7, seed: 74 + x.toInt());
    }
  }

  void _path(SketchPen pen, double w, double h, double groundY) {
    final bottom = h * SceneMetrics.groundBottom;
    final path = Path()
      ..moveTo(w * 0.36, groundY + 0.6)
      ..lineTo(w * 0.42, groundY + 0.6)
      ..quadraticBezierTo(w * 0.40, (groundY + bottom) / 2, w * 0.62, bottom)
      ..lineTo(w * 0.30, bottom)
      ..quadraticBezierTo(w * 0.30, (groundY + bottom) / 2, w * 0.36, groundY + 0.6)
      ..close();
    pen.fill(path, _sand);
    pen.hatch(path, SketchColors.wood.withValues(alpha: 0.4), spacing: 1.6, angle: -0.2, seed: 75);
    pen.stroke(path, SketchColors.wood, width: 0.6, seed: 76);
  }

  void _bigTree(SketchPen pen, double x, double groundY) {
    final trunk = polygon([
      Offset(x - 2.5, groundY),
      Offset(x - 1.5, groundY - 30),
      Offset(x + 2, groundY - 30),
      Offset(x + 3, groundY),
    ]);
    pen.fill(trunk, SketchColors.woodLight);
    pen.hatch(trunk, SketchColors.kibble, spacing: 1.1, seed: 77);
    pen.stroke(trunk, SketchColors.kibbleDark, width: 0.9, seed: 78);
    var crown = Path();
    for (final (c, r) in [
      (Offset(x - 6, groundY - 36), 9.0),
      (Offset(x + 3, groundY - 44), 11.0),
      (Offset(x + 10, groundY - 34), 8.0),
    ]) {
      crown = Path.combine(PathOperation.union, crown, Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    }
    // Autumn colours, where the leaf pile comes from.
    pen.fill(crown, const Color(0xFFFFD9A0));
    pen.hatch(crown, SketchColors.coral, spacing: 1.2, seed: 79, cross: true);
    pen.stroke(crown, SketchColors.kibbleDark, width: 1.0, seed: 80);
  }

  void _bench(SketchPen pen, double w, double h) {
    final left = w * ParkPositions.benchLeft, right = w * ParkPositions.benchRight;
    final seat = h * ParkPositions.benchSeatY;
    final floor = h * SceneMetrics.groundLine;
    for (final x in [left + 3, right - 4]) {
      pen.line(Offset(x, seat), Offset(x, floor), SketchColors.pencil, width: 1.2, sketchy: false);
    }
    for (final (i, y) in [seat - 9, seat - 5.5].indexed) {
      final slat = rectPath(left + 1, y, right - 1, y + 2.2);
      pen.fill(slat, SketchColors.wood);
      pen.stroke(slat, SketchColors.ink, width: 0.6, seed: 81 + i);
    }
    final board = rectPath(left, seat, right, seat + 2.4);
    pen.fill(board, SketchColors.wood);
    pen.hatch(board, SketchColors.kibbleDark.withValues(alpha: 0.4), spacing: 1.0, seed: 83);
    pen.stroke(board, SketchColors.ink, width: 0.8, seed: 84);
    for (final x in [left + 3, right - 4]) {
      pen.line(Offset(x, seat - 9), Offset(x, seat), SketchColors.pencil, width: 1.0, sketchy: false);
    }
  }

  void _lamp(SketchPen pen, double w, double h) {
    final base = Offset(w * ParkPositions.lampPosition.dx, h * ParkPositions.lampPosition.dy);
    final top = base + const Offset(0, -38);
    final lit = phase == DayPhase.evening || phase == DayPhase.night;
    if (lit) {
      for (final (r, a) in const [(14.0, 0.18), (9.0, 0.28)]) {
        pen.fill(ovalPath(top + const Offset(0, 2), r * 2, r * 2), SketchColors.sun.withValues(alpha: a));
      }
    }
    pen.line(base, top + const Offset(0, 4), SketchColors.pencil, width: 1.4, sketchy: false);
    final lantern = polygon([
      top + const Offset(-3, 0),
      top + const Offset(3, 0),
      top + const Offset(2.2, 5),
      top + const Offset(-2.2, 5),
    ]);
    pen.fill(lantern, lit ? SketchColors.sun : SketchColors.white);
    pen.stroke(lantern, SketchColors.pencil, width: 0.8, sketchy: false);
    pen.fill(
      polygon([top + const Offset(-4, 0), top + const Offset(0, -3), top + const Offset(4, 0)]),
      SketchColors.pencil,
    );
  }

  void _pond(SketchPen pen, double w, double h) {
    final c = Offset(w * ParkPositions.pondCenter.dx, h * ParkPositions.pondCenter.dy);
    final rx = w * ParkPositions.pondRadius.width, ry = h * ParkPositions.pondRadius.height;
    final pond = ovalPath(c, rx * 2, ry * 2);
    pen.fill(pond, _water);
    pen.hatch(pond, SketchColors.inkSoft.withValues(alpha: 0.5), spacing: 1.4, angle: -0.15, seed: 85);
    pen.stroke(pond, SketchColors.ink, width: 0.9, seed: 86);
    // Rim stones.
    final rnd = math.Random(87);
    for (var a = 0.2; a < math.pi * 2; a += 0.5) {
      final p = c + Offset(math.cos(a) * rx * 1.03, math.sin(a) * ry * 1.08);
      final stone = ovalPath(p, 3 + rnd.nextDouble() * 1.5, 1.8);
      pen.fill(stone, SketchColors.graphite.withValues(alpha: 0.5));
      pen.stroke(stone, SketchColors.pencil, width: 0.4, sketchy: false, wobble: 0.1);
    }
    // Lily pads and a flower.
    for (final (i, d) in const [Offset(-0.45, -0.1), Offset(0.35, 0.25), Offset(0.1, -0.35)].indexed) {
      final p = c + Offset(d.dx * rx, d.dy * ry);
      final pad = Path.combine(
        PathOperation.difference,
        ovalPath(p, 6, 2.6),
        polygon([p, p + const Offset(3.5, -1.6), p + const Offset(3.5, 1.6)]),
      );
      pen.fill(pad, SketchColors.leaf.withValues(alpha: 0.8));
      pen.stroke(pad, SketchColors.leafDark, width: 0.5, sketchy: false, seed: 88 + i);
    }
    pen.fill(ovalPath(c + Offset(0.35 * rx, 0.25 * ry - 1), 2, 1.6), SketchColors.pink);
    // Reeds at the far side.
    for (final x in [0.82, 0.86, 0.9]) {
      final base = Offset(w * x + 8, c.dy - ry * 0.6);
      pen.line(base, base + const Offset(-1, -9), SketchColors.leafDark, width: 0.7, sketchy: false);
      pen.fill(ovalPath(base + const Offset(-1, -8), 1.4, 3.6), SketchColors.kibble);
    }
  }
}
