/// The time of day, from the device clock. Every scene is drawn for the
/// current phase: a soft sunrise, a blazing hot noon, a pink-orange
/// evening, or a starry night.
enum DayPhase {
  /// 5 am to 11 am.
  morning,

  /// 11 am to 5 pm: very hot.
  noon,

  /// 5 pm to 11 pm.
  evening,

  /// 11 pm to 5 am.
  night;

  static DayPhase fromHour(int hour) => switch (hour % 24) {
    >= 5 && < 11 => morning,
    >= 11 && < 17 => noon,
    >= 17 && < 23 => evening,
    _ => night,
  };

  static DayPhase at(DateTime time) => fromHour(time.hour);
}
