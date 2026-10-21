import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_pet_cat/game/cat_game_screen.dart';
import 'package:my_pet_cat/game/cats/cat_needs.dart';
import 'package:my_pet_cat/game/cats/cat_persona.dart';
import 'package:my_pet_cat/game/cats/cat_profile.dart';
import 'package:my_pet_cat/game/cats/reaction.dart';
import 'package:my_pet_cat/game/controllers/cat_game_controller.dart';
import 'package:my_pet_cat/game/environments/activity_scripts.dart';
import 'package:my_pet_cat/game/models/activity_definition.dart';
import 'package:my_pet_cat/game/models/cat_game_state.dart';
import 'package:my_pet_cat/game/models/game_location.dart';
import 'package:my_pet_cat/game/save/game_store.dart';
import 'package:my_pet_cat/game/scripting/activity_runner.dart';
import 'package:my_pet_cat/game/scripting/scene_state.dart';
import 'package:my_pet_cat/game/scripting/script_step.dart';

const _frame = Duration(milliseconds: 16);

Future<CatGameController> _launch(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 2.7;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: CatGameScreen()));
  await tester.pump();
  return tester.state<CatGameScreenState>(find.byType(CatGameScreen)).controller;
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() done, {double maxSeconds = 40}) async {
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

GameLocation _locationOf(CatActivity activity) =>
    GameLocation.values.firstWhere((l) => Locations.of(l).activities.any((d) => d.activity == activity));

Future<CatGameController> _launchAt(WidgetTester tester, CatActivity activity) async {
  final c = await _launch(tester);
  final location = _locationOf(activity);
  if (location != c.location) {
    c.goTo(location);
    await _pumpUntil(tester, () => c.state == CatGameState.idle);
  }
  return c;
}

CatNeeds get _mochiNeeds => GameStore.instance.save.cat(CatId.mochi).needs;

void main() {
  setUp(GameStore.instance.reset);

  group('every 1.x activity as a script', () {
    for (final activity in CatActivity.values) {
      final script = ActivityScripts.of(activity);

      testWidgets('$activity: starts only when idle, completes, returns to idle, applies needs', (tester) async {
        final c = await _launchAt(tester, activity);
        final before = _mochiNeeds;
        expect(script.needs, isNotEmpty);

        c.startActivity(activity);
        await tester.pump();
        expect(c.mode, GameMode.busy);
        expect(c.activeActivity, activity);

        // A second request (any activity, or a location change) is ignored.
        for (final other in c.locationConfig.activities) {
          c.startActivity(other.activity);
        }
        c.goTo(GameLocation.values.firstWhere((l) => l != c.location));
        expect(c.activeActivity, activity);
        expect(c.mode, GameMode.busy);
        expect(_mochiNeeds, before, reason: 'needs change only at the end');

        await _pumpUntil(tester, () => c.mode == GameMode.idle);
        expect(c.lastCompletedActivity, activity);
        expect(c.catPosition, c.locationConfig.returnPosition);
        expect(c.objects, isEmpty);
        expect(c.effects, isEmpty);
        expect(_mochiNeeds, before.apply(script.needs));
        expect(GameStore.instance.save.cat(CatId.mochi).completed, contains(activity.name));
      });

      testWidgets('$activity: survives background/resume mid-script', (tester) async {
        final c = await _launchAt(tester, activity);
        c.startActivity(activity);
        await _pumpSeconds(tester, 1.2);
        final state = c.state;
        final position = c.catPosition;

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await _pumpSeconds(tester, 8);
        expect(c.state, state, reason: 'frozen while in the background');
        expect(c.catPosition, position);

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await _pumpUntil(tester, () => c.mode == GameMode.idle);
        expect(c.lastCompletedActivity, activity);
        expect(c.objects, isEmpty);
      });

      testWidgets('$activity: disposing mid-script is safe and applies nothing', (tester) async {
        final c = await _launchAt(tester, activity);
        final before = _mochiNeeds;
        c.startActivity(activity);
        await _pumpSeconds(tester, 1.5);
        await tester.pumpWidget(const SizedBox());
        await _pumpSeconds(tester, 2);
        expect(tester.takeException(), isNull);
        expect(_mochiNeeds, before);
      });
    }
  });

  group('ActivityRunner', () {
    late SceneState scene;
    late ActivityRunner runner;

    setUp(() {
      scene = SceneState(const Offset(0.5, 0.7));
      runner = ActivityRunner(scene);
    });

    Future<void> ticks(int n) async {
      for (var i = 0; i < n; i++) {
        runner.tick(0.016);
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('player input ends the wait early; otherwise it times out and carries on', () async {
      var done = false;
      runner.run(const PlayerInput(PlayerInputKind.tap, timeout: 5)).then((ok) => done = ok);
      await ticks(10);
      expect(done, isFalse);
      runner.sendInput(PlayerInputKind.drag); // Wrong kind: still waiting.
      await ticks(2);
      expect(done, isFalse);
      runner.sendInput(PlayerInputKind.tap);
      await ticks(2);
      expect(done, isTrue);
      expect(runner.lastInputTimedOut, isFalse);

      done = false;
      runner.run(const PlayerInput(PlayerInputKind.hold, timeout: 0.1)).then((ok) => done = ok);
      await ticks(10);
      expect(done, isTrue);
      expect(runner.lastInputTimedOut, isTrue);
    });

    test('react asks the persona and shows the outcome until it ends', () async {
      runner.reactionFor = (thingId) => CatPersonas.snowball.reactionTo(thingId!);
      final finished = runner.run(const React(0.1, thingId: 'bathTime'));
      await ticks(1);
      expect(scene.reaction, ReactionOutcome.lovesIt);
      await ticks(10);
      expect(await finished, isTrue);
      expect(scene.reaction, isNull);
    });

    test('apply needs reaches the sink', () async {
      final received = <Map<Need, double>>[];
      runner.onNeeds = received.add;
      expect(await runner.run(const ApplyNeeds({Need.fun: 5})), isTrue);
      expect(received, [
        {Need.fun: 5},
      ]);
    });

    test('restart cancels every running step, including parallel branches', () async {
      final result = runner.run(
        const Sequence([
          Spawn('ball', ObjectKind.yarn, Offset(0.2, 0.7)),
          Parallel([Wait(1), MoveProp('ball', Offset(0.8, 0.7), 2)]),
          ApplyNeeds({Need.fun: 5}),
        ]),
      );
      var needsApplied = false;
      runner.onNeeds = (_) => needsApplied = true;
      await ticks(5);
      runner.restart();
      expect(await result, isFalse);
      await ticks(200);
      expect(needsApplied, isFalse);
    });

    test('a step that throws cancels its script instead of breaking the clock', () async {
      final errors = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = previous);

      final result = runner.run(
        Sequence([
          const Spawn('ball', ObjectKind.yarn, Offset(0.2, 0.7)),
          PropAnim('ball', 'boom', 1, (_, _, _) => throw StateError('boom')),
        ]),
      );
      await ticks(2);
      expect(await result, isFalse);
      expect(errors, hasLength(1));

      // The clock still runs other steps.
      final next = runner.run(const Wait(0.01));
      await ticks(2);
      expect(await next, isTrue);
    });
  });
}
