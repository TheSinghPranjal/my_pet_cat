import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../animations/object_animations.dart';
import '../sketch/sketch.dart';

/// Red colored-pencil ball of yarn with a loose strand.
///
/// The drawing box is 170x110 units; the ball (diameter 100) sits with its
/// center at [ballCenterX] so the strand has room to trail on the right.
class WoolBall extends StatelessWidget {
  const WoolBall({
    super.key,
    required this.ballDiameter,
    this.rotation = 0,
    this.appear = 1,
    this.pop = 0,
  });

  static const aspect = 170 / 110;

  /// Horizontal position of the ball center as a fraction of the box width.
  static const ballCenterX = 60 / 170;

  final double ballDiameter;
  final double rotation;
  final double appear;
  final double pop;

  static Size boxSize(double ballDiameter) =>
      Size(ballDiameter * 1.7, ballDiameter * 1.1);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: boxSize(ballDiameter),
      painter: WoolBallPainter(rotation: rotation, appear: appear, pop: pop),
    );
  }
}

class WoolBallPainter extends CustomPainter {
  WoolBallPainter({this.rotation = 0, this.appear = 1, this.pop = 0});

  final double rotation;
  final double appear;
  final double pop;

  static const _center = Offset(60, 55);
  static const _radius = 48.0;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 170;
    final pen = SketchPen(canvas, pxPerUnit: s);
    canvas.save();
    canvas.scale(s);

    final scale = ObjectAnimations.appearScale(appear) * ObjectAnimations.popScale(pop);
    if (scale > 0.01) {
      canvas.save();
      canvas.translate(_center.dx, 105 + ObjectAnimations.appearLift(appear) * 100);
      canvas.scale(scale);
      canvas.translate(-_center.dx, -105);
      _ball(pen);
      canvas.restore();
    }
    pen.popMarks(_center, 62, pop, SketchColors.wool, width: 2.6);
    canvas.restore();
  }

  void _ball(SketchPen pen) {
    final canvas = pen.canvas;
    pen.hatch(ovalPath(const Offset(64, 105), 96, 9), SketchColors.inkSoft,
        spacing: 2.2, angle: -0.2, width: 0.9, seed: 1);

    // Loose strand trailing to the right with a little curl.
    pen.stroke(
      Path()
        ..moveTo(92, 92)
        ..cubicTo(112, 112, 128, 88, 142, 96)
        ..quadraticBezierTo(152, 102, 160, 92)
        ..quadraticBezierTo(164, 86, 157, 88),
      SketchColors.wool,
      width: 3,
      wobble: 0.6,
      seed: 3,
    );

    final ball = Path()..addOval(Rect.fromCircle(center: _center, radius: _radius));
    pen.fill(ball, SketchColors.white);
    pen.hatch(ball, SketchColors.wool.withValues(alpha: 0.5), spacing: 3.4, angle: -0.7,
        width: 1.2, seed: 5, cross: true);

    canvas.save();
    canvas.clipPath(ball);
    canvas.translate(_center.dx, _center.dy);
    canvas.rotate(rotation);
    // Wraps of yarn: arcs at different angles that spin with the ball.
    final wraps = [
      (0.0, 0.55), (0.6, 0.8), (1.25, 0.5), (1.9, 0.95), (2.5, 0.65), (3.0, 0.35),
    ];
    for (final (angle, squash) in wraps) {
      canvas.save();
      canvas.rotate(angle);
      for (var j = 0; j < 3; j++) {
        final offset = -_radius * 0.15 + j * 7.0;
        pen.stroke(
          Path()
            ..addArc(
              Rect.fromCenter(
                center: Offset(0, offset),
                width: _radius * 2.1,
                height: _radius * 2 * squash,
              ),
              math.pi * 1.05,
              math.pi * 0.9,
            ),
          SketchColors.wool,
          width: 2.0,
          wobble: 0.5,
          sketchy: false,
          seed: (angle * 10).toInt() + j,
        );
      }
      canvas.restore();
    }
    canvas.restore();

    pen.stroke(ball, SketchColors.woolDark, width: 3, wobble: 0.8, seed: 9);
  }

  @override
  bool shouldRepaint(WoolBallPainter oldDelegate) =>
      oldDelegate.rotation != rotation || oldDelegate.appear != appear || oldDelegate.pop != pop;
}
