import 'package:flutter/widgets.dart';

import '../models/game_positions.dart';
import '../sketch/sketch.dart';
import 'scene_background.dart';

/// The bathroom. The tub itself is a scene prop (see `BathTubPainter`) so the
/// kitten can sit inside it.
class BathroomPainter extends SceneBackgroundPainter {
  BathroomPainter(super.unit, {super.phase});

  @override
  void paintScene(Canvas canvas, SketchPen pen, double w, double h) {
    void place(double x, double y, void Function() draw) =>
        SceneBackgroundPainter.place(canvas, Offset(x * w, y * h), draw);
    final groundY = h * SceneMetrics.groundLine;

    _wallTiles(pen, w, h * 0.50, groundY);
    ground(pen, w, h, shade: SketchColors.inkSoft, line: SketchColors.ink, seed: 21);
    _floorTiles(pen, w, groundY, h * SceneMetrics.groundBottom);

    place(0.10, 0.10, () => _window(pen));
    place(0.52, 0.11, () => _mirror(pen));
    place(0.52, 0.36, () => _basin(pen, groundY - h * 0.36));
    place(0.03, 0.30, () => _shelf(pen));
    place(0.07, 0.535, () => _faucet(pen));
    place(0.86, 0.21, () => _towel(pen));
    place(0.68, 0.748, () => _mat(pen));
    place(0.85, 0.53, () => _plant(pen, groundY - h * 0.53));

    // Bubble and water doodles.
    for (final (x, y, r) in const [
      (0.11, 0.565, 1.5), (0.15, 0.548, 1.0), (0.40, 0.57, 2.0), (0.44, 0.55, 1.1),
      (0.47, 0.785, 1.2), (0.505, 0.77, 0.8), (0.93, 0.775, 1.0),
    ]) {
      pen.stroke(ovalPath(Offset(x * w, y * h), r * 2, r * 2), SketchColors.inkSoft,
          width: 0.5, sketchy: false, wobble: 0.1);
    }
  }

  void _wallTiles(SketchPen pen, double w, double top, double bottom) {
    final area = rectPath(0, top, w, bottom);
    pen.hatch(area, SketchColors.inkWash.withValues(alpha: 0.5), spacing: 2.6, angle: -0.8, seed: 22);
    final paint = Paint()
      ..color = SketchColors.inkSoft.withValues(alpha: 0.55)
      ..strokeWidth = 0.4;
    const tile = 7.0;
    for (var x = 0.0; x <= w; x += tile) {
      pen.canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }
    for (var y = top; y <= bottom; y += tile) {
      pen.canvas.drawLine(Offset(0, y), Offset(w, y), paint);
    }
    pen.line(Offset(-2, top), Offset(w + 2, top), SketchColors.ink, width: 0.9, seed: 23);
  }

  void _floorTiles(SketchPen pen, double w, double top, double bottom) {
    final paint = Paint()
      ..color = SketchColors.inkSoft.withValues(alpha: 0.35)
      ..strokeWidth = 0.4;
    for (var x = -20.0; x <= w + 20; x += 12) {
      pen.canvas.drawLine(Offset(x, top), Offset(x + (x - w / 2) * 0.35, bottom), paint);
    }
    for (final f in const [0.3, 0.65]) {
      final y = top + (bottom - top) * f;
      pen.canvas.drawLine(Offset(0, y), Offset(w, y), paint);
    }
  }

  /// A small window with a round top, showing the time of day.
  void _window(SketchPen pen) {
    final frame = Path()
      ..moveTo(0, 18)
      ..lineTo(0, 7)
      ..arcToPoint(const Offset(18, 7), radius: const Radius.circular(9))
      ..lineTo(18, 18)
      ..close();
    pen.canvas.save();
    pen.canvas.clipPath(frame);
    windowSky(pen, const Rect.fromLTRB(0, -2, 18, 18), seed: 28);
    pen.canvas.restore();
    pen.stroke(frame, SketchColors.ink, width: 1.0, seed: 29);
    pen.line(const Offset(9, -2), const Offset(9, 18), SketchColors.ink, width: 0.6);
    pen.line(const Offset(0, 9.5), const Offset(18, 9.5), SketchColors.ink, width: 0.6);
    final sill = rectPath(-1.5, 18, 19.5, 19.8);
    pen.fill(sill, SketchColors.white);
    pen.stroke(sill, SketchColors.ink, width: 0.7, seed: 30);
  }

