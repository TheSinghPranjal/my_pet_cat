import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../animations/cat_animations.dart';
import '../sketch/sketch.dart';

/// The kitten, drawn procedurally so every pose shares the exact same face,
/// proportions, stripes and anchor (bottom-center of the paws).
class CatCharacter extends StatelessWidget {
  const CatCharacter({
    super.key,
    required this.frame,
    required this.facing,
    required this.width,
  });

  /// Width / height of the cat's drawing box.
  static const aspect = 100 / 85;

  final CatFrame frame;
  final double facing;
  final double width;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, width / aspect),
      painter: CatPainter(frame: frame, facing: facing),
    );
  }
}

class CatPainter extends CustomPainter {
  CatPainter({required this.frame, required this.facing});

  final CatFrame frame;
  final double facing;

  // Hips and resting feet: far back, near back, far front, near front.
  static const _hips = [Offset(33, 65), Offset(40, 67), Offset(57, 65), Offset(64, 67)];
  static const _feet = [Offset(32, 81), Offset(40, 83.5), Offset(58, 81), nearFrontPawRest];

  static const _farFur = Color(0xFFEDEDF0);

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
    final width = 56 + frame.bodyLift * 1.5;
    pen.hatch(ovalPath(const Offset(48, 84), width, 6.5),
        SketchColors.inkSoft.withValues(alpha: 0.8),
        spacing: 1.1, angle: -0.25, width: 0.5, seed: 3);
  }

  void _tail(SketchPen pen) {
    const base = Offset(27, 57);
    final a = frame.tailAngle;
    Offset r(double x, double y) =>
        base + Offset(x * math.cos(a) - y * math.sin(a), x * math.sin(a) + y * math.cos(a));
    final c1 = r(-14, 4), c2 = r(-26, -12), end = r(-17, -30);
    final curlControl = r(-14, -36), tip = r(-9, -32);
    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy)
      ..quadraticBezierTo(curlControl.dx, curlControl.dy, tip.dx, tip.dy);
    pen.tube(path,
        width: 6.6, outline: SketchColors.pencil, fill: SketchColors.white, seed: 41);
    // Tabby rings.
    final metric = path.computeMetrics().first;
    for (final f in const [0.38, 0.55, 0.72, 0.88]) {
      final tangent = metric.getTangentForOffset(metric.length * f)!;
      final n = Offset(-tangent.vector.dy, tangent.vector.dx);
      pen.line(tangent.position - n * 3, tangent.position + n * 3, SketchColors.stripe,
          width: 1.3, sketchy: false, wobble: 0.15);
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
      width: 8,
      outline: SketchColors.pencil,
      fill: fur,
      seed: 11 + i,
    );
    _paw(pen, foot, fur, 20 + i);
    if (!far) {
      final mid = Offset.lerp(hip, foot, 0.45)!;
      pen.line(mid + const Offset(-3, 0.4), mid + const Offset(3.2, -0.6), SketchColors.stripe,
          width: 1.1, sketchy: false, wobble: 0.1);
    }
  }

  void _paw(SketchPen pen, Offset foot, Color fur, int seed) {
    final paw = ovalPath(foot + const Offset(1.2, -1.9), 10, 6);
    pen.fill(paw, fur);
    pen.stroke(paw, SketchColors.pencil, width: 0.95, wobble: 0.25, seed: seed);
    for (final dx in const [1.0, 3.6]) {
      pen.line(foot + Offset(dx, -2.4), foot + Offset(dx + 0.2, -0.4), SketchColors.pencil,
          width: 0.55, sketchy: false, wobble: 0);
    }
  }

  void _body(SketchPen pen) {
    final h = 27 * frame.breath;
    final rect = Rect.fromLTRB(23, 72 - h, 69, 72);
    final body = Path()..addOval(rect);
    pen.fill(body, SketchColors.white);
    pen.canvas.save();
    pen.canvas.clipPath(body);
    pen.hatch(rectPath(20, rect.top, 72, rect.top + h * 0.45),
        SketchColors.graphite.withValues(alpha: 0.55),
        spacing: 1.5, angle: -1.0, seed: 5);
    for (final x in const [31.0, 39.0, 47.0, 55.0]) {
      pen.stroke(
        Path()
          ..moveTo(x, rect.top + 0.5)
          ..quadraticBezierTo(x + 3, rect.top + 6, x + 1, rect.top + 11),
        SketchColors.stripe,
        width: 1.5,
        wobble: 0.2,
        sketchy: false,
        seed: x.toInt(),
      );
    }
    pen.canvas.restore();
    pen.stroke(body, SketchColors.pencil, width: 1.1, seed: 21);
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

    _ear(pen, [hc + const Offset(-17, -8), hc + const Offset(-15, -26), hc + const Offset(-4, -17)], 31);
    _ear(pen, [hc + const Offset(4, -17), hc + const Offset(15, -26), hc + const Offset(17, -8)], 32);

    final head = Path()
      ..moveTo(hc.dx, hc.dy - 17)
      ..cubicTo(hc.dx + 13, hc.dy - 17, hc.dx + 21, hc.dy - 9, hc.dx + 21, hc.dy + 1)
      ..cubicTo(hc.dx + 21, hc.dy + 11, hc.dx + 12, hc.dy + 16, hc.dx, hc.dy + 16)
      ..cubicTo(hc.dx - 12, hc.dy + 16, hc.dx - 21, hc.dy + 11, hc.dx - 21, hc.dy + 1)
      ..cubicTo(hc.dx - 21, hc.dy - 9, hc.dx - 13, hc.dy - 17, hc.dx, hc.dy - 17)
      ..close();
    pen.fill(head, SketchColors.white);
    canvas.save();
    canvas.clipPath(head);
    pen.hatch(rectPath(hc.dx - 22, hc.dy - 18, hc.dx + 22, hc.dy - 9),
        SketchColors.graphite.withValues(alpha: 0.4),
        spacing: 1.5, angle: -0.8, seed: 8);
    canvas.restore();
    for (final (a, b) in const [
      (Offset(-4.5, -15.5), Offset(-3.5, -10.5)),
      (Offset(0, -17), Offset(0, -11)),
      (Offset(4.5, -15.5), Offset(3.5, -10.5)),
    ]) {
      pen.line(hc + a, hc + b, SketchColors.stripe, width: 1.4, sketchy: false, wobble: 0.1);
    }
    pen.stroke(head, SketchColors.pencil, width: 1.1, seed: 33);

    for (final side in const [-1.0, 1.0]) {
      final cheek = ovalPath(hc + Offset(14 * side, 8.5), 7.5, 4.2);
      pen.fill(cheek, SketchColors.pink.withValues(alpha: 0.35));
      pen.hatch(cheek, SketchColors.pinkDeep, spacing: 0.8, angle: -0.4, width: 0.4, seed: 9);
    }
    _eye(pen, hc + const Offset(-8.5, 1.5));
    _eye(pen, hc + const Offset(8.5, 1.5));
    _mouth(pen, hc);
    _whiskers(pen, hc);

    canvas.restore();
    return hc;
  }

  void _ear(SketchPen pen, List<Offset> p, int seed) {
    Path earPath(List<Offset> q) => Path()
      ..moveTo(q[0].dx, q[0].dy)
      ..lineTo(Offset.lerp(q[0], q[1], 0.85)!.dx, Offset.lerp(q[0], q[1], 0.85)!.dy)
      ..quadraticBezierTo(q[1].dx, q[1].dy, Offset.lerp(q[1], q[2], 0.15)!.dx,
          Offset.lerp(q[1], q[2], 0.15)!.dy)
      ..lineTo(q[2].dx, q[2].dy)
      ..close();
    final outer = earPath(p);
    pen.fill(outer, SketchColors.white);
    final c = (p[0] + p[1] + p[2]) / 3;
    final inner = earPath([for (final q in p) c + (q - c) * 0.55 + const Offset(0, 1.2)]);
    pen.fill(inner, SketchColors.pink.withValues(alpha: 0.6));
    pen.hatch(inner, SketchColors.pinkDeep, spacing: 0.8, angle: 0.6, width: 0.4, seed: seed);
    pen.stroke(outer, SketchColors.pencil, width: 1.0, seed: seed);
  }

  void _eye(SketchPen pen, Offset c) {
    if (frame.happyEyes) {
      pen.stroke(
        Path()
          ..moveTo(c.dx - 4, c.dy + 1.5)
          ..quadraticBezierTo(c.dx, c.dy - 4, c.dx + 4, c.dy + 1.5),
        SketchColors.pencil,
        width: 1.5,
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
        SketchColors.pencil,
        width: 1.4,
        wobble: 0.1,
        sketchy: false,
      );
      return;
    }
    final eye = ovalPath(c, 9.2 * frame.eyeScale, 10.8 * open * frame.eyeScale);
    final canvas = pen.canvas;
    pen.fill(eye, SketchColors.eye);
    canvas.save();
    canvas.clipPath(eye);
    final look = Offset(frame.gaze * 1.3, frame.gazeY * 1.5);
    pen.fill(ovalPath(c + look + Offset(0, 3.4 * open), 7, 5.5 * open),
        SketchColors.iris.withValues(alpha: 0.85));
    pen.fill(ovalPath(c + look + const Offset(-1.4, -1.9), 3.6, 3.6 * open), SketchColors.white);
    pen.fill(ovalPath(c + look + const Offset(1.7, 1.9), 1.7, 1.7 * open), SketchColors.white);
    canvas.restore();
    pen.stroke(eye, SketchColors.pencil, width: 0.8, wobble: 0.15, sketchy: false);
  }

  void _mouth(SketchPen pen, Offset hc) {
    final nose = polygon([hc + const Offset(-1.8, 6.4), hc + const Offset(1.8, 6.4), hc + const Offset(0, 8.6)]);
    pen.fill(nose, SketchColors.pinkDeep);

    if (frame.mouth == CatMouth.open || frame.mouth == CatMouth.chew) {
      final depth = frame.mouth == CatMouth.chew ? 13.5 : 16.0;
      final open = Path()
        ..moveTo(hc.dx - 2.6, hc.dy + 10.2)
        ..quadraticBezierTo(hc.dx, hc.dy + depth, hc.dx + 2.6, hc.dy + 10.2)
        ..close();
      pen.fill(open, SketchColors.mouth);
      pen.canvas.save();
      pen.canvas.clipPath(open);
      pen.fill(ovalPath(hc + Offset(0, depth - 2.4), 4, 3), SketchColors.pink);
      pen.canvas.restore();
      pen.stroke(open, SketchColors.pencil, width: 0.7, wobble: 0.1, sketchy: false);
    } else if (frame.mouth == CatMouth.tongue) {
      final tongue = ovalPath(hc + const Offset(0.4, 12.4), 3.4, 4.4);
      pen.fill(tongue, SketchColors.pink);
      pen.stroke(tongue, SketchColors.pencil, width: 0.6, wobble: 0.1, sketchy: false);
      pen.line(hc + const Offset(0.4, 11), hc + const Offset(0.4, 13.4), SketchColors.pinkDeep,
          width: 0.5, sketchy: false, wobble: 0);
    }

    pen.stroke(
      Path()
        ..moveTo(hc.dx - 3.6, hc.dy + 9.4)
        ..quadraticBezierTo(hc.dx - 1.8, hc.dy + 11.6, hc.dx, hc.dy + 8.8)
        ..quadraticBezierTo(hc.dx + 1.8, hc.dy + 11.6, hc.dx + 3.6, hc.dy + 9.4),
      SketchColors.pencil,
      width: 0.85,
      wobble: 0.1,
      sketchy: false,
    );
  }

  void _whiskers(SketchPen pen, Offset hc) {
    for (final side in const [-1.0, 1.0]) {
      for (final (start, end) in const [
        (Offset(17.5, 5.5), Offset(27, 3)),
        (Offset(17.5, 8), Offset(28, 8)),
        (Offset(17.5, 10.5), Offset(26.5, 13)),
      ]) {
        pen.line(hc + Offset(start.dx * side, start.dy), hc + Offset(end.dx * side, end.dy),
            SketchColors.pencil, width: 0.55, sketchy: false, wobble: 0.15);
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
      width: 7.6,
      outline: SketchColors.pencil,
      fill: SketchColors.white,
      seed: 17,
    );
    final pad = ovalPath(paw, 8.5, 6.5);
    pen.fill(pad, SketchColors.white);
    pen.stroke(pad, SketchColors.pencil, width: 0.95, wobble: 0.2, seed: 18);
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
    if (frame.sparkle > 0) {
      final pulse = (math.sin(frame.sparkle * 9) + 1) / 2;
      pen.star(const Offset(90, 13), 2 + pulse * 2, SketchColors.sunEdge, width: 1.1);
      pen.star(const Offset(16, 17), 3 - pulse * 1.5, SketchColors.ink, width: 1.0);
      pen.star(const Offset(96, 30), 1.5 + pulse, SketchColors.pinkDeep, width: 0.9);
    }
  }

  @override
  bool shouldRepaint(CatPainter oldDelegate) =>
      oldDelegate.frame != frame || oldDelegate.facing != facing;
}
