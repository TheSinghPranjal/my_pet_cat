/// Scene values of the living room's animated props. All default to 0: the
/// fish swimming calmly, the water still, the curtains hanging straight.
abstract final class LivingRoomKeys {
  /// -1..1: the goldfish darting away from a paw (positive = to the right).
  static const fishDodge = 'living.fishDodge';

  /// 0..1: ripples and drops on the bowl's water.
  static const fishSplash = 'living.fishSplash';

  /// 1 while a cat-shaped lump hides behind the curtain.
  static const curtainLump = 'living.curtainLump';

  /// 1 while eyes peek out from the curtain's edge.
  static const curtainPeek = 'living.curtainPeek';
}
