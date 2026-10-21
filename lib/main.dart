import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/cats/selected_cat.dart';
import 'game/save/game_store.dart';
import 'navigation/app_launch_router.dart';
import 'navigation/app_routes.dart';
import 'navigation/widget_deep_link_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Resolve the launch link before the first frame, so a widget launch never
  // flashes the splash or menu. The native launch screen (same paper color)
  // covers this short wait.
  final links = LaunchLinkChannel();
  final (link, _) = await (links.takeInitialLink(), GameStore.instance.load()).wait;
  selectedCat.syncFromSave();
  final destination = AppLaunchRouter.parse(link);
  runApp(MyPetCatApp(initialDestination: destination, links: links));
}

class MyPetCatApp extends StatefulWidget {
  const MyPetCatApp({super.key, this.initialDestination = LaunchDestination.normal, this.links});

  final LaunchDestination initialDestination;

  /// Source of warm-start links; null in tests and on unsupported platforms.
  final LaunchLinkChannel? links;

  @override
  State<MyPetCatApp> createState() => MyPetCatAppState();
}

class MyPetCatAppState extends State<MyPetCatApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _routes = TopRouteObserver();

  /// Writes the save right away whenever the app leaves the screen.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: GameStore.instance.flush, onPause: GameStore.instance.flush);
    widget.links?.listen(handleLink);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// Handles a link that arrives while the app is already running.
  void handleLink(String link) {
    if (AppLaunchRouter.parse(link) != LaunchDestination.gameHome) return;
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    if (_routes.topName == AppRoutes.gameName) {
      // Already playing: just head back to Home, no duplicate screen.
      widgetHomeRequests.request();
      return;
    }
    // Rebuild the stack as [start, game] so Back still leads to the menu.
    navigator.pushAndRemoveUntil(AppRoutes.start(instant: true), (_) => false);
    navigator.push(AppRoutes.game());
  }

  List<Route<dynamic>> _initialRoutes(String _) => switch (widget.initialDestination) {
        // The start screen sits underneath (never shown) so Back from the
        // game lands on the menu rather than closing the app.
        LaunchDestination.gameHome => [AppRoutes.start(instant: true), AppRoutes.game(instant: true)],
        LaunchDestination.normal => [AppRoutes.splash()],
      };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Pet Cat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF2236B5)),
      navigatorKey: _navigatorKey,
      navigatorObservers: [_routes],
      onGenerateInitialRoutes: _initialRoutes,
      onGenerateRoute: (_) => AppRoutes.splash(),
    );
  }
}
