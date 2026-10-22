import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_pet_cat/game/cat_game_screen.dart';
import 'package:my_pet_cat/game/controllers/cat_game_controller.dart';
import 'package:my_pet_cat/game/environments/girl/girl_keys.dart';
import 'package:my_pet_cat/game/environments/girl/girl_painter.dart';
import 'package:my_pet_cat/game/environments/living_room/living_room_keys.dart';
import 'package:my_pet_cat/game/environments/park/park_keys.dart';
import 'package:my_pet_cat/game/models/activity_definition.dart';
import 'package:my_pet_cat/game/models/cat_game_state.dart';
import 'package:my_pet_cat/game/models/game_location.dart';
import 'package:my_pet_cat/game/models/game_positions.dart';
import 'package:my_pet_cat/game/save/game_store.dart';

const _frame = Duration(milliseconds: 16);

Future<CatGameController> _at(WidgetTester tester, GameLocation location) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 2.7;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: CatGameScreen()));
  await tester.pump();
  final c = tester.state<CatGameScreenState>(find.byType(CatGameScreen)).controller;
  c.goTo(location);
  await _until(tester, () => c.state == CatGameState.idle && c.location == location);
  return c;
}

Future<void> _until(WidgetTester tester, bool Function() done, {double maxSeconds = 40}) async {
  for (var t = 0.0; t < maxSeconds; t += 0.016) {
    if (done()) return;
    await tester.pump(_frame);
  }
  fail('Condition not met within ${maxSeconds}s');
}

void _expectClean(CatGameController c) {
  expect(c.catHidden, isFalse);
  expect(c.objects, isEmpty);
  expect(c.effects, isEmpty);
  expect(c.sceneValue(GirlKeys.mood), 0, reason: 'the girl is happy again');
  expect(c.catPosition, c.locationConfig.returnPosition);
}

void main() {
  setUp(GameStore.instance.reset);

  testWidgets('both new places are in the navigation with their things', (tester) async {
    await _at(tester, GameLocation.home);
    for (final label in ['Go to Living', 'Go to Park']) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    await tester.tap(find.bySemanticsLabel('Go to Living'));
    await tester.pump();
    final c = tester.state<CatGameScreenState>(find.byType(CatGameScreen)).controller;
    await _until(tester, () => c.state == CatGameState.idle);
    for (final label in ['Catch the fish', 'Purr for her', 'Look out the window']) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('fish bowl: paw in the water, the fish gets away, a wet shake', (tester) async {
    final c = await _at(tester, GameLocation.livingRoom);
    c.startActivity(CatActivity.fishBowl);
    await _until(tester, () => c.catPosition == LivingRoomPositions.catAtBowl);
    await _until(tester, () => c.sceneValue(LivingRoomKeys.fishSplash) > 0.5);
    await _until(tester, () => c.sceneValue(LivingRoomKeys.fishDodge).abs() > 0.5);
    await _until(tester, () => c.pose == CatPose.shake);
    expect(c.effects.any((e) => e.kind == EffectKind.droplets), isTrue);
    await _until(tester, () => c.state == CatGameState.idle);
    _expectClean(c);
  });

  testWidgets('purr: the cat rubs back and forth against the girl', (tester) async {
    final c = await _at(tester, GameLocation.livingRoom);
    c.startActivity(CatActivity.purr);
    await _until(tester, () => c.sceneValue(GirlKeys.mood) == GirlMood.adoring.index);
    expect(c.effects.any((e) => e.kind == EffectKind.purr), isTrue);
    await _until(tester, () => c.catPosition == LivingRoomPositions.purrRight);
    await _until(tester, () => c.catPosition == LivingRoomPositions.purrLeft);
    await _until(tester, () => c.state == CatGameState.idle);
    _expectClean(c);
  });

  testWidgets('window: a bird scares her behind the curtain, then she comes back', (tester) async {
    final c = await _at(tester, GameLocation.livingRoom);
    c.startActivity(CatActivity.windowWatch);
    await _until(tester, () => c.catPosition == LivingRoomPositions.catOnSill);
    await _until(tester, () => c.objectOf(ObjectKind.bird) != null);
    await _until(tester, () => c.catHidden);
    expect(c.sceneValue(LivingRoomKeys.curtainLump), 1);
    await _until(tester, () => c.objectOf(ObjectKind.bird) == null);
    await _until(tester, () => c.sceneValue(LivingRoomKeys.curtainPeek) == 1);
    await _until(tester, () => !c.catHidden);
    await _until(tester, () => c.state == CatGameState.idle);
    _expectClean(c);
  });

  testWidgets('ducks: a quack makes the cat jump back; the duck swims off', (tester) async {
    final c = await _at(tester, GameLocation.park);
    c.startActivity(CatActivity.duckPond);
    await _until(tester, () => c.effects.any((e) => e.kind == EffectKind.quack));
    await _until(tester, () => c.catPosition == ParkPositions.catStartled);
    final duck = c.objectOf(ObjectKind.duck)!;
    await _until(tester, () => c.objectOf(ObjectKind.duck) == null);
    expect(duck.position, ParkPositions.duckExit, reason: 'swam away safely');
    await _until(tester, () => c.state == CatGameState.idle);
    _expectClean(c);
  });

  testWidgets('leaves: a leap into the pile, which settles back', (tester) async {
    final c = await _at(tester, GameLocation.park);
    c.startActivity(CatActivity.leafPile);
    await _until(tester, () => c.catPosition == ParkPositions.catInLeaves);
    await _until(tester, () => c.sceneValue(ParkKeys.leafScatter) == 1);
    expect(c.effects.any((e) => e.kind == EffectKind.leafBurst), isTrue);
    await _until(tester, () => c.state == CatGameState.idle);
    expect(c.sceneValue(ParkKeys.leafScatter), 0);
    _expectClean(c);
  });

  testWidgets('pigeon: the cat sneaks up and the pigeon flies off', (tester) async {
    final c = await _at(tester, GameLocation.park);
    c.startActivity(CatActivity.benchPigeon);
    await tester.pump();
    final pigeon = c.objectOf(ObjectKind.pigeon)!;
    expect(pigeon.position, ParkPositions.pigeonOnBench);
    await _until(tester, () => c.catPosition == ParkPositions.catOnBench);
    await _until(tester, () => c.objectOf(ObjectKind.pigeon) == null);
    expect(pigeon.position, ParkPositions.pigeonExit);
    await _until(tester, () => c.state == CatGameState.idle);
    _expectClean(c);
  });
}
