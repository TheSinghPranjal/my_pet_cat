import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_pet_cat/game/cats/cat_needs.dart';
import 'package:my_pet_cat/game/cats/cat_profile.dart';
import 'package:my_pet_cat/game/environments/environment_id.dart';
import 'package:my_pet_cat/game/save/game_save.dart';
import 'package:my_pet_cat/game/save/game_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameSave JSON', () {
    test('round-trips everything', () {
      final save = GameSave(
        selectedCat: CatId.kitty,
        lastEnvironment: EnvironmentId.kitchen,
        settings: GameSettings(wander: false, sound: true),
        stickers: {'feed', 'bathTime'},
        unlocked: {'env:bedroom'},
        lastSeen: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
      save.cat(CatId.kitty)
        ..needs = CatNeeds.initial.apply({Need.hunger: 50, Need.fun: -10})
        ..friendship = 2.5
        ..completed.addAll({'feed', 'play'});

      final copy = GameSave.fromJson(jsonDecode(jsonEncode(save.toJson())));
      expect(copy.toJson(), save.toJson());
      expect(copy.selectedCat, CatId.kitty);
      expect(copy.settings.wander, isFalse);
      expect(copy.cat(CatId.kitty).needs[Need.hunger], 80);
      expect(copy.cat(CatId.kitty).stars, 2);
      expect(copy.totalStars, 2);
      expect(copy.toJson()['schemaVersion'], GameSave.schemaVersion);
    });

    test('broken or out-of-range values fall back or clamp', () {
      final save = GameSave.fromJson({
        'schemaVersion': 1,
        'selectedCat': 'tiger',
        'lastEnvironment': 42,
        'settings': 'loud',
        'cats': {
          'mochi': {
            'needs': {'hunger': 500, 'fun': 'lots', 'energy': -3, 'cleanliness': double.nan},
            'friendship': 99,
            'completed': ['feed', 3, null],
          },
          'unknownCat': {'friendship': 5},
        },
        'stickers': 'not a list',
      });
      expect(save.selectedCat, CatId.mochi);
      expect(save.lastEnvironment, EnvironmentId.livingArea);
      expect(save.settings.wander, isTrue);
      final mochi = save.cat(CatId.mochi);
      expect(mochi.needs[Need.hunger], 100);
      expect(mochi.needs[Need.fun], CatNeeds.initial[Need.fun]);
      expect(mochi.needs[Need.energy], 0);
      expect(mochi.needs[Need.cleanliness], CatNeeds.initial[Need.cleanliness]);
      expect(mochi.friendship, CatSave.maxStars);
      expect(mochi.completed, {'feed'});
      expect(save.cats.keys, [CatId.mochi]);
      expect(save.stickers, isEmpty);
    });

    test('a save without a schema version is migrated to the current one', () {
      final json = GameSave.migrate({'selectedCat': 'kitty'});
      expect(json['schemaVersion'], GameSave.schemaVersion);
      expect(GameSave.fromJson({'selectedCat': 'kitty'}).selectedCat, CatId.kitty);
    });

    test('a locked cat is never restored as the selected one', () {
      expect(GameSave.fromJson({'selectedCat': 'ziggy'}).selectedCat, CatId.mochi);
      final rich = GameSave.fromJson({
        'selectedCat': 'biscuit',
        'cats': {
          'mochi': {'friendship': 2},
          'kitty': {'friendship': 1},
        },
      });
      expect(rich.selectedCat, CatId.biscuit);
    });
  });

  group('GameStore', () {
    test('migrates the 1.x look preference', () {
      expect(GameStore.decode(null, legacyLook: 'classic').selectedCat, CatId.kitty);
      expect(GameStore.decode(null, legacyLook: 'fluffy').selectedCat, CatId.mochi);
      expect(GameStore.decode(null).selectedCat, CatId.mochi);
    });

    test('corrupted JSON falls back to defaults (keeping the 1.x look)', () {
      for (final raw in ['{not json', '[1, 2]', '"text"', '{"cats": {"1": 2}, "selectedCat": []}', '']) {
        final save = GameStore.decode(raw, legacyLook: 'classic');
        expect(save.selectedCat, anyOf(CatId.kitty, CatId.mochi), reason: raw);
        expect(save.settings.wander, isTrue, reason: raw);
      }
      expect(GameStore.decode('{not json', legacyLook: 'classic').selectedCat, CatId.kitty);
    });

    test('loads the 1.x key from storage, then saves one debounced blob', () async {
      SharedPreferences.setMockInitialValues({GameStore.legacyLookKey: 'classic'});
      final store = GameStore(debounce: const Duration(milliseconds: 20));
      await store.load();
      expect(store.save.selectedCat, CatId.kitty);

      final prefs = await SharedPreferences.getInstance();
      store.applyNeeds(CatId.kitty, {Need.fun: 10});
      store.applyNeeds(CatId.kitty, {Need.fun: 5});
      expect(prefs.getString(GameStore.key), isNull, reason: 'debounced');
      await Future<void>.delayed(const Duration(milliseconds: 60));
      final saved = jsonDecode(prefs.getString(GameStore.key)!) as Map;
      expect(saved['selectedCat'], 'kitty');
      expect(saved['cats']['kitty']['needs']['fun'], CatNeeds.initial[Need.fun] + 15);

      final reloaded = GameStore();
      await reloaded.load();
      expect(reloaded.save.toJson(), store.save.toJson());
    });

    test('flush writes at once (app paused)', () async {
      SharedPreferences.setMockInitialValues({});
      final store = GameStore(debounce: const Duration(hours: 1));
      await store.load();
      store.update((save) => save.settings.wander = false);
      await store.flush();
      final prefs = await SharedPreferences.getInstance();
      expect((jsonDecode(prefs.getString(GameStore.key)!) as Map)['settings'], {'wander': false, 'sound': false});
    });

    test('without storage it plays from memory and schedules nothing', () {
      final store = GameStore();
      store.applyNeeds(CatId.mochi, {Need.fun: 1});
      expect(store.save.cat(CatId.mochi).needs[Need.fun], CatNeeds.initial[Need.fun] + 1);
    });
  });
}
