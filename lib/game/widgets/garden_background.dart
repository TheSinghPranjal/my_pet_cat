import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../models/game_positions.dart';
import '../sketch/sketch.dart';
import 'day_sky.dart';
import 'scene_background.dart';

/// The garden: notebook-paper sky, fence, grass, a bush and a climbable tree.
class GardenPainter extends SceneBackgroundPainter {
  GardenPainter(super.unit, {super.phase});

  @override
  bool get outdoors => true;

  @override
  void paintScene(Canvas canvas, SketchPen pen, double w, double h) {
    Offset at(double x, double y) => Offset(x * w, y * h);
    final groundY = h * SceneMetrics.groundLine;

    DaySky.open(pen, w, groundY, phase);

    _fence(pen, w, groundY);
    ground(pen, w, h, shade: SketchColors.leaf, line: SketchColors.leafDark, seed: 31);
    _grassTufts(pen, w, groundY, h * SceneMetrics.groundBottom);
    _stones(pen, at);
    _flowers(pen, at, groundY);
    _bush(pen, at, groundY);
    _tree(pen, at, w, h, groundY);
  }

  void _fence(SketchPen pen, double w, double groundY) {
    final top = groundY - 13;
    for (final y in [groundY - 10, groundY - 4]) {
      final rail = rectPath(-1, y - 0.8, w + 1, y + 0.8);
      pen.fill(rail, SketchColors.white);
      pen.stroke(rail, SketchColors.inkSoft, width: 0.5, sketchy: false, wobble: 0.2);
    }
    for (var x = 1.0; x < w; x += 7) {
      final picket = polygon([
        Offset(x, groundY),
        Offset(x, top + 1.6),
        Offset(x + 1.6, top),
        Offset(x + 3.2, top + 1.6),
        Offset(x + 3.2, groundY),
      ]);
      pen.fill(picket, SketchColors.white);
      pen.hatch(picket, SketchColors.inkWash, spacing: 1.2, seed: x.toInt());
      pen.stroke(picket, SketchColors.inkSoft, width: 0.55, seed: x.toInt(), sketchy: false);
    }
  }

  void _grassTufts(SketchPen pen, double w, double top, double bottom) {
    final rnd = math.Random(33);
    for (var i = 0; i < 70; i++) {
      final base = Offset(rnd.nextDouble() * w, top + 1 + rnd.nextDouble() * (bottom - top));
      final s = 0.8 + rnd.nextDouble() * 0.8;
      final color = i.isEven ? SketchColors.leafDark : SketchColors.leaf;
      for (final dx in const [-1.0, 0.0, 1.0]) {
        pen.line(base, base + Offset(dx * 1.2 * s, -2.6 * s + dx.abs() * 0.6), color,
            width: 0.45, sketchy: false, wobble: 0);
      }
    }
  }

  void _stones(SketchPen pen, Offset Function(double, double) at) {
    for (final (i, (x, y, sw)) in const [
      (0.30, 0.778, 6.0), (0.42, 0.787, 7.0), (0.55, 0.778, 6.0), (0.67, 0.787, 7.0), (0.80, 0.778, 6.0),
    ].indexed) {
      final stone = ovalPath(at(x, y), sw, sw * 0.42);
      pen.fill(stone, SketchColors.white);
      pen.hatch(stone, SketchColors.graphite, spacing: 0.9, seed: 70 + i);
      pen.stroke(stone, SketchColors.stripe, width: 0.6, seed: 70 + i);
    }
  }

  void _flowers(SketchPen pen, Offset Function(double, double) at, double groundY) {
    const colors = [SketchColors.pinkDeep, SketchColors.sun, SketchColors.wool, SketchColors.pink];
    for (final (i, x) in const [0.28, 0.35, 0.49, 0.57, 0.64].indexed) {
      final base = Offset(at(x, 0).dx, groundY + 1.5);
      final head = base + Offset(0.4, -7 - (i % 2) * 1.5);
      pen.line(base, head, SketchColors.leafDark, width: 0.5, sketchy: false);
      leaf(pen, base + const Offset(0, -2.5), base + const Offset(2.6, -4.2), width: 0.7, seed: 80 + i);
      final petal = colors[i % colors.length];
      for (var p = 0; p < 5; p++) {
        final a = p / 5 * math.pi * 2;
        final c = head + Offset(math.cos(a), math.sin(a)) * 1.5;
        pen.fill(ovalPath(c, 2, 2), petal.withValues(alpha: 0.8));
        pen.stroke(ovalPath(c, 2, 2), petal, width: 0.35, sketchy: false, wobble: 0);
      }
      pen.fill(ovalPath(head, 1.4, 1.4), i.isEven ? SketchColors.sunEdge : SketchColors.kibble);
    }
  }

