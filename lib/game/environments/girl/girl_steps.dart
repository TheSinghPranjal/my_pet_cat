import '../../scripting/script_step.dart';
import 'girl_keys.dart';
import 'girl_painter.dart';

/// Script steps that direct the girl.
abstract final class Girl {
  static ScriptStep mood(GirlMood mood) => SetValue(GirlKeys.mood, GirlKeys.moodValue(mood));
  static ScriptStep gait(GirlGait gait) => SetValue(GirlKeys.gait, GirlKeys.gaitValue(gait));
  static ScriptStep face(double facing) => SetValue(GirlKeys.facing, facing);

  /// She walks (or runs) to [x] (offset from her spot), facing that way.
  static ScriptStep to(double x, double seconds, {required double facing, GirlGait gait = GirlGait.walk}) =>
      Sequence([Girl.face(facing), Girl.gait(gait), TweenValue(GirlKeys.x, x, seconds), Girl.gait(GirlGait.stand)]);
}
