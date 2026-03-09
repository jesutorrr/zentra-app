import Flutter
import UIKit
import flutter_local_notifications
import Intents
import ActivityKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  // Reference to the active Live Activity
  @available(iOS 16.2, *)
  static var currentActivity: Activity<ZentraActivityAttributes>?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Request notification permissions
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    
    // Initialize flutter_local_notifications
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }
    
    GeneratedPluginRegistrant.register(with: self)
    
    // Setup channels after a delay to ensure rootViewController is available
    DispatchQueue.main.async { [weak self] in
      guard let controller = self?.window?.rootViewController as? FlutterViewController else { return }
      
      // Setup Quick Actions channel
      let quickActionsChannel = FlutterMethodChannel(name: "com.zentra.app/quickactions", binaryMessenger: controller.binaryMessenger)
      quickActionsChannel.setMethodCallHandler { (call, result) in
        result(FlutterMethodNotImplemented)
      }
      
      // Setup Siri shortcuts channel
      let siriChannel = FlutterMethodChannel(name: "com.zentra.app/siri", binaryMessenger: controller.binaryMessenger)
      siriChannel.setMethodCallHandler { [weak self] (call, result) in
        self?.handleSiriCall(call: call, result: result)
      }
        
      // Setup Live Activity channel
      if #available(iOS 16.2, *) {
          let liveActivityChannel = FlutterMethodChannel(name: "com.jesutorr.zentra/live_activity", binaryMessenger: controller.binaryMessenger)
          liveActivityChannel.setMethodCallHandler { [weak self] (call, result) in
              self?.handleLiveActivity(call: call, result: result)
          }
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
  // MARK: - Live Activity Handler
  @available(iOS 16.2, *)
  private func handleLiveActivity(call: FlutterMethodCall, result: @escaping FlutterResult) {
      switch call.method {
      case "startActivity":
          startActivity(call: call, result: result)
      case "updateActivity":
          updateActivity(call: call, result: result)
      case "endActivity":
          endActivity(call: call, result: result)
      default:
          result(FlutterMethodNotImplemented)
      }
  }
    
  @available(iOS 16.2, *)
  private func startActivity(call: FlutterMethodCall, result: @escaping FlutterResult) {
      guard let args = call.arguments as? [String: Any],
            let endTime = args["endTime"] as? Double,
            let sessionType = args["sessionType"] as? String,
            let activityName = args["activityName"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
          return
      }
      
      let attributes = ZentraActivityAttributes(activityName: activityName)
      let contentState = ZentraActivityAttributes.ContentState(
          timerEndTime: endTime,
          sessionType: sessionType,
          isPaused: false,
          progress: 0.0
      )
      
      do {
          let activity = try Activity<ZentraActivityAttributes>.request(
              attributes: attributes,
              content: .init(state: contentState, staleDate: nil),
              pushType: nil
          )
          AppDelegate.currentActivity = activity
          result(activity.id)
      } catch {
          result(FlutterError(code: "ACTIVITY_ERROR", message: error.localizedDescription, details: nil))
      }
  }
    
  @available(iOS 16.2, *)
  private func updateActivity(call: FlutterMethodCall, result: @escaping FlutterResult) {
      guard let args = call.arguments as? [String: Any],
            let sessionType = args["sessionType"] as? String,
            let isPaused = args["isPaused"] as? Bool else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
          return
      }
      
      let endTime = args["endTime"] as? Double
      
      let contentState = ZentraActivityAttributes.ContentState(
          timerEndTime: endTime,
          sessionType: sessionType,
          isPaused: isPaused,
          progress: 0.0
      )
      
      Task {
          await AppDelegate.currentActivity?.update(
              ActivityContent(state: contentState, staleDate: nil)
          )
          result(nil)
      }
  }
    
  @available(iOS 16.2, *)
  private func endActivity(call: FlutterMethodCall, result: @escaping FlutterResult) {
      Task {
          await AppDelegate.currentActivity?.end(dismissalPolicy: .immediate)
          AppDelegate.currentActivity = nil
          result(nil)
      }
  }
  
  // MARK: - Quick Actions (3D Touch / Haptic Touch)
  override func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
    // Send quick action to Flutter
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "com.zentra.app/quickactions", binaryMessenger: controller.binaryMessenger)
      channel.invokeMethod("quickActionTriggered", arguments: shortcutItem.type)
    }
    completionHandler(true)
  }
  
  // MARK: - Siri Shortcuts Handlers
  private func handleSiriCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "donateShortcut":
      if let args = call.arguments as? [String: Any] {
        donateShortcut(args: args)
        result(nil)
      } else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func donateShortcut(args: [String: Any]) {
    guard let type = args["type"] as? String,
          let title = args["title"] as? String else { return }
    
    let activity = NSUserActivity(activityType: "com.zentra.app.\(type)")
    activity.title = title
    activity.isEligibleForSearch = true
    activity.isEligibleForPrediction = true
    
    if let phrase = args["phrase"] as? String {
      activity.suggestedInvocationPhrase = phrase
    }
    
    // Add user info based on type
    var userInfo: [String: Any] = ["type": type]
    if let habitId = args["habitId"] as? String {
      userInfo["habitId"] = habitId
    }
    if let activityName = args["activityName"] as? String {
      userInfo["activityName"] = activityName
    }
    activity.userInfo = userInfo
    
    activity.becomeCurrent()
  }
  
  // Handle Siri shortcut activation
  override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    if userActivity.activityType.starts(with: "com.zentra.app.") {
      let type = userActivity.activityType.replacingOccurrences(of: "com.zentra.app.", with: "")
      
      // Send to Flutter
      if let controller = window?.rootViewController as? FlutterViewController {
        let channel = FlutterMethodChannel(name: "com.zentra.app/siri", binaryMessenger: controller.binaryMessenger)
        channel.invokeMethod("shortcutActivated", arguments: type)
      }
      return true
    }
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
}
