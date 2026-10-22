import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../models/game_positions.dart';
import '../../sketch/sketch.dart';

const _sage = Color(0xFFCDEBDD);
const _sageDeep = Color(0xFF5FA88F);
const _water = Color(0xFFBFE2F7);
const _goldfish = Color(0xFFFF9A3C);
const _goldfishDeep = Color(0xFFE5602E);

/// A round goldfish bowl on a little wooden stool. The fish swims on its
/// own clock and darts away ([dodge], -1..1) from paws; [splash] ruffles
/// the water and throws up drops. Drawn in a 40x36 unit box, bottom-centre.
class FishBowlPainter extends CustomPainter {
  FishBowlPainter({this.dodge = 0, this.splash = 0, this.time = 0});

  static const aspect = 40 / 36;

  final double dodge;
  final double splash;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 40;
    final pen = SketchPen(canvas, pxPerUnit: k);
    canvas.save();
    canvas.scale(k);

    // The stool.
    for (final x in const [9.0, 29.0]) {
      pen.line(
        Offset(x, 30),
        Offset(x + (x < 20 ? -1.5 : 1.5), 36),
        SketchColors.kibbleDark,
        width: 1.4,
        sketchy: false,
      );
    }
    final seat = ovalPath(const Offset(20, 29.5), 30, 5);
    pen.fill(seat, SketchColors.wood);
    pen.hatch(seat, SketchColors.kibbleDark.withValues(alpha: 0.5), spacing: 1.0, seed: 501);
    pen.stroke(seat, SketchColors.ink, width: 0.8, seed: 502);

    // The bowl, with water below a wavy surface.
    const c = Offset(20, 17);
    final glass = Path.combine(PathOperation.difference, ovalPath(c, 25, 24), rectPath(0, 0, 40, 5.5));
    pen.fill(glass, SketchColors.white.withValues(alpha: 0.85));
    final wave = 0.5 + splash * 1.6;
    final surface = Path()..moveTo(6, 10);
    for (var x = 6.0; x < 34; x += 3.5) {
      surface.quadraticBezierTo(
        x + 1.75,
        10 + (((x / 3.5).round().isEven) ? -wave : wave) * math.sin(time * 6 + x),
        x + 3.5,
        10,
      );
    }
    surface
      ..lineTo(34, 32)
      ..lineTo(6, 32)
      ..close();
    final water = Path.combine(PathOperation.intersect, glass, surface);
    pen.fill(water, _water);
    pen.hatch(water, SketchColors.inkSoft.withValues(alpha: 0.45), spacing: 1.4, angle: -0.5, seed: 503);
    canvas.save();
    canvas.clipPath(water);
    for (final (i, x) in const [11.0, 15.0, 24.0, 28.0].indexed) {
      pen.fill(
        ovalPath(Offset(x, 27.6), 3.4, 2.2),
        const [SketchColors.coral, SketchColors.sun, SketchColors.inkSoft, SketchColors.pink][i],
      );
    }
    for (final x in const [13.0, 27.0]) {
      final weed = Path()..moveTo(x, 28);
      for (var y = 28.0; y > 15; y -= 3) {
        weed.quadraticBezierTo(x + ((y ~/ 3).isEven ? 1.6 : -1.6) + math.sin(time * 1.4 + x) * 0.6, y - 1.5, x, y - 3);
      }
      pen.stroke(weed, SketchColors.leafDark, width: 0.8, sketchy: false, wobble: 0);
    }
    _fish(pen);
    // Bubbles.
    for (var i = 0; i < 3; i++) {
      final ph = (time * 0.6 + i / 3) % 1;
      pen.stroke(
        ovalPath(Offset(22 + i * 3.0, 26 - ph * 15), 1.3, 1.3),
        SketchColors.white,
        width: 0.4,
        sketchy: false,
        wobble: 0,
      );
    }
    canvas.restore();
    pen.stroke(glass, SketchColors.ink, width: 0.9, seed: 504);
    pen.stroke(ovalPath(const Offset(20, 5.6), 15, 2.4), SketchColors.ink, width: 0.7, sketchy: false, wobble: 0.1);
    pen.stroke(
      Path()..addArc(Rect.fromCircle(center: c, radius: 9.5), 3.6, 0.9),
      SketchColors.white,
      width: 1.4,
      sketchy: false,
      wobble: 0,
    );

