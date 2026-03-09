// Script para generar datos de prueba para la app de hábitos
// Ejecutar con: dart run tool/generate_test_data.dart
// Genera un archivo JSON que se puede importar desde la app

import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() {
  final now = DateTime.now();
  final random = Random(42); // Seed fijo para reproducibilidad
  
  print('='.padRight(60, '='));
  print('GENERADOR DE DATOS DE PRUEBA - Habit Tracker');
  print('='.padRight(60, '='));
  print('Fecha base: ${now.toIso8601String().substring(0, 10)}');
  print('');
  
  // Generar datos
  final habits = _generateHabits(now);
  final logs = _generateHabitLogs(habits, now, random);
  final user = _generateUser(now);
  final profile = _generateProfile(now, random);
  
  // Generar datos de Pomodoro
  final pomodoroActivities = _generatePomodoroActivities(now, random);
  final completedTasks = _generateCompletedTasks(now, random);
  final totalPomodoros = pomodoroActivities.fold<int>(0, (sum, a) => sum + (a['cyclesCompleted'] as int));
  final todayPomodoros = pomodoroActivities
    .where((a) => (a['startTime'] as String).startsWith(now.toIso8601String().substring(0, 10)))
    .fold<int>(0, (sum, a) => sum + (a['cyclesCompleted'] as int));
  
  // Crear el backup en el formato que usa la app (versión 2 incluye Pomodoro)
  final backup = {
    'user': user,
    'profile': profile,
    'habits': habits,
    'logs': logs,
    'pomodoroActivities': pomodoroActivities,
    'completedTasks': completedTasks,
    'pomodoroStats': {
      'total': totalPomodoros,
      'today': todayPomodoros,
      'firstDate': now.subtract(const Duration(days: 6)).toIso8601String(),
      'lastDate': now.toIso8601String(),
    },
    'exportedAt': now.toIso8601String(),
    'appVersion': '1.0.0',
    'backupVersion': 2,
  };
  
  final backupJson = const JsonEncoder.withIndent('  ').convert(backup);
  
  // Guardar el archivo en el escritorio
  final desktop = '${Platform.environment['HOME']}/Desktop';
  final file = File('$desktop/test_backup.json');
  file.writeAsStringSync(backupJson);
  
  print('✅ Archivo generado: ~/Desktop/test_backup.json');
  print('');
  print('📋 Resumen de datos:');
  print('   • ${habits.length} hábitos (${habits.where((h) => h['isArchived'] == false).length} activos)');
  print('   • ${logs.length} logs de completados');
  print('   • ${pomodoroActivities.length} actividades Pomodoro');
  print('   • ${completedTasks.length} tareas completadas en historial');
  print('   • $totalPomodoros pomodoros totales');
  print('   • Usuario: ${user['username']}');
  print('');
  print('📱 Para importar:');
  print('   1. Abre la app en el navegador');
  print('   2. Ve a Perfil → Respaldo → Importar');
  print('   3. Selecciona el archivo: ~/Desktop/test_backup.json');
  print('');
}

/// Genera un usuario de prueba
Map<String, dynamic> _generateUser(DateTime now) {
  // Password: 123456 -> SHA256
  // echo -n "123456" | shasum -a 256
  return {
    'id': 'test_user_001',
    'username': 'Usuario Demo',
    'email': 'demo@demo.com',
    'passwordHash': '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', // "123456"
    'avatarEmoji': '🚀',
    'createdAt': now.subtract(const Duration(days: 90)).toIso8601String(), // 3 meses
    'lastLogin': now.toIso8601String(),
  };
}

/// Genera un perfil de usuario compatible con UserProfile
Map<String, dynamic> _generateProfile(DateTime now, Random random) {
  return {
    'id': 'profile_demo_001',
    'name': 'Usuario Demo',
    'avatarEmoji': '🚀',
    'createdAt': now.subtract(const Duration(days: 90)).toIso8601String(), // 3 meses
    'totalHabitsCompleted': 450 + random.nextInt(100),
    'totalDaysActive': 75 + random.nextInt(10),
    'longestStreak': 28,
    'currentLevel': 7,
    'unlockedAchievements': [
      'first_habit',
      'week_streak', 
      'two_week_streak',
      'month_streak',
      'early_bird',
      'night_owl',
      'perfect_day',
      'perfect_week',
      'hydration_master',
      'fitness_enthusiast',
      'zen_master',
      'sleep_champion',
      'habit_collector',
      'consistency_king',
      'pomodoro_starter',
      'pomodoro_pro',
    ],
  };
}

