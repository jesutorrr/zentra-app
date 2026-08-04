import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zentra/application/session_controller.dart';
import 'package:zentra/application/theme_provider.dart';
import 'package:zentra/domain/portable_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads every persisted theme mode', () async {
    for (final mode in AppThemeMode.values) {
      SharedPreferences.setMockInitialValues({
        'app_theme_mode': mode.name,
      });

      expect(await loadSavedThemeMode(), mode);
    }
  });

  test('invalid persisted theme falls back to system', () async {
    SharedPreferences.setMockInitialValues({
      'app_theme_mode': 'sepia',
    });

    expect(await loadSavedThemeMode(), AppThemeMode.system);
  });

  test('controller starts from override and persists changes', () async {
    final container = ProviderContainer(
      overrides: [
        initialThemeModeProvider.overrideWithValue(AppThemeMode.light),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(themeControllerProvider), AppThemeMode.light);

    await container
        .read(themeControllerProvider.notifier)
        .setThemeMode(AppThemeMode.dark);

    expect(container.read(themeControllerProvider), AppThemeMode.dark);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('app_theme_mode'), 'dark');
  });

  test('cloud owner writes and refreshes its portable theme', () async {
    const ownerId = 'a0000000-0000-4000-8000-000000000001';
    final repository = _MemoryPortablePreferencesRepository(ownerId);
    final container = ProviderContainer(
      overrides: [
        activeOwnerIdProvider.overrideWithValue(ownerId),
        initialThemeModeProvider.overrideWithValue(AppThemeMode.light),
        portablePreferencesRepositoryFactoryProvider.overrideWithValue(
          (_) => repository,
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(themeControllerProvider), AppThemeMode.light);
    await container
        .read(themeControllerProvider.notifier)
        .setThemeMode(AppThemeMode.dark);
    expect(repository.themeMode, 'dark');

    repository.themeMode = 'system';
    await container
        .read(themeControllerProvider.notifier)
        .refreshAfterSync(ownerId);
    expect(container.read(themeControllerProvider), AppThemeMode.system);
    expect(
      (await SharedPreferences.getInstance()).getString('app_theme_mode'),
      'system',
    );
  });

  testWidgets('MaterialApp reacts to theme changes', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialThemeModeProvider.overrideWithValue(AppThemeMode.light),
        ],
        child: const _ThemeHarness(),
      ),
    );

    expect(_brightness(tester), Brightness.light);

    await tester.tap(find.byKey(const ValueKey('use-dark-theme')));
    await tester.pumpAndSettle();

    expect(_brightness(tester), Brightness.dark);
  });
}

Brightness _brightness(WidgetTester tester) {
  final context = tester.element(
    find.byKey(const ValueKey('theme-probe')),
  );
  return Theme.of(context).brightness;
}

class _ThemeHarness extends ConsumerWidget {
  const _ThemeHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);

    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode.flutterThemeMode,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Column(
              children: [
                const SizedBox(key: ValueKey('theme-probe')),
                FilledButton(
                  key: const ValueKey('use-dark-theme'),
                  onPressed: () {
                    ref
                        .read(themeControllerProvider.notifier)
                        .setThemeMode(AppThemeMode.dark);
                  },
                  child: const Text('Oscuro'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MemoryPortablePreferencesRepository
    implements PortablePreferencesRepository {
  @override
  final String ownerId;
  String? themeMode;

  _MemoryPortablePreferencesRepository(this.ownerId);

  @override
  Future<PortablePreferences?> loadPortablePreferences() async {
    final mode = themeMode;
    return mode == null
        ? null
        : PortablePreferences(ownerId: ownerId, themeMode: mode);
  }

  @override
  Future<void> savePortableThemeMode(String themeMode) async {
    this.themeMode = themeMode;
  }
}
