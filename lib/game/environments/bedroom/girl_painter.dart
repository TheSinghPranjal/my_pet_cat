import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../sketch/sketch.dart';

/// How the girl feels; drives her face, arms and the little doodles around
/// her head.
enum GirlMood { happy, searching, laughing, furious, surprised }

/// Standing still, walking or running.
enum GirlGait { stand, walk, run }

/// The girl who lives in the bedroom: a chibi doodle with long curly hair,
/// a pink tiered sundress and white sneakers, drawn in navy ink and coloured
/// pencil like the rest of the notebook.
///
/// She is drawn in a 60x130 unit box, anchored bottom-centre at her feet,
/// mostly facing the viewer; [facing] (-1 left, 0 front, 1 right) turns her
/// gaze and leans her into a walk or run.
class GirlPainter extends CustomPainter {
  GirlPainter({
    this.mood = GirlMood.happy,
    this.gait = GirlGait.stand,
    this.stride = 0,
    this.facing = 0,
    this.time = 0,
  });

  /// Width / height of the drawing box.
  static const aspect = 60 / 130;

  final GirlMood mood;
  final GirlGait gait;

  /// Step cycle in radians; legs only move while it changes.
  final double stride;
  final double facing;

  /// Seconds, for blinking, laughing and fuming.
  final double time;

  static const _ink = Color(0xFF1E2A5E);
  static const _skin = Color(0xFFF8D3AE);
  static const _skinShade = Color(0xFFE6A97A);
  static const _hair = Color(0xFF3A2922);
  static const _hairLight = Color(0xFF7A5642);
  static const _dress = Color(0xFFF2589F);
  static const _dressShade = Color(0xFFC92F7C);
  static const _eye = Color(0xFF2A1D19);
  static const _iris = Color(0xFF6E4A38);

  bool get _moving => gait != GirlGait.stand;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 60;
    final pen = SketchPen(canvas, pxPerUnit: s);
    canvas.save();
    canvas.scale(s);

    _shadow(pen);
    // Bob along while walking, bounce while laughing, lean into a run.
    final bob = switch (gait) {
      GirlGait.stand => mood == GirlMood.laughing ? math.sin(time * 16).abs() * -1.2 : 0.0,
      GirlGait.walk => -math.sin(stride).abs() * 1.2,
      GirlGait.run => -math.sin(stride).abs() * 2.4,
    };
    canvas.save();
    if (gait == GirlGait.run) {
      canvas.translate(30, 128);
      canvas.rotate(0.07 * facing);
      canvas.translate(-30, -128);
    }
    canvas.translate(0, bob);
    void bigHead(void Function() draw) {
      // Chibi proportions: a big head and hair, scaled about the chin.
      canvas.save();
      canvas.translate(30, 54);
      canvas.scale(1.16);
      canvas.translate(-30, -54);
      draw();
      canvas.restore();
    }

