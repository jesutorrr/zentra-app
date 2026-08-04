import ActivityKit
import SwiftUI
import WidgetKit

struct ZentraPomodoroLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: ZentraActivityAttributes.self) { context in
      ZentraLockScreenActivity(context: context)
        .activityBackgroundTint(Color(red: 0.965, green: 0.953, blue: 0.925))
        .activitySystemActionForegroundColor(
          Color(red: 0.145, green: 0.478, blue: 0.282)
        )
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          StageIcon(sessionType: context.state.sessionType)
        }
        DynamicIslandExpandedRegion(.trailing) {
          ActivityCountdown(state: context.state, font: .title2)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading, spacing: 8) {
            Text(context.attributes.activityName)
              .font(.headline)
              .lineLimit(1)
            ActivityProgress(state: context.state)
            Text(context.state.nextLabel)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      } compactLeading: {
        StageIcon(sessionType: context.state.sessionType)
      } compactTrailing: {
        ActivityCountdown(state: context.state, font: .caption.monospacedDigit())
          .frame(maxWidth: 54)
      } minimal: {
        StageIcon(sessionType: context.state.sessionType)
      }
      .keylineTint(Color(red: 0.40, green: 0.82, blue: 0.65))
      .widgetURL(URL(string: "com.jesutorr.appzentra://pomodoro"))
    }
  }
}

private struct ZentraLockScreenActivity: View {
  let context: ActivityViewContext<ZentraActivityAttributes>

  var body: some View {
    HStack(spacing: 14) {
      StageIcon(sessionType: context.state.sessionType)
        .font(.title2)
        .frame(width: 42, height: 42)
        .background(
          Color(red: 0.145, green: 0.478, blue: 0.282).opacity(0.12),
          in: Circle()
        )

      VStack(alignment: .leading, spacing: 6) {
        HStack(alignment: .firstTextBaseline) {
          VStack(alignment: .leading, spacing: 2) {
            Text(stageLabel(context.state.sessionType))
              .font(.caption.weight(.semibold))
              .tracking(1.4)
              .foregroundStyle(.secondary)
            Text(context.attributes.activityName)
              .font(.headline)
              .lineLimit(1)
          }
          Spacer(minLength: 12)
          ActivityCountdown(state: context.state, font: .title.monospacedDigit())
        }
        ActivityProgress(state: context.state)
        Text(context.state.nextLabel)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .widgetURL(URL(string: "com.jesutorr.appzentra://pomodoro"))
  }
}

private struct ActivityCountdown: View {
  let state: ZentraActivityAttributes.ContentState
  let font: Font

  var body: some View {
    Group {
      if !state.isPaused, let endTime = state.timerEndTime {
        Text(timerInterval: Date.now...endTime, countsDown: true)
      } else {
        Text(format(seconds: state.remainingSeconds))
      }
    }
    .font(font)
    .monospacedDigit()
    .lineLimit(1)
  }
}

private struct ActivityProgress: View {
  let state: ZentraActivityAttributes.ContentState

  var body: some View {
    Group {
      if !state.isPaused, let endTime = state.timerEndTime {
        ProgressView(
          timerInterval: Date.now...endTime,
          countsDown: true
        )
      } else {
        ProgressView(
          value: pausedProgress,
          total: 1
        )
      }
    }
    .tint(Color(red: 0.145, green: 0.478, blue: 0.282))
  }

  private var pausedProgress: Double {
    let elapsed = state.stageDurationSeconds - state.remainingSeconds
    return min(1, max(0, Double(elapsed) / Double(state.stageDurationSeconds)))
  }
}

private struct StageIcon: View {
  let sessionType: String

  var body: some View {
    Image(
      systemName: sessionType == "work"
        ? "circle.dotted.circle"
        : "cup.and.saucer.fill"
    )
    .foregroundStyle(Color(red: 0.40, green: 0.82, blue: 0.65))
    .accessibilityLabel(stageLabel(sessionType))
  }
}

private func stageLabel(_ sessionType: String) -> String {
  switch sessionType {
  case "shortBreak":
    return "DESCANSO CORTO"
  case "longBreak":
    return "DESCANSO LARGO"
  default:
    return "ENFOQUE"
  }
}

private func format(seconds: Int) -> String {
  let safeSeconds = max(0, seconds)
  return String(
    format: "%02d:%02d",
    safeSeconds / 60,
    safeSeconds % 60
  )
}
