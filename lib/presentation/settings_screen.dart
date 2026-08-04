import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter/services.dart';

import '../application/pomodoro_provider.dart';
import '../application/session_controller.dart';
import '../application/theme_provider.dart';
import '../infrastructure/notification_service.dart';
import '../infrastructure/app_logger.dart';
import 'utils/feedback_utils.dart';
import 'utils/dialogs.dart';
import 'utils/backup_passphrase_dialog.dart';
import 'about_screen.dart';
import 'design_tokens.dart';
import 'widgets/ambient_background.dart';
import 'widgets/responsive_layout.dart';

/// Pantalla de configuración con Apariencia, Notificaciones y más
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        centerTitle: false,
      ),
      body: ResponsiveContentFrame(
        child: ZentraAmbientBackground(
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.all(20),
            children: [
              const _SectionHeader('Apariencia'),
              const SizedBox(height: 10),
              _ThemeSelector(isDark: isDark),
              const SizedBox(height: 24),
              const _SectionHeader('Notificaciones'),
              const SizedBox(height: 10),
              _NotificationsCard(isDark: isDark),
              const SizedBox(height: 24),
              const _SectionHeader('Datos'),
              const SizedBox(height: 10),
              _DataCard(isDark: isDark),
              const _CloudSyncSection(),
              const SizedBox(height: 24),
              const _SectionHeader('Zentra'),
              const SizedBox(height: 10),
              _AboutCard(isDark: isDark),
              const SizedBox(height: 24),
              if (kDebugMode) ...[
                const _SectionHeader('Diagnóstico'),
                const SizedBox(height: 10),
                _DeveloperCard(isDark: isDark),
                const SizedBox(height: 24),
              ],
              _LogoutCard(isDark: isDark),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _CloudSyncSection extends StatelessWidget {
  const _CloudSyncSection();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const _SectionHeader('Cuenta en línea'),
        const SizedBox(height: 10),
        Card(
          key: const ValueKey('settings-cloud-paused'),
          elevation: 0,
          color: context.zentraPalette.functionalSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.primary.withValues(alpha: 0.22),
            ),
          ),
          child: ListTile(
            leading: _SettingIcon(
              Icons.cloud_off_outlined,
              colorScheme.primary,
            ),
            title: const Text('Cuenta y sincronización en la nube'),
            subtitle: const Text(
              'Volverán cuando Zentra local esté completa. '
              'Tu espacio permanece en este dispositivo.',
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Selector de tema compacto
class _ThemeSelector extends riverpod.ConsumerWidget {
  final bool isDark;

  const _ThemeSelector({required this.isDark});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeControllerProvider);
    final themeController = ref.read(themeControllerProvider.notifier);

    return Card(
      elevation: 0,
      color: context.zentraPalette.functionalSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _ThemeOption(
              icon: Icons.brightness_auto_rounded,
              label: 'Auto',
              isSelected: themeMode == AppThemeMode.system,
              onTap: () => themeController.setThemeMode(AppThemeMode.system),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _ThemeOption(
              icon: Icons.light_mode_rounded,
              label: 'Claro',
              isSelected: themeMode == AppThemeMode.light,
              onTap: () => themeController.setThemeMode(AppThemeMode.light),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _ThemeOption(
              icon: Icons.dark_mode_rounded,
              label: 'Oscuro',
              isSelected: themeMode == AppThemeMode.dark,
              onTap: () => themeController.setThemeMode(AppThemeMode.dark),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? null : context.zentraPalette.functionalSurface,
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withValues(
                        alpha: isDark ? 0.32 : 0.18,
                      ),
                      context.zentraPalette.water.withValues(
                        alpha: isDark ? 0.14 : 0.07,
                      ),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: isDark ? 0.3 : 0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected && isDark
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 16,
                      spreadRadius: -5,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card de notificaciones
class _NotificationsCard extends riverpod.ConsumerStatefulWidget {
  final bool isDark;

  const _NotificationsCard({required this.isDark});

  @override
  riverpod.ConsumerState<_NotificationsCard> createState() =>
      _NotificationsCardState();
}

class _NotificationsCardState
    extends riverpod.ConsumerState<_NotificationsCard> {
  final NotificationService _notificationService = NotificationService();
  final SoundService _soundService = SoundService();
  bool _morningEnabled = false;
  bool _eveningEnabled = false;
  bool _pomodoroNotifications = true;
  bool _soundsEnabled = false;
  bool _canScheduleExactAlarms = true;
  int _morningHour = 9;
  int _morningMinute = 0;
  int _eveningHour = 19;
  int _eveningMinute = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabledInSystem =
        await _notificationService.isSystemNotificationPermissionGranted();
    final dailySettings = await _notificationService.getDailyReminderSettings();
    final pomodoroEnabled =
        await _notificationService.arePomodoroNotificationsEnabled();
    final canScheduleExact =
        await _notificationService.canScheduleExactAlarms();
    await _soundService.initialize();

    if (mounted) {
      setState(() {
        _morningEnabled = dailySettings.morningEnabled && enabledInSystem;
        _eveningEnabled = dailySettings.eveningEnabled && enabledInSystem;
        _pomodoroNotifications = pomodoroEnabled;
        _soundsEnabled = _soundService.soundsEnabled;
        _canScheduleExactAlarms = canScheduleExact;
        _morningHour = dailySettings.morningHour;
        _morningMinute = dailySettings.morningMinute;
        _eveningHour = dailySettings.eveningHour;
        _eveningMinute = dailySettings.eveningMinute;
        _isLoading = false;
      });
    }
  }

  Future<bool> _ensureNotificationPermission() async {
    final alreadyGranted =
        await _notificationService.isSystemNotificationPermissionGranted();
    final granted = alreadyGranted ||
        await _notificationService.requestNotificationPermission();
    if (granted || !mounted) return granted;
    showErrorSnackbar(
      context,
      'Activa las notificaciones en los ajustes del sistema para usar recordatorios.',
    );
    return false;
  }

  Future<void> _saveDailyReminderSettings() {
    return _notificationService.setDailyReminderSettings(
      DailyReminderSettings(
        morningEnabled: _morningEnabled,
        morningHour: _morningHour,
        morningMinute: _morningMinute,
        eveningEnabled: _eveningEnabled,
        eveningHour: _eveningHour,
        eveningMinute: _eveningMinute,
      ),
    );
  }

  Future<void> _toggleMorningReminder(bool value) async {
    if (value && !await _ensureNotificationPermission()) return;
    if (!mounted) return;
    setState(() => _morningEnabled = value);
    await _saveDailyReminderSettings();
  }

  Future<void> _toggleEveningReminder(bool value) async {
    if (value && !await _ensureNotificationPermission()) return;
    if (!mounted) return;
    setState(() => _eveningEnabled = value);
    await _saveDailyReminderSettings();
  }

  Future<void> _togglePomodoroNotifications(bool value) async {
    setState(() => _pomodoroNotifications = value);
    await _notificationService.setPomodoroNotificationsEnabled(value);
  }

  Future<void> _toggleSounds(bool value) async {
    setState(() => _soundsEnabled = value);
    await _soundService.setSoundsEnabled(value);
    if (value) _soundService.playSuccess();
  }

  Future<void> _selectMorningTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _morningHour, minute: _morningMinute),
    );
    if (time != null) {
      setState(() {
        _morningHour = time.hour;
        _morningMinute = time.minute;
      });
      await _saveDailyReminderSettings();
    }
  }

  Future<void> _selectEveningTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _eveningHour, minute: _eveningMinute),
    );
    if (time != null) {
      setState(() {
        _eveningHour = time.hour;
        _eveningMinute = time.minute;
      });
      await _saveDailyReminderSettings();
    }
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ownerId = ref.watch(activeOwnerIdProvider);
    final pomodoro =
        ownerId == null ? null : ref.watch(pomodoroControllerProvider(ownerId));
    final pomodoroController = ownerId == null
        ? null
        : ref.read(pomodoroControllerProvider(ownerId).notifier);

    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: context.zentraPalette.functionalSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              colorScheme.primary.withValues(alpha: widget.isDark ? 0.3 : 0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: _SettingIcon(
              Icons.wb_sunny_rounded,
              context.zentraPalette.warmPeach,
            ),
            title: const Text('Mañana'),
            subtitle: Text(_formatTime(_morningHour, _morningMinute)),
            onTap: _morningEnabled
                ? _selectMorningTime
                : () => _toggleMorningReminder(true),
            trailing: Switch(
              value: _morningEnabled,
              onChanged: _toggleMorningReminder,
            ),
          ),
          _Divider(),
          ListTile(
            leading: _SettingIcon(
              Icons.nights_stay_rounded,
              context.zentraPalette.sleep,
            ),
            title: const Text('Noche'),
            subtitle: Text(_formatTime(_eveningHour, _eveningMinute)),
            onTap: _eveningEnabled
                ? _selectEveningTime
                : () => _toggleEveningReminder(true),
            trailing: Switch(
              value: _eveningEnabled,
              onChanged: _toggleEveningReminder,
            ),
          ),
          _Divider(),
          SwitchListTile(
            secondary: const _SettingIcon(Icons.timer_rounded, Colors.red),
            title: const Text('Pomodoro'),
            subtitle: const Text('Al terminar una sesión'),
            value: _pomodoroNotifications,
            onChanged: _togglePomodoroNotifications,
          ),
          // Warning if exact alarms not enabled (Android only)
          if (Platform.isAndroid &&
              !_canScheduleExactAlarms &&
              _pomodoroNotifications) ...[
            _Divider(),
            ListTile(
              leading: const _SettingIcon(
                Icons.warning_amber_rounded,
                Colors.orange,
              ),
              title: const Text('Alarmas exactas'),
              subtitle: const Text('Requerido para notificaciones precisas'),
              trailing: TextButton(
                onPressed: _openExactAlarmsSettings,
                child: const Text('Activar'),
              ),
            ),
          ],
          _Divider(),
          SwitchListTile(
            secondary: const _SettingIcon(
              Icons.alarm_rounded,
              Colors.orange,
            ),
            title: const Text('Alarma sonora'),
            subtitle: const Text('Al terminar un bloque'),
            value: pomodoro?.alarmEnabled ?? false,
            onChanged: pomodoroController == null
                ? null
                : (value) {
                    pomodoroController.toggleAlarm(value);
                    triggerHaptic(HapticType.light);
                  },
          ),
          _Divider(),
          SwitchListTile(
            secondary:
                const _SettingIcon(Icons.volume_up_rounded, Colors.purple),
            title: const Text('Sonidos'),
            subtitle: const Text('Al completar un hábito'),
            value: _soundsEnabled,
            onChanged: _toggleSounds,
          ),
        ],
      ),
    );
  }

  Future<void> _openExactAlarmsSettings() async {
    await _notificationService.requestExactAlarmsPermission();
    if (!mounted) return;

    final canSchedule = await _notificationService.canScheduleExactAlarms();
    if (!mounted) return;

    setState(() => _canScheduleExactAlarms = canSchedule);

    if (canSchedule) {
      showSuccessSnackbar(context, 'Alarmas exactas activadas');
    }
  }
}

