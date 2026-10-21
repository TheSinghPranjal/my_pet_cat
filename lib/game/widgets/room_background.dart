import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../models/game_positions.dart';
import '../sketch/sketch.dart';

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

/// The static, hand-drawn room. Painted once per layout and cached behind a
/// [RepaintBoundary]; it never animates.
class RoomBackground extends StatelessWidget {
  const RoomBackground({super.key, required this.unit});

  final double unit;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _RoomPainter(unit),
        isComplex: true,
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Draws in units where the ideal 9:16 stage is 100 units wide. Each piece of
/// furniture is anchored at a normalized position and sized in units, so it
/// keeps its shape on any aspect ratio.
class _RoomPainter extends CustomPainter {
  _RoomPainter(this.unit);

  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final k = unit / 100;
    final w = size.width / k;
    final h = size.height / k;
    final pen = SketchPen(canvas, pxPerUnit: k, weight: 0.6);
    canvas.save();
    canvas.scale(k);

    void place(double x, double y, void Function() draw) {
      canvas.save();
      canvas.translate(x * w, y * h);
      draw();
      canvas.restore();
    }

    _floor(pen, w, h);
    place(0.5, 0, () => _lamp(pen));
    place(0.03, 0.16, () => _window(pen));
    place(0.57, 0.215, () => _picture(pen));
    place(0.80, 0.235, () => _shelf(pen));
    place(0, 0.575, () => _dresser(pen));
    place(0, 0.42, () => _pottedPlant(pen));
    place(0.72, 0.44, () => _catTree(pen));
    place(-0.01, 0.735, () => _bed(pen));
    place(0.84, 0.79, () => _mouse(pen));

    canvas.restore();
  }

  // --- Floor ----------------------------------------------------------------

  void _floor(SketchPen pen, double w, double h) {
    final top = h * GamePositions.floorLine;
    final bottom = h * GamePositions.floorBottom;
    final rnd = math.Random(7);
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.5;
    for (var i = 0; i < 260; i++) {
      final t = math.pow(rnd.nextDouble(), 1.6).toDouble();
      final y = top + 1.2 + (bottom - top) * t;
      final x = rnd.nextDouble() * w;
      final length = 4 + rnd.nextDouble() * 14;
      final tilt = (rnd.nextDouble() - 0.5) * 1.2;
      paint.color = SketchColors.inkSoft.withValues(alpha: 0.6 * (1 - t * 0.65));
      pen.canvas.drawLine(Offset(x, y), Offset(x + length, y + tilt), paint);
    }
    pen.line(Offset(-2, top), Offset(w + 2, top), SketchColors.ink, width: 1.0, wobble: 0.35, seed: 1);
    pen.line(Offset(-2, top + 0.9), Offset(w + 2, top + 0.9), SketchColors.inkSoft,
        width: 0.5, wobble: 0.4, seed: 2, sketchy: false);
  }

  // --- Lamp -----------------------------------------------------------------

  void _lamp(SketchPen pen) {
    pen.line(Offset.zero, const Offset(0, 13.5), SketchColors.ink, width: 0.8);
    final shade = Path()
      ..moveTo(-2.2, 13.5)
      ..lineTo(2.2, 13.5)
      ..quadraticBezierTo(3, 18, 8, 21.5)
      ..lineTo(-8, 21.5)
      ..quadraticBezierTo(-3, 18, -2.2, 13.5)
      ..close();
    pen.fill(shade, SketchColors.white);
    pen.hatch(shade, SketchColors.inkSoft, spacing: 1.2, angle: -0.5, seed: 3);
    pen.stroke(shade, SketchColors.ink, width: 0.9, seed: 3);
    pen.stroke(ovalPath(const Offset(0, 21.5), 16, 2.2), SketchColors.ink, width: 0.8, seed: 4);
    final bulb = ovalPath(const Offset(0, 23.6), 5, 4.4);
    pen.fill(bulb, SketchColors.sun);
    pen.hatch(bulb, SketchColors.sunEdge, spacing: 0.8, seed: 5);
    pen.stroke(bulb, SketchColors.sunEdge, width: 0.6, seed: 5);
    for (final a in const [2.45, 2.0, 1.15, 0.7]) {
      final d = Offset(math.cos(a), math.sin(a));
      pen.line(const Offset(0, 23.6) + d * 4.6, const Offset(0, 23.6) + d * 7.2,
          SketchColors.sun, width: 0.8, sketchy: false);
    }
  }

