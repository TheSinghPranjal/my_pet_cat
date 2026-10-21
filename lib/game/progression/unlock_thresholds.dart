import '../cats/cat_profile.dart';
import '../environments/environment_id.dart';

/// Unlocks once the player has earned [stars] friendship stars in total
/// (across every cat). Zero means unlocked from the start.
class UnlockRule {
  const UnlockRule(this.stars);

  static const always = UnlockRule(0);

  final int stars;

  bool isMet(int totalStars) => totalStars >= stars;
}

/// Every unlock threshold, in one place for easy tuning.
abstract final class UnlockThresholds {
  static const cats = <CatId, UnlockRule>{
    CatId.mochi: UnlockRule.always,
    CatId.kitty: UnlockRule.always,
    CatId.biscuit: UnlockRule(3),
    CatId.luna: UnlockRule(5),
    CatId.pepper: UnlockRule(8),
    CatId.snowball: UnlockRule(10),
    CatId.ziggy: UnlockRule(12),
  };

  static const environments = <EnvironmentId, UnlockRule>{
    EnvironmentId.livingArea: UnlockRule.always,
    EnvironmentId.kitchen: UnlockRule.always,
    EnvironmentId.bathroom: UnlockRule.always,
    EnvironmentId.bedroom: UnlockRule(1),
    EnvironmentId.park: UnlockRule(2),
    EnvironmentId.rooftop: UnlockRule(4),
    EnvironmentId.car: UnlockRule(6),
  };

  static UnlockRule cat(CatId id) => cats[id]!;

  static UnlockRule environment(EnvironmentId id) => environments[id]!;
}
