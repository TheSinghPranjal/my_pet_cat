import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../animations/object_animations.dart';
import '../../sketch/sketch.dart';

/// A white duck paddling on the pond, bobbing gently. Drawn in a 100x80 unit
/// box like the other critters, bottom-centre at the waterline, facing right.
class DuckPainter extends CustomPainter {
  DuckPainter({this.phase = 0, this.facing = 1, this.appear = 1, this.pop = 0, this.quacking = false});

  static const aspect = 100 / 80;

  final double phase;
  final double facing;
  final double appear;
  final double pop;

  /// Beak open mid-quack.
  final bool quacking;

  @override
  void paint(Canvas canvas, Size size) {
    paintSpawned(
      canvas,
      size,
      boxWidth: 100,
      appear: appear,
      pop: pop,
      facing: facing,
      popCenter: const Offset(50, 46),
      popRadius: 40,
      draw: _duck,
    );
  }

  void _duck(SketchPen pen) {
    final canvas = pen.canvas;
    canvas.save();
    canvas.translate(0, math.sin(phase * 3) * 1.6);
    // Ripples on the water.
    for (final (i, w) in const [60.0, 44.0].indexed) {
      pen.stroke(
        ovalPath(Offset(48, 76 + i * 2.5), w + math.sin(phase * 2 + i) * 4, 5),
        SketchColors.inkSoft,
        width: 1.0,
        sketchy: false,
        wobble: 0.3,
        seed: 601 + i,
      );
    }
    final body = Path()
      ..moveTo(18, 52)
      ..quadraticBezierTo(14, 40, 26, 44)
      ..quadraticBezierTo(46, 40, 66, 50)
      ..quadraticBezierTo(80, 58, 70, 72)
      ..quadraticBezierTo(46, 80, 24, 70)
      ..quadraticBezierTo(14, 62, 18, 52)
      ..close();
    pen.fill(body, SketchColors.white);
    pen.hatch(body, SketchColors.inkWash, spacing: 2.2, angle: -0.5, seed: 603);
    pen.stroke(body, SketchColors.ink, width: 1.4, seed: 604);
    final wing = Path()
      ..moveTo(32, 54)
      ..quadraticBezierTo(46, 46, 58, 58)
      ..quadraticBezierTo(46, 66, 32, 54)
      ..close();
    pen.fill(wing, const Color(0xFFF1F1F6));
    pen.stroke(wing, SketchColors.ink, width: 1.0, seed: 605);
    // Neck and head.
    final head = ovalPath(const Offset(70, 30), 24, 22);
    pen.tube(
      Path()
        ..moveTo(66, 52)
        ..quadraticBezierTo(72, 44, 70, 34),
      width: 12,
      outline: SketchColors.ink,
      fill: SketchColors.white,
      lineWidth: 1.2,
      seed: 606,
    );
    pen.fill(head, SketchColors.white);
    pen.stroke(head, SketchColors.ink, width: 1.3, seed: 607);
    final open = quacking ? 4.0 : 0.0;
    final upper = polygon([const Offset(80, 30), Offset(96, 30 - open * 0.4), const Offset(82, 35)]);
    final lower = polygon([const Offset(80, 35), Offset(94, 36 + open), const Offset(81, 38)]);
    for (final beak in [upper, lower]) {
      pen.fill(beak, SketchColors.sun);
      pen.stroke(beak, SketchColors.sunEdge, width: 1.0, sketchy: false, wobble: 0.1);
    }
    pen.fill(ovalPath(const Offset(73, 26), 5, 6), SketchColors.eye);
    pen.fill(ovalPath(const Offset(72, 24.5), 2, 2), SketchColors.white);
    pen.fill(ovalPath(const Offset(76, 32), 4.6, 2.6), SketchColors.pink.withValues(alpha: 0.6));
    canvas.restore();
  }

  @override
  bool shouldRepaint(DuckPainter old) =>
      old.phase != phase || old.facing != facing || old.appear != appear || old.pop != pop || old.quacking != quacking;
}

/// A heap of autumn leaves. [scatter] (0..1) flattens it after a leap.
/// Drawn in a 44x20 unit box, bottom-centre.
class LeafPilePainter extends CustomPainter {
  LeafPilePainter({this.scatter = 0});

  static const aspect = 44 / 20;

  final double scatter;

  static const _colors = [
    SketchColors.coral,
    SketchColors.sunEdge,
    SketchColors.wool,
    SketchColors.kibble,
    SketchColors.sun,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 44;
    final pen = SketchPen(canvas, pxPerUnit: k);
    canvas.save();
    canvas.scale(k);
    final height = 15 * (1 - 0.65 * scatter);
    final mound = Path()
      ..moveTo(1, 19.5)
      ..quadraticBezierTo(4, 19.5 - height, 22, 19.5 - height * 1.1)
      ..quadraticBezierTo(40, 19.5 - height, 43, 19.5)
      ..close();
    pen.fill(mound, const Color(0xFFF7C68A));
    canvas.save();
    canvas.clipPath(mound);
    final rnd = math.Random(611);
    for (var i = 0; i < 46; i++) {
      final c = Offset(2 + rnd.nextDouble() * 40, 19.5 - rnd.nextDouble() * height * 1.15);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(rnd.nextDouble() * math.pi);
      final leaf = Path()
        ..moveTo(-2.4, 0)
        ..quadraticBezierTo(0, -1.9, 2.4, 0)
        ..quadraticBezierTo(0, 1.9, -2.4, 0)
        ..close();
      pen.fill(leaf, _colors[i % _colors.length]);
      pen.stroke(leaf, SketchColors.kibbleDark, width: 0.3, sketchy: false, wobble: 0);
      canvas.restore();
    }
    canvas.restore();
    pen.stroke(mound, SketchColors.kibbleDark, width: 0.7, seed: 612);
    canvas.restore();
  }

  @override
  bool shouldRepaint(LeafPilePainter oldDelegate) => oldDelegate.scatter != scatter;
}

/// Navigation icon: a park bench under a little tree.
class ParkIconPainter extends CustomPainter {
  const ParkIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 40;
    final pen = SketchPen(canvas, pxPerUnit: k);
    canvas.save();
    canvas.scale(k);
    final crown = ovalPath(const Offset(29, 11), 16, 14);
    pen.fill(crown, const Color(0xFFD4EED0));
    pen.hatch(crown, SketchColors.leaf, spacing: 1.4, seed: 621);
    pen.stroke(crown, SketchColors.leafDark, width: 1.1, seed: 622);
    pen.line(const Offset(29, 18), const Offset(29, 34), SketchColors.kibbleDark, width: 2, sketchy: false);
    for (final y in const [21.0, 25.0]) {
      pen.line(Offset(3, y), Offset(24, y), color, width: 2.2, sketchy: false);
    }
    pen.line(const Offset(2, 29), const Offset(25, 29), color, width: 2.4, sketchy: false);
    for (final x in const [5.0, 22.0]) {
      pen.line(Offset(x, 29), Offset(x, 35), color, width: 1.8, sketchy: false);
    }
    pen.line(const Offset(1, 35.5), const Offset(39, 35.5), SketchColors.leafDark, width: 1.1);
    canvas.restore();
  }

  @override
  bool shouldRepaint(ParkIconPainter oldDelegate) => oldDelegate.color != color;
}