  // --- Window ---------------------------------------------------------------

  void _window(SketchPen pen) {
    const frame = Rect.fromLTRB(5.5, 3.5, 34.5, 42);
    pen.fill(Path()..addRect(frame), SketchColors.white);
    pen.hatch(Path()..addRect(frame.deflate(1.3)), SketchColors.inkWash.withValues(alpha: 0.5),
        spacing: 3.2, angle: -0.7, seed: 11);

    // Sun.
    const sun = Offset(19.5, 10.5);
    for (var i = 0; i < 10; i++) {
      final a = i / 10 * math.pi * 2;
      final d = Offset(math.cos(a), math.sin(a));
      pen.line(sun + d * 5, sun + d * 7.4, SketchColors.sunEdge, width: 0.7, sketchy: false);
    }
    final sunDisc = ovalPath(sun, 7.2, 7.2);
    pen.fill(sunDisc, SketchColors.sun);
    pen.hatch(sunDisc, SketchColors.sunEdge, spacing: 0.9, cross: true, seed: 12);
    pen.stroke(sunDisc, SketchColors.sunEdge, width: 0.7, seed: 12);

    // Cloud.
    final cloud = Path()
      ..moveTo(8, 21.5)
      ..quadraticBezierTo(6, 18, 9.8, 17.6)
      ..quadraticBezierTo(10.8, 14, 14.6, 15.4)
      ..quadraticBezierTo(17.8, 14.2, 18.4, 18)
      ..quadraticBezierTo(21.6, 18.6, 19.8, 21.5)
      ..close();
    pen.fill(cloud, SketchColors.white);
    pen.stroke(cloud, SketchColors.ink, width: 0.75, seed: 13);

    // Bushes outside.
    for (final bush in [
      Path()
        ..moveTo(7, 41)
        ..quadraticBezierTo(7.4, 36, 10.5, 36)
        ..quadraticBezierTo(12, 32.4, 15.5, 34)
        ..quadraticBezierTo(18.2, 31.8, 20.2, 35)
        ..quadraticBezierTo(23.2, 34.4, 24, 38)
        ..quadraticBezierTo(26, 38, 26.6, 41)
        ..close(),
      Path()
        ..moveTo(28.8, 41)
        ..quadraticBezierTo(29, 37, 31, 37.5)
        ..quadraticBezierTo(33, 35, 34, 38)
        ..lineTo(34, 41)
        ..close(),
    ]) {
      pen.fill(bush, SketchColors.leaf.withValues(alpha: 0.3));
      pen.hatch(bush, SketchColors.leaf, spacing: 0.9, cross: true, seed: 14);
      pen.stroke(bush, SketchColors.leafDark, width: 0.6, seed: 14);
    }

    // Frame and mullions.
    pen.stroke(Path()..addRect(frame), SketchColors.ink, width: 1.1, seed: 15);
    pen.stroke(Path()..addRect(frame.deflate(1.3)), SketchColors.ink, width: 0.6, seed: 16);
    pen.stroke(rectPath(27.3, 3.5, 28.7, 42), SketchColors.ink, width: 0.7, seed: 17);
    pen.stroke(rectPath(5.5, 24.4, 34.5, 25.7), SketchColors.ink, width: 0.7, seed: 18);
    final sill = rectPath(4, 42, 36, 44.2);
    pen.fill(sill, SketchColors.white);
    pen.hatch(sill, SketchColors.inkSoft, spacing: 1, seed: 19);
    pen.stroke(sill, SketchColors.ink, width: 0.9, seed: 19);

    // Curtain rod.
    pen.line(const Offset(-0.5, 1.5), const Offset(42.5, 1.5), SketchColors.ink, width: 1.0, seed: 20);
    for (final x in const [-1.0, 43.0]) {
      final knob = ovalPath(Offset(x, 1.5), 2.8, 2.8);
      pen.fill(knob, SketchColors.white);
      pen.stroke(knob, SketchColors.ink, width: 0.8, seed: 21);
    }
    for (final x in const [2.5, 4.5, 37.5, 39.5]) {
      pen.stroke(ovalPath(Offset(x, 2.4), 1.6, 2.2), SketchColors.ink, width: 0.6, sketchy: false);
    }

    // Curtains.
    final left = Path()
      ..moveTo(0.5, 2.5)
      ..lineTo(7.5, 2.5)
      ..cubicTo(6.5, 15, 8.5, 30, 8, 44)
      ..quadraticBezierTo(6.8, 45.4, 5.6, 44.2)
      ..quadraticBezierTo(4.4, 45.4, 3.2, 44.2)
      ..quadraticBezierTo(2, 45.4, 0.8, 44.2)
      ..cubicTo(1.5, 30, -0.5, 15, 0.5, 2.5)
      ..close();
    final right = Path()
      ..moveTo(34, 2.5)
      ..lineTo(41, 2.5)
      ..cubicTo(41, 12, 39, 22, 37.8, 28)
      ..cubicTo(39.5, 34, 41.5, 40, 42, 44.5)
      ..quadraticBezierTo(40.6, 45.8, 39.2, 44.6)
      ..quadraticBezierTo(37.8, 45.8, 36.4, 44.6)
      ..quadraticBezierTo(35, 45.8, 33.5, 44.6)
      ..cubicTo(34.5, 38, 36, 33, 36.2, 28)
      ..cubicTo(35, 22, 33.8, 12, 34, 2.5)
      ..close();
    for (final (i, curtain) in [left, right].indexed) {
      pen.fill(curtain, SketchColors.white);
      pen.hatch(curtain, SketchColors.inkWash, spacing: 1.6, angle: -1.3, seed: 22 + i);
      pen.stroke(curtain, SketchColors.ink, width: 0.9, seed: 22 + i);
    }
    for (final (a, b) in const [
      (Offset(3, 4), Offset(2.6, 43)),
      (Offset(5.4, 4), Offset(5.8, 43)),
      (Offset(37.5, 4), Offset(37.2, 27)),
      (Offset(37.4, 29.5), Offset(38.6, 44)),
    ]) {
      pen.line(a, b, SketchColors.inkSoft, width: 0.5, sketchy: false);
    }
    final tie = ovalPath(const Offset(37.2, 28), 4.2, 2.4);
    pen.fill(tie, SketchColors.white);
    pen.hatch(tie, SketchColors.ink, spacing: 0.7, seed: 24);
    pen.stroke(tie, SketchColors.ink, width: 0.7, seed: 24);
  }

