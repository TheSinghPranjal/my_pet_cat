import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_pet_cat/game/cat_game_screen.dart';
import 'package:my_pet_cat/game/controllers/cat_game_controller.dart';
import 'package:my_pet_cat/game/models/activity_definition.dart';
import 'package:my_pet_cat/game/models/cat_game_state.dart';
import 'package:my_pet_cat/game/models/game_location.dart';
import 'package:my_pet_cat/game/models/game_positions.dart';
import 'package:my_pet_cat/main.dart';

const _frame = Duration(milliseconds: 16);

Future<CatGameController> _launch(WidgetTester tester, {Size size = const Size(1080, 1920)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 2.7;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MyPetCatApp());
  await tester.pump();
  return tester.state<CatGameScreenState>(find.byType(CatGameScreen)).controller;
}

/// Pumps frame by frame (the game clock clamps big jumps) until [done].
Future<void> _pumpUntil(WidgetTester tester, bool Function() done, {double maxSeconds = 25}) async {
  for (var t = 0.0; t < maxSeconds; t += 0.016) {
    if (done()) return;
    await tester.pump(_frame);
  }
  fail('Condition not met within ${maxSeconds}s');
}

Future<void> _pumpSeconds(WidgetTester tester, double seconds) async {
  for (var t = 0.0; t < seconds; t += 0.016) {
    await tester.pump(_frame);
  }
}

Future<void> _goTo(WidgetTester tester, CatGameController c, GameLocation location) async {
  c.goTo(location);
  await _pumpUntil(tester, () => c.state == CatGameState.idle);
  expect(c.location, location);
  expect(c.catPosition, Locations.of(location).startPosition);
}

/// Runs [activity] to completion and checks it ends cleanly.
Future<void> _runToEnd(WidgetTester tester, CatGameController c, CatActivity activity) async {
  c.startActivity(activity);
  await tester.pump();
  expect(c.isBusy, isTrue, reason: '$activity should start');
  await _pumpUntil(tester, () => c.state == CatGameState.idle);
  expect(c.catPosition, c.locationConfig.returnPosition, reason: '$activity return');
  expect(c.objects, isEmpty, reason: '$activity leftovers');
  expect(c.effects, isEmpty, reason: '$activity effects');
  expect(c.tubFoam, 0);
  expect(c.pose, isNot(CatPose.climb));
}

