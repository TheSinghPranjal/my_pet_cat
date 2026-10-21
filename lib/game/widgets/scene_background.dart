import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../models/game_location.dart';
import '../models/game_positions.dart';
import '../sketch/sketch.dart';
import 'bath_background.dart';
import 'garden_background.dart';
import 'room_background.dart';

/// Warm notebook paper with a pale blue grid, covering the whole screen.
class GraphPaper extends StatelessWidget {
  const GraphPaper({super.key, required this.spacing});

  final double spacing;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(painter: _GraphPaperPainter(spacing), child: const SizedBox.expand()),
    );
  }
}

class _GraphPaperPainter extends CustomPainter {
  _GraphPaperPainter(this.spacing);

  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = SketchColors.paper);
    final grid = Paint()
      ..color = SketchColors.grid
      ..strokeWidth = 0.8;
    for (var x = spacing / 2; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = spacing / 2; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    // Faint paper grain.
    final rnd = math.Random(4);
    final grain = Paint()..color = SketchColors.graphite.withValues(alpha: 0.07);
    for (var i = 0; i < 500; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        0.4 + rnd.nextDouble() * 0.6,
        grain,
      );
    }
  }

  @override
  bool shouldRepaint(_GraphPaperPainter oldDelegate) => oldDelegate.spacing != spacing;
}

/// The static artwork for a location. Painted once per layout and cached
/// behind a [RepaintBoundary]; it never animates.
class GameBackground extends StatelessWidget {
  const GameBackground({super.key, required this.location, required this.unit});

  final GameLocation location;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final painter = switch (location) {
      GameLocation.home => HomeRoomPainter(unit),
      GameLocation.bath => BathroomPainter(unit),
      GameLocation.outdoors => GardenPainter(unit),
    };
    return RepaintBoundary(
      child: CustomPaint(painter: painter, isComplex: true, child: const SizedBox.expand()),
    );
  }
}

/// Base for scene artwork. Draws in units where the ideal 9:16 stage is 100
/// units wide; pieces are anchored at normalized positions and sized in
/// units, so they keep their shape on any aspect ratio.
abstract class SceneBackgroundPainter extends CustomPainter {
  SceneBackgroundPainter(this.unit);

  final double unit;

  /// [w] and [h] are the stage size in units.
  void paintScene(Canvas canvas, SketchPen pen, double w, double h);

  @override
  void paint(Canvas canvas, Size size) {
    final k = unit / 100;
    final pen = SketchPen(canvas, pxPerUnit: k, weight: 0.6);
    canvas.save();
    canvas.scale(k);
    paintScene(canvas, pen, size.width / k, size.height / k);
    canvas.restore();
  }

  static void place(Canvas canvas, Offset at, void Function() draw) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    draw();
    canvas.restore();
  }

  /// Scribbled floor shading between the ground line and the floor bottom,
  /// plus the ground baseline.
  void ground(SketchPen pen, double w, double h, {required Color shade, required Color line, int seed = 7}) {
    final top = h * SceneMetrics.groundLine;
    final bottom = h * SceneMetrics.groundBottom;
    final rnd = math.Random(seed);
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.5;
    for (var i = 0; i < 260; i++) {
      final t = math.pow(rnd.nextDouble(), 1.6).toDouble();
      final y = top + 1.2 + (bottom - top) * t;
      final x = rnd.nextDouble() * w;
      final length = 4 + rnd.nextDouble() * 14;
      final tilt = (rnd.nextDouble() - 0.5) * 1.2;
      paint.color = shade.withValues(alpha: 0.6 * (1 - t * 0.65));
      pen.canvas.drawLine(Offset(x, y), Offset(x + length, y + tilt), paint);
    }
    pen.line(Offset(-2, top), Offset(w + 2, top), line, width: 1.0, wobble: 0.35, seed: 1);
    pen.line(Offset(-2, top + 0.9), Offset(w + 2, top + 0.9), shade,
        width: 0.5, wobble: 0.4, seed: 2, sketchy: false);
  }

  void leaf(SketchPen pen, Offset base, Offset tip, {required double width, required int seed}) {
    final dir = tip - base;
    final length = dir.distance;
    if (length == 0) return;
    final n = Offset(-dir.dy, dir.dx) / length;
    final mid = Offset.lerp(base, tip, 0.5)!;
    final shape = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(mid.dx + n.dx * width * 2, mid.dy + n.dy * width * 2, tip.dx, tip.dy)
      ..quadraticBezierTo(mid.dx - n.dx * width * 2, mid.dy - n.dy * width * 2, base.dx, base.dy)
      ..close();
    pen.fill(shape, SketchColors.leaf.withValues(alpha: 0.4));
    pen.hatch(shape, SketchColors.leaf, spacing: 0.7, angle: math.atan2(n.dy, n.dx) + 0.5,
        width: 0.4, seed: seed);
    pen.stroke(shape, SketchColors.leafDark, width: 0.55, wobble: 0.2, seed: seed);
    pen.line(base, Offset.lerp(base, tip, 0.85)!, SketchColors.leafDark,
        width: 0.35, sketchy: false, wobble: 0.1);
  }

  /// A small cloud doodle with its left baseline point at [o].
  void cloud(SketchPen pen, Offset o, double s, int seed) {
    final path = Path()
      ..moveTo(o.dx, o.dy)
      ..quadraticBezierTo(o.dx - 2 * s, o.dy - 3.5 * s, o.dx + 1.8 * s, o.dy - 3.9 * s)
      ..quadraticBezierTo(o.dx + 2.8 * s, o.dy - 7.5 * s, o.dx + 6.6 * s, o.dy - 6.1 * s)
      ..quadraticBezierTo(o.dx + 9.8 * s, o.dy - 7.3 * s, o.dx + 10.4 * s, o.dy - 3.5 * s)
      ..quadraticBezierTo(o.dx + 13.6 * s, o.dy - 2.9 * s, o.dx + 11.8 * s, o.dy)
      ..close();
    pen.fill(path, SketchColors.white);
    pen.stroke(path, SketchColors.ink, width: 0.75, seed: seed);
  }

  /// Sun disc with rays.
  void sun(SketchPen pen, Offset c, double r, int seed) {
    for (var i = 0; i < 10; i++) {
      final a = i / 10 * math.pi * 2;
      final d = Offset(math.cos(a), math.sin(a));
      pen.line(c + d * (r + 1.4), c + d * (r + 3.8), SketchColors.sunEdge, width: 0.7, sketchy: false);
    }
    final disc = ovalPath(c, r * 2, r * 2);
    pen.fill(disc, SketchColors.sun);
    pen.hatch(disc, SketchColors.sunEdge, spacing: 0.9, cross: true, seed: seed);
    pen.stroke(disc, SketchColors.sunEdge, width: 0.7, seed: seed);
  }

  @override
  bool shouldRepaint(SceneBackgroundPainter oldDelegate) =>
      oldDelegate.runtimeType != runtimeType || oldDelegate.unit != unit;
}
