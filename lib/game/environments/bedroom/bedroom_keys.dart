import 'girl_painter.dart';

/// Scene values of the bedroom's animated furniture and of the girl. They
/// all default to 0, which is the room at rest: doors shut, cable on the
/// floor, and the girl happy in her spot, facing the player.
abstract final class BedroomKeys {
  /// The girl's sideways offset from her spot, in stage widths.
  static const girlX = 'bedroom.girlX';

  /// -1 left, 0 the player, 1 right.
  static const girlFacing = 'bedroom.girlFacing';

  /// A [GirlMood] index.
  static const girlMood = 'bedroom.girlMood';

  /// A [GirlGait] index.
  static const girlGait = 'bedroom.girlGait';

  /// 0 shut .. 1 wide open.
  static const wardrobeDoor = 'bedroom.wardrobeDoor';

  /// 1 while eyes peek out of the dark wardrobe.
  static const wardrobeEyes = 'bedroom.wardrobeEyes';

  /// 1 while the cat holds the cable in her mouth.
  static const cableBite = 'bedroom.cableBite';

  /// 0..1 crackle along the cable.
  static const cableZap = 'bedroom.cableZap';

  /// 0..1 how flat the pillow is squashed.
  static const pillowSquish = 'bedroom.pillowSquish';

  static double mood(GirlMood mood) => mood.index.toDouble();
  static double gait(GirlGait gait) => gait.index.toDouble();
}