/// Card de datos (exportar/importar)
class _DataCard extends riverpod.ConsumerWidget {
  final bool isDark;

  const _DataCard({required this.isDark});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: context.zentraPalette.functionalSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const _SettingIcon(Icons.upload_rounded, Colors.blue),
            title: const Text('Exportar respaldo'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _exportBackup(context, ref),
          ),
          _Divider(),
          ListTile(
            leading: const _SettingIcon(Icons.download_rounded, Colors.green),
            title: const Text('Importar respaldo'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _importBackup(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(
    BuildContext context,
    riverpod.WidgetRef ref,
  ) async {
    final passphrase = await showBackupPassphraseDialog(
      context,
      purpose: BackupPassphrasePurpose.export,
    );
    if (passphrase == null || !context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    final result = await ref
        .read(sessionControllerProvider.notifier)
        .exportBackup(passphrase: passphrase);

    if (context.mounted) {
      Navigator.of(context).pop(); // Close loading

      if (result != null) {
        showSuccessSnackbar(context, 'Respaldo cifrado exportado');
      } else {
        showErrorSnackbar(context, 'Error al exportar respaldo');
      }
    }
  }

  Future<void> _importBackup(
    BuildContext context,
    riverpod.WidgetRef ref,
  ) async {
    final confirm = await showConfirmDialog(
      context: context,
      title: '¿Importar respaldo?',
      message:
          'Esto reemplazará los hábitos, notas y el progreso de esta cuenta. '
          'Tu sesión y perfil actual se conservarán.',
      confirmText: 'Importar',
      cancelText: 'Cancelar',
      icon: Icons.download_rounded,
    );

    if (confirm != true || !context.mounted) return;

    final passphrase = await showBackupPassphraseDialog(
      context,
      purpose: BackupPassphrasePurpose.import,
    );
    if (passphrase == null || !context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    final result =
        await ref.read(sessionControllerProvider.notifier).importBackup(
              passphrase: passphrase,
              preserveCurrentUser: true,
            );

    if (context.mounted) {
      Navigator.of(context).pop(); // Close loading

      if (result == true) {
        showSuccessSnackbar(context, 'Respaldo importado correctamente');
      } else if (result == false) {
        // Only show error if it was an actual error, not a cancellation
        showErrorSnackbar(context, 'Error al importar respaldo');
      }
      // If result is null, user cancelled - do nothing
    }
  }
}

class _SettingIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SettingIcon(this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      color:
          Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }
}

/// Card de "Sobre la app"
class _AboutCard extends StatelessWidget {
  final bool isDark;

  const _AboutCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: context.zentraPalette.functionalSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading:
                _SettingIcon(Icons.info_outline_rounded, colorScheme.primary),
            title: const Text('Sobre la app'),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Card de desarrollador (logs)
class _DeveloperCard extends StatelessWidget {
  final bool isDark;

  const _DeveloperCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final logger = AppLogger();

    return Card(
      elevation: 0,
      color: context.zentraPalette.functionalSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading:
                _SettingIcon(Icons.description_rounded, colorScheme.primary),
            title: const Text('Exportar logs'),
            subtitle: Text('${logger.logCount} entradas guardadas'),
            trailing: Icon(
              Icons.share_rounded,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            onTap: () async {
              HapticFeedback.lightImpact();
              if (logger.logCount == 0) {
                showErrorSnackbar(context, 'No hay logs para exportar');
                return;
              }
              final savedPath = await logger.exportLogs();
              if (context.mounted && savedPath != null) {
                showSuccessSnackbar(context, 'Logs guardados en Descargas');
              }
            },
          ),
          _Divider(),
          ListTile(
            leading:
                const _SettingIcon(Icons.delete_sweep_rounded, Colors.orange),
            title: const Text('Limpiar logs'),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              logger.clearLogs();
              showSuccessSnackbar(context, 'Logs eliminados');
            },
          ),
        ],
      ),
    );
  }
}

/// Card para salir o eliminar el espacio local.
class _LogoutCard extends riverpod.ConsumerWidget {
  final bool isDark;

