import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../application/theme_provider.dart';
import '../application/auth_provider.dart';
import '../application/habit_provider.dart';
import '../application/pomodoro_provider.dart';
import '../infrastructure/notification_service.dart';
import '../infrastructure/app_logger.dart';
import 'utils/feedback_utils.dart';
import 'utils/dialogs.dart';
import 'about_screen.dart';
import 'support_screen.dart';

/// Pantalla de configuración con Apariencia, Notificaciones y más
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        centerTitle: false,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.all(20),
        children: [
          // Apariencia
          const _SectionHeader(title: 'Apariencia', icon: Icons.palette_rounded),
          const SizedBox(height: 12),
          _ThemeSelector(isDark: isDark),
          
          const SizedBox(height: 28),
          
          // Notificaciones
          const _SectionHeader(title: 'Notificaciones', icon: Icons.notifications_rounded),
          const SizedBox(height: 12),
          _NotificationsCard(isDark: isDark),
          
          const SizedBox(height: 28),
          
          // Datos
          const _SectionHeader(title: 'Datos', icon: Icons.storage_rounded),
          const SizedBox(height: 12),
          _DataCard(isDark: isDark),
          
          const SizedBox(height: 28),
          
          // Sobre la app
          const _SectionHeader(title: 'Más', icon: Icons.info_outline_rounded),
          const SizedBox(height: 12),
          _AboutCard(isDark: isDark),
          
          const SizedBox(height: 28),
          
          // Desarrollador (logs)
          const _SectionHeader(title: 'Desarrollador', icon: Icons.bug_report_rounded),
          const SizedBox(height: 12),
          _DeveloperCard(isDark: isDark),
          
          const SizedBox(height: 28),
          
          // Cerrar sesión
          _LogoutCard(isDark: isDark),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Selector de tema compacto
class _ThemeSelector extends StatelessWidget {
  final bool isDark;

  const _ThemeSelector({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();

    return Card(
      elevation: 0,
      color: isDark ? Colors.black : Colors.white,
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
              isSelected: themeProvider.themeMode == AppThemeMode.system,
              onTap: () => themeProvider.setThemeMode(AppThemeMode.system),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _ThemeOption(
              icon: Icons.light_mode_rounded,
              label: 'Claro',
              isSelected: themeProvider.themeMode == AppThemeMode.light,
              onTap: () => themeProvider.setThemeMode(AppThemeMode.light),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _ThemeOption(
              icon: Icons.dark_mode_rounded,
              label: 'Oscuro',
              isSelected: themeProvider.themeMode == AppThemeMode.dark,
              onTap: () => themeProvider.setThemeMode(AppThemeMode.dark),
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
            color: isSelected
                ? colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.15)
                : (isDark ? Colors.black : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? colorScheme.primary 
                  : colorScheme.outline.withValues(alpha: isDark ? 0.3 : 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
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
class _NotificationsCard extends StatefulWidget {
  final bool isDark;

  const _NotificationsCard({required this.isDark});

  @override
  State<_NotificationsCard> createState() => _NotificationsCardState();
}

class _NotificationsCardState extends State<_NotificationsCard> {
  final NotificationService _notificationService = NotificationService();
  final SoundService _soundService = SoundService();
  bool _notificationsEnabled = false; // Default to false until we check
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
    final enabled = await _notificationService.areNotificationsEnabled();
    final pomodoroEnabled = await _notificationService.arePomodoroNotificationsEnabled();
    final times = await _notificationService.getReminderTimes();
    final canScheduleExact = await _notificationService.canScheduleExactAlarms();
    await _soundService.initialize();

    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
        _pomodoroNotifications = pomodoroEnabled;
        _soundsEnabled = _soundService.soundsEnabled;
        _canScheduleExactAlarms = canScheduleExact;
        _morningHour = times['morningHour'] ?? 9;
        _morningMinute = times['morningMinute'] ?? 0;
        _eveningHour = times['eveningHour'] ?? 19;
        _eveningMinute = times['eveningMinute'] ?? 0;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);

    if (value) {
      final granted = await _notificationService.requestNotificationPermission();
      if (!granted) {
        if (!mounted) return;
        setState(() => _notificationsEnabled = false);
        showErrorSnackbar(
          context,
          'Activa las notificaciones en los ajustes del sistema para usar recordatorios.',
        );
        return;
      }

      await _notificationService.setNotificationsEnabled(true);
      await _notificationService.scheduleDailyReminders();

      final canSchedule = await _notificationService.canScheduleExactAlarms();
      if (mounted) {
        setState(() => _canScheduleExactAlarms = canSchedule);
      }
    } else {
      await _notificationService.setNotificationsEnabled(false);
    }
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
      await _notificationService.setMorningReminderTime(time.hour, time.minute);
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
      await _notificationService.setEveningReminderTime(time.hour, time.minute);
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
      color: widget.isDark ? Colors.black : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: widget.isDark ? 0.3 : 0.2),
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: _SettingIcon(Icons.notifications_rounded, colorScheme.primary),
            title: const Text('Recordatorios'),
            subtitle: const Text('Recordatorios diarios'),
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          if (_notificationsEnabled) ...[
            _Divider(),
            ListTile(
              leading: const _SettingIcon(Icons.wb_sunny_rounded, Colors.orange),
              title: const Text('Mañana'),
              trailing: Text(_formatTime(_morningHour, _morningMinute)),
              onTap: _selectMorningTime,
            ),
            _Divider(),
            ListTile(
              leading: const _SettingIcon(Icons.nights_stay_rounded, Colors.indigo),
              title: const Text('Tarde'),
              trailing: Text(_formatTime(_eveningHour, _eveningMinute)),
              onTap: _selectEveningTime,
            ),
          ],
          _Divider(),
          SwitchListTile(
            secondary: const _SettingIcon(Icons.timer_rounded, Colors.red),
            title: const Text('Pomodoro'),
            subtitle: const Text('Alertas de sesión'),
            value: _pomodoroNotifications,
            onChanged: _togglePomodoroNotifications,
          ),
          // Warning if exact alarms not enabled (Android only)
          if (!_canScheduleExactAlarms && _pomodoroNotifications) ...[
            _Divider(),
            ListTile(
              leading: const _SettingIcon(Icons.warning_amber_rounded, Colors.orange),
              title: const Text('Alarmas exactas'),
              subtitle: const Text('Requerido para notificaciones precisas'),
              trailing: TextButton(
                onPressed: _openExactAlarmsSettings,
                child: const Text('Activar'),
              ),
            ),
          ],
          _Divider(),
          Consumer<PomodoroProvider>(
            builder: (context, pomodoroProvider, _) {
              return SwitchListTile(
                secondary: const _SettingIcon(Icons.alarm_rounded, Colors.orange),
                title: const Text('Alarma sonora'),
                subtitle: const Text('Sonido fuerte al terminar Pomodoro'),
                value: pomodoroProvider.alarmEnabled,
                onChanged: (value) {
                  pomodoroProvider.toggleAlarm(value);
                  triggerHaptic(HapticType.light);
                },
              );
            },
          ),
          _Divider(),
          SwitchListTile(
            secondary: const _SettingIcon(Icons.volume_up_rounded, Colors.purple),
            title: const Text('Sonidos'),
            subtitle: const Text('Al completar hábitos'),
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
class _DataCard extends StatelessWidget {
  final bool isDark;

  const _DataCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: isDark ? Colors.black : Colors.white,
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
            subtitle: const Text('Guardar datos'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _exportBackup(context),
          ),
          _Divider(),
          ListTile(
            leading: const _SettingIcon(Icons.download_rounded, Colors.green),
            title: const Text('Importar respaldo'),
            subtitle: const Text('Restaurar datos'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _importBackup(context),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    
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

    final result = await authProvider.exportBackup();
    
    if (context.mounted) {
      Navigator.of(context).pop(); // Close loading
      
      if (result != null) {
        final fileName = result.split('/').last;
        showSuccessSnackbar(context, 'Guardado en Downloads: $fileName');
      } else {
        showErrorSnackbar(context, 'Error al exportar respaldo');
      }
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    final confirm = await showConfirmDialog(
      context: context,
      title: '¿Importar respaldo?',
      message: 'Esto reemplazará todos tus datos actuales.',
      confirmText: 'Importar',
      cancelText: 'Cancelar',
      icon: Icons.download_rounded,
    );

    if (confirm != true || !context.mounted) return;

    final authProvider = context.read<AuthProvider>();
    final habitProvider = context.read<HabitProvider>();
    final pomodoroProvider = context.read<PomodoroProvider>();
    
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

    final result = await authProvider.importBackup(preserveCurrentUser: true);
    
    if (context.mounted) {
      Navigator.of(context).pop(); // Close loading
      
      if (result == true) {
        await habitProvider.initialize();
        await pomodoroProvider.initialize();
        if (context.mounted) {
          showSuccessSnackbar(context, 'Respaldo importado correctamente');
        }
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
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
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
      color: isDark ? Colors.black : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: _SettingIcon(Icons.info_outline_rounded, colorScheme.primary),
            title: const Text('Sobre la app'),
            subtitle: const Text('Historia, feedback y más'),
            trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurface.withValues(alpha: 0.4)),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
          _Divider(),
          ListTile(
            leading: const _SettingIcon(Icons.favorite_rounded, Colors.pink),
            title: const Text('Apoyar el desarrollo'),
            subtitle: const Text('Ayuda a mantener la app gratis'),
            trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurface.withValues(alpha: 0.4)),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SupportScreen()),
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
      color: isDark ? Colors.black : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: _SettingIcon(Icons.description_rounded, colorScheme.primary),
            title: const Text('Exportar logs'),
            subtitle: Text('${logger.logCount} entradas guardadas'),
            trailing: Icon(Icons.share_rounded, color: colorScheme.onSurface.withValues(alpha: 0.4)),
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
            leading: const _SettingIcon(Icons.delete_sweep_rounded, Colors.orange),
            title: const Text('Limpiar logs'),
            subtitle: const Text('Eliminar todos los logs guardados'),
            trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurface.withValues(alpha: 0.4)),
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

/// Card de cerrar sesión y eliminar cuenta
class _LogoutCard extends StatelessWidget {
  final bool isDark;

  const _LogoutCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: isDark ? Colors.black : Colors.white,
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
              'Cerrar sesión',
              style: TextStyle(color: colorScheme.error),
            ),
            subtitle: const Text('Salir de tu cuenta'),
            trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.error),
            onTap: () => _showLogoutConfirmation(context),
          ),
          Divider(
            height: 1,
            indent: 56,
            color: colorScheme.error.withValues(alpha: 0.2),
          ),
          ListTile(
            leading: _SettingIcon(Icons.delete_forever_rounded, colorScheme.error),
            title: Text(
              'Eliminar cuenta / Delete Account',
              style: TextStyle(color: colorScheme.error),
            ),
            subtitle: const Text('Permanently delete your account and all data'),
            trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.error),
            onTap: () => _showDeleteAccountConfirmation(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final confirm = await showConfirmDialog(
      context: context,
      title: '¿Cerrar sesión?',
      message: 'Podrás volver a iniciar sesión con tu cuenta cuando quieras.',
      confirmText: 'Cerrar sesión',
      cancelText: 'Cancelar',
      icon: Icons.logout_rounded,
      isDangerous: true,
    );

    if (confirm == true && context.mounted) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();
      
      if (context.mounted) {
        HapticFeedback.mediumImpact();
        // Navigate to auth screen and clear stack
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  Future<void> _showDeleteAccountConfirmation(BuildContext context) async {
    final confirm = await showConfirmDialog(
      context: context,
      title: 'Delete Account?',
      message: 'This action is permanent. All your data, habits, and progress will be deleted. You will not be able to recover this information.',
      confirmText: 'Delete Account',
      cancelText: 'Cancel',
      icon: Icons.delete_forever_rounded,
      isDangerous: true,
    );

    if (confirm == true && context.mounted) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.deleteAccount();
      
      if (context.mounted) {
        HapticFeedback.heavyImpact();
        showSuccessSnackbar(context, 'Cuenta eliminada');
        // Navigate to auth screen and clear stack
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }
}
