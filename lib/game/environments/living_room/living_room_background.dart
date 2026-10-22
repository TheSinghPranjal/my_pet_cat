import 'package:flutter/widgets.dart';

import '../../models/game_positions.dart';
import '../../sketch/sketch.dart';
import '../../widgets/scene_background.dart';

/// The living room where the girl hangs out: a tall window with a curtain
/// rod (the curtains themselves are animated props), a sage sofa with
/// cushions, picture frames, a hanging plant, a rug, and soft wallpaper.
class LivingRoomPainter extends SceneBackgroundPainter {
  LivingRoomPainter(super.unit, {super.phase});

  static const _sage = Color(0xFFCDEBDD);
  static const _sageDeep = Color(0xFF5FA88F);

  @override
  void paintScene(Canvas canvas, SketchPen pen, double w, double h) {
    void place(double x, double y, void Function() draw) =>
        SceneBackgroundPainter.place(canvas, Offset(x * w, y * h), draw);

    _wallpaper(pen, w, h);
    woodFloor(pen, w, h);
    _window(pen, w, h);
    place(0.52, 0.745, () => _rug(pen));
    place(0.66, 0.50, () => _sofa(pen, w, (SceneMetrics.groundLine - 0.50) * h));
    place(0.68, 0.30, () => _frame(pen, 13, 11, fish: true));
    place(0.86, 0.33, () => _frame(pen, 9, 12, fish: false));
    place(0.53, 0.06, () => _hangingPlant(pen));
  }

  /// Faint dotted wallpaper above the floor.
  void _wallpaper(SketchPen pen, double w, double h) {
    final paint = Paint()..color = _sageDeep.withValues(alpha: 0.18);
    for (var y = 6.0; y < h * SceneMetrics.groundLine - 2; y += 9) {
      for (var x = ((y ~/ 9).isEven ? 3.0 : 7.5); x < w; x += 9) {
        pen.canvas.drawCircle(Offset(x, y), 0.6, paint);
      }
    }
  }

  void _window(SketchPen pen, double w, double h) {
    final g = LivingRoomPositions.windowGlass;
    final glass = Rect.fromLTRB(g.left * w, g.top * h, g.right * w, g.bottom * h);
    final frame = glass.inflate(1.6);
    pen.fill(Path()..addRect(frame), SketchColors.white);
    windowSky(pen, glass, seed: 551);
    pen.stroke(Path()..addRect(frame), SketchColors.ink, width: 1.1, seed: 552);
    pen.stroke(Path()..addRect(glass), SketchColors.ink, width: 0.6, seed: 553);
    pen.line(Offset(glass.center.dx, glass.top), Offset(glass.center.dx, glass.bottom), SketchColors.ink, width: 0.8);
    pen.line(Offset(glass.left, glass.center.dy), Offset(glass.right, glass.center.dy), SketchColors.ink, width: 0.8);
    final sill = rectPath(
      frame.left - 2.5,
      LivingRoomPositions.sillY * h - 0.4,
      frame.right + 2.5,
      LivingRoomPositions.sillY * h + 2.2,
    );
    pen.fill(sill, SketchColors.white);
    pen.hatch(sill, SketchColors.inkSoft, spacing: 0.9, seed: 554);
    pen.stroke(sill, SketchColors.ink, width: 0.8, seed: 555);
    // Curtain rod with round finials.
    final rodY = LivingRoomPositions.curtainTop * h - 0.8;
    pen.line(Offset(-1, rodY), Offset(w * 0.435, rodY), SketchColors.wood, width: 1.6, sketchy: false);
    final finial = ovalPath(Offset(w * 0.44, rodY), 2.6, 2.6);
    pen.fill(finial, SketchColors.wood);
    pen.stroke(finial, SketchColors.ink, width: 0.5, sketchy: false);
  }

  void _rug(SketchPen pen) {
    final outer = ovalPath(Offset.zero, 52, 11);
    final inner = ovalPath(Offset.zero, 38, 7);
    pen.fill(outer, SketchColors.sun.withValues(alpha: 0.45));
    pen.hatch(
      Path.combine(PathOperation.difference, outer, inner),
      SketchColors.sunEdge,
      spacing: 1.0,
      angle: -0.5,
      seed: 556,
    );
    pen.fill(inner, _sage);
    pen.hatch(inner, _sageDeep, spacing: 1.3, seed: 557, cross: true);
    pen.stroke(outer, SketchColors.sunEdge, width: 0.8, seed: 558);
  }