    if (splash > 0.05) {
      for (final (i, d) in const [Offset(-6, -5), Offset(-1, -8), Offset(5, -6)].indexed) {
        final p = const Offset(19, 9) + d * (0.6 + splash);
        final drop = ovalPath(p, 1.6, 2.2);
        pen.fill(drop, _water.withValues(alpha: splash));
        pen.stroke(
          drop,
          SketchColors.inkSoft.withValues(alpha: splash),
          width: 0.4,
          sketchy: false,
          wobble: 0,
          seed: 505 + i,
        );
      }
    }
    canvas.restore();
  }

  void _fish(SketchPen pen) {
    final swim = math.sin(time * 0.9);
    final x = 20 + swim * 6 * (1 - dodge.abs()) + dodge * 8;
    final y = 19 + math.sin(time * 1.7) * 1.5 + dodge.abs() * 4;
    final dir = dodge != 0 ? dodge.sign : (math.cos(time * 0.9) >= 0 ? 1.0 : -1.0);
    final canvas = pen.canvas;
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(dir, 1);
    final wag = math.sin(time * 9) * 0.25;
    final tail = polygon([const Offset(-3, 0), Offset(-6.2, -2.4 + wag), Offset(-6.2, 2.4 + wag)]);
    pen.fill(tail, _goldfish);
    pen.stroke(tail, _goldfishDeep, width: 0.4, sketchy: false, wobble: 0);
    final body = ovalPath(Offset.zero, 7.4, 4.6);
    pen.fill(body, _goldfish);
    pen.hatch(body, _goldfishDeep, spacing: 0.8, angle: -0.8, width: 0.3, seed: 506);
    pen.stroke(body, _goldfishDeep, width: 0.5, sketchy: false, wobble: 0);
    pen.fill(ovalPath(const Offset(2, -0.5), 1.2, 1.2), SketchColors.eye);
    canvas.restore();
  }

  @override
  bool shouldRepaint(FishBowlPainter oldDelegate) =>
      oldDelegate.dodge != dodge || oldDelegate.splash != splash || oldDelegate.time != time;
}

/// The two long sage curtains by the window, painted over the whole stage in
/// stage coordinates. A hiding cat makes the right one bulge and tremble
/// ([lump]), with her striped tail poking out under the hem; [peek] shows
/// her eyes at its edge.
class CurtainsPainter extends CustomPainter {
  CurtainsPainter({required this.unit, this.lump = 0, this.peek = false, this.time = 0});

  final double unit;
  final double lump;
  final bool peek;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final k = unit / 100;
    final pen = SketchPen(canvas, pxPerUnit: k);
    final w = size.width / k, h = size.height / k;
    canvas.save();
    canvas.scale(k);
    final top = LivingRoomPositions.curtainTop * h;
    final floor = SceneMetrics.groundLine * h + 1;
    _panel(pen, -1, w * 0.085, top, floor, 0, 511);
    final tremble = lump > 0 ? math.sin(time * 28) * 0.5 : 0.0;
    _panel(
      pen,
      w * LivingRoomPositions.curtainLeft,
      w * LivingRoomPositions.curtainRight,
      top,
      floor,
      lump * 4 + tremble,
      512,
    );
    if (lump > 0) {
      // A striped tail tip, poking out under the hem.
      final base = Offset(w * 0.405, floor - 1.2);
      final tail = Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(base.dx + 4, base.dy + 0.6, base.dx + 6.5 + tremble, base.dy - 3.5);
      pen.tube(tail, width: 2.4, outline: const Color(0xFF3A3A42), fill: SketchColors.white, lineWidth: 0.4, seed: 513);
      pen.line(
        Offset(base.dx + 3, base.dy - 0.6),
        Offset(base.dx + 3.6, base.dy + 1.2),
        SketchColors.stripe,
        width: 0.6,
        sketchy: false,
      );
    }
    if (peek) {
      final edge = Offset(w * LivingRoomPositions.curtainRight + 1.2, floor - 9);
      for (final dx in const [0.0, 3.4]) {
        final eye = ovalPath(edge + Offset(dx, 0), 2.6, 3.2);
        pen.fill(eye, SketchColors.eye);
        pen.fill(ovalPath(edge + Offset(dx - 0.4, -0.6), 1.0, 1.0), SketchColors.white);
      }
    }
    canvas.restore();
  }

  void _panel(SketchPen pen, double left, double right, double top, double floor, double bulge, int seed) {
    final panel = Path()
      ..moveTo(left, top)
      ..lineTo(right, top)
      ..lineTo(right, floor * 0.88)
      ..quadraticBezierTo(right + bulge * 2.2, floor - 4, right + bulge * 0.6, floor)
      ..lineTo(left - bulge * 0.3, floor)
      ..quadraticBezierTo(left - bulge, floor - 4, left, floor * 0.88)
      ..close();
    pen.fill(panel, _sage);
    pen.hatch(panel, _sageDeep.withValues(alpha: 0.55), spacing: 1.3, angle: 1.45, width: 0.4, seed: seed);
    for (var x = left + 2.5; x < right - 1; x += 3) {
      pen.line(
        Offset(x, top + 1),
        Offset(x + bulge * 0.3, floor - 1),
        _sageDeep,
        width: 0.45,
        sketchy: false,
        wobble: 0.15,
      );
    }
    pen.stroke(panel, SketchColors.ink, width: 0.8, seed: seed + 10);
  }

  @override
  bool shouldRepaint(CurtainsPainter oldDelegate) =>
      oldDelegate.unit != unit ||
      oldDelegate.lump != lump ||
      oldDelegate.peek != peek ||
      (lump > 0 && oldDelegate.time != time);
}