  void _mirror(SketchPen pen) {
    pen.fill(ovalPath(const Offset(0, -1.5), 1.6, 1.6), SketchColors.ink);
    final outer = ovalPath(const Offset(0, 17), 30, 36);
    final inner = ovalPath(const Offset(0, 17), 25, 31);
    pen.fill(outer, SketchColors.white);
    pen.hatch(Path.combine(PathOperation.difference, outer, inner), SketchColors.inkSoft,
        spacing: 0.9, seed: 24);
    pen.hatch(inner, SketchColors.inkWash, spacing: 2.4, angle: -0.6, seed: 25);
    for (final (a, b) in const [
      (Offset(-7, 9), Offset(-2, 4)),
      (Offset(-8.5, 14), Offset(-1, 6.5)),
    ]) {
      pen.line(a, b, SketchColors.white, width: 1.6, sketchy: false, wobble: 0);
    }
    pen.stroke(outer, SketchColors.ink, width: 1.1, seed: 26);
    pen.stroke(inner, SketchColors.ink, width: 0.7, seed: 27);
  }

  void _basin(SketchPen pen, double toGround) {
    final pedestal = rectPath(-3.5, 8, 3.5, toGround - 1.5);
    pen.fill(pedestal, SketchColors.white);
    pen.hatch(pedestal, SketchColors.inkWash, spacing: 1.2, seed: 28);
    pen.stroke(pedestal, SketchColors.ink, width: 0.8, seed: 28);
    final foot = rectPath(-6.5, toGround - 1.8, 6.5, toGround + 0.6);
    pen.fill(foot, SketchColors.white);
    pen.stroke(foot, SketchColors.ink, width: 0.8, seed: 29);

    // Tap.
    pen.tube(
      Path()
        ..moveTo(0, -1)
        ..lineTo(0, -6)
        ..lineTo(4, -6),
      width: 1.6,
      outline: SketchColors.ink,
      fill: SketchColors.white,
      lineWidth: 0.6,
    );
    final bowl = Path()
      ..moveTo(-15, 0)
      ..quadraticBezierTo(0, 22, 15, 0)
      ..close();
    pen.fill(bowl, SketchColors.white);
    pen.hatch(bowl, SketchColors.inkWash, spacing: 1.4, angle: -1.1, seed: 30);
    pen.stroke(bowl, SketchColors.ink, width: 1.0, seed: 30);
    final rim = ovalPath(Offset.zero, 30, 5);
    pen.fill(rim, SketchColors.white);
    pen.hatch(ovalPath(const Offset(0, 0.4), 24, 3), SketchColors.inkSoft, spacing: 0.8, seed: 31);
    pen.stroke(rim, SketchColors.ink, width: 0.9, seed: 31);
  }

  void _shelf(SketchPen pen) {
    // Pet shampoo with a pump and a paw label.
    final bottle = Path()..addRRect(RRect.fromLTRBR(3, 0, 10, 10.5, const Radius.circular(1.6)));
    pen.fill(bottle, SketchColors.white);
    pen.hatch(bottle, SketchColors.pink, spacing: 0.8, seed: 40);
    pen.stroke(bottle, SketchColors.pinkDeep, width: 0.7, seed: 40);
    pen.stroke(rectPath(5.4, -2.6, 7.6, 0), SketchColors.pinkDeep, width: 0.6, sketchy: false);
    pen.line(const Offset(6.5, -2.6), const Offset(9.5, -2.6), SketchColors.pinkDeep, width: 0.7, sketchy: false);
    pen.fill(ovalPath(const Offset(6.5, 6.4), 2.6, 2), SketchColors.ink);
    for (final toe in const [Offset(5.2, 4.6), Offset(6.1, 4.0), Offset(6.9, 4.0), Offset(7.8, 4.6)]) {
      pen.fill(ovalPath(toe, 0.9, 1.0), SketchColors.ink);
    }

    final jar = rectPath(12.5, 4, 18, 10.5);
    pen.fill(jar, SketchColors.white);
    pen.hatch(jar, SketchColors.inkSoft, spacing: 0.8, seed: 41);
    pen.stroke(jar, SketchColors.ink, width: 0.7, seed: 41);
    pen.stroke(rectPath(12, 2.6, 18.5, 4), SketchColors.ink, width: 0.6, sketchy: false);

    // Rubber duck.
    final duck = Path()
      ..addOval(Rect.fromCenter(center: const Offset(24.5, 8), width: 8.5, height: 5))
      ..addOval(Rect.fromCircle(center: const Offset(26.5, 4.4), radius: 2.3));
    pen.fill(duck, SketchColors.sun);
    pen.hatch(duck, SketchColors.sunEdge, spacing: 0.8, seed: 42);
    pen.stroke(duck, SketchColors.sunEdge, width: 0.6, seed: 42);
    pen.fill(polygon(const [Offset(28.5, 4.2), Offset(30.6, 4.9), Offset(28.5, 5.6)]), SketchColors.wool);
    pen.fill(ovalPath(const Offset(27, 3.8), 0.7, 0.7), SketchColors.pencil);

    final board = rectPath(0, 10.5, 31, 12.3);
    pen.fill(board, SketchColors.white);
    pen.hatch(board, SketchColors.inkSoft, spacing: 0.8, seed: 43);
    pen.stroke(board, SketchColors.ink, width: 0.8, seed: 43);
    for (final x in const [4.0, 25.0]) {
      pen.stroke(
        Path()
          ..moveTo(x, 12.3)
          ..lineTo(x, 16)
          ..lineTo(x + 2.4, 12.3),
        SketchColors.ink,
        width: 0.7,
      );
    }
  }

