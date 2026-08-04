import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/portable_preferences.dart';
import 'session_controller.dart';

/// Modos de tema disponibles.
enum AppThemeMode {
  system,
  light,
  dark,
}

extension AppThemeModePresentation on AppThemeMode {
  ThemeMode get flutterThemeMode {
    switch (this) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }
}

const _themeModePreferenceKey = 'app_theme_mode';

final initialThemeModeProvider = Provider<AppThemeMode>(
  (ref) => AppThemeMode.system,
);

typedef PortablePreferencesRepositoryFactory = PortablePreferencesRepository
    Function(String ownerId);

final portablePreferencesRepositoryFactoryProvider =
    Provider<PortablePreferencesRepositoryFactory?>((ref) => null);

final themeControllerProvider =
    NotifierProvider<ThemeController, AppThemeMode>(ThemeController.new);

Future<AppThemeMode> loadSavedThemeMode() async {
  final preferences = await SharedPreferences.getInstance();
  final savedMode = preferences.getString(_themeModePreferenceKey);

  return AppThemeMode.values.firstWhere(
    (mode) => mode.name == savedMode,
    orElse: () => AppThemeMode.system,
  );
}

class ThemeController extends Notifier<AppThemeMode> {
  int _loadGeneration = 0;

  @override
  AppThemeMode build() {
    final initial = ref.watch(initialThemeModeProvider);
    final ownerId = ref.watch(activeOwnerIdProvider);
    final factory = ref.watch(portablePreferencesRepositoryFactoryProvider);
    final generation = ++_loadGeneration;
    if (ownerId != null && factory != null) {
      unawaited(
        Future<void>.microtask(
          () => _loadOwnerTheme(
            ownerId,
            factory,
            generation: generation,
          ),
        ),
      );
    }
    return initial;
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (state == mode) return;

    state = mode;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModePreferenceKey, mode.name);
    final ownerId = ref.read(activeOwnerIdProvider);
    final factory = ref.read(portablePreferencesRepositoryFactoryProvider);
    if (ownerId != null && factory != null) {
      await factory(ownerId).savePortableThemeMode(mode.name);
    }
  }

  Future<void> refreshAfterSync(String ownerId) async {
    if (ref.read(activeOwnerIdProvider) != ownerId) return;
    final factory = ref.read(portablePreferencesRepositoryFactoryProvider);
    if (factory == null) return;
    await _loadOwnerTheme(
      ownerId,
      factory,
      generation: ++_loadGeneration,
    );
  }

  Future<void> _loadOwnerTheme(
    String ownerId,
    PortablePreferencesRepositoryFactory factory, {
    required int generation,
  }) async {
    final portable = await factory(ownerId).loadPortablePreferences();
    if (generation != _loadGeneration ||
        ref.read(activeOwnerIdProvider) != ownerId ||
        portable == null) {
      return;
    }
    state = AppThemeMode.values.firstWhere(
      (mode) => mode.name == portable.themeMode,
      orElse: () => AppThemeMode.system,
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModePreferenceKey, state.name);
  }
}
