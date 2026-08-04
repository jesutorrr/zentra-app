import ActivityKit
import Flutter
import Foundation

final class LiveActivityBridge {
  static let shared = LiveActivityBridge()

  private var channel: FlutterMethodChannel?

  private init() {}

  func configure(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.jesutorr.zentra/live_activity",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    self.channel = channel
  }

  private func handle(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard #available(iOS 16.2, *) else {
      result(false)
      return
    }

    switch call.method {
    case "isEnabled":
      result(ActivityAuthorizationInfo().areActivitiesEnabled)
    case "startActivity":
      guard let input = ActivityInput(arguments: call.arguments) else {
        result(
          FlutterError(
            code: "INVALID_ARGS",
            message: "Missing Live Activity arguments",
            details: nil
          )
        )
        return
      }
      Task {
        do {
          let activityID = try await upsertActivity(input)
          result(activityID)
        } catch {
          result(
            FlutterError(
              code: "ACTIVITY_ERROR",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      }
    case "updateActivity":
      guard let input = ActivityInput(arguments: call.arguments) else {
        result(
          FlutterError(
            code: "INVALID_ARGS",
            message: "Missing Live Activity arguments",
            details: nil
          )
        )
        return
      }
      Task {
        await updateActivities(input)
        result(nil)
      }
    case "endActivity":
      Task {
        await endActivities()
        result(nil)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @available(iOS 16.2, *)
  private func upsertActivity(_ input: ActivityInput) async throws -> String {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      throw LiveActivityError.disabled
    }

    let content = ActivityContent(
      state: input.contentState,
      staleDate: input.timerEndTime
    )
    let existing = Activity<ZentraActivityAttributes>.activities
    if let activity = existing.first {
      await activity.update(content)
      for duplicate in existing.dropFirst() {
        await duplicate.end(dismissalPolicy: .immediate)
      }
      return activity.id
    }

    let attributes = ZentraActivityAttributes(
      activityName: input.activityName
    )
    let activity = try Activity<ZentraActivityAttributes>.request(
      attributes: attributes,
      content: content,
      pushType: nil
    )
    return activity.id
  }

  @available(iOS 16.2, *)
  private func updateActivities(_ input: ActivityInput) async {
    let content = ActivityContent(
      state: input.contentState,
      staleDate: input.timerEndTime
    )
    for activity in Activity<ZentraActivityAttributes>.activities {
      await activity.update(content)
    }
  }

  @available(iOS 16.2, *)
  private func endActivities() async {
    for activity in Activity<ZentraActivityAttributes>.activities {
      await activity.end(dismissalPolicy: .immediate)
    }
  }
}

private enum LiveActivityError: LocalizedError {
  case disabled

  var errorDescription: String? {
    switch self {
    case .disabled:
      return "Live Activities are disabled for Zentra"
    }
  }
}

private struct ActivityInput {
  let activityName: String
  let timerEndTime: Date?
  let remainingSeconds: Int
  let stageDurationSeconds: Int
  let sessionType: String
  let isPaused: Bool
  let nextLabel: String

  init?(arguments: Any?) {
    guard
      let arguments = arguments as? [String: Any],
      let activityName = arguments["activityName"] as? String,
      let remainingSeconds = arguments["remainingSeconds"] as? Int,
      let stageDurationSeconds = arguments["stageDurationSeconds"] as? Int,
      let sessionType = arguments["sessionType"] as? String,
      let isPaused = arguments["isPaused"] as? Bool,
      let nextLabel = arguments["nextLabel"] as? String
    else {
      return nil
    }

    self.activityName = activityName
    if let timestamp = arguments["endTime"] as? Double {
      timerEndTime = Date(timeIntervalSince1970: timestamp)
    } else {
      timerEndTime = nil
    }
    self.remainingSeconds = max(0, remainingSeconds)
    self.stageDurationSeconds = max(1, stageDurationSeconds)
    self.sessionType = sessionType
    self.isPaused = isPaused
    self.nextLabel = nextLabel
  }

  @available(iOS 16.2, *)
  var contentState: ZentraActivityAttributes.ContentState {
    ZentraActivityAttributes.ContentState(
      timerEndTime: timerEndTime,
      remainingSeconds: remainingSeconds,
      stageDurationSeconds: stageDurationSeconds,
      sessionType: sessionType,
      isPaused: isPaused,
      nextLabel: nextLabel
    )
  }
}