  // --- Framed cat portrait --------------------------------------------------

  void _picture(SketchPen pen) {
    pen.stroke(ovalPath(const Offset(7, -3.6), 1.8, 1.8), SketchColors.ink, width: 0.6, sketchy: false);
    pen.line(const Offset(1.5, 0.4), const Offset(7, -3), SketchColors.ink, width: 0.6);
    pen.line(const Offset(12.5, 0.4), const Offset(7, -3), SketchColors.ink, width: 0.6);
    final outer = rectPath(0, 0, 14, 15);
    final inner = rectPath(2, 2, 12, 13);
    pen.fill(outer, SketchColors.white);
    pen.hatch(Path.combine(PathOperation.difference, outer, inner), SketchColors.inkSoft,
        spacing: 0.8, seed: 31);
    pen.stroke(outer, SketchColors.ink, width: 0.9, seed: 31);
    pen.stroke(inner, SketchColors.ink, width: 0.6, seed: 32);

    const c = Offset(7, 8.8);
    final face = Path()
      ..moveTo(c.dx - 3.6, c.dy - 1)
      ..lineTo(c.dx - 3.2, c.dy - 4.4)
      ..lineTo(c.dx - 1.4, c.dy - 2.6)
      ..lineTo(c.dx + 1.4, c.dy - 2.6)
      ..lineTo(c.dx + 3.2, c.dy - 4.4)
      ..lineTo(c.dx + 3.6, c.dy - 1)
      ..quadraticBezierTo(c.dx + 3.8, c.dy + 3, c.dx, c.dy + 3)
      ..quadraticBezierTo(c.dx - 3.8, c.dy + 3, c.dx - 3.6, c.dy - 1)
      ..close();
    pen.stroke(face, SketchColors.ink, width: 0.55, wobble: 0.15, sketchy: false);
    for (final x in const [-1.4, 1.4]) {
      pen.fill(ovalPath(c + Offset(x, -0.4), 0.8, 0.9), SketchColors.ink);
    }
    pen.fill(ovalPath(c + const Offset(0, 0.8), 0.6, 0.4), SketchColors.ink);
    for (final side in const [-1.0, 1.0]) {
      pen.line(c + Offset(2.4 * side, 1.2), c + Offset(5 * side, 0.6), SketchColors.ink,
          width: 0.3, sketchy: false, wobble: 0);
      pen.line(c + Offset(2.4 * side, 1.8), c + Offset(5 * side, 2.2), SketchColors.ink,
          width: 0.3, sketchy: false, wobble: 0);
    }
  }

