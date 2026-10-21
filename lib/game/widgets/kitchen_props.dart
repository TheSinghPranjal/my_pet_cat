import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../animations/object_animations.dart';
import '../sketch/sketch.dart';

/// Small drinking glass (100x140 box). [rotation] tips it around its base.
class GlassPainter extends CustomPainter {
  GlassPainter({this.rotation = 0, this.appear = 1, this.pop = 0, this.motionMarks = false});

  static const aspect = 100 / 140;

  final double rotation;
  final double appear;
  final double pop;

  /// Two little "wobble" marks, used on the action button.
  final bool motionMarks;

  @override
  void paint(Canvas canvas, Size size) {
    paintSpawned(canvas, size,
        boxWidth: 100,
        appear: appear,
        pop: pop,
        popCenter: const Offset(50, 80),
        popRadius: 50,
        draw: (pen) {
          final c = pen.canvas;
          c.save();
          c.translate(50, 136);
          c.rotate(rotation);
          c.translate(-50, -136);
          final glass = Path()
            ..moveTo(18, 14)
            ..lineTo(82, 14)
            ..lineTo(74, 132)
            ..quadraticBezierTo(50, 138, 26, 132)
            ..close();
          pen.fill(glass, const Color(0xFFF3F7FF));
          final water = Path()
            ..moveTo(23.5, 62)
            ..quadraticBezierTo(50, 68, 77, 62)
            ..lineTo(74, 132)
            ..quadraticBezierTo(50, 138, 26, 132)
            ..close();
          pen.fill(water, SketchColors.inkWash.withValues(alpha: 0.7));
          pen.hatch(water, SketchColors.inkSoft, spacing: 5, angle: -0.6, width: 1.4, seed: 1);
          pen.line(const Offset(30, 24), const Offset(34, 120), SketchColors.white, width: 6, sketchy: false, wobble: 0);
          pen.stroke(glass, SketchColors.ink, width: 3.4, seed: 2);
          pen.stroke(ovalPath(const Offset(50, 14), 64, 9), SketchColors.ink, width: 2.6, seed: 3);
          c.restore();
          if (motionMarks) {
            for (final (a, b) in const [(Offset(90, 40), Offset(98, 30)), (Offset(92, 60), Offset(100, 56))]) {
              pen.line(a, b, SketchColors.ink, width: 3.4, sketchy: false);
            }
          }
        });
  }

  @override
  bool shouldRepaint(GlassPainter old) =>
      old.rotation != rotation || old.appear != appear || old.pop != pop || old.motionMarks != motionMarks;
}

/// Fish-shaped cat biscuit (100x60 box). [fill] shrinks it while eaten.
class TreatPainter extends CustomPainter {
  TreatPainter({this.fill = 1, this.appear = 1, this.pop = 0});

  static const aspect = 100 / 60;

  final double fill;
  final double appear;
  final double pop;

  @override
  void paint(Canvas canvas, Size size) {
    paintSpawned(canvas, size,
        boxWidth: 100,
        appear: appear * (0.35 + 0.65 * fill),
        pop: pop,
        popCenter: const Offset(50, 30),
        popRadius: 40,
        popColor: SketchColors.coral,
        draw: (pen) => drawFishShape(pen,
            body: const Color(0xFFF2B27A), shade: SketchColors.coral, outline: SketchColors.kibbleDark, seed: 4));
  }

  @override
  bool shouldRepaint(TreatPainter old) => old.fill != fill || old.appear != appear || old.pop != pop;
}