/// Genera hábitos de ejemplo
List<Map<String, dynamic>> _generateHabits(DateTime now) {
  final baseDate = now.subtract(const Duration(days: 60));
  
  return [
    // === AGUA ===
    {
      'id': 'h1',
      'title': 'Beber 8 vasos de agua',
      'category': 'agua',
      'frequency': {'isWeekly': true, 'daysOfWeek': [1, 2, 3, 4, 5, 6, 7]},
      'createdAt': baseDate.toIso8601String(),
      'isArchived': false,
      'isOneTime': false,
    },
    {
      'id': 'h2',
      'title': 'Tomar té verde',
      'category': 'agua',
      'frequency': {'isWeekly': true, 'daysOfWeek': [1, 2, 3, 4, 5]},
      'createdAt': baseDate.subtract(const Duration(days: 10)).toIso8601String(),
      'isArchived': false,
      'isOneTime': false,
    },
    // === MOVIMIENTO ===
    {
      'id': 'h3',
      'title': 'Caminar 30 minutos',
      'category': 'movimiento',
      'frequency': {'isWeekly': true, 'daysOfWeek': [1, 2, 3, 4, 5, 6, 7]},
      'createdAt': baseDate.toIso8601String(),
      'isArchived': false,
      'isOneTime': false,
    },
    {
      'id': 'h4',
      'title': 'Estiramientos matutinos',
      'category': 'movimiento',
      'frequency': {'isWeekly': true, 'daysOfWeek': [1, 2, 3, 4, 5]},
      'createdAt': baseDate.subtract(const Duration(days: 5)).toIso8601String(),
      'isArchived': false,
      'isOneTime': false,
    },
    {
      'id': 'h5',
      'title': 'Hacer 20 sentadillas',
      'category': 'movimiento',
      'frequency': {'isWeekly': true, 'daysOfWeek': [1, 3, 5]},
      'createdAt': baseDate.subtract(const Duration(days: 15)).toIso8601String(),
      'isArchived': false,
      'isOneTime': false,
    },
    {
      'id': 'h6',
      'title': 'Yoga 15 minutos',
      'category': 'movimiento',
      'frequency': {'isWeekly': true, 'daysOfWeek': [6, 7]},
      'createdAt': baseDate.subtract(const Duration(days: 20)).toIso8601String(),
      'isArchived': false,
      'isOneTime': false,
    },
    // === SUEÑO ===
    {
      'id': 'h7',
      'title': 'Dormir antes de las 11pm',
      'category': 'sueno',
      'frequency': {'isWeekly': true, 'daysOfWeek': [1, 2, 3, 4, 5]},
      'createdAt': baseDate.toIso8601String(),
      'isArchived': false,
      'isOneTime': false,
    },
    {
      'id': 'h8',
      'title': 'Sin pantallas 1h antes de dormir',
      'category': 'sueno',
      'frequency': {'isWeekly': true, 'daysOfWeek': [1, 2, 3, 4, 5, 6, 7]},
      'createdAt': baseDate.subtract(const Duration(days: 8)).toIso8601String(),
      'isArchived': false,
      'isOneTime': false,
    },
    {
      'id': 'h9',
      'title': 'Despertar a las 7am',
      'category': 'sueno',
      'frequency': {'isWeekly': true, 'daysOfWeek': [1, 2, 3, 4, 5]},
      'createdAt': baseDate.subtract(const Duration(days: 12)).toIso8601String(),
      'isArchived': false,
      'isOneTime': false,
    },
    // === ENFOQUE ===
    {
      'id': 'h10',
      'title': 'Meditar 10 minutos',
      'category': 'foco',
      'frequency': {'isWeekly': true, 'daysOfWeek': [1, 2, 3, 4, 5, 6, 7]},
      'createdAt': baseDate.toIso8601String(),
      'isArchived': false,
      'isOneTime': false,
    },
    {
      'id': 'h11',
      'title': 'Leer 20 páginas',
      'category': 'foco',
      'frequency': {'isWeekly': true, 'daysOfWeek': [1, 2, 3, 4, 5, 6, 7]},
      'createdAt': baseDate.toIso8601String(),
      'isArchived': false,
      'isOneTime': false,
    },
    {
      'id': 'h12',
      'title': 'Escribir en diario',
      'category': 'foco',
      'frequency': {'isWeekly': true, 'daysOfWeek': [1, 2, 3, 4, 5, 6, 7]},
      'createdAt': baseDate.subtract(const Duration(days: 25)).toIso8601String(),
      'isArchived': false,
      'isOneTime': false,
    },
    {
      'id': 'h13',
      'title': 'Practicar idioma 15min',
      'category': 'foco',
      'frequency': {'isWeekly': true, 'daysOfWeek': [1, 2, 3, 4, 5]},
      'createdAt': baseDate.subtract(const Duration(days: 30)).toIso8601String(),
      'isArchived': false,
      'isOneTime': false,
    },
    // === VARIOS ===
    {
      'id': 'h14',
      'title': 'Revisar finanzas',
      'category': 'varios',
      'frequency': {'isWeekly': true, 'daysOfWeek': [7]},
      'createdAt': baseDate.toIso8601String(),
      'isArchived': false,
      'isOneTime': false,
    },
    {
      'id': 'h15',
      'title': 'Llamar a familia',
      'category': 'varios',
      'frequency': {'isWeekly': true, 'daysOfWeek': [6, 7]},
      'createdAt': baseDate.subtract(const Duration(days: 18)).toIso8601String(),
      'isArchived': false,
      'isOneTime': false,
    },
    {
      'id': 'h16',
      'title': 'Ordenar escritorio',
      'category': 'varios',
      'frequency': {'isWeekly': true, 'daysOfWeek': [5]},
      'createdAt': baseDate.subtract(const Duration(days: 22)).toIso8601String(),
      'isArchived': false,
      'isOneTime': false,
    },
    // === ARCHIVADOS ===
    {
      'id': 'h17',
      'title': 'Correr 5km',
      'category': 'movimiento',
      'frequency': {'isWeekly': true, 'daysOfWeek': [1, 3, 5]},
      'createdAt': baseDate.subtract(const Duration(days: 45)).toIso8601String(),
      'isArchived': true,
      'isOneTime': false,
    },
    {
      'id': 'h18',
      'title': 'Tomar vitaminas',
      'category': 'agua',
      'frequency': {'isWeekly': true, 'daysOfWeek': [1, 2, 3, 4, 5, 6, 7]},
      'createdAt': baseDate.subtract(const Duration(days: 50)).toIso8601String(),
      'isArchived': true,
      'isOneTime': false,
    },
  ];
}