  // --- Shelf with books and a trailing plant --------------------------------

  void _shelf(SketchPen pen) {
    const books = [
      (12.0, 1.5, 3.5, SketchColors.ink),
      (13.6, 1.6, 2.8, SketchColors.inkSoft),
      (15.3, 1.4, 3.8, SketchColors.ink),
      (16.8, 1.6, 3.0, SketchColors.ink),
      (18.5, 1.6, 2.6, SketchColors.wool),
    ];
    for (final (i, (x, width, top, color)) in books.indexed) {
      final book = rectPath(x, top, x + width, 11.5);
      pen.fill(book, SketchColors.white);
      pen.hatch(book, color, spacing: 0.7, angle: -1.2, seed: 40 + i);
      pen.stroke(book, color, width: 0.6, seed: 40 + i);
    }
    final board = rectPath(1, 11.5, 21, 13);
    pen.fill(board, SketchColors.white);
    pen.hatch(board, SketchColors.inkSoft, spacing: 0.8, seed: 46);
    pen.stroke(board, SketchColors.ink, width: 0.8, seed: 46);
    pen.stroke(
      Path()
        ..moveTo(5, 13)
        ..lineTo(5, 18)
        ..lineTo(7.4, 13),
      SketchColors.ink,
      width: 0.8,
      seed: 47,
    );

    // Trailing vines.
    for (final (i, vine) in [
      Path()
        ..moveTo(4.4, 9)
        ..cubicTo(-1, 13, -3.5, 21, -2.5, 30),
      Path()
        ..moveTo(5.4, 9.6)
        ..cubicTo(2.5, 13, 1, 17, 1.5, 21),
    ].indexed) {
      pen.stroke(vine, SketchColors.leafDark, width: 0.55, seed: 48 + i);
      final metric = vine.computeMetrics().first;
      for (var j = 1; j <= 6 - i * 2; j++) {
        final tangent = metric.getTangentForOffset(metric.length * j / (7 - i * 2))!;
        final n = Offset(-tangent.vector.dy, tangent.vector.dx) * (j.isEven ? 1 : -1);
        _leaf(pen, tangent.position, tangent.position + n * 2.6 + tangent.vector * 1.2,
            width: 1.1, seed: 50 + j + i * 10);
      }
    }

    final pot = polygon(const [Offset(3.8, 7.5), Offset(10.2, 7.5), Offset(9.4, 11.5), Offset(4.6, 11.5)]);
    pen.fill(pot, SketchColors.white);
    pen.hatch(pot, SketchColors.inkSoft, spacing: 0.8, seed: 60);
    pen.stroke(pot, SketchColors.ink, width: 0.7, seed: 60);
    final rim = rectPath(3.4, 6.8, 10.6, 8);
    pen.fill(rim, SketchColors.white);
    pen.stroke(rim, SketchColors.ink, width: 0.6, seed: 61);
    for (final (i, tip) in const [Offset(2.5, 1.6), Offset(6.5, -0.4), Offset(10.8, 1.4), Offset(12.6, 4.6)].indexed) {
      _leaf(pen, const Offset(7, 7), tip, width: 1.6, seed: 62 + i);
    }
  }

