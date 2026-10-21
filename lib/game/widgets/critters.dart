import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../animations/object_animations.dart';
import '../sketch/sketch.dart';

/// Little gray mouse (100x60 box, facing right). Sniffs and twitches its ear
/// while still; scurries while [moving].
class MousePainter extends CustomPainter {
  MousePainter({this.phase = 0, this.moving = false, this.facing = 1, this.appear = 1, this.pop = 0});

  static const aspect = 100 / 60;

  final double phase;
  final bool moving;
  final double facing;
  final double appear;
  final double pop;

  @override
  void paint(Canvas canvas, Size size) {
    paintSpawned(canvas, size,
        boxWidth: 100,
        appear: appear,
        pop: pop,
        facing: facing,
        popCenter: const Offset(50, 36),
        popRadius: 40,
        draw: _mouse);
  }

  void _mouse(SketchPen pen) {
    final canvas = pen.canvas;
    final run = moving ? math.sin(phase * 32) : 0.0;
    final sniff = moving ? 0.0 : math.sin(phase * 18);
    final twitch = !moving && phase % 1.2 < 0.25 ? math.sin(phase * 40) * 0.15 : 0.0;

    pen.hatch(ovalPath(const Offset(52, 57), 72, 6), SketchColors.inkSoft,
        spacing: 1.6, angle: -0.2, width: 0.6, seed: 1);
    pen.stroke(
      Path()
        ..moveTo(18, 46)
        ..cubicTo(4 + run * 3, 48, 0, 36, 8, 32)
        ..quadraticBezierTo(12, 29, 10 - run * 2, 25),
      SketchColors.pencil,
      width: 1.4,
      sketchy: false,
      wobble: 0.3,
    );
    for (final (x, sign) in const [(30.0, 1.0), (42.0, -1.0), (62.0, 1.0), (74.0, -1.0)]) {
      final foot = ovalPath(Offset(x + run * 3 * sign, 54), 8, 4);
      pen.fill(foot, const Color(0xFFF9D5DE));
      pen.stroke(foot, SketchColors.pencil, width: 0.8, sketchy: false, wobble: 0.1);
    }

    canvas.save();
    canvas.translate(0, -run.abs() * 1.2);
    final body = Path()
      ..moveTo(18, 50)
      ..cubicTo(14, 26, 50, 16, 72, 26)
      ..cubicTo(84, 31, 92, 40, 97, 46)
      ..cubicTo(88, 53, 40, 55, 18, 50)
      ..close();
    pen.fill(body, const Color(0xFFE6E6EA));
    pen.hatch(body, SketchColors.graphite.withValues(alpha: 0.6), spacing: 1.7, seed: 2);
    pen.stroke(body, SketchColors.pencil, width: 1.2, seed: 3);

    canvas.save();
    canvas.translate(64, 26);
    canvas.rotate(twitch);
    canvas.translate(-64, -26);
    final ear = ovalPath(const Offset(63, 19), 17, 17);
    pen.fill(ear, SketchColors.pink);
    pen.fill(ovalPath(const Offset(64, 20), 9, 9), SketchColors.pinkDeep.withValues(alpha: 0.6));
    pen.stroke(ear, SketchColors.pencil, width: 1.0, seed: 4);
    canvas.restore();

    pen.fill(ovalPath(const Offset(81, 35), 5, 5.6), SketchColors.eye);
    pen.fill(ovalPath(const Offset(80, 33.6), 1.8, 1.8), SketchColors.white);
    pen.fill(ovalPath(const Offset(84, 43.5), 6, 3.5), SketchColors.pink.withValues(alpha: 0.6));
    pen.stroke(
      Path()
        ..moveTo(87, 48.5)
        ..quadraticBezierTo(89.5, 50.5, 92, 48.5),
      SketchColors.pencil,
      width: 0.7,
      sketchy: false,
    );
    final nose = Offset(97, 45.5 + sniff * 0.8);
    pen.fill(ovalPath(nose, 5, 4.4), SketchColors.pinkDeep);
    for (final end in [Offset(107, 40 + sniff), const Offset(108, 46), Offset(106, 52 - sniff)]) {
      pen.line(nose + const Offset(-3, 0), end, SketchColors.pencil, width: 0.5, sketchy: false, wobble: 0);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(MousePainter old) =>
      old.phase != phase || old.moving != moving || old.facing != facing || old.appear != appear || old.pop != pop;
}

/// Tiny blue bird (100x90 box, facing right). Flaps while [airborne].
class BirdPainter extends CustomPainter {
  BirdPainter({this.phase = 0, this.airborne = false, this.facing = 1, this.appear = 1, this.pop = 0});

  static const aspect = 100 / 90;

  final double phase;
  final bool airborne;
  final double facing;
  final double appear;
  final double pop;

  @override
  void paint(Canvas canvas, Size size) {
    paintSpawned(canvas, size,
        boxWidth: 100,
        appear: appear,
        pop: pop,
        facing: facing,
        popCenter: const Offset(50, 50),
        popRadius: 42,
        draw: _bird);
  }

  void _bird(SketchPen pen) {
    final canvas = pen.canvas;
    final flap = airborne
        ? math.sin(phase * 28)
        : (phase % 2.4 < 0.2 ? math.sin(phase * 40) * 0.3 : 0.0);

    if (!airborne) {
      for (final (a, b) in const [(Offset(46, 75), Offset(44, 87)), (Offset(56, 75), Offset(58, 87))]) {
        pen.line(a, b, SketchColors.sunEdge, width: 1.6, sketchy: false, wobble: 0);
        pen.line(b, b + const Offset(4, 0), SketchColors.sunEdge, width: 1.3, sketchy: false, wobble: 0);
      }
    }
    final tail = polygon(const [Offset(24, 46), Offset(4, 38), Offset(6, 56), Offset(26, 58)]);
    pen.fill(tail, const Color(0xFF5E9BE0));
    pen.hatch(tail, SketchColors.ink, spacing: 1.6, seed: 1);
    pen.stroke(tail, SketchColors.ink, width: 1.1, seed: 1);

    final body = ovalPath(const Offset(50, 52), 54, 50);
    pen.fill(body, const Color(0xFF9CCBF5));
    canvas.save();
    canvas.clipPath(body);
    pen.hatch(body, SketchColors.ink.withValues(alpha: 0.45), spacing: 2.2, seed: 2);
    final belly = ovalPath(const Offset(58, 64), 32, 26);
    pen.fill(belly, SketchColors.sun.withValues(alpha: 0.9));
    pen.hatch(belly, SketchColors.sunEdge, spacing: 1.4, seed: 3);
    canvas.restore();
    pen.stroke(body, SketchColors.ink, width: 1.3, seed: 4);

    canvas.save();
    canvas.translate(44, 48);
    canvas.rotate(flap * 0.9);
    final wing = ovalPath(const Offset(-6, 4), 30, 17);
    pen.fill(wing, const Color(0xFF6FA8E8));
    pen.hatch(wing, SketchColors.ink, spacing: 1.5, angle: 0.4, seed: 5);
    pen.stroke(wing, SketchColors.ink, width: 1.1, seed: 5);
    canvas.restore();

    pen.fill(ovalPath(const Offset(64, 42), 6.5, 7.5), SketchColors.eye);
    pen.fill(ovalPath(const Offset(63, 40), 2.2, 2.2), SketchColors.white);
    pen.fill(ovalPath(const Offset(70, 53), 7, 4), SketchColors.pink.withValues(alpha: 0.7));
    final beak = polygon(const [Offset(75, 44), Offset(88, 49), Offset(75, 54)]);
    pen.fill(beak, SketchColors.sunEdge);
    pen.stroke(beak, SketchColors.kibbleDark, width: 0.8, sketchy: false, wobble: 0.1);
    pen.line(const Offset(52, 28), const Offset(49, 21), SketchColors.ink, width: 1.0, sketchy: false);
    pen.line(const Offset(56, 28), const Offset(57, 20), SketchColors.ink, width: 1.0, sketchy: false);
  }

  @override
  bool shouldRepaint(BirdPainter old) =>
      old.phase != phase || old.airborne != airborne || old.facing != facing || old.appear != appear || old.pop != pop;
}

/// Pink-and-yellow butterfly (100x80 box). Always fluttering.
class ButterflyPainter extends CustomPainter {
  ButterflyPainter({this.phase = 0, this.appear = 1, this.pop = 0});

  static const aspect = 100 / 80;

  final double phase;
  final double appear;
  final double pop;

  @override
  void paint(Canvas canvas, Size size) {
    paintSpawned(canvas, size,
        boxWidth: 100,
        appear: appear,
        pop: pop,
        popCenter: const Offset(50, 40),
        popRadius: 40,
        popColor: SketchColors.pinkDeep,
        draw: _butterfly);
  }

  void _butterfly(SketchPen pen) {
    final canvas = pen.canvas;
    final open = 0.3 + 0.7 * math.cos(phase * 16).abs();
    for (final side in const [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(50, 40);
      canvas.scale(side * open, 1);
      final upper = Path()
        ..moveTo(0, -2)
        ..cubicTo(-10, -32, -46, -26, -42, -6)
        ..cubicTo(-40, 4, -14, 6, 0, 2)
        ..close();
      final lower = Path()
        ..moveTo(0, 2)
        ..cubicTo(-8, 4, -32, 10, -27, 25)
        ..cubicTo(-22, 33, -6, 22, 0, 6)
        ..close();
      pen.fill(upper, SketchColors.pink.withValues(alpha: 0.7));
      pen.hatch(upper, SketchColors.pinkDeep, spacing: 1.6, seed: 1);
      pen.fill(lower, SketchColors.sun.withValues(alpha: 0.7));
      pen.hatch(lower, SketchColors.sunEdge, spacing: 1.6, seed: 2);
      for (final (c, r) in const [(Offset(-26, -12), 8.0), (Offset(-16, 15), 5.0)]) {
        pen.fill(ovalPath(c, r, r), SketchColors.white);
        pen.stroke(ovalPath(c, r, r), SketchColors.pinkDeep, width: 0.9, sketchy: false, wobble: 0.1);
      }
      pen.stroke(upper, SketchColors.pencil, width: 1.1, seed: 3);
      pen.stroke(lower, SketchColors.pencil, width: 1.1, seed: 4);
      canvas.restore();
    }
    final body = ovalPath(const Offset(50, 42), 6, 30);
    pen.fill(body, SketchColors.stripe);
    pen.stroke(body, SketchColors.pencil, width: 0.9, sketchy: false, wobble: 0.1);
    for (final side in const [-1.0, 1.0]) {
      pen.stroke(
        Path()
          ..moveTo(50, 28)
          ..quadraticBezierTo(50 + side * 4, 16, 50 + side * 9, 12),
        SketchColors.pencil,
        width: 0.9,
        sketchy: false,
      );
      pen.fill(ovalPath(Offset(50 + side * 9, 12), 3, 3), SketchColors.pencil);
    }
  }

  @override
  bool shouldRepaint(ButterflyPainter old) =>
      old.phase != phase || old.appear != appear || old.pop != pop;
}
