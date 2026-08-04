const Set<String> portableThemeModes = {'system', 'light', 'dark'};

class PortablePreferences {
  final String ownerId;
  final String themeMode;

  const PortablePreferences({
    required this.ownerId,
    required this.themeMode,
  })  : assert(ownerId != ''),
        assert(
          themeMode == 'system' || themeMode == 'light' || themeMode == 'dark',
        );
}

abstract interface class PortablePreferencesRepository {
  String get ownerId;

  Future<PortablePreferences?> loadPortablePreferences();

  Future<void> savePortableThemeMode(String themeMode);
}
