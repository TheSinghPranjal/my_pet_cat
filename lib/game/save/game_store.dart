import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cats/cat_needs.dart';
import '../cats/cat_profile.dart';
import 'game_save.dart';

/// Loads, holds and writes the single [GameSave].
///
/// Changes go through [update]; writes are debounced so a burst of changes
/// costs one write, and [flush] writes at once (app paused). Until [load]
/// has found storage, nothing is written and no timers run, so tests and
/// unsupported platforms simply play from memory.
class GameStore extends ChangeNotifier {
  GameStore({this.debounce = const Duration(seconds: 1)});

  static final instance = GameStore();

  static const key = 'game_save';

  /// The 1.x look preference ("fluffy" or "classic").
  static const legacyLookKey = 'cat_look';

  final Duration debounce;
  GameSave _save = GameSave();
  SharedPreferences? _prefs;
  Timer? _pending;

  GameSave get save => _save;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _prefs = prefs;
      _save = decode(prefs.getString(key), legacyLook: prefs.getString(legacyLookKey));
      notifyListeners();
    } catch (_) {
      // No storage (unsupported platform): play from memory.
    }
  }

  /// Parses [raw], falling back to a fresh save when it is missing or
  /// corrupt. A fresh save adopts the 1.x look choice when there is one.
  @visibleForTesting
  static GameSave decode(String? raw, {String? legacyLook}) {
    if (raw != null) {
      try {
        return GameSave.fromJson(jsonDecode(raw));
      } catch (_) {
        // Corrupt JSON or an unexpected shape: start from defaults below.
      }
    }
    return GameSave(selectedCat: legacyLook == 'classic' ? CatId.kitty : CatId.mochi);
  }

  /// Applies [change] to the save, notifies listeners and schedules a write.
  void update(void Function(GameSave save) change) {
    change(_save);
    notifyListeners();
    if (_prefs == null) return;
    _pending?.cancel();
    _pending = Timer(debounce, flush);
  }

  void applyNeeds(CatId cat, Map<Need, double> deltas) =>
      update((save) => save.cat(cat).needs = save.cat(cat).needs.apply(deltas));

  Future<void> flush() async {
    _pending?.cancel();
    _pending = null;
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(key, jsonEncode(_save.toJson()));
    } catch (_) {
      // Storage refused the write; the next change tries again.
    }
  }

  /// Forgets everything (tests only).
  @visibleForTesting
  void reset() {
    _pending?.cancel();
    _pending = null;
    _prefs = null;
    _save = GameSave();
    notifyListeners();
  }
}