  void _faucet(SketchPen pen) {
    pen.tube(
      Path()
        ..moveTo(0, 0)
        ..lineTo(0, 3)
        ..lineTo(7, 3)
        ..lineTo(7, 5),
      width: 2,
      outline: SketchColors.ink,
      fill: SketchColors.white,
      lineWidth: 0.6,
    );
    pen.line(const Offset(-1.6, 0), const Offset(1.6, 0), SketchColors.ink, width: 0.8, sketchy: false);
    pen.line(const Offset(0, -1.4), const Offset(0, 1.4), SketchColors.ink, width: 0.8, sketchy: false);
    final drop = Path()
      ..moveTo(7, 7)
      ..quadraticBezierTo(8.2, 9, 7, 9.6)
      ..quadraticBezierTo(5.8, 9, 7, 7)
      ..close();
    pen.fill(drop, SketchColors.inkWash);
    pen.stroke(drop, SketchColors.inkSoft, width: 0.5, sketchy: false);
  }

  void _towel(SketchPen pen) {
    pen.stroke(ovalPath(Offset.zero, 2, 2), SketchColors.ink, width: 0.7, sketchy: false);
    final towel = Path()
      ..moveTo(-6.5, 1)
      ..quadraticBezierTo(0, -0.5, 6.5, 1)
      ..lineTo(7, 23)
      ..quadraticBezierTo(5.25, 24.4, 3.5, 23)
      ..quadraticBezierTo(1.75, 24.4, 0, 23)
      ..quadraticBezierTo(-1.75, 24.4, -3.5, 23)
      ..quadraticBezierTo(-5.25, 24.4, -7, 23)
      ..close();
    pen.fill(towel, const Color(0xFFFCE6EC));
    pen.hatch(towel, SketchColors.pink, spacing: 1.2, angle: -1.2, seed: 44);
    pen.canvas.save();
    pen.canvas.clipPath(towel);
    pen.hatch(rectPath(-8, 15, 8, 18), SketchColors.pinkDeep, spacing: 0.7, seed: 45, cross: true);
    pen.hatch(rectPath(-8, 19, 8, 20.2), SketchColors.ink, spacing: 0.6, seed: 46);
    pen.canvas.restore();
    pen.stroke(towel, SketchColors.pinkDeep, width: 0.8, seed: 47);
    pen.line(const Offset(-6.5, 4), const Offset(6.5, 4), SketchColors.pinkDeep, width: 0.5, sketchy: false);
  }

  void _mat(SketchPen pen) {
    final mat = Path()..addRRect(RRect.fromLTRBR(-15, -3.6, 15, 3.6, const Radius.circular(3.4)));
    pen.fill(mat, SketchColors.inkWash.withValues(alpha: 0.5));
    pen.hatch(mat, SketchColors.inkSoft, spacing: 1.1, seed: 48, cross: true);
    pen.stroke(mat, SketchColors.ink, width: 0.8, seed: 48);
    for (final side in const [-1.0, 1.0]) {
      for (var y = -2.6; y <= 2.7; y += 1.3) {
        pen.line(Offset(15.2 * side, y), Offset(16.8 * side, y), SketchColors.ink,
            width: 0.4, sketchy: false, wobble: 0);
      }
    }
  }

  void _plant(SketchPen pen, double toGround) {
    for (final (i, tip) in const [Offset(1, 1), Offset(4.5, -3), Offset(9.5, -2.5), Offset(13.5, 2)].indexed) {
      leaf(pen, Offset(7, toGround - 7.5), tip + Offset(0, toGround - 18), width: 1.8, seed: 50 + i);
    }
    final pot = polygon([
      Offset(2, toGround - 8),
      Offset(12, toGround - 8),
      Offset(11, toGround),
      Offset(3, toGround),
    ]);
    pen.fill(pot, SketchColors.white);
    pen.hatch(pot, SketchColors.inkSoft, spacing: 0.9, seed: 55);
    pen.stroke(pot, SketchColors.ink, width: 0.8, seed: 55);
  }
}
