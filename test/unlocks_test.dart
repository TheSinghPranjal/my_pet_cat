import 'package:flutter_test/flutter_test.dart';
import 'package:my_pet_cat/game/cats/cat_persona.dart';
import 'package:my_pet_cat/game/cats/cat_profile.dart';
import 'package:my_pet_cat/game/cats/selected_cat.dart';
import 'package:my_pet_cat/game/environments/environment_id.dart';
import 'package:my_pet_cat/game/models/cat_look.dart';
import 'package:my_pet_cat/game/save/game_save.dart';
import 'package:my_pet_cat/game/save/game_store.dart';

GameSave _withStars(int stars) {
  final save = GameSave();
  // Spread over two cats to show stars count across every cat.
  save.cat(CatId.mochi).friendship = (stars / 2).ceilToDouble().clamp(0, 5);
  save.cat(CatId.kitty).friendship = (stars - save.cat(CatId.mochi).stars).toDouble().clamp(0, 5);
  return save;
}

void main() {
  test('cats unlock at their thresholds', () {
    const starters = {CatId.mochi, CatId.kitty, CatId.biscuit, CatId.luna, CatId.pepper};
    const expected = <int, Set<CatId>>{
      0: starters,
      9: starters,
      10: {...starters, CatId.snowball},
    };
    for (final MapEntry(key: stars, value: cats) in expected.entries) {
      final save = _withStars(stars);
      expect(save.totalStars, stars);
      expect(CatId.values.where(save.isCatUnlocked).toSet(), cats, reason: '$stars stars');
    }
    // Twelve stars need a third cat's friendship.
    final all = _withStars(10)..cat(CatId.biscuit).friendship = 2;
    expect(CatId.values.every(all.isCatUnlocked), isTrue);
  });

  test('environments unlock at their thresholds', () {
    const open = {
      EnvironmentId.livingArea,
      EnvironmentId.kitchen,
      EnvironmentId.bathroom,
      EnvironmentId.garden,
      EnvironmentId.livingRoom,
    };
    final expected = <int, Set<EnvironmentId>>{
      0: open,
      1: {...open, EnvironmentId.bedroom},
      2: {...open, EnvironmentId.bedroom, EnvironmentId.park},
      4: {...EnvironmentId.values}..remove(EnvironmentId.car),
      6: {...EnvironmentId.values},
    };
    for (final MapEntry(key: stars, value: places) in expected.entries) {
      expect(EnvironmentId.values.where(_withStars(stars).isEnvironmentUnlocked).toSet(), places, reason: '$stars');
    }
  });

  test('locked cats cannot be selected', () {
    final store = GameStore();
    final selected = SelectedCat(store: store);
    // Kitty is unlocked from the start.
    expect(selected.select(CatProfiles.kitty), isTrue);
    expect(store.save.selectedCat, CatId.kitty);

    // A profile whose cat is still locked is refused.
    const locked = CatProfile(
      id: CatId.ziggy,
      name: 'Ziggy',
      look: CatLook.classic,
      persona: CatPersonas.ziggy,
      greetings: [],
    );
    expect(selected.select(locked), isFalse);
    expect(selected.value, CatProfiles.kitty);
    expect(store.save.selectedCat, CatId.kitty);
  });
}
