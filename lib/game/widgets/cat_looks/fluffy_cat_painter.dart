import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../animations/cat_animations.dart';
import '../../sketch/sketch.dart';

/// The fluffy kitten: fine graphite lines, cheek tufts and full tabby markings.
class FluffyCatPainter extends CustomPainter {
  FluffyCatPainter({required this.frame, required this.facing});

  final CatFrame frame;
  final double facing;

  // Hips and resting feet: far back, near back, far front, near front.
  static const _hips = [Offset(34, 65), Offset(40, 67), Offset(57, 65), Offset(63, 67)];
  static const _feet = [Offset(32, 81), Offset(40, 83.5), Offset(58, 81), nearFrontPawRest];

  static const _farFur = Color(0xFFEDEDF0);

  /// Soft graphite outline, finer than the world's ink so the fur reads fluffy.
  static const _line = Color(0xFF3A3A42);
  static const _lineWidth = 0.75;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    final pen = SketchPen(canvas, pxPerUnit: s);
    // Squash through the middle of a turn instead of flipping instantly.
    final flip = facing.abs() < 0.14 ? (facing < 0 ? -0.14 : 0.14) : facing;

    canvas.save();
    canvas.translate(size.width / 2, 0);
    canvas.scale(flip * s, s);
    canvas.translate(-50, 0);

    if (frame.shadow) _shadow(pen);
    canvas.translate(0, frame.bodyLift);
    if (frame.bodyRotation != 0) {
      canvas.translate(48, 62);
      canvas.rotate(frame.bodyRotation);
      canvas.translate(-48, -62);
    }
    _tail(pen);
    _leg(pen, 0, far: true);
    _leg(pen, 2, far: true);
    _body(pen);
    _leg(pen, 1, far: false);
    if (frame.raisedPaw == null) _leg(pen, 3, far: false);
    final headCenter = _head(pen);
    if (frame.raisedPaw != null) _raisedPaw(pen, frame.raisedPaw!);
    _extras(pen, headCenter);

