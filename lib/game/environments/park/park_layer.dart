import 'package:flutter/widgets.dart';

import '../../controllers/cat_game_controller.dart';
import '../../models/game_positions.dart';
import '../girl/girl_layer.dart';
import 'park_keys.dart';
import 'park_props.dart';

/// The park's leaf pile, with the y used for draw order.
List<(double, Widget)> parkItems(CatGameController c, GameLayout layout, Anchored anchored) {
  final width = layout.unit * GameSizes.leafPile;
  final size = Size(width, width / LeafPilePainter.aspect);
  return [
    (
      ParkPositions.leafPilePosition.dy,
      anchored(
        ParkPositions.leafPilePosition,
        size,
        0.5,
        CustomPaint(
          size: size,
          painter: LeafPilePainter(scatter: c.sceneValue(ParkKeys.leafScatter)),
        ),
      ),
    ),
  ];
}
