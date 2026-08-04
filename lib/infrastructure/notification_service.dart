import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/habit_reminder_service.dart';
import '../domain/note_models.dart';
import '../domain/notification_intent.dart';
import 'app_logger.dart';
import 'notification_schedule_planner.dart';

export '../domain/habit_reminder_service.dart' show DailyReminderSnapshot;

/// User choices for the two global daily reminders.
class DailyReminderSettings {
  final bool morningEnabled;
  final int morningHour;
  final int morningMinute;
  final bool eveningEnabled;
  final int eveningHour;
  final int eveningMinute;

  const DailyReminderSettings({
    required this.morningEnabled,
    required this.morningHour,
    required this.morningMinute,
    required this.eveningEnabled,
    required this.eveningHour,
    required this.eveningMinute,
  });

  bool get hasEnabledReminder => morningEnabled || eveningEnabled;
}

class DailyReminderContent {
  final String title;
  final String body;

  const DailyReminderContent({
    required this.title,
    required this.body,
  });
}

/// Servicio de notificaciones locales
/// Maneja recordatorios de hábitos y notificaciones del Pomodoro
class NotificationService implements HabitReminderService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Notification IDs
  static const int _morningReminderId = 1000;
  static const int _eveningReminderId = 1001;
  static const int _morningSnapshotReminderId = 1002;
  static const int _eveningSnapshotReminderId = 1003;
  static const int _pomodoroWorkId = 2000;
  static const int _pomodoroBreakId = 2001;
  static const int _pomodoroCompleteId = 2002;
  static const int _pomodoroAlarmId =
      2003; // Separate ID for alarm so it doesn't replace timer
  static const String _pomodoroCategory = 'zentra_pomodoro_v1';
  static const String _reminderCategory = 'zentra_reminder_v1';
  static const String _pomodoroThread = 'zentra.pomodoro';

  // Preferences keys
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyHabitRemindersEnabled = 'habit_reminders_enabled';
  static const String _keyMorningReminderEnabled = 'morning_reminder_enabled';
  static const String _keyMorningReminderTime = 'morning_reminder_time';
  static const String _keyMorningReminderMinute = 'morning_reminder_minute';
  static const String _keyEveningReminderEnabled = 'evening_reminder_enabled';
  static const String _keyEveningReminderTime = 'evening_reminder_time';
  static const String _keyEveningReminderMinute = 'evening_reminder_minute';
  static const String _keyPomodoroNotifications = 'pomodoro_notifications';

  bool _isInitialized = false;
  String? _timezoneIdentifier;

  String get timezoneIdentifier => _timezoneIdentifier ?? tz.local.name;

  /// Inicializa el servicio de notificaciones
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();
    await refreshTimezone(force: true);

    // Android settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      requestProvisionalPermission: false,
      notificationCategories: <DarwinNotificationCategory>[
        DarwinNotificationCategory(
          _pomodoroCategory,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              'zentra_open_pomodoro',
              'Abrir enfoque',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
        ),
        DarwinNotificationCategory(
          _reminderCategory,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              'zentra_open_reminder',
              'Abrir Zentra',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
        ),
      ],
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create alarm notification channel for Android
    if (Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final alarmChannel = AndroidNotificationChannel(
          'pomodoro_alarm',
          'Alarma Pomodoro',
          description: 'Alarma sonora cuando termina el temporizador',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        );

        await androidPlugin.createNotificationChannel(alarmChannel);
      }
    }

    _isInitialized = true;

    // Check if app was launched from a notification
    final launchDetails =
        await _notifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails!.notificationResponse?.payload;
      if (payload != null) {
        // Store the payload to be handled after the app is fully initialized
        _pendingNotificationPayload = payload;
      }
    }
  }

  /// Refreshes the local timezone without prompting for notification access.
  Future<bool> refreshTimezone({bool force = false}) async {
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final identifier = timezoneInfo.identifier;
      final changed = force || identifier != _timezoneIdentifier;
      if (changed) {
        tz.setLocalLocation(tz.getLocation(identifier));
        _timezoneIdentifier = identifier;
      }
      return changed;
    } catch (error) {
      if (_timezoneIdentifier == null) {
        if (kDebugMode) {
          debugPrint(
            'Error getting timezone: $error, falling back to UTC',
          );
        }
        tz.setLocalLocation(tz.UTC);
        _timezoneIdentifier = tz.UTC.name;
      } else if (kDebugMode) {
        debugPrint('Error refreshing timezone: $error');
      }
      return false;
    }
  }

  // Payload from notification that launched the app
  static String? _pendingNotificationPayload;

  /// Gets and clears the pending notification payload (if app was launched from notification)
  static String? consumePendingNotificationPayload() {
    final payload = _pendingNotificationPayload;
    _pendingNotificationPayload = null;
    return payload;
  }

  /// Solicita permisos de notificación (solo notificaciones)
  Future<bool> requestNotificationPermission() async {
    if (Platform.isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  /// Solicita permiso de alarmas exactas (Solo Android 12+)
  Future<bool> requestExactAlarmsPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.requestExactAlarmsPermission() ?? true;
    }
    return true; // No necesario en iOS
  }

  /// Legacy entry point kept for callers that only need notification access.
  Future<bool> requestPermissions() async {
    return requestNotificationPermission();
  }

  /// Verifica si los permisos de alarmas exactas están concedidos (Android 12+)
  Future<bool> canScheduleExactAlarms() async {
    if (Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.canScheduleExactNotifications() ?? false;
    }
    return true; // iOS doesn't need this
  }

  /// Verifica si los permisos de notificación del SISTEMA están concedidos
  Future<bool> isSystemNotificationPermissionGranted() async {
    if (Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }
    if (Platform.isIOS) {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final permissions = await iosPlugin?.checkPermissions();
      return permissions?.isEnabled ?? false;
    }
    return false;
  }

  Future<AndroidScheduleMode> _androidScheduleMode() async {
    if (!Platform.isAndroid) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    final canScheduleExact = await canScheduleExactAlarms();
    return canScheduleExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Verifica si las notificaciones están habilitadas en las PREFERENCIAS de la app
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? false;
  }

  /// Habilita o deshabilita los recordatorios diarios genéricos.
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);

    if (!enabled) {
      await _cancelDailyReminders();
    } else {
      final settings = await getDailyReminderSettings();
      if (!settings.hasEnabledReminder) {
        await prefs.setBool(_keyMorningReminderEnabled, true);
        await prefs.setBool(_keyEveningReminderEnabled, true);
      }
      await scheduleDailyReminders();
    }
  }

  /// Verifica si los recordatorios configurados dentro de hábitos están activos.
  ///
  /// Cada hábito con recordatorio ya expresa una decisión explícita del usuario,
  /// por eso el valor por defecto conserva los recordatorios de instalaciones
  /// existentes aunque la preferencia todavía no exista.
  Future<bool> areHabitRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHabitRemindersEnabled) ?? true;
  }

  /// Habilita o deshabilita exclusivamente los recordatorios por hábito.
  Future<void> setHabitRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHabitRemindersEnabled, enabled);
  }

  // ============================================================================
  // RECORDATORIOS DIARIOS DE HÁBITOS
  // ============================================================================

  /// Reads the two global daily reminder choices.
  Future<DailyReminderSettings> getDailyReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final globallyEnabled = prefs.getBool(_keyNotificationsEnabled) ?? false;

    return DailyReminderSettings(
      morningEnabled: globallyEnabled &&
          (prefs.getBool(_keyMorningReminderEnabled) ?? true),
      morningHour: _validHour(
        prefs.getInt(_keyMorningReminderTime),
        fallback: 9,
      ),
      morningMinute: _validMinute(
        prefs.getInt(_keyMorningReminderMinute),
      ),
      eveningEnabled: globallyEnabled &&
          (prefs.getBool(_keyEveningReminderEnabled) ?? true),
      eveningHour: _validHour(
        prefs.getInt(_keyEveningReminderTime),
        fallback: 19,
      ),
      eveningMinute: _validMinute(
        prefs.getInt(_keyEveningReminderMinute),
      ),
    );
  }

  /// Persists, cancels and reprograms both global reminders atomically.
  Future<void> setDailyReminderSettings(
    DailyReminderSettings settings, {
    DailyReminderSnapshot? snapshot,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      _keyMorningReminderEnabled,
      settings.morningEnabled,
    );
    await prefs.setInt(
      _keyMorningReminderTime,
      _validHour(settings.morningHour, fallback: 9),
    );
    await prefs.setInt(
      _keyMorningReminderMinute,
      _validMinute(settings.morningMinute),
    );
    await prefs.setBool(
      _keyEveningReminderEnabled,
      settings.eveningEnabled,
    );
    await prefs.setInt(
      _keyEveningReminderTime,
      _validHour(settings.eveningHour, fallback: 19),
    );
    await prefs.setInt(
      _keyEveningReminderMinute,
      _validMinute(settings.eveningMinute),
    );
    await prefs.setBool(
      _keyNotificationsEnabled,
      settings.hasEnabledReminder,
    );

    await _cancelDailyReminders();
    if (settings.hasEnabledReminder) {
      await scheduleDailyReminders(snapshot: snapshot);
    }
  }

  /// Programa los recordatorios globales de mañana y noche.
  ///
  /// Recurring notifications use direct fallback copy because the OS cannot
  /// query live Flutter state while the app is closed. A snapshot is used only
  /// for the next occurrence when it was captured shortly before delivery.
  Future<void> scheduleDailyReminders({
    DailyReminderSnapshot? snapshot,
  }) async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) {
      await _cancelDailyReminders();
      return;
    }

    final settings = await getDailyReminderSettings();
    await _cancelDailyReminders();

    if (settings.morningEnabled) {
      await _scheduleCompanionReminder(
        recurringId: _morningReminderId,
        snapshotId: _morningSnapshotReminderId,
        hour: settings.morningHour,
        minute: settings.morningMinute,
        fallback: morningReminderContent(),
        snapshot: snapshot,
        contentForSnapshot: morningReminderContent,
      );
    }

    if (settings.eveningEnabled) {
      await _scheduleCompanionReminder(
        recurringId: _eveningReminderId,
        snapshotId: _eveningSnapshotReminderId,
        hour: settings.eveningHour,
        minute: settings.eveningMinute,
        fallback: eveningReminderContent(),
        snapshot: snapshot,
        contentForSnapshot: eveningReminderContent,
      );
    }
  }

  Future<void> _scheduleCompanionReminder({
    required int recurringId,
    required int snapshotId,
    required int hour,
    required int minute,
    required DailyReminderContent fallback,
    required DailyReminderSnapshot? snapshot,
    required DailyReminderContent Function(DailyReminderSnapshot?)
        contentForSnapshot,
  }) async {
    final planner = NotificationSchedulePlanner(location: tz.local);
    final nextOccurrence = planner.nextDailyTime(
      hour: hour,
      minute: minute,
    );
    final snapshotIsFresh = _isFreshFor(
      snapshot,
      occurrence: nextOccurrence,
    );

    if (snapshotIsFresh) {
      await _scheduleDailyNotification(
        id: snapshotId,
        scheduledTime: nextOccurrence,
        content: contentForSnapshot(snapshot),
        repeatsDaily: false,
      );
      final tomorrow = tz.TZDateTime(
        tz.local,
        nextOccurrence.year,
        nextOccurrence.month,
        nextOccurrence.day + 1,
        hour,
        minute,
      );
      await _scheduleDailyNotification(
        id: recurringId,
        scheduledTime: tomorrow,
        content: fallback,
      );
      return;
    }

    await _scheduleDailyNotification(
      id: recurringId,
      scheduledTime: nextOccurrence,
      content: fallback,
    );
  }

  /// Programa una notificación global.
  Future<void> _scheduleDailyNotification({
    required int id,
    required tz.TZDateTime scheduledTime,
    required DailyReminderContent content,
    bool repeatsDaily = true,
  }) async {
    final scheduleMode = await _androidScheduleMode();

    await _notifications.zonedSchedule(
      id,
      content.title,
      content.body,
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminders',
          'Recordatorios de Hábitos',
          channelDescription:
              'Recordatorios diarios para completar tus hábitos',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: _reminderCategory,
        ),
      ),
      androidScheduleMode: scheduleMode,
      matchDateTimeComponents: repeatsDaily ? DateTimeComponents.time : null,
    );
  }

  /// Actualiza el horario del recordatorio de mañana
  Future<void> setMorningReminderTime(int hour, int minute) async {
    final current = await getDailyReminderSettings();
    await setDailyReminderSettings(
      DailyReminderSettings(
        morningEnabled: current.morningEnabled,
        morningHour: hour,
        morningMinute: minute,
        eveningEnabled: current.eveningEnabled,
        eveningHour: current.eveningHour,
        eveningMinute: current.eveningMinute,
      ),
    );
  }

  /// Actualiza el horario del recordatorio de noche
  Future<void> setEveningReminderTime(int hour, int minute) async {
    final current = await getDailyReminderSettings();
    await setDailyReminderSettings(
      DailyReminderSettings(
        morningEnabled: current.morningEnabled,
        morningHour: current.morningHour,
        morningMinute: current.morningMinute,
        eveningEnabled: current.eveningEnabled,
        eveningHour: hour,
        eveningMinute: minute,
      ),
    );
  }

  /// Obtiene los horarios actuales de recordatorios
  Future<Map<String, dynamic>> getReminderTimes() async {
    final settings = await getDailyReminderSettings();
    return {
      'morningHour': settings.morningHour,
      'morningMinute': settings.morningMinute,
      'eveningHour': settings.eveningHour,
      'eveningMinute': settings.eveningMinute,
    };
  }

  DailyReminderContent morningReminderContent([
    DailyReminderSnapshot? snapshot,
  ]) {
    if (snapshot == null) {
      return const DailyReminderContent(
        title: 'Revisa tu día',
        body: 'Abre Zentra, mira qué hábitos tienes hoy y elige el primero.',
      );
    }
    if (snapshot.totalHabits == 0) {
      return const DailyReminderContent(
        title: 'Hoy no hay hábitos',
        body: 'Abre Zentra si necesitas agregar uno para hoy.',
      );
    }

    final total = snapshot.totalHabits;
    final noun = total == 1 ? 'hábito' : 'hábitos';
    return DailyReminderContent(
      title: 'Hoy tienes $total $noun',
      body: 'Abre Zentra y elige con cuál empezar.',
    );
  }

  DailyReminderContent eveningReminderContent([
    DailyReminderSnapshot? snapshot,
  ]) {
    if (snapshot == null) {
      return const DailyReminderContent(
        title: 'Cierra el día',
        body: 'Abre Zentra, revisa qué queda y decide qué vas a completar hoy.',
      );
    }
    if (snapshot.totalHabits == 0) {
      return const DailyReminderContent(
        title: 'Hoy no registraste hábitos',
        body: 'Abre Zentra si necesitas preparar mañana.',
      );
    }

    final remaining = snapshot.remainingHabits;
    if (remaining == 0) {
      final total = snapshot.totalHabits;
      return DailyReminderContent(
        title: 'Día completado',
        body: total == 1
            ? 'Terminaste tu hábito de hoy.'
            : 'Terminaste tus $total hábitos de hoy.',
      );
    }

    final noun = remaining == 1 ? 'hábito' : 'hábitos';
    final verb = remaining == 1 ? 'Queda' : 'Quedan';
    return DailyReminderContent(
      title: '$verb $remaining $noun',
      body: 'Abre Zentra y decide qué vas a completar hoy.',
    );
  }

  bool _isFreshFor(
    DailyReminderSnapshot? snapshot, {
    required tz.TZDateTime occurrence,
  }) {
    if (snapshot == null) return false;
    final capturedAt = tz.TZDateTime.from(snapshot.capturedAt, tz.local);
    final sameDay = capturedAt.year == occurrence.year &&
        capturedAt.month == occurrence.month &&
        capturedAt.day == occurrence.day;
    if (!sameDay) return false;

    final ageAtDelivery = occurrence.difference(capturedAt);
    return !ageAtDelivery.isNegative &&
        ageAtDelivery <= const Duration(minutes: 15);
  }

  Future<void> _cancelDailyReminders() async {
    await _notifications.cancel(_morningReminderId);
    await _notifications.cancel(_eveningReminderId);
    await _notifications.cancel(_morningSnapshotReminderId);
    await _notifications.cancel(_eveningSnapshotReminderId);
  }

  static int _validHour(int? value, {required int fallback}) {
    if (value == null || value < 0 || value > 23) return fallback;
    return value;
  }

  static int _validMinute(int? value) {
    if (value == null || value < 0 || value > 59) return 0;
    return value;
  }

  // ============================================================================
  // NOTIFICACIONES DEL POMODORO
  // ============================================================================

  /// Verifica si las notificaciones del Pomodoro están habilitadas
  Future<bool> arePomodoroNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPomodoroNotifications) ?? true;
  }

  /// Habilita o deshabilita las notificaciones del Pomodoro
  Future<void> setPomodoroNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPomodoroNotifications, enabled);
    if (!enabled) {
      await cancelPomodoroNotifications();
      await cancelCompletionNotification();
    }
  }

  /// Programa notificación cuando termine el tiempo de trabajo
  Future<void> schedulePomodoroWorkEnd({
    required Duration duration,
    required String activityName,
    required bool isQuickSession,
  }) async {
    final enabled = await arePomodoroNotificationsEnabled();
    if (!enabled) return;

    final scheduledTime = tz.TZDateTime.now(tz.local).add(duration);
    final scheduleMode = await _androidScheduleMode();

    await _notifications.zonedSchedule(
      _pomodoroWorkId,
      'Enfoque completado',
      isQuickSession
          ? 'Tu sesión terminó. Elige qué quieres hacer ahora.'
          : 'Tu sesión terminó. Inicia tu descanso.',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'pomodoro',
          'Pomodoro Timer',
          channelDescription: 'Notificaciones del temporizador Pomodoro',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: _pomodoroCategory,
          threadIdentifier: _pomodoroThread,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: scheduleMode,
      payload: ZentraNotificationIntent.openPomodoro().encode(),
    );
  }

  /// Programa notificación cuando termine el descanso
  Future<void> schedulePomodoroBreakEnd({
    required Duration duration,
    required String activityName,
    required bool completesCycle,
  }) async {
    final enabled = await arePomodoroNotificationsEnabled();
    if (!enabled) return;

    final scheduledTime = tz.TZDateTime.now(tz.local).add(duration);
    final scheduleMode = await _androidScheduleMode();

    await _notifications.zonedSchedule(
      _pomodoroBreakId,
      completesCycle ? 'Ciclo Pomodoro completado' : 'Descanso terminado',
      completesCycle
          ? 'Tu ciclo quedó guardado.'
          : 'Vuelve al enfoque cuando estés listo.',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'pomodoro',
          'Pomodoro Timer',
          channelDescription: 'Notificaciones del temporizador Pomodoro',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: _pomodoroCategory,
          threadIdentifier: _pomodoroThread,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: scheduleMode,
      payload: ZentraNotificationIntent.openPomodoro().encode(),
    );
  }

  /// Muestra notificación de sesión Pomodoro completada
  Future<void> showPomodoroCompleteNotification({
    required String activityName,
    required int cycles,
    required Duration totalTime,
  }) async {
    final enabled = await arePomodoroNotificationsEnabled();
    if (!enabled) return;

    final minutes = totalTime.inMinutes;

    await _notifications.show(
      _pomodoroCompleteId,
      'Ciclo Pomodoro completado',
      'Terminaste $cycles enfoques ($minutes min).',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'pomodoro',
          'Pomodoro Timer',
          channelDescription: 'Notificaciones del temporizador Pomodoro',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: _pomodoroCategory,
          threadIdentifier: _pomodoroThread,
        ),
      ),
      payload: ZentraNotificationIntent.openPomodoro().encode(),
    );
  }

  /// Cancela las notificaciones programadas del Pomodoro
  Future<void> cancelPomodoroNotifications() async {
    await _notifications.cancel(_pomodoroWorkId);
    await _notifications.cancel(_pomodoroBreakId);
  }

  /// Cancela la notificación de sesión completada
  Future<void> cancelCompletionNotification() async {
    await _notifications.cancel(_pomodoroCompleteId);
    await _notifications.cancel(_pomodoroAlarmId);
  }

  /// Muestra una notificación instantánea (para cuando el timer termina en foreground)
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    final enabled = await arePomodoroNotificationsEnabled();
    if (!enabled) return;

    // Use fixed ID so it replaces previous notification instead of stacking
    await _notifications.show(
      _pomodoroCompleteId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'pomodoro',
          'Pomodoro Timer',
          channelDescription: 'Notificaciones del temporizador Pomodoro',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: _pomodoroCategory,
          threadIdentifier: _pomodoroThread,
        ),
      ),
      payload: ZentraNotificationIntent.openPomodoro().encode(),
    );
  }

  /// Muestra una notificación de ALARMA con máxima prioridad y sonido fuerte
  Future<void> showAlarmNotification({
    required String title,
    required String body,
  }) async {
    // Esta notificación ignora el toggle de pomodoro - si el usuario activó la alarma, debe sonar
    // Usa ID separado para que no sea reemplazada por el timer
    await _notifications.show(
      _pomodoroAlarmId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'pomodoro_alarm',
          'Alarma Pomodoro',
          channelDescription: 'Alarma sonora cuando termina el temporizador',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          autoCancel: false,
          ongoing: false,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: _pomodoroCategory,
          threadIdentifier: _pomodoroThread,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: ZentraNotificationIntent.openPomodoro().encode(),
    );
  }

  // ============================================================================
  // NOTIFICACIONES INSTANTÁNEAS
  // ============================================================================

  /// Muestra una notificación de logro desbloqueado
  Future<void> showAchievementNotification({
    required String title,
    required String description,
  }) async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Logro desbloqueado',
      '$title - $description',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'achievements',
          'Logros',
          channelDescription: 'Notificaciones de logros desbloqueados',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: _reminderCategory,
        ),
      ),
    );
  }

  /// Muestra notificación de día completado
  Future<void> showDayCompletedNotification() async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '¡Día perfecto!',
      'Completaste todos tus hábitos de hoy. ¡Eres increíble!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'achievements',
          'Logros',
          channelDescription: 'Notificaciones de logros',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: _reminderCategory,
        ),
      ),
    );
  }

  // ============================================================================
  // RECORDATORIOS DE HÁBITOS
  // ============================================================================

  /// Programa un recordatorio diario para un hábito
  /// El ID se genera a partir del habitId para poder cancelarlo después
  @override
  Future<HabitReminderScheduleResult> scheduleHabitReminder({
    required String habitId,
    required String habitTitle,
    required int hour,
    required int minute,
    required List<int> daysOfWeek, // 1=Monday, 7=Sunday
    bool isOneTime = false,
    DateTime? scheduledDate,
  }) async {
    final logger = AppLogger();
    final enabled = await areHabitRemindersEnabled();
    logger.info(
      'Notifications',
      'scheduleHabitReminder: habitRemindersEnabled=$enabled, '
          'time=$hour:$minute, days=$daysOfWeek',
    );
    if (!enabled) {
      logger.warning(
        'Notifications',
        'Habit reminders disabled, skipping habit reminder',
      );
      return const HabitReminderScheduleResult(
        requestedCount: 0,
        scheduledCount: 0,
      );
    }

    // Cancelar recordatorios anteriores de este hábito
    await cancelHabitReminder(habitId);

    final planner = NotificationSchedulePlanner(location: tz.local);
    final plans = isOneTime
        ? planner.planOneTimeReminder(
            scheduledDate: scheduledDate,
            hour: hour,
            minute: minute,
          )
        : planner.planHabitReminder(
            hour: hour,
            minute: minute,
            daysOfWeek: daysOfWeek,
          );
    final pending = await getPendingNotifications();
    final allowedCount = NotificationPendingBudget.allowedHabitReminders(
      appliesIosLimit: Platform.isIOS,
      pendingCount: pending.length,
      requestedCount: plans.length,
    );
    final selectedPlans = plans.take(allowedCount).toList();
    final scheduleMode = await _androidScheduleMode();
    var scheduledCount = 0;

    for (final plan in selectedPlans) {
      final notificationId = _getHabitNotificationId(
        habitId,
        plan.idSlot,
      );
      final dateTimeComponents = switch (plan.repeatPattern) {
        ReminderRepeatPattern.oneTime => null,
        ReminderRepeatPattern.daily => DateTimeComponents.time,
        ReminderRepeatPattern.weekly => DateTimeComponents.dayOfWeekAndTime,
      };

      logger.info(
        'Notifications',
        'Scheduling notification id=$notificationId at '
            '${plan.scheduledDate}',
      );

      try {
        await _notifications.zonedSchedule(
          notificationId,
          'Recordatorio',
          'Tienes un hábito pendiente en Zentra.',
          plan.scheduledDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'habit_reminders',
              'Recordatorios de Hábitos',
              channelDescription: 'Recordatorios para completar tus hábitos',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              categoryIdentifier: _reminderCategory,
            ),
          ),
          androidScheduleMode: scheduleMode,
          matchDateTimeComponents: dateTimeComponents,
          payload: ZentraNotificationIntent.openHabit(habitId).encode(),
        );
        scheduledCount++;
        logger.info(
          'Notifications',
          'Habit reminder scheduled successfully',
        );
      } catch (e, stack) {
        logger.error(
          'Notifications',
          'Error scheduling habit reminder',
          e,
          stack,
        );
      }
    }

    if (scheduledCount < plans.length) {
      logger.warning(
        'Notifications',
        'Scheduled $scheduledCount/${plans.length} habit reminders',
      );
    }

    return HabitReminderScheduleResult(
      requestedCount: isOneTime ? 1 : plans.length,
      scheduledCount: scheduledCount,
    );
  }

  /// Cancela los recordatorios de un hábito
  @override
  Future<void> cancelHabitReminder(String habitId) async {
    // Slot 0 is the optimized daily reminder. Slots 1-7 are weekly.
    for (int slot = 0; slot <= DateTime.daysPerWeek; slot++) {
      final notificationId = _getHabitNotificationId(habitId, slot);
      await _notifications.cancel(notificationId);

      // Build 24 and earlier used String.hashCode. Cancel those IDs during
      // migration so existing reminders do not survive an edit or deletion.
      final legacyNotificationId =
          (habitId.hashCode.abs() % 100000) * 10 + slot;
      if (legacyNotificationId != notificationId) {
        await _notifications.cancel(legacyNotificationId);
      }
    }
  }

  /// Genera un ID único para la notificación de un hábito en un día específico
  int _getHabitNotificationId(String habitId, int dayOfWeek) {
    return stableHabitNotificationId(habitId, dayOfWeek);
  }

  // ============================================================================
  // RECORDATORIOS DE NOTAS
  // ============================================================================

  /// Schedules the single active reminder supported by the Notes MVP.
  ///
  /// [scheduledAtUtc] is the canonical instant. It is converted to the
  /// currently configured local timezone only at the OS boundary.
  Future<int?> scheduleNoteReminder({
    required String noteId,
    required String noteTitle,
    required String noteBody,
    required DateTime scheduledAtUtc,
    required NotePrivacyMode privacyMode,
  }) async {
    await cancelNoteReminder(noteId);
    if (!await isSystemNotificationPermissionGranted()) return null;

    final scheduledAt = tz.TZDateTime.from(
      scheduledAtUtc.toUtc(),
      tz.local,
    );
    if (!scheduledAt.isAfter(tz.TZDateTime.now(tz.local))) return null;

    final pending = await getPendingNotifications();
    final allowed = NotificationPendingBudget.allowedHabitReminders(
      appliesIosLimit: Platform.isIOS,
      pendingCount: pending.length,
      requestedCount: 1,
    );
    if (allowed == 0) return null;

    final notificationId = stableNoteNotificationId(noteId);
    final normalizedTitle = noteTitle.trim();
    final normalizedBody = noteBody.trim().replaceAll(RegExp(r'\s+'), ' ');
    final notificationTitle = privacyMode == NotePrivacyMode.titleAndBody &&
            normalizedTitle.isNotEmpty
        ? normalizedTitle
        : 'Nota para revisar';
    final notificationBody = switch (privacyMode) {
      NotePrivacyMode.hidden => 'Tienes una nota pendiente en Zentra.',
      NotePrivacyMode.titleOnly => normalizedTitle.isEmpty
          ? 'Tienes una nota pendiente en Zentra.'
          : normalizedTitle,
      NotePrivacyMode.titleAndBody => normalizedBody.isEmpty
          ? 'Tienes una nota pendiente en Zentra.'
          : normalizedBody.length > 120
              ? normalizedBody.substring(0, 120)
              : normalizedBody,
    };
    await _notifications.zonedSchedule(
      notificationId,
      notificationTitle,
      notificationBody,
      scheduledAt,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'note_reminders',
          'Recordatorios de notas',
          channelDescription:
              'Recordatorios para volver a tus notas importantes',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: _reminderCategory,
        ),
      ),
      androidScheduleMode: await _androidScheduleMode(),
      payload: ZentraNotificationIntent.openNote(noteId).encode(),
    );
    return notificationId;
  }

  Future<void> cancelNoteReminder(String noteId) {
    return _notifications.cancel(stableNoteNotificationId(noteId));
  }

  // ============================================================================
  // UTILIDADES
  // ============================================================================

  /// Cancela todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Callback for notification taps
  static void Function(String? payload)? onNotificationTap;

  /// Callback cuando el usuario interactúa con una notificación
  void _onNotificationResponse(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint('Notification tapped');
    }
    onNotificationTap?.call(response.payload);
  }

  /// Obtiene las notificaciones pendientes
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