/// Genera logs de hábitos para los últimos 30 días
List<Map<String, dynamic>> _generateHabitLogs(
  List<Map<String, dynamic>> habits, 
  DateTime now, 
  Random random,
) {
  final logs = <Map<String, dynamic>>[];
  final activeHabits = habits.where((h) => h['isArchived'] == false).toList();
  
  // Generar logs para los últimos 30 días
  for (int dayOffset = 29; dayOffset >= 0; dayOffset--) {
    final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: dayOffset));
    final dateStr = date.toIso8601String();
    
    for (final habit in activeHabits) {
      final frequency = habit['frequency'] as Map<String, dynamic>;
      final daysOfWeek = (frequency['daysOfWeek'] as List).cast<int>();
      
      // Verificar si el hábito aplica para este día
      if (!daysOfWeek.contains(date.weekday)) continue;
      
      // Verificar si el hábito existía en esa fecha
      final habitCreatedAt = DateTime.parse(habit['createdAt'] as String);
      if (date.isBefore(habitCreatedAt)) continue;
      
      // Probabilidad de completar: más alta en días recientes, con variación
      double completionChance;
      if (dayOffset <= 7) {
        // Última semana: 75-95%
        completionChance = 0.75 + (7 - dayOffset) * 0.03;
      } else if (dayOffset <= 14) {
        // Segunda semana: 65-80%
        completionChance = 0.65 + random.nextDouble() * 0.15;
      } else {
        // Semanas anteriores: 50-70%
        completionChance = 0.50 + random.nextDouble() * 0.20;
      }
      
      // Simular días "malos" ocasionales
      if (random.nextDouble() < 0.1) {
        completionChance *= 0.3; // 10% de días con baja motivación
      }
      
      if (random.nextDouble() < completionChance) {
        logs.add({
          'habitId': habit['id'],
          'date': dateStr,
        });
      }
    }
  }
  
  return logs;
}