/// A little fish in a 100x60 box, used by treats and the cooked fish.
void drawFishShape(SketchPen pen,
    {required Color body, required Color shade, required Color outline, required int seed, double eyeAlpha = 1}) {
  final fish = Path()
    ..moveTo(8, 32)
    ..quadraticBezierTo(30, 6, 64, 14)
    ..quadraticBezierTo(76, 18, 80, 30)
    ..lineTo(96, 14)
    ..lineTo(92, 32)
    ..lineTo(96, 50)
    ..lineTo(80, 36)
    ..quadraticBezierTo(74, 50, 60, 52)
    ..quadraticBezierTo(28, 56, 8, 32)
    ..close();
  pen.fill(fish, body);
  pen.hatch(fish, shade, spacing: 3.2, angle: -0.8, width: 1.4, seed: seed);
  for (final x in const [40.0, 52.0]) {
    pen.stroke(
      Path()
        ..moveTo(x, 18)
        ..quadraticBezierTo(x + 5, 33, x, 48),
      outline.withValues(alpha: 0.7),
      width: 2,
      sketchy: false,
    );
  }
  pen.stroke(fish, outline, width: 2.8, seed: seed + 1);
  pen.fill(ovalPath(const Offset(22, 28), 6, 6), SketchColors.pencil.withValues(alpha: eyeAlpha));
  pen.fill(ovalPath(const Offset(21, 27), 2, 2), SketchColors.white);
}

/// Fish for the pan (100x55 box): pale pink when raw, golden when [progress]
/// reaches 1, through a few in-between shades.
class FishPainter extends CustomPainter {
  FishPainter({this.progress = 0, this.appear = 1, this.pop = 0});

  static const aspect = 100 / 55;

  final double progress;
  final double appear;
  final double pop;

  static const _raw = Color(0xFFF7D3DA);
  static const _rawShade = Color(0xFF9DB4D8);
  static const _cooked = Color(0xFFF2B05E);
  static const _cookedShade = Color(0xFFD9733A);

  @override
  void paint(Canvas canvas, Size size) {
    // Discrete cooking frames read better than a smooth blend.
    final stage = (progress * 3).floor().clamp(0, 3) / 3;
    paintSpawned(canvas, size,
        boxWidth: 100,
        appear: appear,
        pop: pop,
        popCenter: const Offset(50, 28),
        popRadius: 40,
        draw: (pen) {
          drawFishShape(pen,
              body: Color.lerp(_raw, _cooked, stage)!,
              shade: Color.lerp(_rawShade, _cookedShade, stage)!,
              outline: Color.lerp(SketchColors.ink, SketchColors.kibbleDark, stage)!,
              seed: 7);
          if (stage > 0.5) {
            // Grill marks on the cooked side.
            for (final x in const [30.0, 46.0, 62.0]) {
              pen.line(Offset(x, 22), Offset(x + 8, 42), SketchColors.kibbleDark.withValues(alpha: 0.6),
                  width: 2.2, sketchy: false);
            }
          }
        });
  }

  @override
  bool shouldRepaint(FishPainter old) => old.progress != progress || old.appear != appear || old.pop != pop;
}

/// Serving plate (100x45 box) with the cooked fish on it; [fill] shrinks the
/// fish as it's eaten (0 = empty plate).
class PlatePainter extends CustomPainter {
  PlatePainter({this.fill = 0, this.appear = 1, this.pop = 0});

  static const aspect = 100 / 45;

  final double fill;
  final double appear;
  final double pop;

  @override
  void paint(Canvas canvas, Size size) {
    paintSpawned(canvas, size,
        boxWidth: 100,
        appear: appear,
        pop: pop,
        popCenter: const Offset(50, 28),
        popRadius: 46,
        draw: (pen) {
          pen.hatch(ovalPath(const Offset(50, 41), 92, 6), SketchColors.inkSoft, spacing: 1.6, width: 0.7, seed: 1);
          final plate = ovalPath(const Offset(50, 32), 96, 22);
          pen.fill(plate, SketchColors.white);
          pen.hatch(plate, SketchColors.inkWash, spacing: 2.4, seed: 2);
          pen.stroke(plate, SketchColors.ink, width: 1.8, seed: 3);
          pen.stroke(ovalPath(const Offset(50, 31), 70, 13), SketchColors.inkSoft, width: 1.0, seed: 4, sketchy: false);
          if (fill > 0.02) {
            final c = pen.canvas;
            c.save();
            c.translate(50, 33);
            c.scale(0.62 * (0.3 + 0.7 * fill));
            c.translate(-50, -40);
            drawFishShape(pen,
                body: FishPainter._cooked, shade: FishPainter._cookedShade, outline: SketchColors.kibbleDark, seed: 7);
            c.restore();
          }
        });
  }

