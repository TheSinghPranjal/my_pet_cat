/// Scene values of the bedroom's animated furniture. They all default to 0,
/// the room at rest: doors shut, cable on the floor, pillow plump. The girl
/// uses the shared GirlKeys.
abstract final class BedroomKeys {
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
}
