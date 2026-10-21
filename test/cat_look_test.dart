import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_pet_cat/game/animations/cat_animations.dart';
import 'package:my_pet_cat/game/models/cat_look.dart';
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
  setUp(() => catLook.value = CatLook.fluffy);

  testWidgets('swiping the kitten switches her look', (tester) async {
    await _pumpStart(tester);
    expect(find.text('Fluffy Kitty'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pump(const Duration(seconds: 1));
    expect(catLook.value, CatLook.classic);
    expect(find.text('Classic Kitty'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
    await tester.pump(const Duration(seconds: 1));
    expect(catLook.value, CatLook.fluffy);
  });

  testWidgets('arrows step through the looks and slide the kitten', (tester) async {
    await _pumpStart(tester);
    await tester.tap(find.bySemanticsLabel('Next look'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(catLook.value, CatLook.classic);
    expect(tester.widget<PageView>(find.byType(PageView)).controller!.page, 1);

    await tester.tap(find.bySemanticsLabel('Next look'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(catLook.value, CatLook.fluffy, reason: 'wraps around');
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
