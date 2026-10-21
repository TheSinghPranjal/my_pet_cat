import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_pet_cat/game/animations/cat_animations.dart';
import 'package:my_pet_cat/game/cats/cat_profile.dart';
import 'package:my_pet_cat/game/cats/selected_cat.dart';
import 'package:my_pet_cat/game/models/cat_look.dart';
import 'package:my_pet_cat/game/save/game_store.dart';
import 'package:my_pet_cat/game/widgets/cat_character.dart';
import 'package:my_pet_cat/screens/start_screen.dart';

Future<void> _pumpStart(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.7;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: StartScreen()));
  // Kittens animate forever, so step time rather than settling.
  await tester.pump();
}

void main() {
  setUp(() {
    GameStore.instance.reset();
    catLook.value = CatLook.fluffy;
  });

  testWidgets('swiping the kitten switches the cat', (tester) async {
    await _pumpStart(tester);
    expect(find.text('Mochi · Curious explorer'), findsOneWidget);
    expect(find.text('Energy'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pump(const Duration(seconds: 1));
    expect(selectedCat.value, CatProfiles.kitty);
    expect(catLook.value, CatLook.classic);
    expect(find.text('Kitty · Sweet all-rounder'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
    await tester.pump(const Duration(seconds: 1));
    expect(catLook.value, CatLook.fluffy);
  });

  testWidgets('the new cats are in colour and can be picked right away', (tester) async {
    await _pumpStart(tester);
    await tester.tap(find.bySemanticsLabel('Next cat')); // Past Kitty.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    for (final (cat, label) in [
      (CatProfiles.biscuit, 'Biscuit · Lazy foodie'),
      (CatProfiles.luna, 'Luna · Shy night owl'),
      (CatProfiles.pepper, 'Pepper · Mischief maker'),
    ]) {
      await tester.tap(find.bySemanticsLabel('Next cat'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(label), findsOneWidget);
      expect(selectedCat.value, cat);
      expect(catLook.value, cat.look);
      expect(find.byType(ColorFiltered), findsNothing, reason: 'no silhouette');
    }
  });

  testWidgets('arrows step through every cat, wrapping around', (tester) async {
    await _pumpStart(tester);
    await tester.tap(find.bySemanticsLabel('Next cat'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(catLook.value, CatLook.classic);
    expect(tester.widget<PageView>(find.byType(PageView)).controller!.page, 1);

    // Every cat in the carousel is playable, so each step selects her.
    expect(CatProfiles.all.every((c) => GameStore.instance.save.isCatUnlocked(c.id)), isTrue);

    for (var i = 1; i < CatProfiles.all.length; i++) {
      await tester.tap(find.bySemanticsLabel('Next cat'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }
    expect(tester.widget<PageView>(find.byType(PageView)).controller!.page, 0, reason: 'wraps around');
    expect(catLook.value, CatLook.fluffy);
  });

  test('every cat has a look, a persona and eight greetings', () {
    expect(CatProfiles.all.map((c) => c.look).toSet(), hasLength(CatProfiles.all.length));
    for (final cat in CatProfiles.all) {
      expect(cat.greetings, hasLength(8), reason: cat.name);
      expect(CatProfiles.forLook(cat.look), cat);
    }
  });

  testWidgets('kittens without a fixed look follow the chosen one', (tester) async {
    await tester.pumpWidget(const CatCharacter(frame: CatFrame(), facing: 1, width: 100));
    CatPainter painter() => tester.widget<CustomPaint>(find.byType(CustomPaint)).painter! as CatPainter;
    expect(painter().look, CatLook.fluffy);
    catLook.value = CatLook.classic;
    await tester.pump();
    expect(painter().look, CatLook.classic);
  });
}
