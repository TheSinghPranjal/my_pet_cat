import 'package:flutter/widgets.dart';

import '../animations/object_animations.dart';
import '../models/cat_game_state.dart';
import '../models/game_positions.dart';
import '../environments/park/park_props.dart';
import 'critters.dart';
import 'food_bowl.dart';
import 'grooming_props.dart';
import 'kitchen_props.dart';
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
      ObjectKind.glass => box(GameSizes.glass, GlassPainter.aspect),
      ObjectKind.treat => box(GameSizes.treat, TreatPainter.aspect),
      ObjectKind.fish => box(GameSizes.fish, FishPainter.aspect),
      ObjectKind.plate => box(GameSizes.plate, PlatePainter.aspect),
      ObjectKind.duck => box(GameSizes.duck, DuckPainter.aspect),
      ObjectKind.pigeon => box(GameSizes.pigeon, BirdPainter.aspect),
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
      ObjectKind.glass => GlassPainter(rotation: o.rotation, appear: o.appear, pop: o.pop),
      ObjectKind.treat => TreatPainter(fill: o.fill, appear: o.appear, pop: o.pop),
      ObjectKind.fish => FishPainter(progress: o.progress, appear: o.appear, pop: o.pop),
      ObjectKind.plate => PlatePainter(fill: o.fill, appear: o.appear, pop: o.pop),
      ObjectKind.duck => DuckPainter(
          phase: o.phase, facing: o.facing, appear: o.appear, pop: o.pop, quacking: o.progress > 0),
      ObjectKind.pigeon => BirdPainter(
          phase: o.phase, airborne: o.airborne, facing: o.facing, appear: o.appear, pop: o.pop, pigeon: true),
    };
    return Opacity(
      opacity: ObjectAnimations.popOpacity(o.pop),
      child: CustomPaint(size: sizeOf(o.kind, unit), painter: painter),
    );
  }
}
