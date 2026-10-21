part of 'cat_anatomy.dart';

/// Head, ears and face of [CatAnatomy].
extension _CatFace on CatAnatomy {
  /// Head outline: a soft dome with fluffy cheek tufts.
  Path _headPath(Offset hc) {
    final path = Path();
    const n = 160;
    final cheeks = _chubby ? 1.6 : 0.0;
    for (var i = 0; i <= n; i++) {
      final t = i / n * math.pi * 2;
      final sin = math.sin(t), cos = math.cos(t);
      // Chubby cheeks: wider below the eyes than across the crown.
      final rx = 21.0 + cheeks + (1.6 + cheeks) * math.max(0, sin), ry = sin < 0 ? 17.5 : 16.0;
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
    _ear(
      pen,
      [hc + const Offset(3, -16), hc + const Offset(15, -27), hc + const Offset(18, -7)],
      32,
      bent: earStyle == EarStyle.bent,
    );
    canvas.restore();

    final head = _headPath(hc);
    pen.fill(head, coat.fur);
    canvas.save();
    canvas.clipPath(head);
    pen.hatch(
      rectPath(hc.dx - 23, hc.dy - 19, hc.dx + 23, hc.dy - 10),
      coat.shade.withValues(alpha: coat.headShade),
      spacing: 1.4,
      angle: -0.8,
      width: 0.4,
      seed: 8,
    );
    paintHeadInside(pen, hc);
    canvas.restore();
    paintHeadMarks(pen, hc);
    pen.stroke(head, coat.line, width: CatAnatomy._lineWidth, wobble: 0.15, seed: 33);
    // Crown wisp.
    for (final (a, b) in const [
      (Offset(-1.5, -16.8), Offset(-2.6, -19.6)),
      (Offset(0, -17), Offset(0.4, -20.4)),
      (Offset(1.5, -16.8), Offset(3, -19.3)),
    ]) {
      pen.line(hc + a, hc + b, coat.line, width: 0.65, sketchy: false, wobble: 0.05);
    }

    for (final side in const [-1.0, 1.0]) {
      final cheek = ovalPath(hc + Offset(14 * side, 8.5), 7.5, 4.2);
      pen.fill(cheek, SketchColors.pink.withValues(alpha: coat.blush));
      pen.hatch(cheek, SketchColors.pinkDeep, spacing: 0.8, angle: -0.4, width: 0.4, seed: 9);
    }
    _eye(pen, hc + const Offset(-8.5, 1.2));
    _eye(pen, hc + const Offset(8.5, 1.2));
    _mouth(pen, hc);
    _whiskers(pen, hc);
    paintAccessories(pen, hc);

    canvas.restore();
    return hc;
  }

  /// An ear from its base corners and tip. A [bent] ear has its tip folded
  /// down across its front along a crease.
  void _ear(SketchPen pen, List<Offset> p, int seed, {bool bent = false}) {
    Path earPath(List<Offset> q) => Path()
      ..moveTo(q[0].dx, q[0].dy)
      ..lineTo(Offset.lerp(q[0], q[1], 0.85)!.dx, Offset.lerp(q[0], q[1], 0.85)!.dy)
      ..quadraticBezierTo(q[1].dx, q[1].dy, Offset.lerp(q[1], q[2], 0.15)!.dx, Offset.lerp(q[1], q[2], 0.15)!.dy)
      ..lineTo(q[2].dx, q[2].dy)
      ..close();
    final tip = p[1];
    final crease = (Offset.lerp(p[0], tip, 0.6)!, Offset.lerp(p[2], tip, 0.6)!);
    // A bent ear stops at the crease; its tip is mirrored down over it.
    final outer = bent ? polygon([p[0], crease.$1, crease.$2, p[2]]) : earPath(p);
    pen.fill(outer, coat.fur);
    final c = (p[0] + p[1] + p[2]) / 3;
    final innerPoints = [for (final q in p) c + (q - c) * 0.66 + const Offset(0, 1.4)];
    final inner = earPath(innerPoints);
    pen.canvas.save();
    if (bent) pen.canvas.clipPath(outer);
    pen.fill(inner, SketchColors.pink.withValues(alpha: 0.75));
    pen.hatch(inner, SketchColors.pinkDeep, spacing: 0.75, angle: 0.6, width: 0.4, seed: seed);
    pen.canvas.restore();
    // Fur wisps inside the ear.
    final baseMid = Offset.lerp(innerPoints[0], innerPoints[2], 0.5)!;
    for (final f in bent ? const [0.5] : const [0.3, 0.5, 0.7]) {
      final from = Offset.lerp(innerPoints[0], innerPoints[2], f)!;
      pen.line(
        from,
        Offset.lerp(from, innerPoints[1], bent ? 0.25 : 0.45)! + (from - baseMid) * 0.15,
        coat.faceLine.withValues(alpha: 0.7),
        width: 0.4,
        sketchy: false,
        wobble: 0,
      );
    }
    pen.stroke(outer, coat.line, width: CatAnatomy._lineWidth, seed: seed);
    if (bent) {
      final (a, b) = crease;
      final d = b - a;
      final along = ((tip - a).dx * d.dx + (tip - a).dy * d.dy) / (d.dx * d.dx + d.dy * d.dy);
      final foot = a + d * along;
      final flapTip = foot * 2 - tip + (tip - foot) * 0.15;
      final flap = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(flapTip.dx - 1, flapTip.dy - 1, flapTip.dx, flapTip.dy)
        ..quadraticBezierTo(flapTip.dx + 1, flapTip.dy - 1.5, b.dx, b.dy)
        ..close();
      pen.fill(flap, coat.fur);
      pen.stroke(flap, coat.line, width: CatAnatomy._lineWidth, wobble: 0.1, seed: seed + 1);
    }
  }

  void _eye(SketchPen pen, Offset c) {
    final line = coat.faceLine;
    if (frame.happyEyes) {
      pen.stroke(
        Path()
          ..moveTo(c.dx - 4, c.dy + 1.5)
          ..quadraticBezierTo(c.dx, c.dy - 4, c.dx + 4, c.dy + 1.5),
        line,
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
        line,
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
    // Iris glowing up from the bottom of the eye.
    pen.fill(ovalPath(c + look + Offset(0, 2.6 * open), 8.2, 7 * open), eyes.iris.withValues(alpha: 0.9));
    pen.fill(ovalPath(c + look + Offset(0, 3.6 * open), 5.4, 3.6 * open), eyes.glow.withValues(alpha: 0.85));
    pen.fill(ovalPath(c + look + const Offset(0, 0.4), 4.2, 5 * open), SketchColors.eye);
    pen.fill(ovalPath(c + look + const Offset(-1.6, -2.1), 3.8, 3.8 * open), SketchColors.white);
    pen.fill(ovalPath(c + look + const Offset(1.9, 2.2), 1.6, 1.6 * open), SketchColors.white);
    canvas.restore();
    pen.stroke(eye, line, width: 0.8, wobble: 0.15, sketchy: false);
  }

  void _mouth(SketchPen pen, Offset hc) {
    final line = coat.mouthLine;
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
      pen.stroke(open, line, width: 0.7, wobble: 0.1, sketchy: false);
    } else if (frame.mouth == CatMouth.tongue) {
      final tongue = ovalPath(hc + const Offset(0.4, 12.4), 3.4, 4.4);
      pen.fill(tongue, SketchColors.pink);
      pen.stroke(tongue, line, width: 0.6, wobble: 0.1, sketchy: false);
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
      line,
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
          coat.whisker,
          width: 0.45,
          sketchy: false,
          wobble: 0.1,
        );
      }
    }
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
}
