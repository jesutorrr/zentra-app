import 'today_screen_classic.dart';

export 'today_screen_classic.dart' show ClassicTodayScreen, TodayVisualStyle;

/// Salvia is the production Today screen. The previous composition remains
/// available as [ClassicTodayScreen] while the redesign is validated.
class TodayScreen extends ClassicTodayScreen {
  const TodayScreen({super.key}) : super(visualStyle: TodayVisualStyle.salvia);
}
