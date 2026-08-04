const Object _noteUnset = Object();

/// Lifecycle of the single active reminder associated with a note.
enum NoteReminderStatus {
  scheduled,
  delivered,
  snoozed,
  completed,
  cancelled,
  failed;

  static NoteReminderStatus fromStorage(String value) {
    return NoteReminderStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => NoteReminderStatus.failed,
    );
  }
}

/// Controls how much note content may appear outside the unlocked app.
enum NotePrivacyMode {
  titleAndBody,
  titleOnly,
  hidden;

  static NotePrivacyMode fromStorage(String value) {
    return NotePrivacyMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => NotePrivacyMode.hidden,
    );
  }
}

/// Meaning of one review event in the note history.
enum NoteReviewOutcome {
  reviewed,
  focusCompleted,
  focusInterrupted;

  static NoteReviewOutcome fromStorage(String value) {
    return NoteReviewOutcome.values.firstWhere(
      (outcome) => outcome.name == value,
      orElse: () => NoteReviewOutcome.reviewed,
    );
  }
}

/// A local-first active note owned by exactly one Zentra user.
class Note {
  final String id;
  final String userId;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? category;
  final String accentKey;
  final bool isPinned;
  final bool isArchived;
  final DateTime? archivedAt;
  final int formatVersion;
  final List<String> tags;

  Note({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required DateTime createdAt,
    required DateTime updatedAt,
    required this.accentKey,
    this.category,
    this.isPinned = false,
    this.isArchived = false,
    DateTime? archivedAt,
    this.formatVersion = 1,
    List<String> tags = const [],
  })  : createdAt = createdAt.toUtc(),
        updatedAt = updatedAt.toUtc(),
        archivedAt = archivedAt?.toUtc(),
        tags = List.unmodifiable(normalizeNoteTags(tags));

