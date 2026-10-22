import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_pet_cat/game/cat_game_screen.dart';
import 'package:my_pet_cat/game/models/day_phase.dart';
import 'package:my_pet_cat/game/models/game_location.dart';
import 'package:my_pet_cat/game/models/cat_game_state.dart';
import 'package:my_pet_cat/game/save/game_store.dart';
import 'package:my_pet_cat/game/widgets/scene_background.dart';

void main() {
  setUp(GameStore.instance.reset);

  test('hours map to the four parts of the day', () {
    const expected = {
      0: DayPhase.night,
      4: DayPhase.night,
      5: DayPhase.morning,
      10: DayPhase.morning,
      11: DayPhase.noon,
      16: DayPhase.noon,
      17: DayPhase.evening,
      22: DayPhase.evening,
      23: DayPhase.night,
    };
    for (final MapEntry(key: hour, value: phase) in expected.entries) {
      expect(DayPhase.fromHour(hour), phase, reason: '$hour:00');
    }
  });

  testWidgets('every place is drawn for the clock, and follows it', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.7;
    addTearDown(tester.view.reset);
    var now = DateTime(2026, 10, 22, 10, 58);
    await tester.pumpWidget(MaterialApp(home: CatGameScreen(clock: () => now)));
    await tester.pump();
    final c = tester.state<CatGameScreenState>(find.byType(CatGameScreen)).controller;
    GameBackground background() => tester.widget<GameBackground>(find.byType(GameBackground));

    expect(c.dayPhase.value, DayPhase.morning);
    expect(background().phase, DayPhase.morning);

    // The clock passes 11 am: the scene turns to the hot noon within seconds.
    now = DateTime(2026, 10, 22, 11, 1);
    for (var i = 0; i < 400; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(c.dayPhase.value, DayPhase.noon);
    expect(background().phase, DayPhase.noon);

    // Every place renders at night without trouble.
    now = DateTime(2026, 10, 22, 23, 30);
    for (final location in GameLocation.values) {
      if (location != c.location) {
        c.goTo(location);
        for (var i = 0; i < 400 && c.state != CatGameState.idle; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
      }
      expect(c.location, location);
      for (var i = 0; i < 350; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(background().phase, DayPhase.night, reason: '$location');
      expect(tester.takeException(), isNull, reason: '$location');
    }
  });
}
