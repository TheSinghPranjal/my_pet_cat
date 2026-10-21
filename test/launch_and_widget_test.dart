import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_pet_cat/game/cat_game_screen.dart';
import 'package:my_pet_cat/game/models/activity_definition.dart';
import 'package:my_pet_cat/game/models/cat_game_state.dart';
import 'package:my_pet_cat/game/models/game_location.dart';
import 'package:my_pet_cat/home_widget/pet_home_widget_service.dart';
import 'package:my_pet_cat/main.dart';
import 'package:my_pet_cat/navigation/app_launch_router.dart';
import 'package:my_pet_cat/navigation/widget_deep_link_handler.dart';
import 'package:my_pet_cat/screens/splash_screen.dart';
import 'package:my_pet_cat/screens/start_screen.dart';

const _frame = Duration(milliseconds: 16);
const _widgetLink = 'mypetcat://game/home?source=widget';

Future<void> _pumpSeconds(WidgetTester tester, double seconds) async {
  for (var t = 0.0; t < seconds; t += 0.016) {
    await tester.pump(_frame);
  }
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 2.7;
  addTearDown(tester.view.reset);
}

void main() {
  group('AppLaunchRouter', () {
    test('only the exact widget link opens the game', () {
      expect(AppLaunchRouter.parse(_widgetLink), LaunchDestination.gameHome);
      expect(AppLaunchRouter.parse(AppLaunchRouter.widgetLink.toString()), LaunchDestination.gameHome);
      for (final link in [
        null,
        '',
        'not a uri ::',
        'mypetcat://game/home',
        'mypetcat://game/home?source=ad',
        'mypetcat://game/bath?source=widget',
        'mypetcat://shop/home?source=widget',
        'https://game/home?source=widget',
      ]) {
        expect(AppLaunchRouter.parse(link), LaunchDestination.normal, reason: '$link');
      }
    });
  });

  testWidgets('widget cold start goes straight to the playable Home scene', (tester) async {
    _phone(tester);
    await tester.pumpWidget(const MyPetCatApp(initialDestination: LaunchDestination.gameHome));
    await tester.pump();
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(CatGameScreen), findsOneWidget);
    final game = tester.state<CatGameScreenState>(find.byType(CatGameScreen)).controller;
    expect(game.location, GameLocation.home);
    expect(game.state, CatGameState.idle);
    expect(find.bySemanticsLabel('Feed the cat'), findsOneWidget);
    expect(find.bySemanticsLabel('Catch mice'), findsOneWidget);

    // Interactive right away.
    await tester.tap(find.bySemanticsLabel('Feed the cat'));
    await tester.pump();
    expect(game.state, CatGameState.walkingToFood);

    // Back leads to the menu, not out of the app.
    await tester.tap(find.bySemanticsLabel('Back to menu'));
    await _pumpSeconds(tester, 0.5);
    expect(find.byType(StartScreen), findsOneWidget);
    expect(find.byType(CatGameScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('normal launch keeps the splash and menu', (tester) async {
    _phone(tester);
    await tester.pumpWidget(const MyPetCatApp());
    expect(find.byType(SplashScreen), findsOneWidget);
    await _pumpSeconds(tester, 3);
    expect(find.byType(StartScreen), findsOneWidget);
    expect(find.byType(CatGameScreen), findsNothing);
  });

  testWidgets('warm widget links open the game once and return to Home', (tester) async {
    _phone(tester);
    await tester.pumpWidget(const MyPetCatApp());
    await _pumpSeconds(tester, 0.5); // Still on the splash.
    final app = tester.state<MyPetCatAppState>(find.byType(MyPetCatApp));

    app.handleLink('mypetcat://evil/path');
    await _pumpSeconds(tester, 0.5);
    expect(find.byType(CatGameScreen), findsNothing);

    app.handleLink(_widgetLink);
    await _pumpSeconds(tester, 0.6);
    expect(find.byType(CatGameScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    // The splash timer firing later must not navigate away.
    await _pumpSeconds(tester, 3);
    expect(find.byType(CatGameScreen), findsOneWidget);

    // Repeated taps: still a single game screen.
    app.handleLink(_widgetLink);
    app.handleLink(_widgetLink);
    await _pumpSeconds(tester, 0.6);
    expect(find.byType(CatGameScreen), findsOneWidget);

    // From the Bath, a widget tap brings the open game back to Home.
    final game = tester.state<CatGameScreenState>(find.byType(CatGameScreen)).controller;
    game.goTo(GameLocation.bath);
    await _pumpSeconds(tester, 0.6);
    expect(game.location, GameLocation.bath);
    app.handleLink(_widgetLink);
    await _pumpSeconds(tester, 0.6);
    expect(game.location, GameLocation.home);
    expect(find.byType(CatGameScreen), findsOneWidget);

    // Back still reaches the menu.
    await tester.tap(find.bySemanticsLabel('Back to menu'));
    await _pumpSeconds(tester, 0.5);
    expect(find.byType(StartScreen), findsOneWidget);
  });

  group('native channels', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    test('initial link is taken from the launch channel', () async {
      const channel = MethodChannel('test/launch');
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'takeInitialLink');
        return _widgetLink;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      expect(await LaunchLinkChannel(channel: channel).takeInitialLink(), _widgetLink);
    });

    test('missing native side means a normal launch', () async {
      expect(await LaunchLinkChannel(channel: const MethodChannel('test/none')).takeInitialLink(), isNull);
    });

    test('warm links are delivered to the listener', () async {
      const channel = MethodChannel('test/launch_warm');
      final received = <String>[];
      LaunchLinkChannel(channel: channel).listen(received.add);
      await messenger.handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(const MethodCall('onLink', _widgetLink)),
        (_) {},
      );
      expect(received, [_widgetLink]);
    });

    test('widget payload is sent once on flush, with the interaction label', () async {
      const channel = MethodChannel('test/widget');
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final service = PetHomeWidgetService(channel: channel);

      await service.flush();
      expect(calls, isEmpty);

      service.record(location: GameLocation.home, completed: CatActivity.feed);
      service.record(location: GameLocation.bath); // Location change keeps the label.
      await service.flush();
      await service.flush();
      expect(calls, hasLength(1));
      final payload = calls.single.arguments as Map;
      expect(calls.single.method, 'updateWidget');
      expect(payload['schemaVersion'], 1);
      expect(payload['pose'], 'happy');
      expect(payload['location'], 'Bath');
      expect(payload['lastInteraction'], 'Yum! Thanks for dinner!');
    });
  });

  testWidgets('finishing an activity records it for the widget', (tester) async {
    _phone(tester);
    await tester.pumpWidget(const MaterialApp(home: CatGameScreen()));
    await tester.pump();
    final game = tester.state<CatGameScreenState>(find.byType(CatGameScreen)).controller;
    game.feed();
    for (var i = 0; i < 1500 && !(game.state == CatGameState.idle && game.lastCompletedActivity != null); i++) {
      await tester.pump(_frame);
    }
    expect(game.lastCompletedActivity, CatActivity.feed);
    expect(PetHomeWidgetService.instance.pending?.lastInteraction, 'Yum! Thanks for dinner!');
  });
}
