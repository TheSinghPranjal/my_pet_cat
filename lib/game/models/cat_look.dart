import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The kitten's drawing styles, picked by swiping her on the start screen.
enum CatLook {
  fluffy('Fluffy Kitty'),
  classic('Classic Kitty');

  const CatLook(this.label);

  final String label;
}

/// The player's chosen look, shared by every kitten in the app.
final catLook = CatLookSetting();

/// Remembers the chosen [CatLook] between launches.
class CatLookSetting extends ValueNotifier<CatLook> {
  CatLookSetting() : super(CatLook.fluffy);

  static const _key = 'cat_look';

  Future<void> load() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(_key);
      value = CatLook.values.firstWhere((look) => look.name == saved, orElse: () => value);
    } catch (_) {
      // No storage (tests, unsupported platform): keep the default look.
    }
  }

  void select(CatLook look) {
    if (look == value) return;
    value = look;
    SharedPreferences.getInstance().then((prefs) => prefs.setString(_key, look.name)).catchError((_) => false);
  }
}
