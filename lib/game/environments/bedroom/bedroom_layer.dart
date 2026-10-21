import 'package:flutter/widgets.dart';

import '../../controllers/cat_game_controller.dart';
import '../../models/game_positions.dart';
import 'bedroom_keys.dart';
import 'bedroom_props.dart';
import 'girl_painter.dart';

/// Places a widget with its bottom anchor at a normalized stage position.
typedef Anchored = Widget Function(Offset position, Size size, double anchorX, Widget child);

/// The bedroom's animated props and the girl, each with the y used for draw
/// order (lower on the floor = in front).
List<(double, Widget)> bedroomItems(CatGameController c, GameLayout layout, Anchored anchored) {
  final unit = layout.unit;
  double v(String key) => c.sceneValue(key);

  final wardrobeWidth = unit * GameSizes.wardrobe;
  final wardrobeSize = Size(wardrobeWidth, wardrobeWidth / WardrobePainter.aspect);
  final pillowWidth = unit * GameSizes.pillow;
  final pillowSize = Size(pillowWidth, pillowWidth / PillowPainter.aspect);
  final girlWidth = unit * GameSizes.girl;
  final girlSize = Size(girlWidth, girlWidth / GirlPainter.aspect);
  final girlX = v(BedroomKeys.girlX);
  final girlAt = BedroomPositions.girlPosition + Offset(girlX, 0);

  return [
    (
      BedroomPositions.wardrobePosition.dy,
      anchored(
        BedroomPositions.wardrobePosition,
        wardrobeSize,
        0.5,
        CustomPaint(
          size: wardrobeSize,
          painter: WardrobePainter(
            door: v(BedroomKeys.wardrobeDoor),
            eyes: v(BedroomKeys.wardrobeEyes) > 0,
            time: c.sceneTime,
          ),
        ),
      ),
    ),
    // The pillow sits on the bed, behind anything standing on it.
    (
      BedroomPositions.pillowPosition.dy - 0.05,
      anchored(
        BedroomPositions.pillowPosition,
        pillowSize,
        0.5,
        CustomPaint(
          size: pillowSize,
          painter: PillowPainter(squish: v(BedroomKeys.pillowSquish)),
        ),
      ),
    ),
    (
      BedroomPositions.cableRestPoint.dy,
      Positioned.fill(
        child: CustomPaint(
          painter: ChargerCablePainter(
            unit: unit,
            bitten: v(BedroomKeys.cableBite) > 0,
            zap: v(BedroomKeys.cableZap),
            time: c.sceneTime,
          ),
        ),
      ),
    ),
    (
      girlAt.dy,
      anchored(
        girlAt,
        girlSize,
        0.5,
        CustomPaint(
          size: girlSize,
          painter: GirlPainter(
            mood: GirlMood.values[v(BedroomKeys.girlMood).round().clamp(0, GirlMood.values.length - 1)],
            gait: GirlGait.values[v(BedroomKeys.girlGait).round().clamp(0, GirlGait.values.length - 1)],
            // Steps follow the distance walked, so legs stop when she does.
            stride: girlX * 70,
            facing: v(BedroomKeys.girlFacing),
            time: c.sceneTime,
          ),
        ),
      ),
    ),
  ];
}