  Note copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? category = _noteUnset,
    String? accentKey,
    bool? isPinned,
    bool? isArchived,
    Object? archivedAt = _noteUnset,
    int? formatVersion,
    List<String>? tags,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category:
          identical(category, _noteUnset) ? this.category : category as String?,
      accentKey: accentKey ?? this.accentKey,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: identical(archivedAt, _noteUnset)
          ? this.archivedAt
          : archivedAt as DateTime?,
      formatVersion: formatVersion ?? this.formatVersion,
      tags: tags ?? this.tags,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'category': category,
        'accentKey': accentKey,
        'isPinned': isPinned,
        'isArchived': isArchived,
        'archivedAt': archivedAt?.toIso8601String(),
        'formatVersion': formatVersion,
        'tags': tags,
      };

  factory Note.fromJson(Map<String, Object?> json) {
    return Note(
      id: json['id']! as String,
      userId: json['userId']! as String,
      title: json['title']! as String,
      body: json['body']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
      updatedAt: DateTime.parse(json['updatedAt']! as String),
      category: json['category'] as String?,
      accentKey: json['accentKey']! as String,
      isPinned: json['isPinned'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      archivedAt: _dateTimeOrNull(json['archivedAt']),
      formatVersion: json['formatVersion'] as int? ?? 1,
      tags: (json['tags'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }
}

/// The scheduling record for a note. There may be only one per [noteId].
class NoteReminder {
  final String id;
  final String noteId;
  final String userId;
  final DateTime scheduledAtUtc;
  final String timezoneName;
  final NoteReminderStatus status;
  final int notificationId;
  final NotePrivacyMode privacyMode;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteReminder({
    required this.id,
    required this.noteId,
    required this.userId,
    required DateTime scheduledAtUtc,
    required this.timezoneName,
    required this.status,
    required this.notificationId,
    required this.privacyMode,
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : scheduledAtUtc = scheduledAtUtc.toUtc(),
        createdAt = createdAt.toUtc(),
        updatedAt = updatedAt.toUtc();

  NoteReminder copyWith({
    String? id,
    String? noteId,
    String? userId,
    DateTime? scheduledAtUtc,
    String? timezoneName,
    NoteReminderStatus? status,
    int? notificationId,
    NotePrivacyMode? privacyMode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteReminder(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      userId: userId ?? this.userId,
      scheduledAtUtc: scheduledAtUtc ?? this.scheduledAtUtc,
      timezoneName: timezoneName ?? this.timezoneName,
      status: status ?? this.status,
      notificationId: notificationId ?? this.notificationId,
      privacyMode: privacyMode ?? this.privacyMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'noteId': noteId,
        'userId': userId,
        'scheduledAtUtc': scheduledAtUtc.toIso8601String(),
        'timezoneName': timezoneName,
        'status': status.name,
        'notificationId': notificationId,
        'privacyMode': privacyMode.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory NoteReminder.fromJson(Map<String, Object?> json) {
    return NoteReminder(
      id: json['id']! as String,
      noteId: json['noteId']! as String,
      userId: json['userId']! as String,
      scheduledAtUtc: DateTime.parse(json['scheduledAtUtc']! as String),
      timezoneName: json['timezoneName']! as String,
      status: NoteReminderStatus.fromStorage(json['status']! as String),
      notificationId: json['notificationId']! as int,
      privacyMode: NotePrivacyMode.fromStorage(
        json['privacyMode']! as String,
      ),
      createdAt: DateTime.parse(json['createdAt']! as String),
      updatedAt: DateTime.parse(json['updatedAt']! as String),
    );
  }
}

/// One meaningful review of a note, optionally backed by a focus session.
class NoteReview {
  final String id;
  final String noteId;
  final String userId;
  final DateTime reviewedAt;
  final String? focusSessionId;
  final NoteReviewOutcome outcome;

  NoteReview({
    required this.id,
    required this.noteId,
    required this.userId,
    required DateTime reviewedAt,
    required this.outcome,
    this.focusSessionId,
  }) : reviewedAt = reviewedAt.toUtc();

  NoteReview copyWith({
    String? id,
    String? noteId,
    String? userId,
    DateTime? reviewedAt,
    Object? focusSessionId = _noteUnset,
    NoteReviewOutcome? outcome,
  }) {
    return NoteReview(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      userId: userId ?? this.userId,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      focusSessionId: identical(focusSessionId, _noteUnset)
          ? this.focusSessionId
          : focusSessionId as String?,
      outcome: outcome ?? this.outcome,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'noteId': noteId,
        'userId': userId,
        'reviewedAt': reviewedAt.toIso8601String(),
        'focusSessionId': focusSessionId,
        'outcome': outcome.name,
      };

  factory NoteReview.fromJson(Map<String, Object?> json) {
    return NoteReview(
      id: json['id']! as String,
      noteId: json['noteId']! as String,
      userId: json['userId']! as String,
      reviewedAt: DateTime.parse(json['reviewedAt']! as String),
      focusSessionId: json['focusSessionId'] as String?,
      outcome: NoteReviewOutcome.fromStorage(json['outcome']! as String),
    );
  }
}

/// Versioned owner snapshot used by backup and restore orchestration.
class NoteOwnerSnapshot {
  final int schemaVersion;
  final String ownerId;
  final DateTime exportedAt;
  final List<Note> notes;
  final List<NoteReminder> reminders;
  final List<NoteReview> reviews;

  NoteOwnerSnapshot({
    required this.ownerId,
    required DateTime exportedAt,
    required List<Note> notes,
    required List<NoteReminder> reminders,
    required List<NoteReview> reviews,
    this.schemaVersion = 1,
  })  : exportedAt = exportedAt.toUtc(),
        notes = List.unmodifiable(notes),
        reminders = List.unmodifiable(reminders),
        reviews = List.unmodifiable(reviews);

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'ownerId': ownerId,
        'exportedAt': exportedAt.toIso8601String(),
        'notes': notes.map((note) => note.toJson()).toList(),
        'reminders': reminders.map((reminder) => reminder.toJson()).toList(),
        'reviews': reviews.map((review) => review.toJson()).toList(),
      };

  factory NoteOwnerSnapshot.fromJson(Map<String, Object?> json) {
    return NoteOwnerSnapshot(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      ownerId: json['ownerId']! as String,
      exportedAt: DateTime.parse(json['exportedAt']! as String),
      notes: _mapJsonList(json['notes'], Note.fromJson),
      reminders: _mapJsonList(json['reminders'], NoteReminder.fromJson),
      reviews: _mapJsonList(json['reviews'], NoteReview.fromJson),
    );
  }
}

/// Produces stable, case-insensitive tags while preserving accents for display.
List<String> normalizeNoteTags(Iterable<String> tags) {
  final normalized = <String>{};
  for (final tag in tags) {
    final value = tag.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    if (value.isNotEmpty) normalized.add(value);
  }
  final result = normalized.toList()..sort();
  return result;
}

DateTime? _dateTimeOrNull(Object? value) {
  return value is String && value.isNotEmpty ? DateTime.parse(value) : null;
}

List<T> _mapJsonList<T>(
  Object? value,
  T Function(Map<String, Object?> json) fromJson,
) {
  return (value as List<Object?>? ?? const [])
      .whereType<Map>()
      .map((entry) => fromJson(entry.cast<String, Object?>()))
      .toList();
}
