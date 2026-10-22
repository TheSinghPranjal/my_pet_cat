import 'package:flutter/widgets.dart';

import '../../controllers/cat_game_controller.dart';
import '../../models/game_positions.dart';
import 'girl_keys.dart';
import 'girl_painter.dart';

/// Places a widget with its bottom anchor at a normalized stage position.
typedef Anchored = Widget Function(Offset position, Size size, double anchorX, Widget child);

/// The girl standing at [home] (moved by the scripts), with the y used for
/// draw order.
(double, Widget) girlItem(CatGameController c, GameLayout layout, Anchored anchored, Offset home) {
  final width = layout.unit * GameSizes.girl;
  final size = Size(width, width / GirlPainter.aspect);
  final x = c.sceneValue(GirlKeys.x);
  final at = home + Offset(x, 0);
  return (
    at.dy,
    anchored(
      at,
      size,
      0.5,
      CustomPaint(
        size: size,
        painter: GirlPainter(
          mood: GirlMood.values[c.sceneValue(GirlKeys.mood).round().clamp(0, GirlMood.values.length - 1)],
          gait: GirlGait.values[c.sceneValue(GirlKeys.gait).round().clamp(0, GirlGait.values.length - 1)],
          // Steps follow the distance walked, so legs stop when she does.
          stride: x * 70,
          facing: c.sceneValue(GirlKeys.facing),
          time: c.sceneTime,
        ),
      ),
    ),
  );
}
