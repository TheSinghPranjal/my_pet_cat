import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../models/game_positions.dart';
import '../sketch/sketch.dart';
import 'scene_background.dart';

/// The kitchen: window with café curtains, clock, shelf, utensils, a long
/// counter over three cabinets, a stove with its pan, and the fridge.
class KitchenPainter extends SceneBackgroundPainter {
  KitchenPainter(super.unit, {super.phase});

  @override
  void paintScene(Canvas canvas, SketchPen pen, double w, double h) {
    void place(double x, double y, void Function() draw) =>
        SceneBackgroundPainter.place(canvas, Offset(x * w, y * h), draw);
    Offset at(double x, double y) => Offset(x * w, y * h);
    const k = KitchenPositions.counterTop;

    woodFloor(pen, w, h);
    _backsplash(pen, at(0, 0.385), at(KitchenPositions.stoveRight, k));
    place(0.06, 0.12, () => _window(pen));
    place(0.44, 0.165, () => _clock(pen));
    place(0.53, 0.215, () => _shelf(pen));
    _utensils(pen, at(0.375, 0.285), at(0.5, 0.285));
    _fridge(pen, at(KitchenPositions.fridgeLeft, 0.25), at(0.99, SceneMetrics.groundLine + 0.004));
    _cabinets(pen, w, h);
    _stove(pen, w, h);
    place(0.44, 0.757, () => _mat(pen));
  }

  void _backsplash(SketchPen pen, Offset topLeft, Offset bottomRight) {
    final area = Path()..addRect(Rect.fromPoints(topLeft, bottomRight));
    pen.fill(area, SketchColors.inkWash.withValues(alpha: 0.25));
    final paint = Paint()
      ..color = SketchColors.inkSoft.withValues(alpha: 0.45)
      ..strokeWidth = 0.4;
    for (var x = topLeft.dx; x <= bottomRight.dx; x += 5) {
      pen.canvas.drawLine(Offset(x, topLeft.dy), Offset(x, bottomRight.dy), paint);
    }
    for (var y = topLeft.dy; y <= bottomRight.dy; y += 5) {
      pen.canvas.drawLine(Offset(topLeft.dx, y), Offset(bottomRight.dx, y), paint);
    }
  }

  void _window(SketchPen pen) {
    const frame = Rect.fromLTRB(0, 0, 26, 30);
    pen.fill(Path()..addRect(frame), SketchColors.white);
    windowSky(pen, frame.deflate(1.2), seed: 1);
    pen.stroke(Path()..addRect(frame), SketchColors.ink, width: 1.1, seed: 4);
    pen.stroke(rectPath(12.4, 0, 13.6, 30), SketchColors.ink, width: 0.6, seed: 5);
    pen.stroke(rectPath(0, 14.4, 26, 15.6), SketchColors.ink, width: 0.6, seed: 6);
    // Café curtains on the lower half.
    pen.line(const Offset(-1.5, 15), const Offset(27.5, 15), SketchColors.ink, width: 0.9, seed: 7);
    for (final (i, x) in const [0.0, 13.5].indexed) {
      final curtain = Path()
        ..moveTo(x, 15.5)
        ..lineTo(x + 12.5, 15.5)
        ..lineTo(x + 12.5, 29);
      for (var cx = x + 12.5; cx > x; cx -= 2.5) {
        curtain.quadraticBezierTo(cx - 1.25, 30.2, cx - 2.5, 29);
      }
      curtain.close();
      pen.fill(curtain, SketchColors.coralLight);
      pen.hatch(curtain, SketchColors.coral, spacing: 1.4, seed: 8 + i, cross: true);
      pen.stroke(curtain, SketchColors.coral, width: 0.7, seed: 8 + i);
    }
    final sill = rectPath(-1.5, 30, 27.5, 32);
    pen.fill(sill, SketchColors.white);
    pen.hatch(sill, SketchColors.inkSoft, spacing: 0.9, seed: 10);
    pen.stroke(sill, SketchColors.ink, width: 0.8, seed: 10);
  }