  @override
  bool shouldRepaint(PlatePainter old) => old.fill != fill || old.appear != appear || old.pop != pop;
}

/// The treat cabinet's door as it opens. Drawn over the static door in the
/// background at exactly the same rect: the dark inside with a treat jar,
/// and the door panel swinging toward its left hinge.
class CabinetDoorPainter extends CustomPainter {
  CabinetDoorPainter({required this.open});

  /// 0 closed (nothing drawn), small values rattle, 1 fully open.
  final double open;

  @override
  void paint(Canvas canvas, Size size) {
    if (open <= 0) return;
    final pen = SketchPen(canvas, pxPerUnit: size.width / 30);
    final w = size.width, h = size.height;
    final inside = rectPath(0, 0, w, h);
    pen.fill(inside, const Color(0xFF3B3F63));
    pen.hatch(inside, SketchColors.ink, spacing: w / 14, seed: 1, cross: true);
    // Treat jar on the shelf inside.
    final jar = Path()..addRRect(RRect.fromLTRBR(w * 0.52, h * 0.38, w * 0.86, h * 0.8, Radius.circular(w * 0.05)));
    pen.fill(jar, const Color(0xFFFDE6C8));
    pen.stroke(jar, SketchColors.coral, width: w / 60, seed: 2);
    pen.line(Offset(0, h * 0.82), Offset(w, h * 0.82), SketchColors.inkWash, width: w / 50, sketchy: false);

    // Door panel: shrinks toward the left hinge as it swings open.
    final panelWidth = w * (1 - 0.85 * open.clamp(0.0, 1.0));
    final panel = rectPath(0, 0, panelWidth, h);
    pen.fill(panel, SketchColors.white);
    pen.hatch(panel, SketchColors.woodLight, spacing: w / 18, angle: -1.3, width: w / 120, seed: 3);
    pen.stroke(panel, SketchColors.ink, width: w / 45, seed: 4);
    pen.fill(ovalPath(Offset(panelWidth * 0.82, h * 0.5), w * 0.07, w * 0.07), SketchColors.ink);
  }

  @override
  bool shouldRepaint(CabinetDoorPainter old) => old.open != open;
}

/// Frying pan with a fish and aroma curls, for the Fish button and the
/// Kitchen tab.
class PanIconPainter extends CustomPainter {
  PanIconPainter({this.withFish = true, this.color = SketchColors.ink});

  final bool withFish;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = math.min(size.width, size.height) / 40;
    final pen = SketchPen(canvas, pxPerUnit: k);
    canvas.save();
    canvas.translate((size.width - 40 * k) / 2, (size.height - 40 * k) / 2);
    canvas.scale(k);
    for (final x in const [14.0, 22.0]) {
      pen.stroke(
        Path()
          ..moveTo(x, 17)
          ..quadraticBezierTo(x - 3, 13, x, 9)
          ..quadraticBezierTo(x + 3, 5, x, 2),
        SketchColors.sunEdge,
        width: 1.3,
        sketchy: false,
      );
    }
    pen.line(const Offset(30, 26), const Offset(39, 22), color, width: 2.6, sketchy: false);
    final pan = Path()
      ..moveTo(3, 22)
      ..lineTo(31, 22)
      ..quadraticBezierTo(30, 32, 17, 32)
      ..quadraticBezierTo(4, 32, 3, 22)
      ..close();
    pen.fill(pan, color.withValues(alpha: 0.85));
    pen.stroke(pan, color, width: 1.4, seed: 1);
    if (withFish) {
      canvas.save();
      canvas.translate(5, 15);
      canvas.scale(0.24);
      drawFishShape(pen,
          body: FishPainter._cooked, shade: FishPainter._cookedShade, outline: SketchColors.kibbleDark, seed: 9);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(PanIconPainter old) => old.withFish != withFish || old.color != color;
}
