import ActivityKit
import SwiftUI
import WidgetKit

struct ZentraPomodoroLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: ZentraActivityAttributes.self) { context in
      ZentraLockScreenActivity(context: context)
        .activityBackgroundTint(ZentraActivityPalette.cream)
        .activitySystemActionForegroundColor(ZentraActivityPalette.deepGreen)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          HStack(spacing: 6) {
            // Mint here, not deep green: the island is drawn on black, where the
            // mint reads at 11.24:1 and the deep green would nearly vanish.
            StageIcon(sessionType: context.state.sessionType)
              .foregroundStyle(ZentraActivityPalette.mint)
            Text(stageLabel(context.state.sessionType))
              .font(.caption2.weight(.semibold))
              .foregroundStyle(ZentraActivityPalette.mint)
          }
        }
        DynamicIslandExpandedRegion(.trailing) {
          ActivityCountdown(
            state: context.state,
            font: .system(size: 28, weight: .medium, design: .rounded)
          )
        }
        DynamicIslandExpandedRegion(.bottom) {
          // The session name used to head this region. It is generic by policy,
          // so it said nothing the stage label above does not already say.
          VStack(alignment: .leading, spacing: 6) {
            ActivityProgress(state: context.state)
            Text(context.state.nextLabel)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }
      } compactLeading: {
        StageIcon(sessionType: context.state.sessionType)
          .foregroundStyle(ZentraActivityPalette.mint)
      } compactTrailing: {
        ActivityCountdown(state: context.state, font: .caption.monospacedDigit())
          .frame(maxWidth: 54)
      } minimal: {
        StageIcon(sessionType: context.state.sessionType)
          .foregroundStyle(ZentraActivityPalette.mint)
      }
      .keylineTint(ZentraActivityPalette.mint)
      .widgetURL(URL(string: "com.jesutorr.appzentra://pomodoro"))
    }
  }
}

/// The lock screen face of a focus session.
///
/// The countdown is the whole point of this surface, so it gets the size: it is
/// the one thing worth reading from across a desk. It used to share a baseline
/// with `attributes.activityName` at `.headline`, which squeezed it and truncated
/// the name to "Sesión de enf…" — and that name is deliberately generic (the
/// published privacy policy keeps user-typed session names off the lock screen),
/// so the most prominent line on the widget was spending itself to say nothing.
/// Dropping it costs no information and buys the timer its full width.
private struct ZentraLockScreenActivity: View {
  let context: ActivityViewContext<ZentraActivityAttributes>

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 8) {
        StageIcon(sessionType: context.state.sessionType)
          .font(.caption)
        Text(stageLabel(context.state.sessionType))
          .font(.caption2.weight(.semibold))
          .tracking(1.4)
          .foregroundStyle(ZentraActivityPalette.deepGreen)
        if context.state.isPaused {
          Text("EN PAUSA")
            .font(.caption2.weight(.bold))
            .tracking(1.2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
              ZentraActivityPalette.deepGreen.opacity(0.12),
              in: Capsule()
            )
            .foregroundStyle(ZentraActivityPalette.deepGreen)
        }
        Spacer(minLength: 0)
      }

      ActivityCountdown(
        state: context.state,
        font: .system(size: 46, weight: .medium, design: .rounded)
      )
      .foregroundStyle(ZentraActivityPalette.ink)

      ActivityProgress(state: context.state)

      Text(context.state.nextLabel)
        .font(.caption)
        .foregroundStyle(ZentraActivityPalette.inkSecondary)
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 18)
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
    .tint(ZentraActivityPalette.deepGreen)
  }

  private var pausedProgress: Double {
    guard state.stageDurationSeconds > 0 else { return 0 }
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
    // Deep green, not the mint that used to be here: on the cream background the
    // mint measured 1.69:1, well under the 3.0:1 an icon needs, so the glyph
    // that names the stage was the least legible thing on the widget.
    .foregroundStyle(ZentraActivityPalette.deepGreen)
    .accessibilityLabel(stageLabel(sessionType))
  }
}

/// The widget cannot reach the app's `ZentraPalette`, so the few colours it needs
/// live here. Every value is checked against the cream activity background:
/// `deepGreen` 4.80:1, `ink` 14.20:1, `inkSecondary` 6.00:1.
private enum ZentraActivityPalette {
  static let cream = Color(red: 0.965, green: 0.953, blue: 0.925)
  static let deepGreen = Color(red: 0.145, green: 0.478, blue: 0.282)
  static let ink = Color(red: 0.106, green: 0.145, blue: 0.137)
  static let inkSecondary = Color(red: 0.322, green: 0.373, blue: 0.365)
  /// Only for the Dynamic Island keyline, which is drawn on black.
  static let mint = Color(red: 0.40, green: 0.82, blue: 0.65)
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
