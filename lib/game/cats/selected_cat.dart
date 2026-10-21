import 'package:flutter/foundation.dart';

import '../save/game_store.dart';
import 'cat_profile.dart';

/// The cat the player is caring for, shared across the app and saved.
final selectedCat = SelectedCat();

class SelectedCat extends ValueNotifier<CatProfile> {
  SelectedCat({GameStore? store}) : _store = store ?? GameStore.instance, super(CatProfiles.mochi);

  final GameStore _store;

  /// Picks up the saved choice; call after [GameStore.load].
  void syncFromSave() {
    final saved = CatProfiles.byId(_store.save.selectedCat);
    if (saved != null) value = saved;
  }

  /// Selects [cat] unless she is still locked. Returns whether she is now
  /// the selected cat.
  bool select(CatProfile cat) {
    if (cat == value) return true;
    if (!_store.save.isCatUnlocked(cat.id)) return false;
    value = cat;
    _store.update((save) => save.selectedCat = cat.id);
    return true;
  }
}
