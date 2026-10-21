import 'package:flutter/widgets.dart';

import '../animations/object_animations.dart';
import '../models/cat_game_state.dart';
import '../models/game_positions.dart';
import 'critters.dart';
import 'food_bowl.dart';
import 'grooming_props.dart';
import 'wool_ball.dart';

/// Renders any [SpawnedObject] with the shared fade-out, at a size derived
/// from [GameSizes].
class InteractiveObject extends StatelessWidget {
  const InteractiveObject({super.key, required this.object, required this.unit});

  final SpawnedObject object;
  final double unit;

  /// Pixel size of the sprite box for [kind].
  static Size sizeOf(ObjectKind kind, double unit) {
    Size box(double widthFraction, double aspect) {
      final w = unit * widthFraction;
      return Size(w, w / aspect);
    }

    return switch (kind) {
      ObjectKind.bowl => box(GameSizes.bowl, FoodBowl.aspect),
      ObjectKind.yarn => WoolBall.boxSize(unit * GameSizes.yarn),
      ObjectKind.mouse => box(GameSizes.mouse, MousePainter.aspect),
      ObjectKind.bird => box(GameSizes.bird, BirdPainter.aspect),
      ObjectKind.butterfly => box(GameSizes.butterfly, ButterflyPainter.aspect),
      ObjectKind.brush => box(GameSizes.brush, BrushPainter.aspect),
      ObjectKind.towel => box(GameSizes.towel, TowelPainter.aspect),
    };
  }

  /// Where the object's position sits horizontally inside its box (0..1).
  static double anchorX(ObjectKind kind) => kind == ObjectKind.yarn ? WoolBall.ballCenterX : 0.5;

  @override
  Widget build(BuildContext context) {
    final o = object;
    final CustomPainter painter = switch (o.kind) {
      ObjectKind.bowl => FoodBowlPainter(fill: o.fill, appear: o.appear, pop: o.pop),
      ObjectKind.yarn => WoolBallPainter(rotation: o.rotation, appear: o.appear, pop: o.pop),
      ObjectKind.mouse => MousePainter(
          phase: o.phase, moving: o.moving, facing: o.facing, appear: o.appear, pop: o.pop),
      ObjectKind.bird => BirdPainter(
          phase: o.phase, airborne: o.airborne, facing: o.facing, appear: o.appear, pop: o.pop),
      ObjectKind.butterfly => ButterflyPainter(phase: o.phase, appear: o.appear, pop: o.pop),
      ObjectKind.brush => BrushPainter(facing: o.facing, appear: o.appear, pop: o.pop),
      ObjectKind.towel => TowelPainter(appear: o.appear, pop: o.pop),
    };
    return Opacity(
      opacity: ObjectAnimations.popOpacity(o.pop),
      child: CustomPaint(size: sizeOf(o.kind, unit), painter: painter),
    );
  }
}
