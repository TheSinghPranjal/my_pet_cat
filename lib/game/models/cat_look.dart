import 'package:flutter/foundation.dart';

import '../cats/cat_profile.dart';
import '../cats/selected_cat.dart';

/// The cats' drawing styles; each [CatProfile] has one.
enum CatLook {
  fluffy('Fluffy Kitty'),
  classic('Classic Kitty'),
  ginger('Chubby Ginger'),
  tuxedo('Tuxedo'),
  tortie('Tortoiseshell');

  const CatLook(this.label);

  final String label;
}

/// The selected cat's look, for painters and the look carousel. The
/// selected cat ([selectedCat]) is the source of truth and is what gets
/// saved; changing this picks the cat with that look.
final catLook = CatLookSetting();

class CatLookSetting extends ValueNotifier<CatLook> {
  CatLookSetting() : super(selectedCat.value.look) {
    selectedCat.addListener(() => value = selectedCat.value.look);
    addListener(() {
      if (selectedCat.value.look == value) return;
      // A locked cat's look can't be chosen; snap back to the selected cat.
      if (!selectedCat.select(CatProfiles.forLook(value))) value = selectedCat.value.look;
    });
  }

  void select(CatLook look) => value = look;
}
