import 'package:flutter/widgets.dart';

import '../models/activity_definition.dart';
import '../sketch/sketch.dart';
import 'critters.dart';
import 'food_bowl.dart';
import 'grooming_props.dart';
import 'wool_ball.dart';

/// Action-button icons, reusing the in-game sprites at rest so buttons and
/// scene always match.
class ActivityIcon extends StatelessWidget {
  const ActivityIcon(this.activity, {super.key});

  final CatActivity activity;

  @override
  Widget build(BuildContext context) {
    final (double aspect, CustomPainter painter) = switch (activity) {
      CatActivity.feed => (FoodBowl.aspect, FoodBowlPainter()),
      CatActivity.play => (WoolBall.aspect, WoolBallPainter(rotation: 0.4)),
      CatActivity.catchMouse => (MousePainter.aspect, MousePainter()),
      CatActivity.bathTime => (BathTubPainter.aspect, BathTubPainter(foam: 1)),
      CatActivity.brushFur => (BrushPainter.aspect, BrushPainter()),
      CatActivity.towelDry => (TowelPainter.aspect, TowelPainter()),
      CatActivity.catchBird => (BirdPainter.aspect, BirdPainter()),
      CatActivity.climbTree => (1.0, TreeIconPainter()),
      CatActivity.chaseButterflies => (ButterflyPainter.aspect, ButterflyPainter()),
    };
    return AspectRatio(aspectRatio: aspect, child: CustomPaint(painter: painter));
  }
}

/// Small tree with grass, used for Climb Tree and the Garden tab.
class TreeIconPainter extends CustomPainter {
  TreeIconPainter({this.withSun = false});

  final bool withSun;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 40;
    final pen = SketchPen(canvas, pxPerUnit: k);
    canvas.save();
    canvas.scale(k);
    if (withSun) {
      final sun = ovalPath(const Offset(32, 8), 8, 8);
      pen.fill(sun, SketchColors.sun);
      pen.stroke(sun, SketchColors.sunEdge, width: 0.9, sketchy: false);
    }
    final trunk = polygon(const [Offset(17, 36), Offset(18, 20), Offset(22, 20), Offset(23, 36)]);
    pen.fill(trunk, SketchColors.white);
    pen.hatch(trunk, SketchColors.kibble, spacing: 1.2, seed: 1);
    pen.stroke(trunk, SketchColors.kibbleDark, width: 1.1, seed: 1);
    var canopy = Path();
    for (final (c, r) in const [(Offset(14, 16), 8.0), (Offset(20, 10), 9.0), (Offset(27, 16), 8.0)]) {
      canopy = Path.combine(PathOperation.union, canopy, Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    }
    pen.fill(canopy, const Color(0xFFD4EED0));
    pen.hatch(canopy, SketchColors.leaf, spacing: 1.3, seed: 2, cross: true);
    pen.stroke(canopy, SketchColors.leafDark, width: 1.2, seed: 3);
    pen.line(const Offset(4, 36.5), const Offset(36, 36.5), SketchColors.leafDark, width: 1.2);
    for (final x in const [8.0, 28.0, 33.0]) {
      pen.line(Offset(x, 36.5), Offset(x - 1, 33.5), SketchColors.leaf, width: 0.9, sketchy: false);
      pen.line(Offset(x, 36.5), Offset(x + 1, 33.5), SketchColors.leaf, width: 0.9, sketchy: false);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(TreeIconPainter oldDelegate) => oldDelegate.withSun != withSun;
}