  // --- Dresser and potted plant ---------------------------------------------

  void _dresser(SketchPen pen) {
    final body = rectPath(0, 2.6, 18.6, 19);
    pen.fill(body, SketchColors.white);
    pen.hatch(body, SketchColors.inkWash, spacing: 2.2, seed: 70);
    pen.hatch(rectPath(17, 2.6, 18.6, 19), SketchColors.ink, spacing: 0.8, seed: 71, cross: true);
    for (final legX in const [1.0, 16.0]) {
      final leg = rectPath(legX, 19, legX + 1.6, 21);
      pen.fill(leg, SketchColors.white);
      pen.stroke(leg, SketchColors.ink, width: 0.6, seed: 72);
    }
    pen.stroke(body, SketchColors.ink, width: 0.9, seed: 73);
    pen.line(const Offset(0, 10.8), const Offset(18.6, 10.8), SketchColors.ink, width: 0.7, seed: 74);
    for (final (i, y) in const [3.6, 11.7].indexed) {
      pen.stroke(rectPath(1, y, 16.4, y + 6.3), SketchColors.inkSoft, width: 0.5, seed: 75 + i);
      final knob = ovalPath(Offset(8.2, y + 3.15), 2.4, 2.4);
      pen.fill(knob, SketchColors.white);
      pen.stroke(knob, SketchColors.ink, width: 0.7, seed: 77 + i);
    }
    final top = rectPath(-1, 0, 20, 2.6);
    pen.fill(top, SketchColors.white);
    pen.hatch(top, SketchColors.inkSoft, spacing: 0.8, seed: 79);
    pen.stroke(top, SketchColors.ink, width: 0.9, seed: 79);
  }

  void _pottedPlant(SketchPen pen) {
    const base = Offset(10.8, 18);
    const tips = [Offset(1.5, 9), Offset(5.5, 1.5), Offset(11.5, -1.5), Offset(16.5, 3.5), Offset(19.8, 10.5)];
    for (final (i, tip) in tips.indexed) {
      final stemEnd = Offset.lerp(base, tip, 0.35)!;
      pen.line(base, stemEnd, SketchColors.leafDark, width: 0.55, seed: 80 + i);
      _leaf(pen, stemEnd, tip, width: 2.8, seed: 85 + i);
    }
    final pot = polygon(const [Offset(5, 18.5), Offset(16.5, 18.5), Offset(15.2, 28.5), Offset(6.3, 28.5)]);
    pen.fill(pot, SketchColors.white);
    pen.hatch(pot, SketchColors.inkWash, spacing: 1.4, seed: 90);
    pen.stroke(pot, SketchColors.ink, width: 0.9, seed: 90);
    final rim = rectPath(4.3, 17.2, 17.2, 19.5);
    pen.fill(rim, SketchColors.white);
    pen.hatch(rim, SketchColors.inkSoft, spacing: 0.9, seed: 91);
    pen.stroke(rim, SketchColors.ink, width: 0.8, seed: 91);
    final heart = Path()
      ..moveTo(10.8, 25.6)
      ..cubicTo(8, 23.6, 8.8, 21.4, 10.8, 22.6)
      ..cubicTo(12.8, 21.4, 13.6, 23.6, 10.8, 25.6)
      ..close();
    pen.stroke(heart, SketchColors.ink, width: 0.6, seed: 92);
  }

