import 'package:flutter/widgets.dart';

import '../animations/object_animations.dart';
import '../sketch/sketch.dart';

/// Grooming brush (100x45 box): wooden handle on the left, bristles down.
class BrushPainter extends CustomPainter {
  BrushPainter({this.facing = 1, this.appear = 1, this.pop = 0});

  static const aspect = 100 / 45;

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
        popCenter: const Offset(50, 22),
        popRadius: 40,
        draw: _brush);
  }

  void _brush(SketchPen pen) {
    for (var x = 51.0; x <= 94; x += 3.5) {
      pen.line(Offset(x, 25), Offset(x + 0.4, 41), SketchColors.pencil, width: 0.9, sketchy: false, wobble: 0.1);
    }
    final handle = Path()..addRRect(RRect.fromLTRBR(2, 10, 52, 22, const Radius.circular(6)));
    pen.fill(handle, const Color(0xFFF3D9B1));
    pen.hatch(handle, SketchColors.kibble, spacing: 1.5, angle: -0.3, seed: 1);
    pen.stroke(handle, SketchColors.kibbleDark, width: 1.1, seed: 1);
    pen.stroke(ovalPath(const Offset(9, 16), 4, 4), SketchColors.kibbleDark, width: 0.8, sketchy: false);
    final head = Path()..addRRect(RRect.fromLTRBR(46, 4, 98, 26, const Radius.circular(6)));
    pen.fill(head, SketchColors.inkWash);
    pen.hatch(head, SketchColors.ink, spacing: 1.6, seed: 2);
    pen.stroke(head, SketchColors.ink, width: 1.3, seed: 2);
    final heart = Path()
      ..moveTo(72, 20)
      ..cubicTo(64, 14, 67, 8, 72, 11)
      ..cubicTo(77, 8, 80, 14, 72, 20)
      ..close();
    pen.fill(heart, SketchColors.pink);
    pen.stroke(heart, SketchColors.pinkDeep, width: 0.8, sketchy: false);
  }

  @override
  bool shouldRepaint(BrushPainter old) => old.facing != facing || old.appear != appear || old.pop != pop;
}

/// Soft striped towel (100x62 box), draped with a wavy hem.
class TowelPainter extends CustomPainter {
  TowelPainter({this.appear = 1, this.pop = 0});

  static const aspect = 100 / 62;

  final double appear;
  final double pop;

  @override
  void paint(Canvas canvas, Size size) {
    paintSpawned(canvas, size,
        boxWidth: 100,
        appear: appear,
        pop: pop,
        popCenter: const Offset(50, 30),
        popRadius: 46,
        popColor: SketchColors.pinkDeep,
        draw: _towel);
  }

  void _towel(SketchPen pen) {
    final towel = Path()
      ..moveTo(6, 8)
      ..quadraticBezierTo(50, 0, 94, 8)
      ..lineTo(98, 52);
    for (var x = 98.0; x > 2; x -= 12) {
      towel.quadraticBezierTo(x - 6, 60, x - 12, 52);
    }
    towel.close();
    pen.fill(towel, const Color(0xFFFCE6EC));
    pen.hatch(towel, SketchColors.pink, spacing: 1.8, angle: -1.2, seed: 1);
    pen.canvas.save();
    pen.canvas.clipPath(towel);
    pen.hatch(rectPath(0, 36, 100, 43), SketchColors.inkSoft, spacing: 1.2, seed: 2, cross: true);
    pen.hatch(rectPath(0, 45, 100, 47.5), SketchColors.ink, spacing: 1.0, seed: 3);
    pen.canvas.restore();
    pen.stroke(towel, SketchColors.pinkDeep, width: 1.3, seed: 4);
    for (final (a, b) in const [(Offset(30, 8), Offset(27, 50)), (Offset(70, 8), Offset(73, 50))]) {
      pen.line(a, b, SketchColors.pinkDeep.withValues(alpha: 0.6), width: 0.7, sketchy: false);
    }
  }

  @override
  bool shouldRepaint(TowelPainter old) => old.appear != appear || old.pop != pop;
}

/// The bathtub (100x42 box). It's drawn in front of the cat so the kitten
/// can sit "inside"; [foam] (0..1) heaps bubbles along the rim.
class BathTubPainter extends CustomPainter {
  BathTubPainter({this.foam = 0});

  static const aspect = 100 / 42;

  final double foam;

  static const _bubbles = [
    (10.0, 6.0, 4.5), (18.0, 3.5, 5.5), (27.0, 5.5, 4.0), (35.0, 2.5, 5.5), (44.0, 5.0, 4.5),
    (52.0, 2.0, 6.0), (61.0, 5.0, 4.5), (69.0, 3.0, 5.5), (78.0, 5.5, 4.5), (87.0, 4.0, 5.0),
    (23.0, -1.5, 3.0), (48.0, -3.0, 3.5), (73.0, -1.5, 3.0), (92.0, 7.0, 3.5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    final pen = SketchPen(canvas, pxPerUnit: s);
    canvas.save();
    canvas.scale(s);
    pen.hatch(ovalPath(const Offset(50, 41), 92, 4), SketchColors.inkSoft, spacing: 1.4, angle: -0.2, seed: 1);
    for (final x in const [16.0, 84.0]) {
      final foot = ovalPath(Offset(x, 38.5), 8, 6);
      pen.fill(foot, SketchColors.white);
      pen.stroke(foot, SketchColors.ink, width: 0.9, sketchy: false, wobble: 0.2);
    }
    final body = Path()
      ..moveTo(4, 10)
      ..lineTo(96, 10)
      ..cubicTo(95, 30, 84, 36, 50, 36)
      ..cubicTo(16, 36, 5, 30, 4, 10)
      ..close();
    pen.fill(body, SketchColors.white);
    pen.hatch(body, SketchColors.inkWash, spacing: 2.0, angle: -1.1, width: 0.7, seed: 2);
    pen.stroke(body, SketchColors.ink, width: 1.3, seed: 3);
    final rim = Path()..addRRect(RRect.fromLTRBR(0, 6, 100, 12, const Radius.circular(3)));
    pen.fill(rim, SketchColors.white);
    pen.hatch(rim, SketchColors.inkSoft, spacing: 1.3, seed: 4);
    pen.stroke(rim, SketchColors.ink, width: 1.2, seed: 5);

    if (foam > 0) {
      final grow = Curves.easeOutBack.transform(foam.clamp(0.0, 1.0));
      for (final (i, (x, y, r)) in _bubbles.indexed) {
        final bubble = ovalPath(Offset(x, y), r * 2 * grow, r * 2 * grow);
        pen.fill(bubble, SketchColors.white);
        pen.stroke(bubble, SketchColors.inkSoft, width: 0.8, seed: 10 + i, sketchy: false, wobble: 0.2);
        pen.fill(ovalPath(Offset(x - r * 0.35, y - r * 0.35), r * 0.5 * grow, r * 0.5 * grow),
            SketchColors.inkWash);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BathTubPainter old) => old.foam != foam;
}
