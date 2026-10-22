import 'package:flutter/widgets.dart';

import '../../controllers/cat_game_controller.dart';
import '../../models/game_positions.dart';
import 'bedroom_keys.dart';
import 'bedroom_props.dart';
import '../girl/girl_layer.dart';

/// The bedroom's animated props and the girl, each with the y used for draw
/// order (lower on the floor = in front).
List<(double, Widget)> bedroomItems(CatGameController c, GameLayout layout, Anchored anchored) {
  final unit = layout.unit;
  double v(String key) => c.sceneValue(key);

  final wardrobeWidth = unit * GameSizes.wardrobe;
  final wardrobeSize = Size(wardrobeWidth, wardrobeWidth / WardrobePainter.aspect);
  final pillowWidth = unit * GameSizes.pillow;
  final pillowSize = Size(pillowWidth, pillowWidth / PillowPainter.aspect);
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
    girlItem(c, layout, anchored, BedroomPositions.girlPosition),
  ];
}