  void _leaf(SketchPen pen, Offset base, Offset tip, {required double width, required int seed}) {
    final dir = tip - base;
    final length = dir.distance;
    if (length == 0) return;
    final n = Offset(-dir.dy, dir.dx) / length;
    final mid = Offset.lerp(base, tip, 0.5)!;
    final leaf = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(mid.dx + n.dx * width * 2, mid.dy + n.dy * width * 2, tip.dx, tip.dy)
      ..quadraticBezierTo(mid.dx - n.dx * width * 2, mid.dy - n.dy * width * 2, base.dx, base.dy)
      ..close();
    pen.fill(leaf, SketchColors.leaf.withValues(alpha: 0.4));
    pen.hatch(leaf, SketchColors.leaf, spacing: 0.7, angle: math.atan2(n.dy, n.dx) + 0.5,
        width: 0.4, seed: seed);
    pen.stroke(leaf, SketchColors.leafDark, width: 0.55, wobble: 0.2, seed: seed);
    pen.line(base, Offset.lerp(base, tip, 0.85)!, SketchColors.leafDark,
        width: 0.35, sketchy: false, wobble: 0.1);
  }

  // --- Cat tree -------------------------------------------------------------

  void _catTree(SketchPen pen) {
    final post = rectPath(12, 2, 16.5, 30);
    pen.fill(post, SketchColors.white);
    pen.hatch(post, SketchColors.ink, spacing: 1.0, angle: -0.5, width: 0.5, seed: 100, cross: true);
    pen.stroke(post, SketchColors.ink, width: 0.8, seed: 100);

    final support = rectPath(4, 24.5, 7, 30);
    pen.fill(support, SketchColors.white);
    pen.hatch(support, SketchColors.inkSoft, spacing: 0.9, seed: 101);
    pen.stroke(support, SketchColors.ink, width: 0.7, seed: 101);

    for (final (i, board) in [rectPath(1.5, 0, 26, 2.2), rectPath(0.5, 22, 14.5, 24.5)].indexed) {
      pen.fill(board, SketchColors.white);
      pen.hatch(board, SketchColors.ink, spacing: 0.9, seed: 102 + i);
      pen.stroke(board, SketchColors.ink, width: 0.9, seed: 102 + i);
    }

    // Dangling toy.
    pen.line(const Offset(24, 2.2), const Offset(24, 13), SketchColors.ink, width: 0.5);
    final toy = ovalPath(const Offset(24, 15.6), 5.2, 5.2);
    pen.fill(toy, SketchColors.white);
    pen.hatch(toy, SketchColors.inkSoft, spacing: 0.8, cross: true, seed: 104);
    pen.stroke(toy, SketchColors.ink, width: 0.7, seed: 104);
    pen.line(const Offset(21.4, 15.6), const Offset(26.6, 15.6), SketchColors.ink, width: 0.5, sketchy: false);
    for (final dx in const [-1.4, 0.0, 1.4]) {
      pen.line(const Offset(24, 18.2), Offset(24 + dx, 21), SketchColors.ink, width: 0.4, sketchy: false);
    }

    final box = rectPath(1, 30, 26, 46);
    final hole = Path()
      ..moveTo(7.5, 46)
      ..lineTo(7.5, 39)
      ..arcToPoint(const Offset(19.5, 39), radius: const Radius.circular(6))
      ..lineTo(19.5, 46)
      ..close();
    pen.fill(box, SketchColors.white);
    pen.hatch(Path.combine(PathOperation.difference, box, hole), SketchColors.inkWash,
        spacing: 1.6, seed: 105);
    pen.fill(hole, SketchColors.inkWash);
    pen.hatch(hole, SketchColors.ink, spacing: 0.7, angle: -0.7, width: 0.5, seed: 106, cross: true);
    pen.stroke(hole, SketchColors.ink, width: 0.9, seed: 106);
    pen.stroke(box, SketchColors.ink, width: 1.0, seed: 107);
  }

