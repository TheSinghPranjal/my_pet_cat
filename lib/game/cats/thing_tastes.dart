import 'reaction.dart';

/// Which trait decides each thing's reaction, by thing id. Things not
/// listed get a neutral taste (curiosity), so every cat is at least "fine".
abstract final class ThingTastes {
  static const _neutral = ThingTaste(Trait.curiosity, lovesAt: 2, nopeAt: -1);

  static const _tastes = <String, ThingTaste>{
    // Living area (1.x Home).
    'feed': ThingTaste(Trait.appetite),
    'play': ThingTaste(Trait.energy),
    'catchMouse': ThingTaste(Trait.curiosity),
    // Bathroom.
    'bathTime': ThingTaste(Trait.tidiness),
    'brushFur': ThingTaste(Trait.cuddliness),
    'towelDry': ThingTaste(Trait.tidiness),
    // Park.
    'catchBird': ThingTaste(Trait.curiosity),
    'climbTree': ThingTaste(Trait.energy),
    'chaseButterflies': ThingTaste(Trait.curiosity),
    // Kitchen. Knocking a glass over delights the messiest cats.
    'glassTrouble': ThingTaste(Trait.tidiness, inverted: true),
    'treatTime': ThingTaste(Trait.appetite),
    'fishySurprise': ThingTaste(Trait.appetite),
    // The universal favourite.
    'cardboardBox': ThingTaste.universal(),
  };

  static ThingTaste of(String thingId) => _tastes[thingId] ?? _neutral;
}