void main() {
  testWidgets('launches at home with its three actions and the navigation', (tester) async {
    final c = await _launch(tester);
    expect(c.state, CatGameState.idle);
    expect(c.location, GameLocation.home);
    for (final label in ['Feed the cat', 'Play with the cat', 'Catch mice', 'Go to Home', 'Go to Bathroom', 'Go to Garden']) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('feed runs the full sequence and ignores extra taps', (tester) async {
    final c = await _launch(tester);
    await _pumpSeconds(tester, 6); // Wander away from the start spot first.

    await tester.tap(find.bySemanticsLabel('Feed the cat'));
    await tester.pump();
    expect(c.state, CatGameState.walkingToFood);
    expect(c.bowl!.position, HomePositions.bowlPosition);

    await tester.tap(find.bySemanticsLabel('Feed the cat'));
    await tester.tap(find.bySemanticsLabel('Play with the cat'));
    await tester.tap(find.bySemanticsLabel('Go to Garden'));
    await tester.pump();
    expect(c.yarn, isNull);
    expect(c.location, GameLocation.home);

    await _pumpUntil(tester, () => c.state == CatGameState.eating);
    expect(c.catPosition, HomePositions.feedingPosition);
    expect(c.facing, -1);
    c.play();
    c.goTo(GameLocation.bath);
    expect(c.state, CatGameState.eating);

    await _pumpUntil(tester, () => c.state == CatGameState.returningFromFood);
    expect(c.bowl, isNull);
    await _pumpUntil(tester, () => c.state == CatGameState.idle);
    expect(c.catPosition, HomePositions.returnPosition);
  });

  testWidgets('play follows the fixed yarn path and cleans up', (tester) async {
    final c = await _launch(tester);
    c.play();
    await tester.pump();
    expect(c.yarn!.position, HomePositions.yarnStartPosition);
    await _pumpUntil(tester, () => c.state == CatGameState.playing);
    expect(c.catPosition, HomePositions.playPosition);
    await _pumpUntil(tester, () => c.pose == CatPose.happy);
    expect(c.yarn!.position, HomePositions.yarnEndPosition);
    expect(c.catPosition, HomePositions.chasePosition);
    await _pumpUntil(tester, () => c.state == CatGameState.idle);
    expect(c.yarn, isNull);
    expect(c.catPosition, HomePositions.returnPosition);
  });

  testWidgets('catch mice: mouse follows its waypoints and escapes', (tester) async {
    final c = await _launch(tester);
    await tester.tap(find.bySemanticsLabel('Catch mice'));
    await tester.pump();
    expect(c.state, CatGameState.catchingMouse);
    final mouse = c.objectOf(ObjectKind.mouse)!;
    expect(mouse.position, HomePositions.mouseSpawnPosition);

    await _pumpUntil(tester, () => c.catPosition == HomePositions.catMouseApproachPosition);
    await _pumpUntil(tester, () => mouse.position == HomePositions.mouseWaypointC);
    await _pumpUntil(tester, () => c.pose == CatPose.surprised);
    expect(c.catPosition, HomePositions.catMousePounceTarget);
    expect(mouse.position, HomePositions.mouseFinalPosition);
    await _pumpUntil(tester, () => c.state == CatGameState.idle);
    expect(c.objects, isEmpty);
    expect(c.catPosition, HomePositions.catMouseReturnPosition);
  });

  testWidgets('every activity in every location completes, twice, without drift', (tester) async {
    final c = await _launch(tester);
    for (final location in [GameLocation.home, GameLocation.bath, GameLocation.outdoors]) {
      if (location != c.location) await _goTo(tester, c, location);
      for (final def in Locations.of(location).activities) {
        await _runToEnd(tester, c, def.activity);
        await _runToEnd(tester, c, def.activity);
      }
    }
  });

  testWidgets('activities from another location are ignored', (tester) async {
    final c = await _launch(tester);
    c.startActivity(CatActivity.bathTime);
    c.startActivity(CatActivity.climbTree);
    expect(c.state, CatGameState.idle);
  });

  testWidgets('bath time puts the cat in the tub with foam', (tester) async {
    final c = await _launch(tester);
    await _goTo(tester, c, GameLocation.bath);
    await tester.tap(find.bySemanticsLabel('Bath time'));
    await tester.pump();
    expect(c.state, CatGameState.walkingToBath);
    await _pumpUntil(tester, () => c.pose == CatPose.relax);
    expect(c.catPosition, BathPositions.catBathPosition);
    expect(c.tubFoam, 1);
    expect(c.effects.any((e) => e.kind == EffectKind.bubbles), isTrue);
    await _pumpUntil(tester, () => c.state == CatGameState.idle);
  });

  testWidgets('climb tree visits the fixed branches', (tester) async {
    final c = await _launch(tester);
    await _goTo(tester, c, GameLocation.outdoors);
    c.startActivity(CatActivity.climbTree);
    await _pumpUntil(tester, () => c.catPosition == OutdoorPositions.treeLowBranchPosition);
    await _pumpUntil(tester, () => c.catPosition == OutdoorPositions.treeHighBranchPosition);
    await _pumpUntil(tester, () => c.state == CatGameState.idle);
    expect(c.catPosition, OutdoorPositions.treeClimbReturnPosition);
  });

  testWidgets('bird and butterfly fly away safely', (tester) async {
    final c = await _launch(tester);
    await _goTo(tester, c, GameLocation.outdoors);
    c.startActivity(CatActivity.catchBird);
    await tester.pump();
    final bird = c.objectOf(ObjectKind.bird)!;
    await _pumpUntil(tester, () => c.objectOf(ObjectKind.bird) == null);
    expect(bird.position, OutdoorPositions.birdExitPosition);
    await _pumpUntil(tester, () => c.state == CatGameState.idle);

    c.startActivity(CatActivity.chaseButterflies);
    await tester.pump();
    final butterfly = c.objectOf(ObjectKind.butterfly)!;
    await _pumpUntil(tester, () => c.objectOf(ObjectKind.butterfly) == null);
    expect(butterfly.position, OutdoorPositions.butterflyExitPosition);
    await _pumpUntil(tester, () => c.state == CatGameState.idle);
  });

  testWidgets('switching location fades and lands on the start spot', (tester) async {
    final c = await _launch(tester);
    await _pumpSeconds(tester, 6);
    await tester.tap(find.bySemanticsLabel('Go to Bathroom'));
    await tester.pump();
    expect(c.state, CatGameState.changingLocation);
    await _pumpSeconds(tester, 0.1);
    expect(c.sceneOpacity.value, lessThan(1));
    await _pumpUntil(tester, () => c.state == CatGameState.idle);
    expect(c.location, GameLocation.bath);
    expect(c.sceneOpacity.value, 1);
    expect(find.bySemanticsLabel('Bath time'), findsOneWidget);
    expect(find.bySemanticsLabel('Feed the cat'), findsNothing);
  });

  test('start and idle positions are inside each walk area', () {
    for (final location in GameLocation.values) {
      final config = Locations.of(location);
      for (final p in config.idlePositions) {
        expect(config.walkArea.contains(p), isTrue, reason: '$location $p');
      }
    }
  });

  testWidgets('backgrounding freezes the sequence, resuming finishes it', (tester) async {
    final c = await _launch(tester);
    c.feed();
    await _pumpUntil(tester, () => c.state == CatGameState.eating);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await _pumpSeconds(tester, 10);
    expect(c.state, CatGameState.eating);
    expect(c.bowl, isNotNull);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _pumpUntil(tester, () => c.state == CatGameState.idle);
    expect(c.bowl, isNull);
  });

  testWidgets('works on a short wide screen too', (tester) async {
    final c = await _launch(tester, size: const Size(1200, 1600));
    await _goTo(tester, c, GameLocation.outdoors);
    await _runToEnd(tester, c, CatActivity.chaseButterflies);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing mid-animation is safe', (tester) async {
    final c = await _launch(tester);
    c.feed();
    await _pumpSeconds(tester, 1);
    await tester.pumpWidget(const SizedBox());
    await _pumpSeconds(tester, 1);
    expect(tester.takeException(), isNull);
  });
}
