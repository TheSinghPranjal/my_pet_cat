import 'package:flutter/widgets.dart';

import '../../controllers/cat_game_controller.dart';
import '../../models/game_positions.dart';
import '../girl/girl_layer.dart';
import 'living_room_keys.dart';
import 'living_room_props.dart';

/// The living room's animated props and the girl, each with the y used for
/// draw order (lower on the floor = in front).
List<(double, Widget)> livingRoomItems(CatGameController c, GameLayout layout, Anchored anchored) {
  double v(String key) => c.sceneValue(key);
  final bowlWidth = layout.unit * GameSizes.fishBowl;
  final bowlSize = Size(bowlWidth, bowlWidth / FishBowlPainter.aspect);
  return [
    // The curtains hang just in front of anything hiding behind them.
    (
      SceneMetrics.groundLine + 0.016,
      Positioned.fill(
        child: CustomPaint(
          painter: CurtainsPainter(
            unit: layout.unit,
            lump: v(LivingRoomKeys.curtainLump),
            peek: v(LivingRoomKeys.curtainPeek) > 0,
            time: c.sceneTime,
          ),
        ),
      ),
    ),
    (
      LivingRoomPositions.fishBowlPosition.dy,
      anchored(
        LivingRoomPositions.fishBowlPosition,
        bowlSize,
        0.5,
        CustomPaint(
          size: bowlSize,
          painter: FishBowlPainter(
            dodge: v(LivingRoomKeys.fishDodge),
            splash: v(LivingRoomKeys.fishSplash),
            time: c.sceneTime,
          ),
        ),
      ),
    ),
    girlItem(c, layout, anchored, LivingRoomPositions.girlPosition),
  ];
}