  // --- Cat bed --------------------------------------------------------------

  void _bed(SketchPen pen) {
    pen.hatch(ovalPath(const Offset(12, 14), 26, 2.6), SketchColors.inkSoft,
        spacing: 0.9, angle: -0.15, seed: 110);
    final outer = Path()
      ..addRRect(RRect.fromLTRBR(0, 3, 23, 13.5, const Radius.circular(5.5)));
    pen.fill(outer, SketchColors.pink.withValues(alpha: 0.3));
    pen.hatch(outer, SketchColors.pink, spacing: 0.9, angle: -0.6, seed: 111);
    pen.stroke(outer, SketchColors.pinkDeep, width: 0.9, seed: 111);
    for (final x in const [6.5, 12.0, 17.5]) {
      pen.stroke(
        Path()
          ..moveTo(x, 7.5)
          ..quadraticBezierTo(x - 1.2, 10.5, x, 13.2),
        SketchColors.pinkDeep.withValues(alpha: 0.6),
        width: 0.5,
        sketchy: false,
      );
    }
    final cushion = ovalPath(const Offset(11.5, 4.3), 20, 7.6);
    pen.fill(cushion, const Color(0xFFFCE6EC));
    pen.hatch(cushion, SketchColors.pink, spacing: 1.1, angle: 0.4, seed: 112);
    pen.stroke(cushion, SketchColors.pinkDeep, width: 0.8, seed: 112);
    final hollow = ovalPath(const Offset(11.5, 4.3), 13.5, 4);
    pen.fill(hollow, SketchColors.pink.withValues(alpha: 0.5));
    pen.hatch(hollow, SketchColors.pinkDeep, spacing: 0.8, seed: 113);
    pen.stroke(hollow, SketchColors.pinkDeep, width: 0.6, seed: 113);
    // Paw print.
    pen.fill(ovalPath(const Offset(16, 10.6), 2.4, 1.8), SketchColors.ink);
    for (final toe in const [Offset(14.6, 9.0), Offset(15.6, 8.4), Offset(16.6, 8.4), Offset(17.5, 9.0)]) {
      pen.fill(ovalPath(toe, 0.85, 0.95), SketchColors.ink);
    }
  }

  // --- Toy mouse ------------------------------------------------------------

  void _mouse(SketchPen pen) {
    pen.hatch(ovalPath(const Offset(6, 5.4), 10, 1.4), SketchColors.inkSoft, spacing: 0.6, seed: 120);
    pen.stroke(
      Path()
        ..moveTo(9.4, 4.4)
        ..cubicTo(11.5, 3.8, 11.8, 6.2, 13.4, 5)
        ..quadraticBezierTo(14.4, 4.2, 15.2, 4.8),
      SketchColors.wool,
      width: 0.5,
      sketchy: false,
    );
    final body = Path()
      ..moveTo(0.8, 4.3)
      ..quadraticBezierTo(2.4, 0.8, 6.4, 1.2)
      ..quadraticBezierTo(9.6, 1.8, 9.6, 4.6)
      ..lineTo(1.6, 4.8)
      ..close();
    pen.fill(body, SketchColors.white);
    pen.hatch(body, SketchColors.graphite, spacing: 0.6, seed: 121);
    pen.stroke(body, SketchColors.pencil, width: 0.5, seed: 121);
    final ear = ovalPath(const Offset(4.2, 1.6), 2.6, 2.6);
    pen.fill(ear, SketchColors.pink);
    pen.stroke(ear, SketchColors.pencil, width: 0.45, sketchy: false);
    pen.fill(ovalPath(const Offset(2.6, 2.9), 0.7, 0.7), SketchColors.pencil);
    pen.fill(ovalPath(const Offset(0.9, 4.1), 0.8, 0.7), SketchColors.pinkDeep);
  }

  @override
  bool shouldRepaint(_RoomPainter oldDelegate) => oldDelegate.unit != unit;
}