/// Genera actividades Pomodoro para los últimos 7 días
List<Map<String, dynamic>> _generatePomodoroActivities(DateTime now, Random random) {
  final activities = <Map<String, dynamic>>[];
  
  final activityNames = [
    'Estudiar Flutter',
    'Proyecto personal',
    'Curso de inglés',
    'Preparar presentación',
    'Revisar código',
    'Diseño de UI',
    'Documentación',
    'Planificación semanal',
    'Investigación',
    'Desarrollo de features',
    'Testing',
    'Refactorización',
    'Aprender Dart',
    'Leer artículos técnicos',
    'Práctica de algoritmos',
  ];
  
  int idCounter = 1;
  
  for (int dayOffset = 6; dayOffset >= 0; dayOffset--) {
    final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: dayOffset));
    
    // Generar entre 1-4 actividades por día
    final activitiesPerDay = 1 + random.nextInt(4);
    
    for (int i = 0; i < activitiesPerDay; i++) {
      // Hora de inicio aleatoria entre 8:00 y 20:00
      final startHour = 8 + random.nextInt(12);
      final startMinute = random.nextInt(60);
      final startTime = DateTime(date.year, date.month, date.day, startHour, startMinute);
      
      // Ciclos completados (1-4)
      final cycles = 1 + random.nextInt(4);
      final totalMinutes = cycles * 25;
      
      // Tiempo de fin = inicio + (ciclos * 25min) + descansos
      final endTime = startTime.add(Duration(minutes: totalMinutes + (cycles - 1) * 5));
      
      activities.add({
        'id': 'pom_${idCounter++}',
        'name': activityNames[random.nextInt(activityNames.length)],
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'cyclesCompleted': cycles,
        'totalMinutes': totalMinutes,
        'isCompleted': true,
      });
    }
  }
  
  // Ordenar por fecha descendente (más recientes primero)
  activities.sort((a, b) => 
    (b['startTime'] as String).compareTo(a['startTime'] as String),);
  
  return activities;
}

/// Genera historial de tareas completadas/eliminadas
List<Map<String, dynamic>> _generateCompletedTasks(DateTime now, Random random) {
  final tasks = <Map<String, dynamic>>[];
  
  final taskTitles = [
    {'title': 'Enviar reporte mensual', 'category': 'foco', 'wasOneTime': true},
    {'title': 'Llamar al doctor', 'category': 'varios', 'wasOneTime': true},
    {'title': 'Comprar regalo de cumpleaños', 'category': 'varios', 'wasOneTime': true},
    {'title': 'Hacer ejercicio intenso', 'category': 'movimiento', 'wasOneTime': false},
    {'title': 'Tomar vitaminas', 'category': 'agua', 'wasOneTime': false},
    {'title': 'Revisar correos', 'category': 'foco', 'wasOneTime': true},
    {'title': 'Pagar servicios', 'category': 'varios', 'wasOneTime': true},
    {'title': 'Preparar comida de la semana', 'category': 'varios', 'wasOneTime': true},
    {'title': 'Actualizar CV', 'category': 'foco', 'wasOneTime': true},
    {'title': 'Yoga matutino', 'category': 'movimiento', 'wasOneTime': false},
  ];
  
  int idCounter = 1;
  
  // Generar entre 5-10 tareas en el historial
  final numTasks = 5 + random.nextInt(6);
  final selectedTasks = List<Map<String, dynamic>>.from(taskTitles)..shuffle(random);
  
  for (int i = 0; i < numTasks && i < selectedTasks.length; i++) {
    final task = selectedTasks[i];
    final daysAgo = random.nextInt(14); // Últimos 14 días
    final completedAt = now.subtract(Duration(days: daysAgo, hours: random.nextInt(12)));
    
    tasks.add({
      'id': 'ct_${idCounter++}',
      'title': task['title'],
      'category': task['category'],
      'completedAt': completedAt.toIso8601String(),
      'wasOneTime': task['wasOneTime'],
    });
  }
  
  // Ordenar por fecha descendente
  tasks.sort((a, b) => 
    (b['completedAt'] as String).compareTo(a['completedAt'] as String),);
  
  return tasks;
}