    canvas.restore();
  }

  void _shadow(SketchPen pen) {
    final width = 52 + frame.bodyLift * 1.5;
    pen.hatch(
      ovalPath(const Offset(48, 84), width, 6),
      SketchColors.ink.withValues(alpha: 0.75),
      spacing: 0.9,
      angle: -0.2,
      width: 0.5,
      seed: 3,
    );
  }

  void _tail(SketchPen pen) {
    const base = Offset(30, 58);
    final a = frame.tailAngle;
    Offset r(double x, double y) => base + Offset(x * math.cos(a) - y * math.sin(a), x * math.sin(a) + y * math.cos(a));
    final c1 = r(-13, 2), c2 = r(-22, -14), end = r(-15, -31);
    final curlControl = r(-12, -38), tip = r(-6, -33);
    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy)
      ..quadraticBezierTo(curlControl.dx, curlControl.dy, tip.dx, tip.dy);
    pen.tube(path, width: 5.6, outline: _line, fill: SketchColors.white, lineWidth: 0.8, seed: 41);
    // Fine tabby rings, closer together toward the tip.
    final metric = path.computeMetrics().first;
    for (final f in const [0.3, 0.42, 0.53, 0.63, 0.72, 0.8, 0.88, 0.95]) {
      final tangent = metric.getTangentForOffset(metric.length * f)!;
      final n = Offset(-tangent.vector.dy, tangent.vector.dx);
      final t = tangent.vector * 0.6;
      pen.stroke(
        Path()
          ..moveTo((tangent.position - n * 2.7).dx, (tangent.position - n * 2.7).dy)
          ..quadraticBezierTo(
            (tangent.position + t).dx,
            (tangent.position + t).dy,
            (tangent.position + n * 2.7).dx,
            (tangent.position + n * 2.7).dy,
          ),
        SketchColors.stripe,
        width: 0.95,
        sketchy: false,
        wobble: 0.1,
      );
    }
  }

  void _leg(SketchPen pen, int i, {required bool far}) {
    final hip = _hips[i];
    final foot = _feet[i] + frame.feet[i];
    final fur = far ? _farFur : SketchColors.white;
    pen.tube(
      Path()
        ..moveTo(hip.dx, hip.dy)
        ..lineTo(foot.dx, foot.dy - 2),
      width: 6.6,
      outline: _line,
      fill: fur,
      lineWidth: 0.8,
      seed: 11 + i,
    );
    _paw(pen, foot, fur, 20 + i);
    for (final f in far ? const [0.4] : const [0.3, 0.5, 0.7]) {
      final mid = Offset.lerp(hip, foot, f)!;
      pen.line(
        mid + const Offset(-2.6, 0.3),
        mid + const Offset(2.2, -0.5),
        SketchColors.stripe,
        width: 0.85,
        sketchy: false,
        wobble: 0.1,
      );
    }
  }

  void _paw(SketchPen pen, Offset foot, Color fur, int seed) {
    final paw = ovalPath(foot + const Offset(1, -1.8), 8.6, 5.4);
    pen.fill(paw, fur);
    pen.stroke(paw, _line, width: 0.8, wobble: 0.2, seed: seed);
    for (final dx in const [0.6, 3.0]) {
      pen.line(foot + Offset(dx, -2.2), foot + Offset(dx + 0.2, -0.5), _line, width: 0.5, sketchy: false, wobble: 0);
    }
  }

  void _body(SketchPen pen) {
    final h = 25 * frame.breath;
    final rect = Rect.fromLTRB(26, 72 - h, 68, 72);
    final body = Path()..addOval(rect);
    pen.fill(body, SketchColors.white);
    pen.canvas.save();
    pen.canvas.clipPath(body);
    pen.hatch(
      rectPath(20, rect.top, 72, rect.top + h * 0.4),
      SketchColors.graphite.withValues(alpha: 0.35),
      spacing: 1.3,
      angle: -1.0,
      width: 0.4,
      seed: 5,
    );
    // Back stripes, curving down the flank.
    for (final x in const [32.0, 37.0, 42.0, 47.0, 52.0, 57.0]) {
      pen.stroke(
        Path()
          ..moveTo(x, rect.top + 0.3)
          ..quadraticBezierTo(x + 2.4, rect.top + 5, x + 0.6, rect.top + 9.5),
        SketchColors.stripe,
        width: 1.0,
        wobble: 0.15,
        sketchy: false,
        seed: x.toInt(),
      );
    }
    // Haunch swirl.
    pen.stroke(
      Path()
        ..moveTo(31, rect.top + 12)
        ..quadraticBezierTo(36, rect.top + 10, 37, rect.top + 15),
      SketchColors.stripe,
      width: 0.9,
      wobble: 0.1,
      sketchy: false,
    );
    pen.canvas.restore();
    pen.stroke(body, _line, width: _lineWidth, seed: 21);
    // Fluffy chest and belly tufts over the outline.
    _tuft(pen, Offset(65.5, rect.top + h * 0.55), 4, 1.9, 0.35, 61);
    _tuft(pen, Offset(48, 71.6), 4, 1.5, math.pi / 2, 62);
  }

  /// A small row of fur spikes poking out from an outline at [at], pointing
  /// in [direction] (radians).
  void _tuft(SketchPen pen, Offset at, int spikes, double length, double direction, int seed) {
    final out = Offset(math.cos(direction), math.sin(direction));
    final along = Offset(-out.dy, out.dx);
    const gap = 1.7;
    final start = at - along * (gap * spikes / 2);
    final path = Path()..moveTo(start.dx, start.dy);
    for (var i = 0; i < spikes; i++) {
      final tip = start + along * (gap * (i + 0.5)) + out * length + along * 0.4;
      final next = start + along * (gap * (i + 1));
      path
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(next.dx, next.dy);
    }
    final fill = Path.from(path)..close();
    pen.fill(fill, SketchColors.white);
    pen.stroke(path, _line, width: 0.75, wobble: 0.05, sketchy: false, seed: seed);
  }

  /// Head outline: a soft dome with fluffy cheek tufts.
  Path _headPath(Offset hc) {
    final path = Path();
    const n = 160;
    for (var i = 0; i <= n; i++) {
      final t = i / n * math.pi * 2;
      final sin = math.sin(t), cos = math.cos(t);
      // Chubby cheeks: wider below the eyes than across the crown.
      final rx = 21.0 + 1.6 * math.max(0, sin), ry = sin < 0 ? 17.5 : 16.0;
      var extra = 0.0;
      // Cheek fluff on both sides, below the eyes.
      for (final (from, to) in const [(0.05, 1.05), (2.09, 3.09)]) {
        if (t > from && t < to) {
          final u = (t - from) / (to - from) * 4;
          final saw = u - u.floorToDouble();
          extra = 3.0 * (1 - (2 * saw - 1).abs()) * math.sin(math.pi * u / 4);
        }
      }
      final x = (rx + extra) * cos;
      final y = (ry + extra) * sin + 1;
      if (i == 0) {
        path.moveTo(hc.dx + x, hc.dy + y);
      } else {
        path.lineTo(hc.dx + x, hc.dy + y);
      }
    }
    return path..close();
  }

  /// Draws the head and returns its center (before tilt).
  Offset _head(SketchPen pen) {
    final hc = const Offset(70, 35) + frame.headOffset;
    final pivot = const Offset(62, 53) + frame.headOffset;
    final canvas = pen.canvas;
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(frame.headTilt);
    canvas.translate(-pivot.dx, -pivot.dy);
    // A slightly bigger head than body, kitten proportions.
    canvas.translate(hc.dx, hc.dy + 8);
    canvas.scale(1.08);
    canvas.translate(-hc.dx, -hc.dy - 8);

    _ear(pen, [hc + const Offset(-18, -7), hc + const Offset(-15, -27), hc + const Offset(-3, -16)], 31);
    canvas.save();
    final earBase = hc + const Offset(10, -12);
    canvas.translate(earBase.dx, earBase.dy);
    canvas.rotate(frame.earTwitch);
    canvas.translate(-earBase.dx, -earBase.dy);
    _ear(pen, [hc + const Offset(3, -16), hc + const Offset(15, -27), hc + const Offset(18, -7)], 32);
    canvas.restore();

    final head = _headPath(hc);
    pen.fill(head, SketchColors.white);
    canvas.save();
    canvas.clipPath(head);
    pen.hatch(
      rectPath(hc.dx - 23, hc.dy - 19, hc.dx + 23, hc.dy - 10),
      SketchColors.graphite.withValues(alpha: 0.28),
      spacing: 1.4,
      angle: -0.8,
      width: 0.4,
      seed: 8,
    );
    canvas.restore();
    // Tabby "M" on the forehead.
    for (final (a, c, b) in const [
      (Offset(0, -17.5), Offset(0.4, -14), Offset(0, -10)),
      (Offset(-3.6, -16.8), Offset(-3.6, -13.5), Offset(-2.6, -10.8)),
      (Offset(3.6, -16.8), Offset(3.6, -13.5), Offset(2.6, -10.8)),
      (Offset(-7.5, -15.2), Offset(-7.2, -12.6), Offset(-5.6, -10.6)),
      (Offset(7.5, -15.2), Offset(7.2, -12.6), Offset(5.6, -10.6)),
    ]) {
      pen.stroke(
        Path()
          ..moveTo(hc.dx + a.dx, hc.dy + a.dy)
          ..quadraticBezierTo(hc.dx + c.dx, hc.dy + c.dy, hc.dx + b.dx, hc.dy + b.dy),
        SketchColors.stripe,
        width: 1.0,
        sketchy: false,
        wobble: 0.08,
      );
    }
    // Cheek stripes running out from the eyes.
    for (final side in const [-1.0, 1.0]) {
      for (final (a, b) in const [(Offset(14.5, -2.5), Offset(20.5, -4)), (Offset(15, 0.5), Offset(21, 0))]) {
        pen.line(
          hc + Offset(a.dx * side, a.dy),
          hc + Offset(b.dx * side, b.dy),
          SketchColors.stripe,
          width: 0.9,
          sketchy: false,
          wobble: 0.08,
        );
      }
    }
    pen.stroke(head, _line, width: _lineWidth, wobble: 0.15, seed: 33);
    // Crown wisp.
    for (final (a, b) in const [
      (Offset(-1.5, -16.8), Offset(-2.6, -19.6)),
      (Offset(0, -17), Offset(0.4, -20.4)),
      (Offset(1.5, -16.8), Offset(3, -19.3)),
    ]) {
      pen.line(hc + a, hc + b, _line, width: 0.65, sketchy: false, wobble: 0.05);
    }

    for (final side in const [-1.0, 1.0]) {
      final cheek = ovalPath(hc + Offset(14 * side, 8.5), 7.5, 4.2);
      pen.fill(cheek, SketchColors.pink.withValues(alpha: 0.35));
      pen.hatch(cheek, SketchColors.pinkDeep, spacing: 0.8, angle: -0.4, width: 0.4, seed: 9);
    }
    _eye(pen, hc + const Offset(-8.5, 1.2));
    _eye(pen, hc + const Offset(8.5, 1.2));
    _mouth(pen, hc);
    _whiskers(pen, hc);

    canvas.restore();
    return hc;
  }

  void _ear(SketchPen pen, List<Offset> p, int seed) {
    Path earPath(List<Offset> q) => Path()
      ..moveTo(q[0].dx, q[0].dy)
      ..lineTo(Offset.lerp(q[0], q[1], 0.85)!.dx, Offset.lerp(q[0], q[1], 0.85)!.dy)
      ..quadraticBezierTo(q[1].dx, q[1].dy, Offset.lerp(q[1], q[2], 0.15)!.dx, Offset.lerp(q[1], q[2], 0.15)!.dy)
      ..lineTo(q[2].dx, q[2].dy)
      ..close();
    final outer = earPath(p);
    pen.fill(outer, SketchColors.white);
    final c = (p[0] + p[1] + p[2]) / 3;
    final innerPoints = [for (final q in p) c + (q - c) * 0.66 + const Offset(0, 1.4)];
    final inner = earPath(innerPoints);
    pen.fill(inner, SketchColors.pink.withValues(alpha: 0.75));
    pen.hatch(inner, SketchColors.pinkDeep, spacing: 0.75, angle: 0.6, width: 0.4, seed: seed);
    // Fur wisps inside the ear.
    final baseMid = Offset.lerp(innerPoints[0], innerPoints[2], 0.5)!;
    for (final f in const [0.3, 0.5, 0.7]) {
      final from = Offset.lerp(innerPoints[0], innerPoints[2], f)!;
      pen.line(
        from,
        Offset.lerp(from, innerPoints[1], 0.45)! + (from - baseMid) * 0.15,
        _line.withValues(alpha: 0.7),
        width: 0.4,
        sketchy: false,
        wobble: 0,
      );
    }
    pen.stroke(outer, _line, width: _lineWidth, seed: seed);
  }

  void _eye(SketchPen pen, Offset c) {
    if (frame.happyEyes) {
      pen.stroke(
        Path()
          ..moveTo(c.dx - 4, c.dy + 1.5)
          ..quadraticBezierTo(c.dx, c.dy - 4, c.dx + 4, c.dy + 1.5),
        _line,
        width: 1.4,
        wobble: 0.15,
        sketchy: false,
      );
      return;
    }
    final open = frame.eyeOpen;
    if (open < 0.25) {
      pen.stroke(
        Path()
          ..moveTo(c.dx - 4, c.dy + 0.5)
          ..quadraticBezierTo(c.dx, c.dy + 3, c.dx + 4, c.dy + 0.5),
        _line,
        width: 1.3,
        wobble: 0.1,
        sketchy: false,
      );
      return;
    }
    final eye = ovalPath(c, 9.6 * frame.eyeScale, 11 * open * frame.eyeScale);
    final canvas = pen.canvas;
    pen.fill(eye, SketchColors.eye);
    canvas.save();
    canvas.clipPath(eye);
    final look = Offset(frame.gaze * 1.3, frame.gazeY * 1.5);
    // Blue iris glowing up from the bottom of the eye.
    pen.fill(ovalPath(c + look + Offset(0, 2.6 * open), 8.2, 7 * open), SketchColors.iris.withValues(alpha: 0.9));
    pen.fill(
      ovalPath(c + look + Offset(0, 3.6 * open), 5.4, 3.6 * open),
      const Color(0xFF7FA6F0).withValues(alpha: 0.85),
    );
    pen.fill(ovalPath(c + look + const Offset(0, 0.4), 4.2, 5 * open), SketchColors.eye);
    pen.fill(ovalPath(c + look + const Offset(-1.6, -2.1), 3.8, 3.8 * open), SketchColors.white);
    pen.fill(ovalPath(c + look + const Offset(1.9, 2.2), 1.6, 1.6 * open), SketchColors.white);
    canvas.restore();
    pen.stroke(eye, _line, width: 0.8, wobble: 0.15, sketchy: false);
  }

  void _mouth(SketchPen pen, Offset hc) {
    final nose = polygon([hc + const Offset(-1.8, 6.2), hc + const Offset(1.8, 6.2), hc + const Offset(0, 8.4)]);
    pen.fill(nose, SketchColors.pinkDeep);

    if (frame.mouth == CatMouth.open || frame.mouth == CatMouth.chew) {
      final depth = frame.mouth == CatMouth.chew ? 13.5 : 16.5;
      final open = Path()
        ..moveTo(hc.dx - 3.2, hc.dy + 10)
        ..quadraticBezierTo(hc.dx, hc.dy + 9.2, hc.dx + 3.2, hc.dy + 10)
        ..cubicTo(hc.dx + 3, hc.dy + depth - 1, hc.dx - 3, hc.dy + depth - 1, hc.dx - 3.2, hc.dy + 10)
        ..close();
      pen.fill(open, SketchColors.mouth);
      pen.canvas.save();
      pen.canvas.clipPath(open);
      pen.fill(ovalPath(hc + Offset(0, depth - 2.6), 5, 3.6), SketchColors.pink);
      pen.canvas.restore();
      pen.stroke(open, _line, width: 0.7, wobble: 0.1, sketchy: false);
    } else if (frame.mouth == CatMouth.tongue) {
      final tongue = ovalPath(hc + const Offset(0.4, 12.4), 3.4, 4.4);
      pen.fill(tongue, SketchColors.pink);
      pen.stroke(tongue, _line, width: 0.6, wobble: 0.1, sketchy: false);
      pen.line(
        hc + const Offset(0.4, 11),
        hc + const Offset(0.4, 13.4),
        SketchColors.pinkDeep,
        width: 0.5,
        sketchy: false,
        wobble: 0,
      );
    }

    pen.stroke(
      Path()
        ..moveTo(hc.dx - 3.8, hc.dy + 9.2)
        ..quadraticBezierTo(hc.dx - 1.9, hc.dy + 11.4, hc.dx, hc.dy + 8.6)
        ..quadraticBezierTo(hc.dx + 1.9, hc.dy + 11.4, hc.dx + 3.8, hc.dy + 9.2),
      _line,
      width: 0.8,
      wobble: 0.1,
      sketchy: false,
    );
  }

  void _whiskers(SketchPen pen, Offset hc) {
    for (final side in const [-1.0, 1.0]) {
      for (final (start, control, end) in const [
        (Offset(18, 5), Offset(23, 3), Offset(28, 2.6)),
        (Offset(18, 7.5), Offset(23.5, 7), Offset(29, 7.8)),
        (Offset(18, 10), Offset(22.5, 11), Offset(27, 13)),
      ]) {
        pen.stroke(
          Path()
            ..moveTo(hc.dx + start.dx * side, hc.dy + start.dy)
            ..quadraticBezierTo(hc.dx + control.dx * side, hc.dy + control.dy, hc.dx + end.dx * side, hc.dy + end.dy),
          _line,
          width: 0.45,
          sketchy: false,
          wobble: 0.1,
        );
      }
    }
  }

  void _raisedPaw(SketchPen pen, Offset paw) {
    const shoulder = Offset(63, 65);
    final control = Offset((shoulder.dx + paw.dx) / 2 + 3, math.max(shoulder.dy, paw.dy) + 2);
    pen.tube(
      Path()
        ..moveTo(shoulder.dx, shoulder.dy)
        ..quadraticBezierTo(control.dx, control.dy, paw.dx, paw.dy + 1),
      width: 6.6,
      outline: _line,
      fill: SketchColors.white,
      seed: 17,
    );
    final pad = ovalPath(paw, 8.5, 6.5);
    pen.fill(pad, SketchColors.white);
    pen.stroke(pad, _line, width: 0.95, wobble: 0.2, seed: 18);
    pen.fill(ovalPath(paw + const Offset(0.5, 0.8), 3, 2), SketchColors.pink.withValues(alpha: 0.7));
  }

  void _extras(SketchPen pen, Offset hc) {
    if (frame.motionMarks) {
      for (final o in const [Offset(17, 72), Offset(23, 79), Offset(86, 76)]) {
        pen.stroke(
          Path()
            ..moveTo(o.dx, o.dy)
            ..quadraticBezierTo(o.dx - 2, o.dy + 3, o.dx, o.dy + 6),
          SketchColors.graphite,
          width: 0.8,
          sketchy: false,
          wobble: 0,
        );
      }
    }
    if (frame.eatMarks > 0) {
      final color = SketchColors.ink.withValues(alpha: frame.eatMarks);
      pen.line(hc + const Offset(23, -4), hc + const Offset(27, -7), color, width: 0.9, sketchy: false);
      pen.line(hc + const Offset(24.5, 1), hc + const Offset(29, 0.5), color, width: 0.9, sketchy: false);
      pen.line(hc + const Offset(-23, -4), hc + const Offset(-27, -7), color, width: 0.9, sketchy: false);
    }
    if (frame.mark == CatMark.exclaim) {
      final top = hc + const Offset(0, -34);
      pen.line(top, top + const Offset(0.6, 7), SketchColors.ink, width: 1.8, sketchy: false, wobble: 0.1);
      pen.fill(ovalPath(top + const Offset(0.8, 10), 2, 2), SketchColors.ink);
      pen.line(top + const Offset(-5, 2), top + const Offset(-7.5, 0), SketchColors.ink, width: 0.9, sketchy: false);
      pen.line(top + const Offset(5, 2), top + const Offset(7.5, 0), SketchColors.ink, width: 0.9, sketchy: false);
    }
    if (frame.mark == CatMark.question) {
      final top = hc + const Offset(1, -38);
      pen.stroke(
        Path()
          ..moveTo(top.dx - 3.5, top.dy)
          ..quadraticBezierTo(top.dx - 3, top.dy - 5, top.dx + 0.5, top.dy - 5)
          ..quadraticBezierTo(top.dx + 4.5, top.dy - 4.5, top.dx + 3.5, top.dy - 1)
          ..quadraticBezierTo(top.dx + 2.5, top.dy + 1.5, top.dx, top.dy + 2.5)
          ..lineTo(top.dx, top.dy + 4.5),
        SketchColors.ink,
        width: 1.6,
        sketchy: false,
        wobble: 0.1,
      );
      pen.fill(ovalPath(top + const Offset(0, 8), 2, 2), SketchColors.ink);
    }
    if (frame.sparkle > 0) {
      final pulse = (math.sin(frame.sparkle * 9) + 1) / 2;
      pen.star(const Offset(90, 13), 2 + pulse * 2, SketchColors.sunEdge, width: 1.1);
      pen.star(const Offset(16, 17), 3 - pulse * 1.5, SketchColors.ink, width: 1.0);
      pen.star(const Offset(96, 30), 1.5 + pulse, SketchColors.pinkDeep, width: 0.9);
    }
  }

  @override
  bool shouldRepaint(FluffyCatPainter oldDelegate) => oldDelegate.frame != frame || oldDelegate.facing != facing;
}
