import 'package:flutter/foundation.dart';

/// Where a launch should take the player.
enum LaunchDestination {
  /// Normal startup: splash, then the start screen.
  normal,

  /// Straight into the playable Home location (home-screen widget tap).
  gameHome,
}

/// Validates launch links. Only the exact widget link skips the splash and
/// start screen; anything else (unknown host, path or source) falls back to
/// the normal, safe startup.
abstract final class AppLaunchRouter {
  static const scheme = 'mypetcat';

  /// The link the home-screen widget opens. Mirrored in the native widget
  /// code (Android `PetWidgetProvider.WIDGET_URI`, iOS `PetWidget.launchURL`).
  static final widgetLink = Uri.parse('mypetcat://game/home?source=widget');

  static LaunchDestination parse(String? link) {
    if (link == null) return LaunchDestination.normal;
    final uri = Uri.tryParse(link);
    if (uri == null) return LaunchDestination.normal;
    final isWidgetHome = uri.scheme == scheme &&
        uri.host == 'game' &&
        uri.path == '/home' &&
        uri.queryParameters['source'] == 'widget';
    return isWidgetHome ? LaunchDestination.gameHome : LaunchDestination.normal;
  }
}

/// Fired when a widget link arrives while the game screen is already open,
/// so the open game returns to Home instead of a duplicate screen opening.
class WidgetHomeRequests extends ChangeNotifier {
  void request() => notifyListeners();
}

final widgetHomeRequests = WidgetHomeRequests();