  void _sofa(SketchPen pen, double w, double toGround) {
    final width = w * 0.33;
    for (final x in [4.0, width - 6]) {
      final leg = rectPath(x, toGround - 3, x + 2, toGround);
      pen.fill(leg, SketchColors.wood);
    }
    final back = Path()..addRRect(RRect.fromLTRBR(2, 0, width - 2, 13, const Radius.circular(4)));
    pen.fill(back, _sage);
    pen.hatch(back, _sageDeep, spacing: 1.1, angle: -1.0, seed: 559);
    pen.stroke(back, SketchColors.ink, width: 0.9, seed: 560);
    final base = rectPath(1, toGround - 6, width - 1, toGround - 3);
    pen.fill(base, _sage);
    pen.hatch(base, _sageDeep, spacing: 0.8, seed: 561, cross: true);
    pen.stroke(base, SketchColors.ink, width: 0.8, seed: 562);
    final seatWidth = (width - 10) / 2;
    for (var i = 0; i < 2; i++) {
      final x = 5 + i * seatWidth;
      final cushion = Path()
        ..addRRect(RRect.fromLTRBR(x, 11, x + seatWidth, toGround - 5.5, const Radius.circular(2.5)));
      pen.fill(cushion, SketchColors.white);
      pen.hatch(cushion, _sageDeep.withValues(alpha: 0.6), spacing: 1.3, angle: 0.3, seed: 563 + i);
      pen.stroke(cushion, SketchColors.ink, width: 0.8, seed: 563 + i);
    }
    for (final x in [-1.5, width - 6]) {
      final arm = Path()..addRRect(RRect.fromLTRBR(x, 6.5, x + 7.5, toGround - 4, const Radius.circular(3)));
      pen.fill(arm, _sage);
      pen.hatch(arm, _sageDeep, spacing: 0.9, angle: -0.7, seed: 565);
      pen.stroke(arm, SketchColors.ink, width: 0.9, seed: 566);
    }
    final pillow = Path()..addRRect(RRect.fromLTRBR(width * 0.55, 4, width * 0.55 + 9, 12, const Radius.circular(3)));
    pen.fill(pillow, SketchColors.pink);
    pen.hatch(pillow, SketchColors.pinkDeep, spacing: 1.0, seed: 567);
    pen.stroke(pillow, SketchColors.ink, width: 0.7, seed: 568);
  }

  void _frame(SketchPen pen, double fw, double fh, {required bool fish}) {
    final frame = rectPath(0, 0, fw, fh);
    pen.fill(frame, SketchColors.white);
    pen.stroke(frame, SketchColors.wood, width: 1.4, seed: fish ? 569 : 570);
    if (fish) {
      final body = ovalPath(Offset(fw * 0.45, fh * 0.55), 5, 3);
      pen.fill(body, const Color(0xFFFF9A3C));
      pen.fill(
        polygon([Offset(fw * 0.25, fh * 0.55), Offset(fw * 0.12, fh * 0.4), Offset(fw * 0.12, fh * 0.7)]),
        const Color(0xFFFF9A3C),
      );
      pen.stroke(ovalPath(Offset(fw * 0.75, fh * 0.3), 1.4, 1.4), SketchColors.inkSoft, width: 0.4, sketchy: false);
    } else {
      final heart = Path()
        ..moveTo(fw / 2, fh * 0.75)
        ..cubicTo(fw * 0.1, fh * 0.45, fw * 0.3, fh * 0.15, fw / 2, fh * 0.35)
        ..cubicTo(fw * 0.7, fh * 0.15, fw * 0.9, fh * 0.45, fw / 2, fh * 0.75)
        ..close();
      pen.fill(heart, SketchColors.pink);
      pen.stroke(heart, SketchColors.pinkDeep, width: 0.6, sketchy: false);
    }
  }

  void _hangingPlant(SketchPen pen) {
    pen.line(const Offset(4, 0), const Offset(4, 9), SketchColors.ink, width: 0.5, sketchy: false);
    final pot = polygon(const [Offset(0, 9), Offset(8, 9), Offset(7, 14), Offset(1, 14)]);
    pen.fill(pot, SketchColors.coral);
    pen.stroke(pot, SketchColors.ink, width: 0.6, seed: 571);
    for (final (i, (dx, len)) in const [(-1.0, 11.0), (2.0, 15.0), (6.0, 9.0), (9.0, 12.0)].indexed) {
      final vine = Path()..moveTo(dx.clamp(0, 8), 11);
      for (var y = 11.0; y < 11 + len; y += 3) {
        vine.quadraticBezierTo(dx + ((y ~/ 3).isEven ? 1.2 : -1.2), y + 1.5, dx, y + 3);
        pen.fill(ovalPath(Offset(dx + 1.2, y + 2), 1.8, 1.2), SketchColors.leaf);
      }
      pen.stroke(vine, SketchColors.leafDark, width: 0.5, sketchy: false, wobble: 0, seed: 572 + i);
    }
  }
}
