import 'dart:async';

import 'package:flutter/services.dart';

/// Receives launch links from the native side (`my_pet_cat/launch`).
///
/// Cold start: Dart asks once for the link that launched the app
/// ([takeInitialLink]); the native side hands it over and clears it, so it
/// is processed exactly once. Warm start: the native side pushes each new
/// link through [listen]. Links that arrive before Dart has asked are held
/// natively as the initial link, so nothing is lost while Flutter starts.
class LaunchLinkChannel {
  LaunchLinkChannel({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('my_pet_cat/launch');

  final MethodChannel _channel;

  Future<String?> takeInitialLink() async {
    try {
      return await _channel
          .invokeMethod<String>('takeInitialLink')
          .timeout(const Duration(seconds: 2));
    } on MissingPluginException {
      return null; // Platforms without the native bridge (desktop, web, tests).
    } on PlatformException {
      return null;
    } on TimeoutException {
      return null;
    }
  }

  void listen(void Function(String link) onLink) {
    _channel.setMethodCallHandler((call) async {
      final link = call.arguments;
      if (call.method == 'onLink' && link is String) onLink(link);
    });
  }
}
