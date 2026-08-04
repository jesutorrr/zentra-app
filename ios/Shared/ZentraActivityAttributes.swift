import ActivityKit
import Foundation

struct ZentraActivityAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    var timerEndTime: Date?
    var remainingSeconds: Int
    var stageDurationSeconds: Int
    var sessionType: String
    var isPaused: Bool
    var nextLabel: String
  }

  var activityName: String
}