    bigHead(() => _backHair(pen));
    _legs(pen);
    _arms(pen);
    _dressShape(pen);
    _neck(pen);
    bigHead(() => _head(pen));
    canvas.restore();
    canvas.restore();
  }

  void _shadow(SketchPen pen) {
    pen.hatch(
      ovalPath(const Offset(30, 128.5), 34, 4),
      SketchColors.ink.withValues(alpha: 0.7),
      spacing: 0.9,
      angle: -0.2,
      width: 0.5,
      seed: 201,
    );
  }

  // --- Hair ------------------------------------------------------------------

  /// A soft scalloped blob: curly hair.
  Path _curly(Offset c, double rx, double ry, {int lobes = 22, double bump = 1.8, double flatBelow = 1e9}) {
    final path = Path();
    const n = 220;
    for (var i = 0; i <= n; i++) {
      final t = i / n * math.pi * 2;
      final r = 1 + bump / rx * math.pow(math.sin(t * lobes / 2).abs(), 0.6);
      final p = Offset(c.dx + rx * r * math.cos(t), math.min(flatBelow, c.dy + ry * r * math.sin(t)));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  void _curls(SketchPen pen, Rect area, int count, int seed) {
    final rnd = math.Random(seed);
    for (var i = 0; i < count; i++) {
      final c = Offset(area.left + area.width * rnd.nextDouble(), area.top + area.height * rnd.nextDouble());
      final r = 1.2 + rnd.nextDouble() * 1.4;
      final a = rnd.nextDouble() * math.pi * 2;
      pen.stroke(
        Path()..addArc(Rect.fromCircle(center: c, radius: r), a, math.pi * 1.3),
        _hairLight,
        width: 0.45,
        sketchy: false,
        wobble: 0,
      );
    }
  }

  void _backHair(SketchPen pen) {
    final sway = _moving ? math.sin(stride) * 1.5 : math.sin(time * 1.3) * 0.4;
    final hair = _curly(Offset(30 + sway * 0.3, 52), 26, 40, lobes: 26, bump: 2.2);
    pen.fill(hair, _hair);
    pen.canvas.save();
    pen.canvas.clipPath(hair);
    _curls(pen, const Rect.fromLTRB(4, 14, 56, 92), 70, 202);
    pen.canvas.restore();
    pen.stroke(hair, _ink, width: 0.8, wobble: 0.25, seed: 203);
  }

  void _frontHair(SketchPen pen) {
    // Top of the head, parted a little off centre, and curls framing the face.
    final cap = Path()
      ..moveTo(12.5, 40)
      ..cubicTo(10, 18, 22, 11, 30, 11.5)
      ..cubicTo(40, 11, 50, 18, 47.5, 40)
      ..quadraticBezierTo(45, 30, 42, 26)
      ..quadraticBezierTo(36, 24, 32, 18.5)
      ..quadraticBezierTo(27, 25, 18, 27)
      ..quadraticBezierTo(15, 32, 12.5, 40)
      ..close();
    pen.fill(cap, _hair);
    pen.canvas.save();
    pen.canvas.clipPath(cap);
    _curls(pen, const Rect.fromLTRB(10, 10, 50, 30), 22, 204);
    pen.canvas.restore();
    pen.stroke(cap, _ink, width: 0.8, wobble: 0.2, seed: 205);
    // Ringlets falling in front of the shoulders.
    for (final (i, x) in const [12.0, 48.0].indexed) {
      final side = i == 0 ? -1.0 : 1.0;
      final lock = Path()..moveTo(x, 30);
      for (var y = 30.0; y < 64; y += 5) {
        lock.quadraticBezierTo(x + side * 3.2 * (((y ~/ 5).isEven) ? 1 : -1), y + 2.5, x + side * 0.4, y + 5);
      }
      pen.tube(lock, width: 4.4, outline: _ink, fill: _hair, lineWidth: 0.6, seed: 206 + i);
    }
  }

  // --- Body ------------------------------------------------------------------

  void _legs(SketchPen pen) {
    for (final (i, x) in const [25.0, 35.0].indexed) {
      final swing = _moving ? math.sin(stride + i * math.pi) * (gait == GirlGait.run ? 4.5 : 2.6) : 0.0;
      final lift = _moving ? math.max(0, math.sin(stride + i * math.pi)) * (gait == GirlGait.run ? 3.0 : 1.4) : 0.0;
      final hip = Offset(x, 100);
      final ankle = Offset(x + swing, 121 - lift);
      pen.tube(
        Path()
          ..moveTo(hip.dx, hip.dy)
          ..lineTo(ankle.dx, ankle.dy),
        width: 5,
        outline: _ink,
        fill: _skin,
        lineWidth: 0.7,
        seed: 210 + i,
      );
      // White sneakers with two straps.
      final shoe = Path()
        ..addRRect(
          RRect.fromLTRBR(
            ankle.dx - 4.2 + (i == 0 ? -1 : 1),
            ankle.dy - 1.5,
            ankle.dx + 4.2 + (i == 0 ? -1 : 1),
            ankle.dy + 6.5,
            const Radius.circular(3),
          ),
        );
      pen.fill(shoe, SketchColors.white);
      pen.hatch(shoe, SketchColors.inkWash, spacing: 1.2, angle: -0.6, width: 0.35, seed: 212 + i);
      pen.stroke(shoe, _ink, width: 0.8, seed: 214 + i);
      pen.line(
        Offset(ankle.dx - 3, ankle.dy + 4.6),
        Offset(ankle.dx + 4, ankle.dy + 4.6),
        _ink,
        width: 0.5,
        sketchy: false,
      );
      for (final dy in const [0.6, 2.4]) {
        pen.line(
          Offset(ankle.dx - 2.2, ankle.dy + dy),
          Offset(ankle.dx + 2.4, ankle.dy + dy - 0.3),
          _ink,
          width: 0.5,
          sketchy: false,
        );
      }
    }
  }

  /// Elbow and hand for the left and right arm.
  ((Offset, Offset), (Offset, Offset)) get _armPose {
    if (gait == GirlGait.run) {
      final a = math.sin(stride) * 5;
      return ((Offset(15, 74 + a), Offset(11, 66 + a)), (Offset(45, 74 - a), Offset(49, 66 - a)));
    }
    return switch (mood) {
      GirlMood.searching => (
        (const Offset(16, 76), const Offset(15, 91)),
        // A hand shading her eyes as she looks around.
        (Offset(48 + facing, 54), Offset(40 + facing * 3, 28)),
      ),
      GirlMood.laughing => ((const Offset(18, 77), const Offset(26, 80)), (const Offset(42, 77), const Offset(34, 80))),
      GirlMood.furious => ((const Offset(14, 74), const Offset(16, 66)), (const Offset(46, 74), const Offset(44, 66))),
      GirlMood.surprised => (
        (const Offset(13, 66), const Offset(15, 52)),
        (const Offset(47, 66), const Offset(45, 52)),
      ),
      GirlMood.happy => ((const Offset(17, 77), const Offset(12, 91)), (const Offset(43, 77), const Offset(48, 91))),
    };
  }

  void _arms(SketchPen pen) {
    final (left, right) = _armPose;
    for (final (i, (shoulder, (elbow, hand))) in [
      (const Offset(22, 61), left),
      (const Offset(38, 61), right),
    ].indexed) {
      pen.tube(
        Path()
          ..moveTo(shoulder.dx, shoulder.dy)
          ..quadraticBezierTo(elbow.dx, elbow.dy, hand.dx, hand.dy),
        width: 4.4,
        outline: _ink,
        fill: _skin,
        lineWidth: 0.7,
        seed: 220 + i,
      );
      final palm = ovalPath(hand, mood == GirlMood.furious && gait != GirlGait.run ? 5 : 4.4, 4.4);
      pen.fill(palm, _skin);
      pen.stroke(palm, _ink, width: 0.7, wobble: 0.15, seed: 222 + i);
    }
  }

  void _dressShape(SketchPen pen) {
    final sway = _moving ? math.sin(stride) * 1.6 : 0.0;
    // Lower tier first, then the upper tier over it.
    for (final (i, (top, bottom, half)) in const [(89.0, 103.0, 19.5), (77.0, 96.0, 16.5)].indexed) {
      final hem = Path()..moveTo(30 - (i == 0 ? 15 : 9), top);
      hem.lineTo(30 + (i == 0 ? 15 : 9), top);
      hem.lineTo(30 + half + sway, bottom - 1);
      for (var x = half; x > -half; x -= 4.5) {
        hem.quadraticBezierTo(30 + x - 2.2 + sway, bottom + 1.8, 30 + x - 4.5 + sway, bottom);
      }
      hem.close();
      pen.fill(hem, _dress);
      pen.hatch(hem, _dressShade, spacing: 1.1, angle: -1.1, width: 0.4, seed: 230 + i);
      for (final x in const [-9.0, -3.0, 3.0, 9.0]) {
        pen.line(
          Offset(30 + x * 0.6, top + 1),
          Offset(30 + x + sway * 0.6, bottom - 1),
          _dressShade,
          width: 0.5,
          sketchy: false,
          wobble: 0.1,
        );
      }
      pen.stroke(hem, _ink, width: 0.8, seed: 232 + i);
    }
    final bodice = Path()..addRRect(RRect.fromLTRBR(21.5, 57, 38.5, 79, const Radius.circular(3)));
    pen.fill(bodice, _dress);
    pen.hatch(bodice, _dressShade, spacing: 1.0, angle: -1.1, width: 0.4, seed: 234);
    pen.stroke(bodice, _ink, width: 0.8, seed: 235);
    pen.line(const Offset(21.5, 77.5), const Offset(38.5, 77.5), _ink, width: 0.6, sketchy: false);
    // Thin straps.
    pen.line(const Offset(24.5, 57.5), const Offset(24, 53.5), _ink, width: 0.9, sketchy: false);
    pen.line(const Offset(35.5, 57.5), const Offset(36, 53.5), _ink, width: 0.9, sketchy: false);
  }

  void _neck(SketchPen pen) {
    final neck = rectPath(27, 48, 33, 58);
    pen.fill(neck, _skin);
    pen.hatch(neck, _skinShade, spacing: 1.0, angle: 0.4, width: 0.35, seed: 240);
    pen.line(const Offset(27, 48), const Offset(27, 57), _ink, width: 0.6, sketchy: false);
    pen.line(const Offset(33, 48), const Offset(33, 57), _ink, width: 0.6, sketchy: false);
  }

  // --- Head ------------------------------------------------------------------

  void _head(SketchPen pen) {
    final turn = facing * 1.2;
    // Ears with little pearl earrings.
    for (final side in const [-1.0, 1.0]) {
      final ear = ovalPath(Offset(30 + 16 * side, 37), 4.6, 6.2);
      pen.fill(ear, _skin);
      pen.stroke(ear, _ink, width: 0.7, seed: 241);
      final pearl = ovalPath(Offset(30 + 16.4 * side, 42), 2.2, 2.2);
      pen.fill(pearl, SketchColors.white);
      pen.stroke(pearl, _ink, width: 0.45, sketchy: false);
    }
    final face = ovalPath(Offset(30 + turn * 0.3, 34), 32, 35);
    final flush = mood == GirlMood.furious ? 0.45 + 0.15 * math.sin(time * 6) : 0.0;
    pen.fill(face, _skin);
    pen.hatch(face, _skinShade.withValues(alpha: 0.6), spacing: 1.3, angle: 0.5, width: 0.35, seed: 242);
    if (flush > 0) pen.fill(face, SketchColors.coral.withValues(alpha: flush * 0.5));
    pen.stroke(face, _ink, width: 0.85, seed: 243);
    _frontHair(pen);

    final c = Offset(30 + turn, 0);
    for (final side in const [-1.0, 1.0]) {
      final cheek = ovalPath(Offset(c.dx + 10.5 * side, 42.5), 6.4, 3.4);
      pen.fill(cheek, SketchColors.pink.withValues(alpha: mood == GirlMood.furious ? 0.9 : 0.55));
      pen.hatch(cheek, SketchColors.pinkDeep, spacing: 0.8, angle: -0.4, width: 0.35, seed: 244);
    }
    _brows(pen, c.dx);
    _eyes(pen, c.dx);
    pen.line(Offset(c.dx + 0.3, 40.5), Offset(c.dx - 0.4, 41.6), _skinShade, width: 0.7, sketchy: false);
    _mouth(pen, c.dx);
    _moodDoodles(pen);
  }

  void _brows(SketchPen pen, double cx) {
    for (final side in const [-1.0, 1.0]) {
      final (inner, outer) = switch (mood) {
        GirlMood.furious => (Offset(cx + 2.5 * side, 30.5), Offset(cx + 10 * side, 27.5)),
        GirlMood.surprised => (Offset(cx + 3 * side, 26), Offset(cx + 10 * side, 26.5)),
        GirlMood.searching =>
          side > 0 ? (Offset(cx + 3, 26.5), Offset(cx + 10, 25.5)) : (Offset(cx - 3, 28.5), Offset(cx - 10, 28.5)),
        _ => (Offset(cx + 3 * side, 28), Offset(cx + 10 * side, 28)),
      };
      pen.stroke(
        Path()
          ..moveTo(inner.dx, inner.dy)
          ..quadraticBezierTo((inner.dx + outer.dx) / 2, math.min(inner.dy, outer.dy) - 1.2, outer.dx, outer.dy),
        _hair,
        width: 1.3,
        sketchy: false,
        wobble: 0.05,
      );
    }
  }

  void _eyes(SketchPen pen, double cx) {
    final blink = mood == GirlMood.happy && (time % 3.7) < 0.12;
    for (final side in const [-1.0, 1.0]) {
      final e = Offset(cx + 6.6 * side, 35.5);
      if (mood == GirlMood.laughing || blink) {
        // Squeezed shut with joy (or a quick blink).
        pen.stroke(
          Path()
            ..moveTo(e.dx - 3.4, e.dy + (blink ? 0 : 1.2))
            ..quadraticBezierTo(e.dx, e.dy + (blink ? 2 : -3), e.dx + 3.4, e.dy + (blink ? 0 : 1.2)),
          _ink,
          width: 1.3,
          sketchy: false,
          wobble: 0.05,
        );
        continue;
      }
      final scale = mood == GirlMood.surprised ? 1.15 : 1.0;
      final height = (mood == GirlMood.furious ? 6.2 : 8.2) * scale;
      final eye = ovalPath(e, 6.6 * scale, height);
      pen.fill(eye, _eye);
      pen.canvas.save();
      pen.canvas.clipPath(eye);
      final look = Offset(facing * 1.1, mood == GirlMood.searching ? -0.4 : 0);
      pen.fill(ovalPath(e + look + const Offset(0, 1.6), 5.2, 4.4), _iris);
      pen.fill(ovalPath(e + look + const Offset(-1.2, -1.6), 2.6, 2.6), SketchColors.white);
      pen.fill(ovalPath(e + look + const Offset(1.3, 1.6), 1.1, 1.1), SketchColors.white);
      pen.canvas.restore();
      // Upper lid and lashes.
      pen.stroke(
        Path()
          ..addArc(Rect.fromCenter(center: e, width: 7.4 * scale, height: height + 0.6), math.pi * 1.05, math.pi * 0.9),
        _ink,
        width: 1.2,
        sketchy: false,
        wobble: 0,
      );
      final lashBase = e + Offset(3.4 * side, -height * 0.3);
      pen.line(lashBase, lashBase + Offset(1.6 * side, -1.2), _ink, width: 0.7, sketchy: false);
      pen.line(
        lashBase + Offset(0.1 * side, 1.4),
        lashBase + Offset(1.9 * side, 0.6),
        _ink,
        width: 0.7,
        sketchy: false,
      );
    }
  }

  void _mouth(SketchPen pen, double cx) {
    final m = Offset(cx, 46);
    switch (mood) {
      case GirlMood.happy || GirlMood.laughing:
        final wide = mood == GirlMood.laughing ? 5.2 : 3.6;
        final deep = mood == GirlMood.laughing ? 5.2 : 3.6;
        final mouth = Path()
          ..moveTo(m.dx - wide, m.dy - 0.6)
          ..quadraticBezierTo(m.dx, m.dy + 0.4, m.dx + wide, m.dy - 0.6)
          ..quadraticBezierTo(m.dx + wide * 0.6, m.dy + deep, m.dx, m.dy + deep)
          ..quadraticBezierTo(m.dx - wide * 0.6, m.dy + deep, m.dx - wide, m.dy - 0.6)
          ..close();
        pen.fill(mouth, SketchColors.mouth);
        pen.fill(ovalPath(m + Offset(0, deep - 1.2), wide, 2.2), SketchColors.pink);
        pen.fill(rectPath(m.dx - wide * 0.7, m.dy - 0.5, m.dx + wide * 0.7, m.dy + 0.6), SketchColors.white);
        pen.stroke(mouth, _ink, width: 0.75, sketchy: false, wobble: 0.05);
      case GirlMood.furious:
        // A cross little "grr" with gritted teeth.
        final mouth = Path()
          ..moveTo(m.dx - 4, m.dy + 2.6)
          ..quadraticBezierTo(m.dx, m.dy - 1.2, m.dx + 4, m.dy + 2.6)
          ..quadraticBezierTo(m.dx, m.dy + 1.8, m.dx - 4, m.dy + 2.6)
          ..close();
        pen.fill(mouth, SketchColors.white);
        pen.stroke(mouth, _ink, width: 0.8, sketchy: false, wobble: 0.05);
        for (final x in const [-1.6, 0.0, 1.6]) {
          pen.line(Offset(m.dx + x, m.dy + 0.4), Offset(m.dx + x, m.dy + 2.2), _ink, width: 0.4, sketchy: false);
        }
      case GirlMood.surprised || GirlMood.searching:
        final o = ovalPath(
          m + const Offset(0, 1.2),
          mood == GirlMood.surprised ? 3.6 : 2.4,
          mood == GirlMood.surprised ? 4.4 : 2.2,
        );
        pen.fill(o, SketchColors.mouth);
        pen.stroke(o, _ink, width: 0.7, sketchy: false, wobble: 0.05);
    }
  }

  /// "?" while searching, "ha ha!" while laughing, an anger mark and steam
  /// puffs while furious.
  void _moodDoodles(SketchPen pen) {
    switch (mood) {
      case GirlMood.searching:
        for (final (i, x) in const [44.0, 53.0].indexed) {
          final y = 12 - i * 5 + math.sin(time * 4 + i) * 1.2;
          _question(pen, Offset(x, y), 1.0 - i * 0.2);
        }
      case GirlMood.laughing:
        final hop = math.sin(time * 12).abs() * 1.5;
        _ha(pen, Offset(46, 12 - hop), 0.18);
        _ha(pen, Offset(52, 3 + hop), -0.12);
      case GirlMood.furious:
        _angerMark(pen, Offset(46, 14), 1 + 0.12 * math.sin(time * 10));
        for (final (i, side) in const [-1.0, 1.0].indexed) {
          final ph = (time * 1.4 + i * 0.5) % 1;
          final c = Offset(30 + side * (20 + ph * 6), 18 - ph * 10);
          final puff = ovalPath(c, 4 + ph * 3, 3 + ph * 2);
          pen.fill(puff, SketchColors.white.withValues(alpha: 1 - ph));
          pen.stroke(puff, SketchColors.graphite.withValues(alpha: 1 - ph), width: 0.6, sketchy: false, wobble: 0.1);
        }
      case GirlMood.surprised:
        for (final (a, b) in const [
          (Offset(16, 8), Offset(13, 3)),
          (Offset(30, 5), Offset(30, -1)),
          (Offset(44, 8), Offset(47, 3)),
        ]) {
          pen.line(a, b, _ink, width: 1.0, sketchy: false);
        }
      case GirlMood.happy:
        break;
    }
  }

  void _question(SketchPen pen, Offset at, double scale) {
    final s = scale;
    pen.stroke(
      Path()
        ..moveTo(at.dx - 2.6 * s, at.dy - 2 * s)
        ..quadraticBezierTo(at.dx - 2.4 * s, at.dy - 5.6 * s, at.dx + 0.4 * s, at.dy - 5.6 * s)
        ..quadraticBezierTo(at.dx + 3.4 * s, at.dy - 5.2 * s, at.dx + 2.6 * s, at.dy - 2.4 * s)
        ..quadraticBezierTo(at.dx + 1.8 * s, at.dy - 0.6 * s, at.dx, at.dy + 0.4 * s)
        ..lineTo(at.dx, at.dy + 2 * s),
      SketchColors.ink,
      width: 1.3,
      sketchy: false,
      wobble: 0.05,
    );
    pen.fill(ovalPath(at + Offset(0, 4.6 * s), 1.8 * s, 1.8 * s), SketchColors.ink);
  }

  /// A hand-lettered "ha" in ink.
  void _ha(SketchPen pen, Offset at, double tilt) {
    final canvas = pen.canvas;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(tilt);
    final h = Path()
      ..moveTo(-4, -3.5)
      ..lineTo(-4.4, 3)
      ..moveTo(-4.2, 0.6)
      ..quadraticBezierTo(-2.2, -1.6, -1.4, 0.4)
      ..lineTo(-1.6, 3);
    final a = Path()
      ..addOval(Rect.fromCenter(center: const Offset(2.2, 1.6), width: 3.4, height: 3))
      ..moveTo(3.9, 0)
      ..lineTo(4.1, 3.2);
    pen.stroke(h, SketchColors.ink, width: 1.0, sketchy: false, wobble: 0.05);
    pen.stroke(a, SketchColors.ink, width: 1.0, sketchy: false, wobble: 0.05);
    canvas.restore();
  }

  /// The comic "cross" vein of a cross face, in coral.
  void _angerMark(SketchPen pen, Offset c, double s) {
    for (var q = 0; q < 4; q++) {
      final a = q * math.pi / 2 + math.pi / 4;
      final d = Offset(math.cos(a), math.sin(a));
      final n = Offset(-d.dy, d.dx);
      final p = c + d * 2.6 * s;
      pen.stroke(
        Path()
          ..moveTo((p + n * 2 * s).dx, (p + n * 2 * s).dy)
          ..quadraticBezierTo((c + d * 1.0 * s).dx, (c + d * 1.0 * s).dy, (p - n * 2 * s).dx, (p - n * 2 * s).dy),
        SketchColors.wool,
        width: 1.2,
        sketchy: false,
        wobble: 0,
      );
    }
  }

  @override
  bool shouldRepaint(GirlPainter oldDelegate) =>
      oldDelegate.mood != mood ||
      oldDelegate.gait != gait ||
      oldDelegate.stride != stride ||
      oldDelegate.facing != facing ||
      oldDelegate.time != time;
}
