import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_pet_cat/game/cat_game_screen.dart';
import 'package:my_pet_cat/game/controllers/cat_game_controller.dart';
import 'package:my_pet_cat/game/models/cat_game_state.dart';
import 'package:my_pet_cat/game/models/game_positions.dart';
import 'package:my_pet_cat/main.dart';

const _frame = Duration(milliseconds: 16);

Future<CatGameController> _launch(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 2.7;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MyPetCatApp());
  await tester.pump();
  return tester.state<CatGameScreenState>(find.byType(CatGameScreen)).controller;
}

/// Pumps frame by frame (the game clock clamps big jumps) until [done].
Future<void> _pumpUntil(WidgetTester tester, bool Function() done, {double maxSeconds = 20}) async {
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

void main() {
  testWidgets('launches idle with both buttons available', (tester) async {
    final controller = await _launch(tester);
    expect(controller.state, CatGameState.idle);
    expect(find.bySemanticsLabel('Feed the cat'), findsOneWidget);
    expect(find.bySemanticsLabel('Play with the cat'), findsOneWidget);
    expect(controller.bowl, isNull);
    expect(controller.yarn, isNull);
  });

  testWidgets('feed runs the full sequence and ignores extra taps', (tester) async {
    final controller = await _launch(tester);
    // Let the cat wander off its spot first so it starts from elsewhere.
    await _pumpSeconds(tester, 6);

    await tester.tap(find.bySemanticsLabel('Feed the cat'));
    await tester.pump();
    expect(controller.state, CatGameState.walkingToFood);
    expect(controller.bowl!.position, GamePositions.bowlPosition);

    await tester.tap(find.bySemanticsLabel('Feed the cat'));
    await tester.tap(find.bySemanticsLabel('Play with the cat'));
    await tester.pump();
    expect(controller.yarn, isNull);

    await _pumpUntil(tester, () => controller.state == CatGameState.eating);
    expect(controller.catPosition, GamePositions.feedingPosition);
    expect(controller.facing, -1);

    controller.play(); // Rejected while eating.
    expect(controller.state, CatGameState.eating);

    await _pumpUntil(tester, () => controller.state == CatGameState.returningFromFood);
    expect(controller.bowl, isNull);
    await _pumpUntil(tester, () => controller.state == CatGameState.idle);
    expect(controller.catPosition, GamePositions.returnPosition);
  });

  testWidgets('play follows the fixed yarn path and cleans up', (tester) async {
    final controller = await _launch(tester);
    controller.play();
    await tester.pump();
    expect(controller.state, CatGameState.walkingToToy);
    expect(controller.yarn!.position, GamePositions.yarnStartPosition);

    controller.feed(); // Rejected while playing.
    expect(controller.bowl, isNull);

    await _pumpUntil(tester, () => controller.state == CatGameState.playing);
    expect(controller.catPosition, GamePositions.playPosition);
    expect(controller.facing, 1);

    await _pumpUntil(tester, () => controller.pose == CatPose.happy);
    expect(controller.yarn!.position, GamePositions.yarnEndPosition);
    expect(controller.catPosition, GamePositions.chasePosition);

    await _pumpUntil(tester, () => controller.state == CatGameState.idle);
    expect(controller.yarn, isNull);
    expect(controller.catPosition, GamePositions.returnPosition);
  });

  testWidgets('repeated interactions never drift', (tester) async {
    final controller = await _launch(tester);
    for (var i = 0; i < 3; i++) {
      controller.feed();
      await _pumpUntil(tester, () => controller.state == CatGameState.eating);
      expect(controller.catPosition, GamePositions.feedingPosition);
      await _pumpUntil(tester, () => controller.state == CatGameState.idle);
      expect(controller.catPosition, GamePositions.returnPosition);

      controller.play();
      await _pumpUntil(tester, () => controller.state == CatGameState.playing);
      expect(controller.catPosition, GamePositions.playPosition);
      await _pumpUntil(tester, () => controller.state == CatGameState.idle);
      expect(controller.catPosition, GamePositions.returnPosition);
      expect(controller.yarn, isNull);
      expect(controller.bowl, isNull);
    }
  });

  testWidgets('backgrounding freezes the sequence, resuming finishes it', (tester) async {
    final controller = await _launch(tester);
    controller.feed();
    await _pumpUntil(tester, () => controller.state == CatGameState.eating);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await _pumpSeconds(tester, 10);
    expect(controller.state, CatGameState.eating);
    expect(controller.bowl, isNotNull);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _pumpUntil(tester, () => controller.state == CatGameState.idle);
    expect(controller.bowl, isNull);
  });

  testWidgets('home cancels an interaction and leaves no props behind', (tester) async {
    final controller = await _launch(tester);
    controller.play();
    await _pumpUntil(tester, () => controller.state == CatGameState.playing);

    await tester.tap(find.bySemanticsLabel('Call kitty home'));
    await tester.pump();
    expect(controller.state, CatGameState.idle);
    await _pumpSeconds(tester, 1);
    expect(controller.yarn, isNull);
    await _pumpUntil(tester, () => controller.catPosition == GamePositions.returnPosition);

    // A new interaction works right away.
    controller.feed();
    await _pumpUntil(tester, () => controller.state == CatGameState.eating);
    expect(controller.catPosition, GamePositions.feedingPosition);
  });

  testWidgets('disposing mid-animation is safe', (tester) async {
    final controller = await _launch(tester);
    controller.feed();
    await _pumpSeconds(tester, 1);
    await tester.pumpWidget(const SizedBox());
    await _pumpSeconds(tester, 1);
    expect(tester.takeException(), isNull);
  });
}