  void _bush(SketchPen pen, Offset Function(double, double) at, double groundY) {
    final left = Offset(at(0.70, 0).dx, groundY + 1);
    final right = Offset(at(0.995, 0).dx, groundY + 1);
    final tops = [at(0.72, 0.60), at(0.78, 0.572), at(0.85, 0.565), at(0.92, 0.575), at(0.975, 0.60)];
    final bush = Path()..moveTo(left.dx, left.dy);
    var prev = left;
    for (final p in [...tops, right]) {
      final mid = Offset.lerp(prev, p, 0.5)!;
      final bulge = Offset(mid.dx, math.min(prev.dy, p.dy) - 3.2);
      bush.quadraticBezierTo(bulge.dx, bulge.dy, p.dx, p.dy);
      prev = p;
    }
    bush.close();
    pen.fill(bush, SketchColors.leaf.withValues(alpha: 0.35));
    pen.hatch(bush, SketchColors.leaf, spacing: 0.9, seed: 90, cross: true);
    pen.stroke(bush, SketchColors.leafDark, width: 0.8, seed: 90);
    for (final (x, y) in const [(0.76, 0.61), (0.83, 0.595), (0.9, 0.612), (0.95, 0.6)]) {
      pen.fill(ovalPath(at(x, y), 1.5, 1.5), SketchColors.pinkDeep);
    }
  }

  void _tree(SketchPen pen, Offset Function(double, double) at, double w, double h, double groundY) {
    final l = OutdoorPositions.trunkLeft * w;
    final r = OutdoorPositions.trunkRight * w;
    final top = h * 0.30;
    final trunk = Path()
      ..moveTo(l - 2.5, groundY + 1)
      ..quadraticBezierTo(l + 1.5, groundY - 3, l + 2, groundY - 10)
      ..lineTo(l + 3, top)
      ..lineTo(r - 3, top)
      ..lineTo(r - 2, groundY - 10)
      ..quadraticBezierTo(r - 1.5, groundY - 3, r + 2.5, groundY + 1)
      ..close();
    pen.fill(trunk, SketchColors.white);
    pen.hatch(trunk, SketchColors.kibble.withValues(alpha: 0.7), spacing: 1.2, angle: -1.3, seed: 100);
    final rnd = math.Random(101);
    for (var i = 0; i < 6; i++) {
      final x = l + 3.5 + rnd.nextDouble() * (r - l - 7);
      final y = top + 6 + rnd.nextDouble() * (groundY - top - 16);
      pen.line(Offset(x, y), Offset(x + 0.4, y + 5), SketchColors.kibbleDark, width: 0.5, sketchy: false);
    }
    pen.stroke(trunk, SketchColors.kibbleDark, width: 0.9, seed: 102);

    for (final (i, (start, end)) in [
      (OutdoorPositions.lowBranchStart, OutdoorPositions.lowBranchEnd),
      (OutdoorPositions.highBranchStart, OutdoorPositions.highBranchEnd),
    ].indexed) {
      final a = at(start.dx, start.dy);
      final b = at(end.dx, end.dy);
      final branch = polygon([a, b, b + const Offset(0.6, 1.4), a + const Offset(0, 3.8)]);
      pen.fill(branch, SketchColors.white);
      pen.hatch(branch, SketchColors.kibble.withValues(alpha: 0.7), spacing: 0.9, seed: 103 + i);
      pen.stroke(branch, SketchColors.kibbleDark, width: 0.8, seed: 103 + i);
      leaf(pen, b, b + const Offset(3, -2.6), width: 1.1, seed: 105 + i);
      leaf(pen, b + const Offset(-3, 0.3), b + const Offset(-1.5, 3.4), width: 1.0, seed: 107 + i);
    }

    // Canopy: a union of bumps.
    const blobs = [
      (0.06, 0.16, 10.0), (0.16, 0.09, 12.0), (0.28, 0.13, 11.0), (0.34, 0.22, 9.0),
      (0.24, 0.25, 10.0), (0.10, 0.26, 9.0), (0.17, 0.18, 12.0),
    ];
    var canopy = Path();
    for (final (x, y, radius) in blobs) {
      canopy = Path.combine(PathOperation.union, canopy,
          Path()..addOval(Rect.fromCircle(center: at(x, y), radius: radius)));
    }
    pen.fill(canopy, const Color(0xFFD4EED0));
    pen.hatch(canopy, SketchColors.leaf, spacing: 1.0, seed: 110, cross: true);
    pen.stroke(canopy, SketchColors.leafDark, width: 0.9, seed: 111);
    for (final (x, y) in const [(0.12, 0.2), (0.25, 0.17), (0.2, 0.26)]) {
      final apple = ovalPath(at(x, y), 2.6, 2.6);
      pen.fill(apple, SketchColors.wool);
      pen.stroke(apple, SketchColors.woolDark, width: 0.5, sketchy: false);
    }
  }
}
