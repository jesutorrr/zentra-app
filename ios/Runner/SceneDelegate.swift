import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(
      scene,
      willConnectTo: session,
      options: connectionOptions
    )

    if let shortcutItem = connectionOptions.shortcutItem {
      QuickActionsBridge.shared.dispatch(shortcutItem.type)
    }
  }

  override func windowScene(
    _ windowScene: UIWindowScene,
    performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) {
    QuickActionsBridge.shared.dispatch(shortcutItem.type)
    completionHandler(true)
  }

  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    let opensPomodoro = URLContexts.contains { context in
      context.url.scheme == "com.jesutorr.appzentra" &&
        context.url.host == "pomodoro"
    }
    if opensPomodoro {
      QuickActionsBridge.shared.dispatch("PomodoroAction")
      return
    }

    super.scene(scene, openURLContexts: URLContexts)
  }
}

final class QuickActionsBridge {
  static let shared = QuickActionsBridge()

  private var channel: FlutterMethodChannel?
  private var pendingAction: String?
  private var isDartReady = false

  private init() {}

  func configure(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.zentra.app/quickactions",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "ready" else {
        result(FlutterMethodNotImplemented)
        return
      }

      self?.isDartReady = true
      result(nil)

      DispatchQueue.main.async {
        self?.deliverPending()
      }
    }
    self.channel = channel
  }

  func dispatch(_ action: String) {
    guard isDartReady, let channel else {
      pendingAction = action
      return
    }

    channel.invokeMethod(
      "quickActionTriggered",
      arguments: action
    )
  }

  private func deliverPending() {
    guard let action = pendingAction else {
      return
    }

    pendingAction = nil
    dispatch(action)
  }
}
