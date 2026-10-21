import 'package:flutter/services.dart';

import '../game/models/activity_definition.dart';
import '../game/models/game_location.dart';
import 'pet_widget_payload.dart';

/// Pushes [PetWidgetPayload]s to the native widget (`my_pet_cat/widget`).
///
/// Updates are recorded as they happen but only sent when the player leaves
/// the game or the app goes to the background, i.e. right when the home
/// screen becomes visible. That keeps widget reloads rare, as WidgetKit's
/// budget and Android battery guidance expect.
class PetHomeWidgetService {
  PetHomeWidgetService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('my_pet_cat/widget');

  static final instance = PetHomeWidgetService();

  final MethodChannel _channel;
  PetWidgetPayload? _pending;

  PetWidgetPayload? get pending => _pending;

  void record({required GameLocation location, CatActivity? completed}) {
    // Keep the last interaction label when only the location changes.
    final keep = completed == null ? _pending?.lastInteraction : null;
    final next = PetWidgetPayload.from(location: location, completed: completed);
    _pending = keep == null
        ? next
        : PetWidgetPayload(
            pose: _pending!.pose,
            location: next.location,
            lastInteraction: keep,
            updatedAt: next.updatedAt,
          );
  }

  Future<void> flush() async {
    final payload = _pending;
    if (payload == null) return;
    _pending = null;
    await _invoke<void>('updateWidget', payload.toMap());
  }

  /// Whether the launcher lets the app offer "Add widget" (Android 8+ with a
  /// supporting launcher). iOS never does; players add widgets themselves.
  Future<bool> canRequestPin() async => await _invoke<bool>('canRequestPin') ?? false;

  /// Asks the launcher to show its own add-widget prompt. Returns whether the
  /// prompt was requested; the player still decides.
  Future<bool> requestPin() async => await _invoke<bool>('requestPin', 'medium') ?? false;

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null; // No native widget on this platform (desktop, web, tests).
    } on PlatformException {
      return null;
    }
  }
}
