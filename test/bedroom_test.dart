import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_pet_cat/game/cat_game_screen.dart';
import 'package:my_pet_cat/game/controllers/cat_game_controller.dart';
import 'package:my_pet_cat/game/environments/bedroom/bedroom_keys.dart';
import 'package:my_pet_cat/game/environments/girl/girl_keys.dart';
import 'package:my_pet_cat/game/environments/girl/girl_painter.dart';
import 'package:my_pet_cat/game/models/activity_definition.dart';
import 'package:my_pet_cat/game/models/cat_game_state.dart';
import 'package:my_pet_cat/game/models/game_location.dart';
import 'package:my_pet_cat/game/models/game_positions.dart';
import 'package:my_pet_cat/game/save/game_store.dart';

const _frame = Duration(milliseconds: 16);

Future<CatGameController> _bedroom(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 2.7;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: CatGameScreen()));
  await tester.pump();
  final c = tester.state<CatGameScreenState>(find.byType(CatGameScreen)).controller;
  await tester.tap(find.bySemanticsLabel('Go to Bedroom'));
  await _until(tester, () => c.state == CatGameState.idle && c.location == GameLocation.bedroom);
  return c;
}

Future<void> _until(WidgetTester tester, bool Function() done, {double maxSeconds = 40}) async {
  for (var t = 0.0; t < maxSeconds; t += 0.016) {
    if (done()) return;
    await tester.pump(_frame);
  }
  fail('Condition not met within ${maxSeconds}s');
}

GirlMood _mood(CatGameController c) => GirlMood.values[c.sceneValue(GirlKeys.mood).round()];

/// Back to rest: girl home and happy, doors shut, cable down, cat visible.
void _expectRoomAtRest(CatGameController c) {
  expect(c.sceneValue(GirlKeys.x), 0);
  expect(_mood(c), GirlMood.happy);
  expect(c.sceneValue(BedroomKeys.wardrobeDoor), 0);
  expect(c.sceneValue(BedroomKeys.cableZap), 0);
  expect(c.catHidden, isFalse);
  expect(c.catPosition, BedroomPositions.returnPosition);
  expect(c.objects, isEmpty);
  expect(c.effects, isEmpty);
}

void main() {
  setUp(GameStore.instance.reset);

  testWidgets('the bedroom has its three things on cards', (tester) async {
    await _bedroom(tester);
    for (final label in ['Hide in the wardrobe', 'Chew the cable', 'Jump on the pillow']) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('wardrobe: the cat hides, the girl searches, the cat jumps out', (tester) async {
    final c = await _bedroom(tester);
    await tester.tap(find.bySemanticsLabel('Hide in the wardrobe'));
    await _until(tester, () => c.catHidden);
    expect(c.sceneValue(BedroomKeys.wardrobeEyes), 1, reason: 'eyes peek out of the dark');

    await _until(tester, () => _mood(c) == GirlMood.searching);
    await _until(tester, () => c.sceneValue(GirlKeys.x) >= BedroomPositions.girlAtBed);
    expect(c.catHidden, isTrue, reason: 'still hidden while she looks by the bed');
    await _until(tester, () => c.sceneValue(GirlKeys.x) <= BedroomPositions.girlAtWardrobe);
    await _until(tester, () => !c.catHidden);
    expect(c.sceneValue(BedroomKeys.wardrobeDoor), 1, reason: 'she opened the door');
    await _until(tester, () => c.catPosition == BedroomPositions.catWardrobeJumpOut);
    await _until(tester, () => _mood(c) == GirlMood.laughing);

    await _until(tester, () => c.state == CatGameState.idle);
    expect(c.lastCompletedActivity, CatActivity.wardrobeHide);
    _expectRoomAtRest(c);
  });

  testWidgets('cable: a chew, a silly zap, the girl laughs, all okay', (tester) async {
    final c = await _bedroom(tester);
    c.startActivity(CatActivity.chewCable);
    await _until(tester, () => c.sceneValue(BedroomKeys.cableBite) > 0);
    expect(c.catPosition, BedroomPositions.catChewPosition);
    expect(c.pose, CatPose.eat);
    await _until(tester, () => c.effects.any((e) => e.kind == EffectKind.zap));
    expect(c.sceneValue(BedroomKeys.cableZap), 1);
    await _until(tester, () => _mood(c) == GirlMood.laughing);
    await _until(tester, () => c.pose == CatPose.happy);
    expect(c.sceneValue(BedroomKeys.cableZap), 0, reason: 'okay again');
    await _until(tester, () => c.state == CatGameState.idle);
    _expectRoomAtRest(c);
  });

  testWidgets('pillow: bouncing, the girl runs after the cat, the cat comes down', (tester) async {
    final c = await _bedroom(tester);
    c.startActivity(CatActivity.pillowJump);
    await _until(tester, () => c.catPosition == BedroomPositions.catOnPillow);
    await _until(tester, () => c.sceneValue(BedroomKeys.pillowSquish) > 0.5);
    expect(c.effects.any((e) => e.kind == EffectKind.feathers), isTrue);
    await _until(tester, () => _mood(c) == GirlMood.furious);
    await _until(tester, () => c.sceneValue(GirlKeys.gait) == GirlGait.run.index);
    await _until(tester, () => c.catPosition == BedroomPositions.catBedJumpDown);
    expect(c.pose, CatPose.innocent);
    await _until(tester, () => c.state == CatGameState.idle);
    _expectRoomAtRest(c);
  });

  testWidgets('leaving mid-hide brings the cat back out', (tester) async {
    final c = await _bedroom(tester);
    c.startActivity(CatActivity.wardrobeHide);
    await _until(tester, () => c.catHidden);
    // Backgrounding and resuming must not strand her in the wardrobe.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 3));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _until(tester, () => c.state == CatGameState.idle);
    expect(c.catHidden, isFalse);
  });
}
