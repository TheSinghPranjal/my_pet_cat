import 'girl_painter.dart';

/// Scene values for the girl, shared by every room she lives in. They all
/// default to 0: happy in her spot, standing still, facing the player.
abstract final class GirlKeys {
  /// Her sideways offset from her spot, in stage widths.
  static const x = 'girl.x';

  /// -1 left, 0 the player, 1 right.
  static const facing = 'girl.facing';

  /// A [GirlMood] index.
  static const mood = 'girl.mood';

  /// A [GirlGait] index.
  static const gait = 'girl.gait';

  static double moodValue(GirlMood mood) => mood.index.toDouble();
  static double gaitValue(GirlGait gait) => gait.index.toDouble();
}
