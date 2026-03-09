/// Model for a Pomodoro Activity session
class PomodoroActivity {
  final String id;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final int cyclesCompleted; // How many pomodoro cycles (max 4)
  final int totalMinutes; // Total focus time in minutes
  final bool isCompleted;

  PomodoroActivity({
    required this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    this.cyclesCompleted = 0,
    this.totalMinutes = 0,
    this.isCompleted = false,
  });

  PomodoroActivity copyWith({
    String? id,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    int? cyclesCompleted,
    int? totalMinutes,
    bool? isCompleted,
  }) {
    return PomodoroActivity(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      cyclesCompleted: cyclesCompleted ?? this.cyclesCompleted,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'cyclesCompleted': cyclesCompleted,
      'totalMinutes': totalMinutes,
      'isCompleted': isCompleted,
    };
  }

  factory PomodoroActivity.fromJson(Map<String, dynamic> json) {
    return PomodoroActivity(
      id: json['id'] as String,
      name: json['name'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null 
          ? DateTime.parse(json['endTime'] as String) 
          : null,
      cyclesCompleted: json['cyclesCompleted'] as int? ?? 0,
      totalMinutes: json['totalMinutes'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  /// Format start time as HH:mm
  String get formattedStartTime {
    return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  }

  /// Format end time as HH:mm
  String get formattedEndTime {
    if (endTime == null) return '--:--';
    return '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}';
  }

  /// Get duration string
  String get durationString {
    if (totalMinutes < 60) {
      return '$totalMinutes min';
    }
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    return '${hours}h ${mins}m';
  }

  /// Get the date only (no time) for grouping
  DateTime get dateOnly => DateTime(startTime.year, startTime.month, startTime.day);
}

/// Daily summary of pomodoro activities
class DailyPomodoroSummary {
  final DateTime date;
  final List<PomodoroActivity> activities;

  DailyPomodoroSummary({
    required this.date,
    required this.activities,
  });

  int get totalActivities => activities.length;
  int get completedActivities => activities.where((a) => a.isCompleted).length;
  int get totalCycles => activities.fold(0, (sum, a) => sum + a.cyclesCompleted);
  int get totalMinutes => activities.fold(0, (sum, a) => sum + a.totalMinutes);

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Hoy';
    if (dateOnly == yesterday) return 'Ayer';

    final weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 
                    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',];
    
    return '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
  }
}
