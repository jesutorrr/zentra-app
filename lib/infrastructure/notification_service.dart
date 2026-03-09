import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger.dart';

/// Servicio de notificaciones locales
/// Maneja recordatorios de hábitos y notificaciones del Pomodoro
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  // Notification IDs
  static const int _morningReminderId = 1000;
  static const int _eveningReminderId = 1001;
  static const int _pomodoroWorkId = 2000;
  static const int _pomodoroBreakId = 2001;
  static const int _pomodoroCompleteId = 2002;
  static const int _pomodoroAlarmId = 2003; // Separate ID for alarm so it doesn't replace timer
  
  // Preferences keys
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyMorningReminderTime = 'morning_reminder_time';
  static const String _keyMorningReminderMinute = 'morning_reminder_minute';
  static const String _keyEveningReminderTime = 'evening_reminder_time';
  static const String _keyEveningReminderMinute = 'evening_reminder_minute';
  static const String _keyPomodoroNotifications = 'pomodoro_notifications';

  bool _isInitialized = false;

  /// Inicializa el servicio de notificaciones
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      // FlutterTimezone 5.x returns TimezoneInfo object with identifier property
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (e) {
      // Fallback to UTC if timezone detection fails
      debugPrint('Error getting timezone: $e, falling back to UTC');
      tz.setLocalLocation(tz.UTC);
    }

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS settings
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create alarm notification channel for Android
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
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
    final launchDetails = await _notifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails!.notificationResponse?.payload;
      if (payload != null) {
        // Store the payload to be handled after the app is fully initialized
        _pendingNotificationPayload = payload;
      }
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
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  /// Solicita permiso de alarmas exactas (Solo Android 12+)
  Future<bool> requestExactAlarmsPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.requestExactAlarmsPermission() ?? true;
    }
    return true; // No necesario en iOS
  }

  /// Método legacy que solicita TODO (mantenido por compatibilidad si se usa en otros lados)
  Future<bool> requestPermissions() async {
    final notif = await requestNotificationPermission();
    final alarm = await requestExactAlarmsPermission();
    return notif && alarm;
  }
  
  /// Verifica si los permisos de alarmas exactas están concedidos (Android 12+)
  Future<bool> canScheduleExactAlarms() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.canScheduleExactNotifications() ?? false;
    }
    return true; // iOS doesn't need this
  }

  /// Verifica si los permisos de notificación del SISTEMA están concedidos
  Future<bool> isSystemNotificationPermissionGranted() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }
    // En iOS no podemos verificar sin solicitar/prompt, así que asumimos false 
    // para forzar al usuario a tocar el botón y verificar/solicitar.
    return false;
  }

  /// Verifica si las notificaciones están habilitadas en las PREFERENCIAS de la app
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  /// Habilita o deshabilita las notificaciones
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
    
    if (!enabled) {
      await cancelAllNotifications();
    } else {
      await scheduleDailyReminders();
    }
  }

  // ============================================================================
  // RECORDATORIOS DIARIOS DE HÁBITOS
  // ============================================================================

  /// Programa los recordatorios diarios (mañana y tarde)
  Future<void> scheduleDailyReminders() async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    final prefs = await SharedPreferences.getInstance();
    
    // Horario de mañana (default 9:00 AM)
    final morningHour = prefs.getInt(_keyMorningReminderTime) ?? 9;
    final morningMinute = prefs.getInt(_keyMorningReminderMinute) ?? 0;
    
    // Horario de tarde (default 7:00 PM)
    final eveningHour = prefs.getInt(_keyEveningReminderTime) ?? 19;
    final eveningMinute = prefs.getInt(_keyEveningReminderMinute) ?? 0;

    // Cancelar recordatorios anteriores
    await _notifications.cancel(_morningReminderId);
    await _notifications.cancel(_eveningReminderId);

    // Programar recordatorio de mañana
    await _scheduleDailyNotification(
      id: _morningReminderId,
      hour: morningHour,
      minute: morningMinute,
      title: '¡Buenos días!',
      body: 'Es hora de revisar tus hábitos del día. ¡Tú puedes!',
    );

    // Programar recordatorio de tarde
    await _scheduleDailyNotification(
      id: _eveningReminderId,
      hour: eveningHour,
      minute: eveningMinute,
      title: '¡Última llamada!',
      body: '¿Ya completaste tus hábitos de hoy? Aún hay tiempo.',
    );
  }

  /// Programa una notificación diaria recurrente
  Future<void> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final scheduledTime = _nextInstanceOfTime(hour, minute);
    
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminders',
          'Recordatorios de Hábitos',
          channelDescription: 'Recordatorios diarios para completar tus hábitos',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Obtiene la próxima instancia de una hora específica
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  /// Actualiza el horario del recordatorio de mañana
  Future<void> setMorningReminderTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMorningReminderTime, hour);
    await prefs.setInt(_keyMorningReminderMinute, minute);
    await scheduleDailyReminders();
  }

  /// Actualiza el horario del recordatorio de tarde
  Future<void> setEveningReminderTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyEveningReminderTime, hour);
    await prefs.setInt(_keyEveningReminderMinute, minute);
    await scheduleDailyReminders();
  }

  /// Obtiene los horarios actuales de recordatorios
  Future<Map<String, dynamic>> getReminderTimes() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'morningHour': prefs.getInt(_keyMorningReminderTime) ?? 9,
      'morningMinute': prefs.getInt(_keyMorningReminderMinute) ?? 0,
      'eveningHour': prefs.getInt(_keyEveningReminderTime) ?? 19,
      'eveningMinute': prefs.getInt(_keyEveningReminderMinute) ?? 0,
    };
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
  }

  /// Programa notificación cuando termine el tiempo de trabajo
  Future<void> schedulePomodoroWorkEnd({
    required Duration duration,
    required String activityName,
  }) async {
    final enabled = await arePomodoroNotificationsEnabled();
    if (!enabled) return;

    final scheduledTime = tz.TZDateTime.now(tz.local).add(duration);

    await _notifications.zonedSchedule(
      _pomodoroWorkId,
      '¡Tiempo de descanso!',
      'Completaste tu sesión de "$activityName". Tómate un break.',
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
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'pomodoro',
    );
  }

  /// Programa notificación cuando termine el descanso
  Future<void> schedulePomodoroBreakEnd({
    required Duration duration,
    required String activityName,
  }) async {
    final enabled = await arePomodoroNotificationsEnabled();
    if (!enabled) return;

    final scheduledTime = tz.TZDateTime.now(tz.local).add(duration);

    await _notifications.zonedSchedule(
      _pomodoroBreakId,
      '¡Volvamos al trabajo!',
      'Tu descanso terminó. Continúa con "$activityName".',
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
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'pomodoro',
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
      '¡Sesión completada!',
      'Terminaste $cycles ciclos de "$activityName" ($minutes min). ¡Increíble!',
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
        ),
      ),
      payload: 'pomodoro', // Navigate to Pomodoro screen when tapped
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
        ),
      ),
      payload: 'pomodoro', // Navigate to Pomodoro screen when tapped
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
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]), // Vibración fuerte
          fullScreenIntent: true, // Mostrar en pantalla completa incluso si el teléfono está bloqueado
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          autoCancel: false, // Don't auto-dismiss when tapped
          ongoing: false, // Not an ongoing notification, but sticky
          timeoutAfter: null, // Never timeout
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'alarm.aiff', // iOS usará sonido de alarma si existe
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: 'pomodoro',
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
      '🏆 ¡Logro desbloqueado!',
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
        ),
      ),
    );
  }

  // ============================================================================
  // RECORDATORIOS DE HÁBITOS
  // ============================================================================

  /// Programa un recordatorio diario para un hábito
  /// El ID se genera a partir del habitId para poder cancelarlo después
  Future<void> scheduleHabitReminder({
    required String habitId,
    required String habitTitle,
    required int hour,
    required int minute,
    required List<int> daysOfWeek, // 1=Monday, 7=Sunday
  }) async {
    final logger = AppLogger();
    final enabled = await areNotificationsEnabled();
    logger.info('Notifications', 'scheduleHabitReminder: enabled=$enabled, habit=$habitTitle, time=$hour:$minute, days=$daysOfWeek');
    if (!enabled) {
      logger.warning('Notifications', 'Notifications disabled, skipping habit reminder');
      return;
    }

    // Cancelar recordatorios anteriores de este hábito
    await cancelHabitReminder(habitId);

    // Programar para cada día de la semana
    for (final day in daysOfWeek) {
      final notificationId = _getHabitNotificationId(habitId, day);
      
      // Calcular próxima fecha para este día
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // Ajustar al día de la semana correcto
      while (scheduledDate.weekday != day) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Si ya pasó hoy, programar para la próxima semana
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }

      logger.info('Notifications', 'Scheduling notification id=$notificationId for day=$day at $scheduledDate');

      try {
        await _notifications.zonedSchedule(
          notificationId,
          'Recordatorio',
          habitTitle,
          scheduledDate,
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
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: 'habit:$habitId',
        );
        logger.info('Notifications', 'Habit reminder scheduled successfully for day $day');
      } catch (e, stack) {
        logger.error('Notifications', 'Error scheduling habit reminder', e, stack);
      }
    }
    
    // Verificar notificaciones pendientes
    final pending = await getPendingNotifications();
    logger.info('Notifications', 'Total pending notifications: ${pending.length}');
  }

  /// Cancela los recordatorios de un hábito
  Future<void> cancelHabitReminder(String habitId) async {
    // Cancelar para todos los días de la semana (1-7)
    for (int day = 1; day <= 7; day++) {
      final notificationId = _getHabitNotificationId(habitId, day);
      await _notifications.cancel(notificationId);
    }
  }

  /// Genera un ID único para la notificación de un hábito en un día específico
  int _getHabitNotificationId(String habitId, int dayOfWeek) {
    // Usar hash del habitId + día para generar ID único
    return (habitId.hashCode.abs() % 100000) * 10 + dayOfWeek;
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
    debugPrint('Notification tapped: ${response.payload}');
    onNotificationTap?.call(response.payload);
  }

  /// Obtiene las notificaciones pendientes
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
