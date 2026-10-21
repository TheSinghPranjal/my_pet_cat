import 'package:flutter/material.dart';

import '../game/cat_game_screen.dart';
import '../screens/fade_route.dart';
import '../screens/splash_screen.dart';
import '../screens/start_screen.dart';

/// Named page routes, so the launch router can find and replace them.
abstract final class AppRoutes {
  static const splashName = '/splash';
  static const startName = '/start';
  static const gameName = '/game';

  static Route<void> splash() =>
      fadeRoute(const SplashScreen(), settings: const RouteSettings(name: splashName));

  static Route<void> start({bool instant = false}) => fadeRoute(
        const StartScreen(),
        settings: const RouteSettings(name: startName),
        duration: instant ? Duration.zero : const Duration(milliseconds: 350),
      );

  static Route<void> game({bool instant = false}) => fadeRoute(
        const CatGameScreen(),
        settings: const RouteSettings(name: gameName),
        duration: instant ? Duration.zero : const Duration(milliseconds: 350),
      );
}

/// Remembers which named route is on top.
class TopRouteObserver extends NavigatorObserver {
  final _stack = <String?>[];

  String? get topName => _stack.isEmpty ? null : _stack.last;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _stack.add(route.settings.name);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _remove(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _remove(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _stack.lastIndexOf(oldRoute.settings.name);
    if (i >= 0) {
      _stack[i] = newRoute?.settings.name;
    } else {
      _stack.add(newRoute?.settings.name);
    }
  }

  void _remove(Route<dynamic> route) {
    final i = _stack.lastIndexOf(route.settings.name);
    if (i >= 0) _stack.removeAt(i);
  }
}
