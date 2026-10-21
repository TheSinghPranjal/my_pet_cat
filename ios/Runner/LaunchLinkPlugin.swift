import Flutter
import UIKit
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Hands launch links to Dart (`my_pet_cat/launch`) and shares the widget
/// payload with the WidgetKit extension (`my_pet_cat/widget`).
///
/// Cold start: the scene's connection options carry the widget URL; it is kept
/// until Dart asks for it once, then cleared. Warm start: URLs arrive through
/// `scene(_:openURLContexts:)` and are pushed to Dart with `onLink`.
final class LaunchLinkPlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
  static let appGroup = "group.com.thelazybearClub.myPetCat"
  private static let scheme = "mypetcat"

  private var channel: FlutterMethodChannel?
  private var initialLink: String?
  private var dartReady = false

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = LaunchLinkPlugin()
    let channel = FlutterMethodChannel(name: "my_pet_cat/launch", binaryMessenger: registrar.messenger())
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)

    let widget = FlutterMethodChannel(name: "my_pet_cat/widget", binaryMessenger: registrar.messenger())
    widget.setMethodCallHandler { call, result in instance.handleWidget(call, result: result) }

    registrar.addApplicationDelegate(instance)
    registrar.addSceneDelegate(instance)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "takeInitialLink":
      dartReady = true
      result(initialLink)
      initialLink = nil
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @discardableResult
  private func receive(_ url: URL?) -> Bool {
    guard let url, url.scheme == LaunchLinkPlugin.scheme else { return false }
    if dartReady {
      channel?.invokeMethod("onLink", arguments: url.absoluteString)
    } else {
      initialLink = url.absoluteString
    }
    return true
  }

  // MARK: Scene lifecycle (the app uses UIScene)

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    return receive(connectionOptions?.urlContexts.first?.url)
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    return receive(URLContexts.first?.url)
  }

  // MARK: App delegate fallback (no scenes)

  func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    return receive(url)
  }

  // MARK: Widget payload

  private func handleWidget(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "updateWidget":
      if let payload = call.arguments as? [String: Any],
         let defaults = UserDefaults(suiteName: LaunchLinkPlugin.appGroup) {
        for key in ["schemaVersion", "pose", "location", "lastInteraction", "updatedAt"] {
          defaults.set(payload[key] is NSNull ? nil : payload[key], forKey: key)
        }
        // Only called when the player leaves the game, so reloads stay rare.
        if #available(iOS 14.0, *) {
          WidgetCenter.shared.reloadAllTimelines()
        }
      }
      result(nil)
    case "canRequestPin", "requestPin":
      result(false)  // iOS lets only the user add widgets.
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