/// Action-button icon: a heart over a little paw.
class PurrIconPainter extends CustomPainter {
  const PurrIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 40;
    final pen = SketchPen(canvas, pxPerUnit: k);
    canvas.save();
    canvas.scale(k);
    final heart = Path()
      ..moveTo(20, 24)
      ..cubicTo(6, 14, 10, 2, 20, 9)
      ..cubicTo(30, 2, 34, 14, 20, 24)
      ..close();
    pen.fill(heart, SketchColors.pink);
    pen.hatch(heart, SketchColors.pinkDeep, spacing: 1.3, seed: 521);
    pen.stroke(heart, SketchColors.pinkDeep, width: 1.2, seed: 522);
    pen.fill(ovalPath(const Offset(20, 33), 8, 6), SketchColors.ink);
    for (final toe in const [Offset(14.5, 28.5), Offset(18, 26.5), Offset(22, 26.5), Offset(25.5, 28.5)]) {
      pen.fill(ovalPath(toe, 3, 3.4), SketchColors.ink);
    }
    for (final (i, x) in const [3.0, 33.0].indexed) {
      final wave = Path()..moveTo(x, 14);
      for (var j = 0; j < 3; j++) {
        wave.quadraticBezierTo(x + 1 + j * 1.3, 14 + (j.isEven ? -1.4 : 1.4), x + 1.3 * (j + 1), 14);
      }
      pen.stroke(wave, SketchColors.pinkDeep, width: 0.8, sketchy: false, wobble: 0, seed: 523 + i);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(PurrIconPainter oldDelegate) => false;
}

/// Action-button icon: a window with a little bird outside.
class WindowIconPainter extends CustomPainter {
  const WindowIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 40;
    final pen = SketchPen(canvas, pxPerUnit: k);
    canvas.save();
    canvas.scale(k);
    final glass = rectPath(6, 4, 34, 32);
    pen.fill(glass, const Color(0xFFC9E6FF));
    pen.hatch(glass, SketchColors.inkSoft.withValues(alpha: 0.5), spacing: 2, seed: 531);
    final bird = ovalPath(const Offset(25, 13), 8, 6);
    pen.fill(bird, const Color(0xFF9CCBF5));
    pen.stroke(bird, SketchColors.ink, width: 0.8, sketchy: false);
    pen.fill(polygon(const [Offset(29, 12), Offset(32, 13), Offset(29, 14)]), SketchColors.sunEdge);
    pen.stroke(glass, SketchColors.ink, width: 1.4, seed: 532);
    pen.line(const Offset(20, 4), const Offset(20, 32), SketchColors.ink, width: 1.0);
    pen.line(const Offset(6, 18), const Offset(34, 18), SketchColors.ink, width: 1.0);
    for (final x in const [2.0, 31.0]) {
      final drape = rectPath(x, 2, x + 7, 36);
      pen.fill(drape, _sage);
      pen.hatch(drape, _sageDeep, spacing: 1.4, angle: 1.45, seed: 533);
      pen.stroke(drape, SketchColors.ink, width: 0.9, seed: 534);
    }
    final sill = rectPath(4, 32, 36, 35);
    pen.fill(sill, SketchColors.white);
    pen.stroke(sill, SketchColors.ink, width: 0.9, seed: 535);
    canvas.restore();
  }

  @override
  bool shouldRepaint(WindowIconPainter oldDelegate) => false;
}

/// Navigation icon: a little sofa.
class SofaIconPainter extends CustomPainter {
  const SofaIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 40;
    final pen = SketchPen(canvas, pxPerUnit: k);
    canvas.save();
    canvas.scale(k);
    final back = Path()..addRRect(RRect.fromLTRBR(7, 10, 33, 24, const Radius.circular(4)));
    final seat = Path()..addRRect(RRect.fromLTRBR(5, 22, 35, 31, const Radius.circular(3)));
    pen.fill(back, color.withValues(alpha: 0.85));
    pen.stroke(back, color, width: 1.4, wobble: 0.3, seed: 541);
    pen.fill(seat, color.withValues(alpha: 0.85));
    pen.stroke(seat, color, width: 1.4, wobble: 0.3, seed: 542);
    for (final x in const [3.0, 33.0]) {
      final arm = Path()..addRRect(RRect.fromLTRBR(x, 17, x + 5, 31, const Radius.circular(2.5)));
      pen.fill(arm, SketchColors.white);
      pen.stroke(arm, color, width: 1.3, wobble: 0.3, seed: 543);
    }
    for (final x in const [8.0, 31.0]) {
      pen.line(Offset(x, 31), Offset(x, 35), color, width: 1.8, sketchy: false);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SofaIconPainter oldDelegate) => oldDelegate.color != color;
}
