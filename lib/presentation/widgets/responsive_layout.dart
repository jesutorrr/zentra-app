import 'package:flutter/material.dart';
import '../design_tokens.dart';

/// Window-size classes used across Zentra's presentation layer.
///
/// The breakpoints describe available logical width, not a specific device.
/// This keeps the layout useful in iPad Split View, Stage Manager and future
/// form factors where the device name does not tell us the actual app width.
enum ZentraWindowClass {
  compact,
  medium,
  expanded,
  large,
  extraLarge,
}

abstract final class ZentraBreakpoints {
  static const double medium = 600;
  static const double expanded = 840;
  static const double large = 1200;
  static const double extraLarge = 1600;

  static ZentraWindowClass windowClassFor(double width) {
    if (width >= extraLarge) return ZentraWindowClass.extraLarge;
    if (width >= large) return ZentraWindowClass.large;
    if (width >= expanded) return ZentraWindowClass.expanded;
    if (width >= medium) return ZentraWindowClass.medium;
    return ZentraWindowClass.compact;
  }
}

extension ZentraWindowClassCapabilities on ZentraWindowClass {
  bool get isAtLeastExpanded => index >= ZentraWindowClass.expanded.index;
}

extension ZentraResponsiveContext on BuildContext {
  ZentraWindowClass get zentraWindowClass =>
      ZentraBreakpoints.windowClassFor(MediaQuery.sizeOf(this).width);
}

@immutable
class ResponsiveLayoutData {
  final BoxConstraints constraints;
  final ZentraWindowClass windowClass;

  const ResponsiveLayoutData({
    required this.constraints,
    required this.windowClass,
  });

  double get width => constraints.maxWidth;
  double get height => constraints.maxHeight;

  bool get isCompact => windowClass == ZentraWindowClass.compact;
  bool get isMedium => windowClass == ZentraWindowClass.medium;
  bool get isExpanded => windowClass.isAtLeastExpanded;
  bool get isLarge => windowClass == ZentraWindowClass.large;
  bool get isExtraLarge => windowClass == ZentraWindowClass.extraLarge;
  bool get isShort => height < 700;

  double get horizontalPagePadding {
    switch (windowClass) {
      case ZentraWindowClass.compact:
        return ZentraSpacing.standard.md;
      case ZentraWindowClass.medium:
        return ZentraSpacing.standard.lg;
      case ZentraWindowClass.expanded:
      case ZentraWindowClass.large:
      case ZentraWindowClass.extraLarge:
        return ZentraSpacing.standard.xl;
    }
  }

  double get verticalPagePadding =>
      isShort ? ZentraSpacing.standard.md : ZentraSpacing.standard.lg;
}

typedef ResponsiveLayoutWidgetBuilder = Widget Function(
  BuildContext context,
  ResponsiveLayoutData layout,
);

/// Provides a consistent, testable view of the space available to a screen.
class ResponsiveLayoutBuilder extends StatelessWidget {
  final ResponsiveLayoutWidgetBuilder builder;

  const ResponsiveLayoutBuilder({
    required this.builder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = ResponsiveLayoutData(
          constraints: constraints,
          windowClass: ZentraBreakpoints.windowClassFor(constraints.maxWidth),
        );
        return builder(context, layout);
      },
    );
  }
}

/// Centers scrollable page content and prevents cards from stretching across
/// an entire tablet or desktop-sized window.
class ResponsiveContentFrame extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  const ResponsiveContentFrame({
    required this.child,
    this.maxWidth = 720,
    this.alignment = Alignment.topCenter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