  void _clock(SketchPen pen) {
    final face = ovalPath(Offset.zero, 10, 10);
    pen.fill(face, SketchColors.white);
    pen.stroke(face, SketchColors.ink, width: 1.0, seed: 11);
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * math.pi * 2;
      final d = Offset(math.cos(a), math.sin(a));
      pen.line(d * 3.8, d * 4.4, SketchColors.ink, width: 0.4, sketchy: false, wobble: 0);
    }
    pen.line(Offset.zero, const Offset(0, -3.2), SketchColors.ink, width: 0.7, sketchy: false);
    pen.line(Offset.zero, const Offset(2.2, 0.8), SketchColors.coral, width: 0.7, sketchy: false);
  }

  void _shelf(SketchPen pen) {
    // Cookie jar.
    final jar = Path()..addRRect(RRect.fromLTRBR(1, 3, 6.5, 10, const Radius.circular(1.2)));
    pen.fill(jar, const Color(0xFFF4F7FF));
    for (final c in const [Offset(2.6, 8), Offset(4.6, 8.4), Offset(3.6, 6.4)]) {
      pen.fill(ovalPath(c, 2, 2), SketchColors.kibble);
    }
    pen.stroke(jar, SketchColors.ink, width: 0.6, seed: 12);
    pen.fill(rectPath(1.6, 1.8, 5.9, 3), SketchColors.coral);
    // Little herb pot.
    for (final (i, tip) in const [Offset(8, 2), Offset(10.5, 0.5), Offset(13, 2.5)].indexed) {
      leaf(pen, const Offset(10.5, 6.5), tip, width: 1.0, seed: 13 + i);
    }
    final pot = polygon(const [Offset(8.3, 6.5), Offset(12.7, 6.5), Offset(12, 10), Offset(9, 10)]);
    pen.fill(pot, SketchColors.white);
    pen.hatch(pot, SketchColors.coral, spacing: 0.8, seed: 16);
    pen.stroke(pot, SketchColors.ink, width: 0.6, seed: 16);
    // Three cups.
    for (final (i, (x, color)) in const [
      (15.0, SketchColors.coral),
      (18.2, SketchColors.inkSoft),
      (21.4, SketchColors.sunEdge),
    ].indexed) {
      final cup = Path()
        ..moveTo(x, 6.5)
        ..lineTo(x + 2.4, 6.5)
        ..lineTo(x + 2.1, 10)
        ..lineTo(x + 0.3, 10)
        ..close();
      pen.fill(cup, SketchColors.white);
      pen.hatch(cup, color, spacing: 0.7, seed: 17 + i);
      pen.stroke(cup, color, width: 0.6, seed: 17 + i);
    }
    final board = rectPath(0, 10, 24.5, 11.5);
    pen.fill(board, SketchColors.woodLight);
    pen.hatch(board, SketchColors.wood, spacing: 0.8, seed: 20);
    pen.stroke(board, SketchColors.ink, width: 0.8, seed: 20);
    for (final x in const [3.0, 20.0]) {
      pen.stroke(
        Path()
          ..moveTo(x, 11.5)
          ..lineTo(x, 15)
          ..lineTo(x + 2.2, 11.5),
        SketchColors.ink,
        width: 0.7,
      );
    }
  }

  void _utensils(SketchPen pen, Offset from, Offset to) {
    pen.line(from, to, SketchColors.ink, width: 0.9, seed: 21);
    final span = to.dx - from.dx;
    // Spoon, ladle, whisk.
    final spoonX = from.dx + span * 0.2;
    pen.line(Offset(spoonX, from.dy), Offset(spoonX, from.dy + 7), SketchColors.ink, width: 0.7, sketchy: false);
    pen.stroke(ovalPath(Offset(spoonX, from.dy + 8.6), 2.2, 3.2), SketchColors.ink, width: 0.7, seed: 22);
    final ladleX = from.dx + span * 0.5;
    pen.line(Offset(ladleX, from.dy), Offset(ladleX, from.dy + 8), SketchColors.ink, width: 0.7, sketchy: false);
    final ladle = Path()
      ..moveTo(ladleX - 2.2, from.dy + 8)
      ..quadraticBezierTo(ladleX, from.dy + 12, ladleX + 2.2, from.dy + 8)
      ..close();
    pen.fill(ladle, SketchColors.inkWash);
    pen.stroke(ladle, SketchColors.ink, width: 0.7, seed: 23);
    final whiskX = from.dx + span * 0.8;
    pen.line(Offset(whiskX, from.dy), Offset(whiskX, from.dy + 4), SketchColors.ink, width: 0.7, sketchy: false);
    for (final dx in const [-1.4, 0.0, 1.4]) {
      pen.stroke(
        Path()
          ..moveTo(whiskX, from.dy + 4)
          ..quadraticBezierTo(whiskX + dx * 1.6, from.dy + 8, whiskX, from.dy + 10),
        SketchColors.ink,
        width: 0.45,
        sketchy: false,
      );
    }
  }

  void _cabinets(SketchPen pen, double w, double h) {
    final right = KitchenPositions.counterRight * w;
    final front = KitchenPositions.counterFrontBottom * h;
    final ground = SceneMetrics.groundLine * h;
    final body = rectPath(0, front, right, ground + 0.6);
    pen.fill(body, SketchColors.white);
    pen.hatch(body, SketchColors.inkWash.withValues(alpha: 0.6), spacing: 2.2, seed: 30);
    pen.stroke(body, SketchColors.ink, width: 0.9, seed: 30);
    for (final (i, door) in KitchenPositions.cabinetDoors.indexed) {
      final r = Rect.fromLTRB(door.left * w, door.top * h, door.right * w, door.bottom * h);
      final path = Path()..addRect(r);
      pen.fill(path, SketchColors.white);
      pen.hatch(path, SketchColors.woodLight, spacing: 1.4, angle: -1.3, width: 0.5, seed: 31 + i);
      pen.stroke(path, SketchColors.ink, width: 0.8, seed: 31 + i);
      pen.stroke(Path()..addRect(r.deflate(1.4)), SketchColors.inkSoft, width: 0.4, sketchy: false, seed: 35 + i);
      pen.fill(ovalPath(Offset(r.right - r.width * 0.18, r.center.dy), 1.6, 1.6), SketchColors.ink);
    }
    // Countertop slab.
    final top = rectPath(-1, KitchenPositions.counterTop * h, right + 0.5, front);
    pen.fill(top, SketchColors.woodLight);
    pen.hatch(top, SketchColors.wood, spacing: 0.9, angle: -0.1, seed: 40);
    pen.stroke(top, SketchColors.ink, width: 1.0, seed: 40);
  }

  void _stove(SketchPen pen, double w, double h) {
    final l = KitchenPositions.stoveLeft * w;
    final r = KitchenPositions.stoveRight * w;
    final top = KitchenPositions.counterTop * h;
    final ground = SceneMetrics.groundLine * h;
    final body = rectPath(l, top, r, ground + 0.6);
    pen.fill(body, SketchColors.white);
    pen.hatch(body, SketchColors.inkWash.withValues(alpha: 0.4), spacing: 2.4, seed: 41);
    pen.stroke(body, SketchColors.ink, width: 0.9, seed: 41);
    final slab = rectPath(l - 0.5, top, r + 0.5, top + 2.4);
    pen.fill(slab, SketchColors.pencil.withValues(alpha: 0.85));
    pen.stroke(slab, SketchColors.ink, width: 0.8, seed: 42);
    for (var i = 0; i < 4; i++) {
      final knob = ovalPath(Offset(l + 3 + i * (r - l - 6) / 3, top + 4.6), 2.2, 2.2);
      pen.fill(knob, SketchColors.white);
      pen.stroke(knob, SketchColors.ink, width: 0.6, sketchy: false, seed: 43 + i);
    }
    final door = rectPath(l + 2, top + 7.5, r - 2, ground - 2);
    pen.stroke(door, SketchColors.ink, width: 0.8, seed: 47);
    final glass = rectPath(l + 4.5, top + 11.5, r - 4.5, ground - 6);
    pen.fill(glass, const Color(0xFF3B3F63));
    pen.hatch(glass, SketchColors.ink, spacing: 1.2, seed: 48, cross: true);
    pen.line(Offset(l + 4, top + 9.4), Offset(r - 4, top + 9.4), SketchColors.ink, width: 1.2, sketchy: false);

    // The pan on its burner (static; the fish is an animated prop).
    final pan = Offset(KitchenPositions.fishPanPosition.dx * w, top);
    pen.hatch(ovalPath(pan + const Offset(0, -0.4), 13, 1.6), SketchColors.sunEdge, spacing: 0.7, seed: 49);
    pen.line(pan + const Offset(6, -2), pan + const Offset(14, -4.5), SketchColors.pencil, width: 1.6, sketchy: false);
    final bowl = Path()
      ..moveTo(pan.dx - 7.5, pan.dy - 3.4)
      ..lineTo(pan.dx + 7.5, pan.dy - 3.4)
      ..quadraticBezierTo(pan.dx + 7, pan.dy - 0.2, pan.dx, pan.dy - 0.2)
      ..quadraticBezierTo(pan.dx - 7, pan.dy - 0.2, pan.dx - 7.5, pan.dy - 3.4)
      ..close();
    pen.fill(bowl, const Color(0xFF55596F));
    pen.hatch(bowl, SketchColors.pencil, spacing: 0.8, seed: 50);
    pen.stroke(bowl, SketchColors.ink, width: 0.8, seed: 50);
  }

  void _fridge(SketchPen pen, Offset topLeft, Offset bottomRight) {
    final rect = Rect.fromPoints(topLeft, bottomRight);
    final fridge = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)));
    pen.fill(fridge, SketchColors.white);
    pen.hatch(fridge, SketchColors.inkWash.withValues(alpha: 0.7), spacing: 2.2, angle: -1.2, seed: 51);
    pen.stroke(fridge, SketchColors.ink, width: 1.0, seed: 51);
    final split = rect.top + rect.height * 0.3;
    pen.line(Offset(rect.left, split), Offset(rect.right, split), SketchColors.ink, width: 0.8, seed: 52);
    for (final (y0, y1) in [(split - 8, split - 2), (split + 3, split + 14)]) {
      pen.line(Offset(rect.left + 2.4, y0), Offset(rect.left + 2.4, y1), SketchColors.ink, width: 1.4, sketchy: false);
    }
    // Magnets: a heart, a fish doodle, a note.
    final c = Offset(rect.center.dx + 2, split + 8);
    final heart = Path()
      ..moveTo(c.dx, c.dy + 2)
      ..cubicTo(c.dx - 3, c.dy, c.dx - 1.6, c.dy - 2.4, c.dx, c.dy - 1)
      ..cubicTo(c.dx + 1.6, c.dy - 2.4, c.dx + 3, c.dy, c.dx, c.dy + 2)
      ..close();
    pen.fill(heart, SketchColors.coral);
    final note = rectPath(rect.center.dx - 1, split + 13, rect.center.dx + 6, split + 20);
    pen.fill(note, const Color(0xFFFFF4C2));
    pen.stroke(note, SketchColors.sunEdge, width: 0.5, sketchy: false);
    for (var i = 0; i < 3; i++) {
      final y = split + 15 + i * 1.6;
      pen.line(Offset(rect.center.dx, y), Offset(rect.center.dx + 5, y), SketchColors.inkSoft, width: 0.3, sketchy: false, wobble: 0);
    }
    pen.stroke(
      Path()
        ..moveTo(rect.center.dx - 1, rect.top + 6)
        ..quadraticBezierTo(rect.center.dx + 2, rect.top + 3.5, rect.center.dx + 5, rect.top + 6)
        ..quadraticBezierTo(rect.center.dx + 2, rect.top + 8.5, rect.center.dx - 1, rect.top + 6)
        ..lineTo(rect.center.dx - 3, rect.top + 4.5)
        ..lineTo(rect.center.dx - 3, rect.top + 7.5)
        ..close(),
      SketchColors.inkSoft,
      width: 0.6,
      seed: 53,
    );
  }

  void _mat(SketchPen pen) {
    final mat = Path()..addRRect(RRect.fromLTRBR(-13, -3, 13, 3, const Radius.circular(1.5)));
    pen.fill(mat, SketchColors.white);
    pen.canvas.save();
    pen.canvas.clipPath(mat);
    for (var x = -13.0; x < 13; x += 4) {
      pen.fill(rectPath(x, -3, x + 2, 3), SketchColors.coral.withValues(alpha: 0.55));
    }
    pen.canvas.restore();
    pen.stroke(mat, SketchColors.ink, width: 0.7, seed: 54);
    for (final side in const [-1.0, 1.0]) {
      for (var y = -2.2; y <= 2.3; y += 1.1) {
        pen.line(Offset(13.2 * side, y), Offset(14.6 * side, y), SketchColors.ink, width: 0.35, sketchy: false, wobble: 0);
      }
    }
  }
}