  const _LogoutCard({required this.isDark});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: context.zentraPalette.functionalSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.error.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: _SettingIcon(Icons.logout_rounded, colorScheme.error),
            title: Text(
              'Salir de este espacio',
              style: TextStyle(color: colorScheme.error),
            ),
            subtitle: const Text(
              'Tu espacio seguirá guardado en este dispositivo',
            ),
            trailing:
                Icon(Icons.chevron_right_rounded, color: colorScheme.error),
            onTap: () => _showLogoutConfirmation(context, ref),
          ),
          Divider(
            height: 1,
            indent: 56,
            color: colorScheme.error.withValues(alpha: 0.2),
          ),
          ListTile(
            leading:
                _SettingIcon(Icons.delete_forever_rounded, colorScheme.error),
            title: Text(
              'Eliminar espacio de este dispositivo',
              style: TextStyle(color: colorScheme.error),
            ),
            subtitle: const Text(
              'Elimina sólo la copia local guardada en este dispositivo',
            ),
            trailing:
                Icon(Icons.chevron_right_rounded, color: colorScheme.error),
            onTap: () => _showDeleteAccountConfirmation(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutConfirmation(
    BuildContext context,
    riverpod.WidgetRef ref,
  ) async {
    final confirm = await showConfirmDialog(
      context: context,
      title: '¿Salir de este espacio?',
      message: 'Tu espacio seguirá guardado en este dispositivo. '
          'Podrás volver a abrirlo cuando quieras.',
      confirmText: 'Salir',
      cancelText: 'Cancelar',
      icon: Icons.logout_rounded,
      isDangerous: true,
    );

    if (confirm == true && context.mounted) {
      final ownerId = ref.read(activeOwnerIdProvider);
      try {
        if (ownerId != null) {
          try {
            await ref
                .read(pomodoroControllerProvider(ownerId).notifier)
                .shutdown()
                .timeout(const Duration(seconds: 2));
          } catch (error, stackTrace) {
            AppLogger().error(
              'SettingsScreen',
              'Could not stop Pomodoro before leaving local workspace',
              error,
              stackTrace,
            );
          } finally {
            ref.invalidate(pomodoroControllerProvider(ownerId));
          }
        }
        await ref.read(sessionControllerProvider.notifier).logout();

        if (context.mounted) {
          HapticFeedback.mediumImpact();
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (error, stackTrace) {
        AppLogger().error(
          'SettingsScreen',
          'Could not leave local workspace',
          error,
          stackTrace,
        );
        if (context.mounted) {
          showErrorSnackbar(
            context,
            'No pudimos salir de este espacio. Tus datos siguen disponibles.',
          );
        }
      }
    }
  }

  Future<void> _showDeleteAccountConfirmation(
    BuildContext context,
    riverpod.WidgetRef ref,
  ) async {
    final confirm = await showConfirmDialog(
      context: context,
      title: '¿Eliminar este espacio del dispositivo?',
      message: 'Se eliminarán permanentemente los hábitos, notas y progreso '
          'guardados en este dispositivo. No se eliminará ninguna cuenta ni '
          'dato remoto.',
      confirmText: 'Eliminar espacio',
      cancelText: 'Cancelar',
      icon: Icons.delete_forever_rounded,
      isDangerous: true,
    );

    if (confirm == true && context.mounted) {
      final ownerId = ref.read(activeOwnerIdProvider);
      try {
        if (ownerId != null) {
          try {
            await ref
                .read(pomodoroControllerProvider(ownerId).notifier)
                .shutdown()
                .timeout(const Duration(seconds: 2));
          } catch (error, stackTrace) {
            AppLogger().error(
              'SettingsScreen',
              'Could not stop Pomodoro before deleting local workspace',
              error,
              stackTrace,
            );
          } finally {
            ref.invalidate(pomodoroControllerProvider(ownerId));
          }
        }
        await ref.read(sessionControllerProvider.notifier).deleteAccount();

        if (context.mounted) {
          HapticFeedback.heavyImpact();
          showSuccessSnackbar(
            context,
            'Espacio eliminado de este dispositivo',
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (error, stackTrace) {
        AppLogger().error(
          'SettingsScreen',
          'Could not finish deleting local workspace',
          error,
          stackTrace,
        );
        if (ownerId != null) {
          ref.invalidate(pomodoroControllerProvider(ownerId));
        }
        if (context.mounted) {
          showErrorSnackbar(
            context,
            'No pudimos completar la eliminación. Reintenta para terminar.',
          );
        }
      }
    }
  }
}
