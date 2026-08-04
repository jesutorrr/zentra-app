// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zentra_database.dart';

// ignore_for_file: type=lint
class $NoteEntriesTable extends NoteEntries
    with TableInfo<$NoteEntriesTable, NoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoteEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _accentKeyMeta =
      const VerificationMeta('accentKey');
  @override
  late final GeneratedColumn<String> accentKey = GeneratedColumn<String>(
      'accent_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isPinnedMeta =
      const VerificationMeta('isPinned');
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
      'is_pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_pinned" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _archivedAtMeta =
      const VerificationMeta('archivedAt');
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
      'archived_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _formatVersionMeta =
      const VerificationMeta('formatVersion');
  @override
  late final GeneratedColumn<int> formatVersion = GeneratedColumn<int>(
      'format_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _serverRevisionMeta =
      const VerificationMeta('serverRevision');
  @override
  late final GeneratedColumn<int> serverRevision = GeneratedColumn<int>(
      'server_revision', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        title,
        body,
        createdAt,
        updatedAt,
        category,
        accentKey,
        isPinned,
        isArchived,
        archivedAt,
        deletedAt,
        formatVersion,
        version,
        serverRevision
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(Insertable<NoteRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('accent_key')) {
      context.handle(_accentKeyMeta,
          accentKey.isAcceptableOrUnknown(data['accent_key']!, _accentKeyMeta));
    } else if (isInserting) {
      context.missing(_accentKeyMeta);
    }
    if (data.containsKey('is_pinned')) {
      context.handle(_isPinnedMeta,
          isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('archived_at')) {
      context.handle(
          _archivedAtMeta,
          archivedAt.isAcceptableOrUnknown(
              data['archived_at']!, _archivedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('format_version')) {
      context.handle(
          _formatVersionMeta,
          formatVersion.isAcceptableOrUnknown(
              data['format_version']!, _formatVersionMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('server_revision')) {
      context.handle(
          _serverRevisionMeta,
          serverRevision.isAcceptableOrUnknown(
              data['server_revision']!, _serverRevisionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      accentKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}accent_key'])!,
      isPinned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_pinned'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      archivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}archived_at']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      formatVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}format_version'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      serverRevision: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_revision'])!,
    );
  }

  @override
  $NoteEntriesTable createAlias(String alias) {
    return $NoteEntriesTable(attachedDatabase, alias);
  }
}

class NoteRow extends DataClass implements Insertable<NoteRow> {
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
  final DateTime? deletedAt;
  final int formatVersion;
  final int version;
  final int serverRevision;
  const NoteRow(
      {required this.id,
      required this.userId,
      required this.title,
      required this.body,
      required this.createdAt,
      required this.updatedAt,
      this.category,
      required this.accentKey,
      required this.isPinned,
      required this.isArchived,
      this.archivedAt,
      this.deletedAt,
      required this.formatVersion,
      required this.version,
      required this.serverRevision});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['accent_key'] = Variable<String>(accentKey);
    map['is_pinned'] = Variable<bool>(isPinned);
    map['is_archived'] = Variable<bool>(isArchived);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['format_version'] = Variable<int>(formatVersion);
    map['version'] = Variable<int>(version);
    map['server_revision'] = Variable<int>(serverRevision);
    return map;
  }

  NoteEntriesCompanion toCompanion(bool nullToAbsent) {
    return NoteEntriesCompanion(
      id: Value(id),
      userId: Value(userId),
      title: Value(title),
      body: Value(body),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      accentKey: Value(accentKey),
      isPinned: Value(isPinned),
      isArchived: Value(isArchived),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      formatVersion: Value(formatVersion),
      version: Value(version),
      serverRevision: Value(serverRevision),
    );
  }

  factory NoteRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      category: serializer.fromJson<String?>(json['category']),
      accentKey: serializer.fromJson<String>(json['accentKey']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      formatVersion: serializer.fromJson<int>(json['formatVersion']),
      version: serializer.fromJson<int>(json['version']),
      serverRevision: serializer.fromJson<int>(json['serverRevision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'category': serializer.toJson<String?>(category),
      'accentKey': serializer.toJson<String>(accentKey),
      'isPinned': serializer.toJson<bool>(isPinned),
      'isArchived': serializer.toJson<bool>(isArchived),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'formatVersion': serializer.toJson<int>(formatVersion),
      'version': serializer.toJson<int>(version),
      'serverRevision': serializer.toJson<int>(serverRevision),
    };
  }

  NoteRow copyWith(
          {String? id,
          String? userId,
          String? title,
          String? body,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<String?> category = const Value.absent(),
          String? accentKey,
          bool? isPinned,
          bool? isArchived,
          Value<DateTime?> archivedAt = const Value.absent(),
          Value<DateTime?> deletedAt = const Value.absent(),
          int? formatVersion,
          int? version,
          int? serverRevision}) =>
      NoteRow(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        body: body ?? this.body,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        category: category.present ? category.value : this.category,
        accentKey: accentKey ?? this.accentKey,
        isPinned: isPinned ?? this.isPinned,
        isArchived: isArchived ?? this.isArchived,
        archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        formatVersion: formatVersion ?? this.formatVersion,
        version: version ?? this.version,
        serverRevision: serverRevision ?? this.serverRevision,
      );
  NoteRow copyWithCompanion(NoteEntriesCompanion data) {
    return NoteRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      category: data.category.present ? data.category.value : this.category,
      accentKey: data.accentKey.present ? data.accentKey.value : this.accentKey,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      archivedAt:
          data.archivedAt.present ? data.archivedAt.value : this.archivedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      formatVersion: data.formatVersion.present
          ? data.formatVersion.value
          : this.formatVersion,
      version: data.version.present ? data.version.value : this.version,
      serverRevision: data.serverRevision.present
          ? data.serverRevision.value
          : this.serverRevision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('category: $category, ')
          ..write('accentKey: $accentKey, ')
          ..write('isPinned: $isPinned, ')
          ..write('isArchived: $isArchived, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('formatVersion: $formatVersion, ')
          ..write('version: $version, ')
          ..write('serverRevision: $serverRevision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      title,
      body,
      createdAt,
      updatedAt,
      category,
      accentKey,
      isPinned,
      isArchived,
      archivedAt,
      deletedAt,
      formatVersion,
      version,
      serverRevision);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.body == this.body &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.category == this.category &&
          other.accentKey == this.accentKey &&
          other.isPinned == this.isPinned &&
          other.isArchived == this.isArchived &&
          other.archivedAt == this.archivedAt &&
          other.deletedAt == this.deletedAt &&
          other.formatVersion == this.formatVersion &&
          other.version == this.version &&
          other.serverRevision == this.serverRevision);
}

class NoteEntriesCompanion extends UpdateCompanion<NoteRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> title;
  final Value<String> body;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> category;
  final Value<String> accentKey;
  final Value<bool> isPinned;
  final Value<bool> isArchived;
  final Value<DateTime?> archivedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> formatVersion;
  final Value<int> version;
  final Value<int> serverRevision;
  final Value<int> rowid;
  const NoteEntriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.category = const Value.absent(),
    this.accentKey = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.formatVersion = const Value.absent(),
    this.version = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NoteEntriesCompanion.insert({
    required String id,
    required String userId,
    required String title,
    required String body,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.category = const Value.absent(),
    required String accentKey,
    this.isPinned = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.formatVersion = const Value.absent(),
    this.version = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        title = Value(title),
        body = Value(body),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        accentKey = Value(accentKey);
  static Insertable<NoteRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<String>? body,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? category,
    Expression<String>? accentKey,
    Expression<bool>? isPinned,
    Expression<bool>? isArchived,
    Expression<DateTime>? archivedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? formatVersion,
    Expression<int>? version,
    Expression<int>? serverRevision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (category != null) 'category': category,
      if (accentKey != null) 'accent_key': accentKey,
      if (isPinned != null) 'is_pinned': isPinned,
      if (isArchived != null) 'is_archived': isArchived,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (formatVersion != null) 'format_version': formatVersion,
      if (version != null) 'version': version,
      if (serverRevision != null) 'server_revision': serverRevision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NoteEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? title,
      Value<String>? body,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<String?>? category,
      Value<String>? accentKey,
      Value<bool>? isPinned,
      Value<bool>? isArchived,
      Value<DateTime?>? archivedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? formatVersion,
      Value<int>? version,
      Value<int>? serverRevision,
      Value<int>? rowid}) {
    return NoteEntriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      accentKey: accentKey ?? this.accentKey,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      formatVersion: formatVersion ?? this.formatVersion,
      version: version ?? this.version,
      serverRevision: serverRevision ?? this.serverRevision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (accentKey.present) {
      map['accent_key'] = Variable<String>(accentKey.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (formatVersion.present) {
      map['format_version'] = Variable<int>(formatVersion.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (serverRevision.present) {
      map['server_revision'] = Variable<int>(serverRevision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteEntriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('category: $category, ')
          ..write('accentKey: $accentKey, ')
          ..write('isPinned: $isPinned, ')
          ..write('isArchived: $isArchived, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('formatVersion: $formatVersion, ')
          ..write('version: $version, ')
          ..write('serverRevision: $serverRevision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NoteTagEntriesTable extends NoteTagEntries
    with TableInfo<$NoteTagEntriesTable, NoteTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoteTagEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
      'note_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES notes (id) ON DELETE CASCADE'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [noteId, userId, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_tags';
  @override
  VerificationContext validateIntegrity(Insertable<NoteTagRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('note_id')) {
      context.handle(_noteIdMeta,
          noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta));
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {noteId, value};
  @override
  NoteTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteTagRow(
      noteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $NoteTagEntriesTable createAlias(String alias) {
    return $NoteTagEntriesTable(attachedDatabase, alias);
  }
}

class NoteTagRow extends DataClass implements Insertable<NoteTagRow> {
  final String noteId;
  final String userId;
  final String value;
  const NoteTagRow(
      {required this.noteId, required this.userId, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['note_id'] = Variable<String>(noteId);
    map['user_id'] = Variable<String>(userId);
    map['value'] = Variable<String>(value);
    return map;
  }

  NoteTagEntriesCompanion toCompanion(bool nullToAbsent) {
    return NoteTagEntriesCompanion(
      noteId: Value(noteId),
      userId: Value(userId),
      value: Value(value),
    );
  }

  factory NoteTagRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteTagRow(
      noteId: serializer.fromJson<String>(json['noteId']),
      userId: serializer.fromJson<String>(json['userId']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'noteId': serializer.toJson<String>(noteId),
      'userId': serializer.toJson<String>(userId),
      'value': serializer.toJson<String>(value),
    };
  }

  NoteTagRow copyWith({String? noteId, String? userId, String? value}) =>
      NoteTagRow(
        noteId: noteId ?? this.noteId,
        userId: userId ?? this.userId,
        value: value ?? this.value,
      );
  NoteTagRow copyWithCompanion(NoteTagEntriesCompanion data) {
    return NoteTagRow(
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      userId: data.userId.present ? data.userId.value : this.userId,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteTagRow(')
          ..write('noteId: $noteId, ')
          ..write('userId: $userId, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(noteId, userId, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteTagRow &&
          other.noteId == this.noteId &&
          other.userId == this.userId &&
          other.value == this.value);
}

class NoteTagEntriesCompanion extends UpdateCompanion<NoteTagRow> {
  final Value<String> noteId;
  final Value<String> userId;
  final Value<String> value;
  final Value<int> rowid;
  const NoteTagEntriesCompanion({
    this.noteId = const Value.absent(),
    this.userId = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NoteTagEntriesCompanion.insert({
    required String noteId,
    required String userId,
    required String value,
    this.rowid = const Value.absent(),
  })  : noteId = Value(noteId),
        userId = Value(userId),
        value = Value(value);
  static Insertable<NoteTagRow> custom({
    Expression<String>? noteId,
    Expression<String>? userId,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (noteId != null) 'note_id': noteId,
      if (userId != null) 'user_id': userId,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NoteTagEntriesCompanion copyWith(
      {Value<String>? noteId,
      Value<String>? userId,
      Value<String>? value,
      Value<int>? rowid}) {
    return NoteTagEntriesCompanion(
      noteId: noteId ?? this.noteId,
      userId: userId ?? this.userId,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteTagEntriesCompanion(')
          ..write('noteId: $noteId, ')
          ..write('userId: $userId, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NoteReminderEntriesTable extends NoteReminderEntries
    with TableInfo<$NoteReminderEntriesTable, NoteReminderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoteReminderEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
      'note_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES notes (id) ON DELETE CASCADE'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scheduledAtUtcMeta =
      const VerificationMeta('scheduledAtUtc');
  @override
  late final GeneratedColumn<DateTime> scheduledAtUtc =
      GeneratedColumn<DateTime>('scheduled_at_utc', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _timezoneNameMeta =
      const VerificationMeta('timezoneName');
  @override
  late final GeneratedColumn<String> timezoneName = GeneratedColumn<String>(
      'timezone_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notificationIdMeta =
      const VerificationMeta('notificationId');
  @override
  late final GeneratedColumn<int> notificationId = GeneratedColumn<int>(
      'notification_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _privacyModeMeta =
      const VerificationMeta('privacyMode');
  @override
  late final GeneratedColumn<String> privacyMode = GeneratedColumn<String>(
      'privacy_mode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _serverRevisionMeta =
      const VerificationMeta('serverRevision');
  @override
  late final GeneratedColumn<int> serverRevision = GeneratedColumn<int>(
      'server_revision', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        noteId,
        userId,
        scheduledAtUtc,
        timezoneName,
        status,
        notificationId,
        privacyMode,
        createdAt,
        updatedAt,
        deletedAt,
        version,
        serverRevision
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_reminders';
  @override
  VerificationContext validateIntegrity(Insertable<NoteReminderRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(_noteIdMeta,
          noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta));
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('scheduled_at_utc')) {
      context.handle(
          _scheduledAtUtcMeta,
          scheduledAtUtc.isAcceptableOrUnknown(
              data['scheduled_at_utc']!, _scheduledAtUtcMeta));
    } else if (isInserting) {
      context.missing(_scheduledAtUtcMeta);
    }
    if (data.containsKey('timezone_name')) {
      context.handle(
          _timezoneNameMeta,
          timezoneName.isAcceptableOrUnknown(
              data['timezone_name']!, _timezoneNameMeta));
    } else if (isInserting) {
      context.missing(_timezoneNameMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('notification_id')) {
      context.handle(
          _notificationIdMeta,
          notificationId.isAcceptableOrUnknown(
              data['notification_id']!, _notificationIdMeta));
    } else if (isInserting) {
      context.missing(_notificationIdMeta);
    }
    if (data.containsKey('privacy_mode')) {
      context.handle(
          _privacyModeMeta,
          privacyMode.isAcceptableOrUnknown(
              data['privacy_mode']!, _privacyModeMeta));
    } else if (isInserting) {
      context.missing(_privacyModeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('server_revision')) {
      context.handle(
          _serverRevisionMeta,
          serverRevision.isAcceptableOrUnknown(
              data['server_revision']!, _serverRevisionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {noteId},
      ];
  @override
  NoteReminderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteReminderRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      noteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      scheduledAtUtc: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}scheduled_at_utc'])!,
      timezoneName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}timezone_name'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      notificationId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}notification_id'])!,
      privacyMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}privacy_mode'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      serverRevision: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_revision'])!,
    );
  }

  @override
  $NoteReminderEntriesTable createAlias(String alias) {
    return $NoteReminderEntriesTable(attachedDatabase, alias);
  }
}

class NoteReminderRow extends DataClass implements Insertable<NoteReminderRow> {
  final String id;
  final String noteId;
  final String userId;
  final DateTime scheduledAtUtc;
  final String timezoneName;
  final String status;
  final int notificationId;
  final String privacyMode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;
  final int serverRevision;
  const NoteReminderRow(
      {required this.id,
      required this.noteId,
      required this.userId,
      required this.scheduledAtUtc,
      required this.timezoneName,
      required this.status,
      required this.notificationId,
      required this.privacyMode,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.version,
      required this.serverRevision});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['note_id'] = Variable<String>(noteId);
    map['user_id'] = Variable<String>(userId);
    map['scheduled_at_utc'] = Variable<DateTime>(scheduledAtUtc);
    map['timezone_name'] = Variable<String>(timezoneName);
    map['status'] = Variable<String>(status);
    map['notification_id'] = Variable<int>(notificationId);
    map['privacy_mode'] = Variable<String>(privacyMode);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['version'] = Variable<int>(version);
    map['server_revision'] = Variable<int>(serverRevision);
    return map;
  }

  NoteReminderEntriesCompanion toCompanion(bool nullToAbsent) {
    return NoteReminderEntriesCompanion(
      id: Value(id),
      noteId: Value(noteId),
      userId: Value(userId),
      scheduledAtUtc: Value(scheduledAtUtc),
      timezoneName: Value(timezoneName),
      status: Value(status),
      notificationId: Value(notificationId),
      privacyMode: Value(privacyMode),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      version: Value(version),
      serverRevision: Value(serverRevision),
    );
  }

  factory NoteReminderRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteReminderRow(
      id: serializer.fromJson<String>(json['id']),
      noteId: serializer.fromJson<String>(json['noteId']),
      userId: serializer.fromJson<String>(json['userId']),
      scheduledAtUtc: serializer.fromJson<DateTime>(json['scheduledAtUtc']),
      timezoneName: serializer.fromJson<String>(json['timezoneName']),
      status: serializer.fromJson<String>(json['status']),
      notificationId: serializer.fromJson<int>(json['notificationId']),
      privacyMode: serializer.fromJson<String>(json['privacyMode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      version: serializer.fromJson<int>(json['version']),
      serverRevision: serializer.fromJson<int>(json['serverRevision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'noteId': serializer.toJson<String>(noteId),
      'userId': serializer.toJson<String>(userId),
      'scheduledAtUtc': serializer.toJson<DateTime>(scheduledAtUtc),
      'timezoneName': serializer.toJson<String>(timezoneName),
      'status': serializer.toJson<String>(status),
      'notificationId': serializer.toJson<int>(notificationId),
      'privacyMode': serializer.toJson<String>(privacyMode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'version': serializer.toJson<int>(version),
      'serverRevision': serializer.toJson<int>(serverRevision),
    };
  }

  NoteReminderRow copyWith(
          {String? id,
          String? noteId,
          String? userId,
          DateTime? scheduledAtUtc,
          String? timezoneName,
          String? status,
          int? notificationId,
          String? privacyMode,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          int? version,
          int? serverRevision}) =>
      NoteReminderRow(
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
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        version: version ?? this.version,
        serverRevision: serverRevision ?? this.serverRevision,
      );
  NoteReminderRow copyWithCompanion(NoteReminderEntriesCompanion data) {
    return NoteReminderRow(
      id: data.id.present ? data.id.value : this.id,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      userId: data.userId.present ? data.userId.value : this.userId,
      scheduledAtUtc: data.scheduledAtUtc.present
          ? data.scheduledAtUtc.value
          : this.scheduledAtUtc,
      timezoneName: data.timezoneName.present
          ? data.timezoneName.value
          : this.timezoneName,
      status: data.status.present ? data.status.value : this.status,
      notificationId: data.notificationId.present
          ? data.notificationId.value
          : this.notificationId,
      privacyMode:
          data.privacyMode.present ? data.privacyMode.value : this.privacyMode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      version: data.version.present ? data.version.value : this.version,
      serverRevision: data.serverRevision.present
          ? data.serverRevision.value
          : this.serverRevision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteReminderRow(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('userId: $userId, ')
          ..write('scheduledAtUtc: $scheduledAtUtc, ')
          ..write('timezoneName: $timezoneName, ')
          ..write('status: $status, ')
          ..write('notificationId: $notificationId, ')
          ..write('privacyMode: $privacyMode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('version: $version, ')
          ..write('serverRevision: $serverRevision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      noteId,
      userId,
      scheduledAtUtc,
      timezoneName,
      status,
      notificationId,
      privacyMode,
      createdAt,
      updatedAt,
      deletedAt,
      version,
      serverRevision);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteReminderRow &&
          other.id == this.id &&
          other.noteId == this.noteId &&
          other.userId == this.userId &&
          other.scheduledAtUtc == this.scheduledAtUtc &&
          other.timezoneName == this.timezoneName &&
          other.status == this.status &&
          other.notificationId == this.notificationId &&
          other.privacyMode == this.privacyMode &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.version == this.version &&
          other.serverRevision == this.serverRevision);
}

class NoteReminderEntriesCompanion extends UpdateCompanion<NoteReminderRow> {
  final Value<String> id;
  final Value<String> noteId;
  final Value<String> userId;
  final Value<DateTime> scheduledAtUtc;
  final Value<String> timezoneName;
  final Value<String> status;
  final Value<int> notificationId;
  final Value<String> privacyMode;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> version;
  final Value<int> serverRevision;
  final Value<int> rowid;
  const NoteReminderEntriesCompanion({
    this.id = const Value.absent(),
    this.noteId = const Value.absent(),
    this.userId = const Value.absent(),
    this.scheduledAtUtc = const Value.absent(),
    this.timezoneName = const Value.absent(),
    this.status = const Value.absent(),
    this.notificationId = const Value.absent(),
    this.privacyMode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NoteReminderEntriesCompanion.insert({
    required String id,
    required String noteId,
    required String userId,
    required DateTime scheduledAtUtc,
    required String timezoneName,
    required String status,
    required int notificationId,
    required String privacyMode,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        noteId = Value(noteId),
        userId = Value(userId),
        scheduledAtUtc = Value(scheduledAtUtc),
        timezoneName = Value(timezoneName),
        status = Value(status),
        notificationId = Value(notificationId),
        privacyMode = Value(privacyMode),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<NoteReminderRow> custom({
    Expression<String>? id,
    Expression<String>? noteId,
    Expression<String>? userId,
    Expression<DateTime>? scheduledAtUtc,
    Expression<String>? timezoneName,
    Expression<String>? status,
    Expression<int>? notificationId,
    Expression<String>? privacyMode,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? version,
    Expression<int>? serverRevision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (noteId != null) 'note_id': noteId,
      if (userId != null) 'user_id': userId,
      if (scheduledAtUtc != null) 'scheduled_at_utc': scheduledAtUtc,
      if (timezoneName != null) 'timezone_name': timezoneName,
      if (status != null) 'status': status,
      if (notificationId != null) 'notification_id': notificationId,
      if (privacyMode != null) 'privacy_mode': privacyMode,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (version != null) 'version': version,
      if (serverRevision != null) 'server_revision': serverRevision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NoteReminderEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? noteId,
      Value<String>? userId,
      Value<DateTime>? scheduledAtUtc,
      Value<String>? timezoneName,
      Value<String>? status,
      Value<int>? notificationId,
      Value<String>? privacyMode,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? version,
      Value<int>? serverRevision,
      Value<int>? rowid}) {
    return NoteReminderEntriesCompanion(
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
      deletedAt: deletedAt ?? this.deletedAt,
      version: version ?? this.version,
      serverRevision: serverRevision ?? this.serverRevision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (scheduledAtUtc.present) {
      map['scheduled_at_utc'] = Variable<DateTime>(scheduledAtUtc.value);
    }
    if (timezoneName.present) {
      map['timezone_name'] = Variable<String>(timezoneName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notificationId.present) {
      map['notification_id'] = Variable<int>(notificationId.value);
    }
    if (privacyMode.present) {
      map['privacy_mode'] = Variable<String>(privacyMode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (serverRevision.present) {
      map['server_revision'] = Variable<int>(serverRevision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteReminderEntriesCompanion(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('userId: $userId, ')
          ..write('scheduledAtUtc: $scheduledAtUtc, ')
          ..write('timezoneName: $timezoneName, ')
          ..write('status: $status, ')
          ..write('notificationId: $notificationId, ')
          ..write('privacyMode: $privacyMode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('version: $version, ')
          ..write('serverRevision: $serverRevision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NoteReviewEntriesTable extends NoteReviewEntries
    with TableInfo<$NoteReviewEntriesTable, NoteReviewRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoteReviewEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
      'note_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES notes (id) ON DELETE CASCADE'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reviewedAtMeta =
      const VerificationMeta('reviewedAt');
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
      'reviewed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _focusSessionIdMeta =
      const VerificationMeta('focusSessionId');
  @override
  late final GeneratedColumn<String> focusSessionId = GeneratedColumn<String>(
      'focus_session_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _outcomeMeta =
      const VerificationMeta('outcome');
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
      'outcome', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _serverRevisionMeta =
      const VerificationMeta('serverRevision');
  @override
  late final GeneratedColumn<int> serverRevision = GeneratedColumn<int>(
      'server_revision', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        noteId,
        userId,
        reviewedAt,
        focusSessionId,
        outcome,
        deletedAt,
        version,
        serverRevision
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_reviews';
  @override
  VerificationContext validateIntegrity(Insertable<NoteReviewRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(_noteIdMeta,
          noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta));
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
          _reviewedAtMeta,
          reviewedAt.isAcceptableOrUnknown(
              data['reviewed_at']!, _reviewedAtMeta));
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    if (data.containsKey('focus_session_id')) {
      context.handle(
          _focusSessionIdMeta,
          focusSessionId.isAcceptableOrUnknown(
              data['focus_session_id']!, _focusSessionIdMeta));
    }
    if (data.containsKey('outcome')) {
      context.handle(_outcomeMeta,
          outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta));
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('server_revision')) {
      context.handle(
          _serverRevisionMeta,
          serverRevision.isAcceptableOrUnknown(
              data['server_revision']!, _serverRevisionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteReviewRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteReviewRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      noteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      reviewedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}reviewed_at'])!,
      focusSessionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}focus_session_id']),
      outcome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}outcome'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      serverRevision: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_revision'])!,
    );
  }

  @override
  $NoteReviewEntriesTable createAlias(String alias) {
    return $NoteReviewEntriesTable(attachedDatabase, alias);
  }
}

class NoteReviewRow extends DataClass implements Insertable<NoteReviewRow> {
  final String id;
  final String noteId;
  final String userId;
  final DateTime reviewedAt;
  final String? focusSessionId;
  final String outcome;
  final DateTime? deletedAt;
  final int version;
  final int serverRevision;
  const NoteReviewRow(
      {required this.id,
      required this.noteId,
      required this.userId,
      required this.reviewedAt,
      this.focusSessionId,
      required this.outcome,
      this.deletedAt,
      required this.version,
      required this.serverRevision});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['note_id'] = Variable<String>(noteId);
    map['user_id'] = Variable<String>(userId);
    map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    if (!nullToAbsent || focusSessionId != null) {
      map['focus_session_id'] = Variable<String>(focusSessionId);
    }
    map['outcome'] = Variable<String>(outcome);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['version'] = Variable<int>(version);
    map['server_revision'] = Variable<int>(serverRevision);
    return map;
  }

  NoteReviewEntriesCompanion toCompanion(bool nullToAbsent) {
    return NoteReviewEntriesCompanion(
      id: Value(id),
      noteId: Value(noteId),
      userId: Value(userId),
      reviewedAt: Value(reviewedAt),
      focusSessionId: focusSessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(focusSessionId),
      outcome: Value(outcome),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      version: Value(version),
      serverRevision: Value(serverRevision),
    );
  }

  factory NoteReviewRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteReviewRow(
      id: serializer.fromJson<String>(json['id']),
      noteId: serializer.fromJson<String>(json['noteId']),
      userId: serializer.fromJson<String>(json['userId']),
      reviewedAt: serializer.fromJson<DateTime>(json['reviewedAt']),
      focusSessionId: serializer.fromJson<String?>(json['focusSessionId']),
      outcome: serializer.fromJson<String>(json['outcome']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      version: serializer.fromJson<int>(json['version']),
      serverRevision: serializer.fromJson<int>(json['serverRevision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'noteId': serializer.toJson<String>(noteId),
      'userId': serializer.toJson<String>(userId),
      'reviewedAt': serializer.toJson<DateTime>(reviewedAt),
      'focusSessionId': serializer.toJson<String?>(focusSessionId),
      'outcome': serializer.toJson<String>(outcome),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'version': serializer.toJson<int>(version),
      'serverRevision': serializer.toJson<int>(serverRevision),
    };
  }

  NoteReviewRow copyWith(
          {String? id,
          String? noteId,
          String? userId,
          DateTime? reviewedAt,
          Value<String?> focusSessionId = const Value.absent(),
          String? outcome,
          Value<DateTime?> deletedAt = const Value.absent(),
          int? version,
          int? serverRevision}) =>
      NoteReviewRow(
        id: id ?? this.id,
        noteId: noteId ?? this.noteId,
        userId: userId ?? this.userId,
        reviewedAt: reviewedAt ?? this.reviewedAt,
        focusSessionId:
            focusSessionId.present ? focusSessionId.value : this.focusSessionId,
        outcome: outcome ?? this.outcome,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        version: version ?? this.version,
        serverRevision: serverRevision ?? this.serverRevision,
      );
  NoteReviewRow copyWithCompanion(NoteReviewEntriesCompanion data) {
    return NoteReviewRow(
      id: data.id.present ? data.id.value : this.id,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      userId: data.userId.present ? data.userId.value : this.userId,
      reviewedAt:
          data.reviewedAt.present ? data.reviewedAt.value : this.reviewedAt,
      focusSessionId: data.focusSessionId.present
          ? data.focusSessionId.value
          : this.focusSessionId,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      version: data.version.present ? data.version.value : this.version,
      serverRevision: data.serverRevision.present
          ? data.serverRevision.value
          : this.serverRevision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteReviewRow(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('userId: $userId, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('focusSessionId: $focusSessionId, ')
          ..write('outcome: $outcome, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('version: $version, ')
          ..write('serverRevision: $serverRevision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, noteId, userId, reviewedAt,
      focusSessionId, outcome, deletedAt, version, serverRevision);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteReviewRow &&
          other.id == this.id &&
          other.noteId == this.noteId &&
          other.userId == this.userId &&
          other.reviewedAt == this.reviewedAt &&
          other.focusSessionId == this.focusSessionId &&
          other.outcome == this.outcome &&
          other.deletedAt == this.deletedAt &&
          other.version == this.version &&
          other.serverRevision == this.serverRevision);
}

class NoteReviewEntriesCompanion extends UpdateCompanion<NoteReviewRow> {
  final Value<String> id;
  final Value<String> noteId;
  final Value<String> userId;
  final Value<DateTime> reviewedAt;
  final Value<String?> focusSessionId;
  final Value<String> outcome;
  final Value<DateTime?> deletedAt;
  final Value<int> version;
  final Value<int> serverRevision;
  final Value<int> rowid;
  const NoteReviewEntriesCompanion({
    this.id = const Value.absent(),
    this.noteId = const Value.absent(),
    this.userId = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.focusSessionId = const Value.absent(),
    this.outcome = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NoteReviewEntriesCompanion.insert({
    required String id,
    required String noteId,
    required String userId,
    required DateTime reviewedAt,
    this.focusSessionId = const Value.absent(),
    required String outcome,
    this.deletedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        noteId = Value(noteId),
        userId = Value(userId),
        reviewedAt = Value(reviewedAt),
        outcome = Value(outcome);
  static Insertable<NoteReviewRow> custom({
    Expression<String>? id,
    Expression<String>? noteId,
    Expression<String>? userId,
    Expression<DateTime>? reviewedAt,
    Expression<String>? focusSessionId,
    Expression<String>? outcome,
    Expression<DateTime>? deletedAt,
    Expression<int>? version,
    Expression<int>? serverRevision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (noteId != null) 'note_id': noteId,
      if (userId != null) 'user_id': userId,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (focusSessionId != null) 'focus_session_id': focusSessionId,
      if (outcome != null) 'outcome': outcome,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (version != null) 'version': version,
      if (serverRevision != null) 'server_revision': serverRevision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NoteReviewEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? noteId,
      Value<String>? userId,
      Value<DateTime>? reviewedAt,
      Value<String?>? focusSessionId,
      Value<String>? outcome,
      Value<DateTime?>? deletedAt,
      Value<int>? version,
      Value<int>? serverRevision,
      Value<int>? rowid}) {
    return NoteReviewEntriesCompanion(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      userId: userId ?? this.userId,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      focusSessionId: focusSessionId ?? this.focusSessionId,
      outcome: outcome ?? this.outcome,
      deletedAt: deletedAt ?? this.deletedAt,
      version: version ?? this.version,
      serverRevision: serverRevision ?? this.serverRevision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (focusSessionId.present) {
      map['focus_session_id'] = Variable<String>(focusSessionId.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (serverRevision.present) {
      map['server_revision'] = Variable<int>(serverRevision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteReviewEntriesCompanion(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('userId: $userId, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('focusSessionId: $focusSessionId, ')
          ..write('outcome: $outcome, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('version: $version, ')
          ..write('serverRevision: $serverRevision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfileEntriesTable extends ProfileEntries
    with TableInfo<$ProfileEntriesTable, ProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _serverRevisionMeta =
      const VerificationMeta('serverRevision');
  @override
  late final GeneratedColumn<int> serverRevision = GeneratedColumn<int>(
      'server_revision', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, payloadJson, updatedAt, version, serverRevision];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(Insertable<ProfileRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('server_revision')) {
      context.handle(
          _serverRevisionMeta,
          serverRevision.isAcceptableOrUnknown(
              data['server_revision']!, _serverRevisionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      serverRevision: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_revision'])!,
    );
  }

  @override
  $ProfileEntriesTable createAlias(String alias) {
    return $ProfileEntriesTable(attachedDatabase, alias);
  }
}

class ProfileRow extends DataClass implements Insertable<ProfileRow> {
  final String id;
  final String userId;
  final String payloadJson;
  final DateTime updatedAt;
  final int version;
  final int serverRevision;
  const ProfileRow(
      {required this.id,
      required this.userId,
      required this.payloadJson,
      required this.updatedAt,
      required this.version,
      required this.serverRevision});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['payload_json'] = Variable<String>(payloadJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['version'] = Variable<int>(version);
    map['server_revision'] = Variable<int>(serverRevision);
    return map;
  }

  ProfileEntriesCompanion toCompanion(bool nullToAbsent) {
    return ProfileEntriesCompanion(
      id: Value(id),
      userId: Value(userId),
      payloadJson: Value(payloadJson),
      updatedAt: Value(updatedAt),
      version: Value(version),
      serverRevision: Value(serverRevision),
    );
  }

  factory ProfileRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
      serverRevision: serializer.fromJson<int>(json['serverRevision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'version': serializer.toJson<int>(version),
      'serverRevision': serializer.toJson<int>(serverRevision),
    };
  }

  ProfileRow copyWith(
          {String? id,
          String? userId,
          String? payloadJson,
          DateTime? updatedAt,
          int? version,
          int? serverRevision}) =>
      ProfileRow(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        payloadJson: payloadJson ?? this.payloadJson,
        updatedAt: updatedAt ?? this.updatedAt,
        version: version ?? this.version,
        serverRevision: serverRevision ?? this.serverRevision,
      );
  ProfileRow copyWithCompanion(ProfileEntriesCompanion data) {
    return ProfileRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
      serverRevision: data.serverRevision.present
          ? data.serverRevision.value
          : this.serverRevision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('serverRevision: $serverRevision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, payloadJson, updatedAt, version, serverRevision);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.payloadJson == this.payloadJson &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.serverRevision == this.serverRevision);
}

class ProfileEntriesCompanion extends UpdateCompanion<ProfileRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> payloadJson;
  final Value<DateTime> updatedAt;
  final Value<int> version;
  final Value<int> serverRevision;
  final Value<int> rowid;
  const ProfileEntriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfileEntriesCompanion.insert({
    required String id,
    required String userId,
    required String payloadJson,
    required DateTime updatedAt,
    this.version = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        payloadJson = Value(payloadJson),
        updatedAt = Value(updatedAt);
  static Insertable<ProfileRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? payloadJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? version,
    Expression<int>? serverRevision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (serverRevision != null) 'server_revision': serverRevision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfileEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? payloadJson,
      Value<DateTime>? updatedAt,
      Value<int>? version,
      Value<int>? serverRevision,
      Value<int>? rowid}) {
    return ProfileEntriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      payloadJson: payloadJson ?? this.payloadJson,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      serverRevision: serverRevision ?? this.serverRevision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (serverRevision.present) {
      map['server_revision'] = Variable<int>(serverRevision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileEntriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('serverRevision: $serverRevision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitEntriesTable extends HabitEntries
    with TableInfo<$HabitEntriesTable, HabitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isOneTimeMeta =
      const VerificationMeta('isOneTime');
  @override
  late final GeneratedColumn<bool> isOneTime = GeneratedColumn<bool>(
      'is_one_time', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_one_time" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _serverRevisionMeta =
      const VerificationMeta('serverRevision');
  @override
  late final GeneratedColumn<int> serverRevision = GeneratedColumn<int>(
      'server_revision', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        title,
        category,
        createdAt,
        isArchived,
        isOneTime,
        deletedAt,
        version,
        serverRevision
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habits';
  @override
  VerificationContext validateIntegrity(Insertable<HabitRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('is_one_time')) {
      context.handle(
          _isOneTimeMeta,
          isOneTime.isAcceptableOrUnknown(
              data['is_one_time']!, _isOneTimeMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('server_revision')) {
      context.handle(
          _serverRevisionMeta,
          serverRevision.isAcceptableOrUnknown(
              data['server_revision']!, _serverRevisionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      isOneTime: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_one_time'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      serverRevision: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_revision'])!,
    );
  }

  @override
  $HabitEntriesTable createAlias(String alias) {
    return $HabitEntriesTable(attachedDatabase, alias);
  }
}

class HabitRow extends DataClass implements Insertable<HabitRow> {
  final String id;
  final String userId;
  final String title;
  final String category;
  final DateTime createdAt;
  final bool isArchived;
  final bool isOneTime;
  final DateTime? deletedAt;
  final int version;
  final int serverRevision;
  const HabitRow(
      {required this.id,
      required this.userId,
      required this.title,
      required this.category,
      required this.createdAt,
      required this.isArchived,
      required this.isOneTime,
      this.deletedAt,
      required this.version,
      required this.serverRevision});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['title'] = Variable<String>(title);
    map['category'] = Variable<String>(category);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_archived'] = Variable<bool>(isArchived);
    map['is_one_time'] = Variable<bool>(isOneTime);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['version'] = Variable<int>(version);
    map['server_revision'] = Variable<int>(serverRevision);
    return map;
  }

  HabitEntriesCompanion toCompanion(bool nullToAbsent) {
    return HabitEntriesCompanion(
      id: Value(id),
      userId: Value(userId),
      title: Value(title),
      category: Value(category),
      createdAt: Value(createdAt),
      isArchived: Value(isArchived),
      isOneTime: Value(isOneTime),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      version: Value(version),
      serverRevision: Value(serverRevision),
    );
  }

  factory HabitRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String>(json['category']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      isOneTime: serializer.fromJson<bool>(json['isOneTime']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      version: serializer.fromJson<int>(json['version']),
      serverRevision: serializer.fromJson<int>(json['serverRevision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String>(category),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isArchived': serializer.toJson<bool>(isArchived),
      'isOneTime': serializer.toJson<bool>(isOneTime),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'version': serializer.toJson<int>(version),
      'serverRevision': serializer.toJson<int>(serverRevision),
    };
  }

  HabitRow copyWith(
          {String? id,
          String? userId,
          String? title,
          String? category,
          DateTime? createdAt,
          bool? isArchived,
          bool? isOneTime,
          Value<DateTime?> deletedAt = const Value.absent(),
          int? version,
          int? serverRevision}) =>
      HabitRow(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        category: category ?? this.category,
        createdAt: createdAt ?? this.createdAt,
        isArchived: isArchived ?? this.isArchived,
        isOneTime: isOneTime ?? this.isOneTime,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        version: version ?? this.version,
        serverRevision: serverRevision ?? this.serverRevision,
      );
  HabitRow copyWithCompanion(HabitEntriesCompanion data) {
    return HabitRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      isOneTime: data.isOneTime.present ? data.isOneTime.value : this.isOneTime,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      version: data.version.present ? data.version.value : this.version,
      serverRevision: data.serverRevision.present
          ? data.serverRevision.value
          : this.serverRevision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('isArchived: $isArchived, ')
          ..write('isOneTime: $isOneTime, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('version: $version, ')
          ..write('serverRevision: $serverRevision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, title, category, createdAt,
      isArchived, isOneTime, deletedAt, version, serverRevision);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.category == this.category &&
          other.createdAt == this.createdAt &&
          other.isArchived == this.isArchived &&
          other.isOneTime == this.isOneTime &&
          other.deletedAt == this.deletedAt &&
          other.version == this.version &&
          other.serverRevision == this.serverRevision);
}

class HabitEntriesCompanion extends UpdateCompanion<HabitRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> title;
  final Value<String> category;
  final Value<DateTime> createdAt;
  final Value<bool> isArchived;
  final Value<bool> isOneTime;
  final Value<DateTime?> deletedAt;
  final Value<int> version;
  final Value<int> serverRevision;
  final Value<int> rowid;
  const HabitEntriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isOneTime = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitEntriesCompanion.insert({
    required String id,
    required String userId,
    required String title,
    required String category,
    required DateTime createdAt,
    this.isArchived = const Value.absent(),
    this.isOneTime = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        title = Value(title),
        category = Value(category),
        createdAt = Value(createdAt);
  static Insertable<HabitRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<String>? category,
    Expression<DateTime>? createdAt,
    Expression<bool>? isArchived,
    Expression<bool>? isOneTime,
    Expression<DateTime>? deletedAt,
    Expression<int>? version,
    Expression<int>? serverRevision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (createdAt != null) 'created_at': createdAt,
      if (isArchived != null) 'is_archived': isArchived,
      if (isOneTime != null) 'is_one_time': isOneTime,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (version != null) 'version': version,
      if (serverRevision != null) 'server_revision': serverRevision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? title,
      Value<String>? category,
      Value<DateTime>? createdAt,
      Value<bool>? isArchived,
      Value<bool>? isOneTime,
      Value<DateTime?>? deletedAt,
      Value<int>? version,
      Value<int>? serverRevision,
      Value<int>? rowid}) {
    return HabitEntriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
      isOneTime: isOneTime ?? this.isOneTime,
      deletedAt: deletedAt ?? this.deletedAt,
      version: version ?? this.version,
      serverRevision: serverRevision ?? this.serverRevision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (isOneTime.present) {
      map['is_one_time'] = Variable<bool>(isOneTime.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (serverRevision.present) {
      map['server_revision'] = Variable<int>(serverRevision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitEntriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('isArchived: $isArchived, ')
          ..write('isOneTime: $isOneTime, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('version: $version, ')
          ..write('serverRevision: $serverRevision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitScheduleEntriesTable extends HabitScheduleEntries
    with TableInfo<$HabitScheduleEntriesTable, HabitScheduleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitScheduleEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _habitIdMeta =
      const VerificationMeta('habitId');
  @override
  late final GeneratedColumn<String> habitId = GeneratedColumn<String>(
      'habit_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES habits (id) ON DELETE CASCADE'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isWeeklyMeta =
      const VerificationMeta('isWeekly');
  @override
  late final GeneratedColumn<bool> isWeekly = GeneratedColumn<bool>(
      'is_weekly', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_weekly" IN (0, 1))'));
  static const VerificationMeta _daysOfWeekJsonMeta =
      const VerificationMeta('daysOfWeekJson');
  @override
  late final GeneratedColumn<String> daysOfWeekJson = GeneratedColumn<String>(
      'days_of_week_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scheduledDateMeta =
      const VerificationMeta('scheduledDate');
  @override
  late final GeneratedColumn<DateTime> scheduledDate =
      GeneratedColumn<DateTime>('scheduled_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _reminderEnabledMeta =
      const VerificationMeta('reminderEnabled');
  @override
  late final GeneratedColumn<bool> reminderEnabled = GeneratedColumn<bool>(
      'reminder_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("reminder_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _reminderHourMeta =
      const VerificationMeta('reminderHour');
  @override
  late final GeneratedColumn<int> reminderHour = GeneratedColumn<int>(
      'reminder_hour', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _reminderMinuteMeta =
      const VerificationMeta('reminderMinute');
  @override
  late final GeneratedColumn<int> reminderMinute = GeneratedColumn<int>(
      'reminder_minute', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _timeZoneMeta =
      const VerificationMeta('timeZone');
  @override
  late final GeneratedColumn<String> timeZone = GeneratedColumn<String>(
      'time_zone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _serverRevisionMeta =
      const VerificationMeta('serverRevision');
  @override
  late final GeneratedColumn<int> serverRevision = GeneratedColumn<int>(
      'server_revision', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        habitId,
        userId,
        isWeekly,
        daysOfWeekJson,
        scheduledDate,
        reminderEnabled,
        reminderHour,
        reminderMinute,
        timeZone,
        updatedAt,
        version,
        serverRevision
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_schedules';
  @override
  VerificationContext validateIntegrity(Insertable<HabitScheduleRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('habit_id')) {
      context.handle(_habitIdMeta,
          habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta));
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('is_weekly')) {
      context.handle(_isWeeklyMeta,
          isWeekly.isAcceptableOrUnknown(data['is_weekly']!, _isWeeklyMeta));
    } else if (isInserting) {
      context.missing(_isWeeklyMeta);
    }
    if (data.containsKey('days_of_week_json')) {
      context.handle(
          _daysOfWeekJsonMeta,
          daysOfWeekJson.isAcceptableOrUnknown(
              data['days_of_week_json']!, _daysOfWeekJsonMeta));
    } else if (isInserting) {
      context.missing(_daysOfWeekJsonMeta);
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
          _scheduledDateMeta,
          scheduledDate.isAcceptableOrUnknown(
              data['scheduled_date']!, _scheduledDateMeta));
    }
    if (data.containsKey('reminder_enabled')) {
      context.handle(
          _reminderEnabledMeta,
          reminderEnabled.isAcceptableOrUnknown(
              data['reminder_enabled']!, _reminderEnabledMeta));
    }
    if (data.containsKey('reminder_hour')) {
      context.handle(
          _reminderHourMeta,
          reminderHour.isAcceptableOrUnknown(
              data['reminder_hour']!, _reminderHourMeta));
    }
    if (data.containsKey('reminder_minute')) {
      context.handle(
          _reminderMinuteMeta,
          reminderMinute.isAcceptableOrUnknown(
              data['reminder_minute']!, _reminderMinuteMeta));
    }
    if (data.containsKey('time_zone')) {
      context.handle(_timeZoneMeta,
          timeZone.isAcceptableOrUnknown(data['time_zone']!, _timeZoneMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('server_revision')) {
      context.handle(
          _serverRevisionMeta,
          serverRevision.isAcceptableOrUnknown(
              data['server_revision']!, _serverRevisionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitScheduleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitScheduleRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      habitId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}habit_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      isWeekly: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_weekly'])!,
      daysOfWeekJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}days_of_week_json'])!,
      scheduledDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}scheduled_date']),
      reminderEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}reminder_enabled'])!,
      reminderHour: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reminder_hour']),
      reminderMinute: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reminder_minute']),
      timeZone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}time_zone']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      serverRevision: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_revision'])!,
    );
  }

  @override
  $HabitScheduleEntriesTable createAlias(String alias) {
    return $HabitScheduleEntriesTable(attachedDatabase, alias);
  }
}

class HabitScheduleRow extends DataClass
    implements Insertable<HabitScheduleRow> {
  final String id;
  final String habitId;
  final String userId;
  final bool isWeekly;
  final String daysOfWeekJson;
  final DateTime? scheduledDate;
  final bool reminderEnabled;
  final int? reminderHour;
  final int? reminderMinute;
  final String? timeZone;
  final DateTime updatedAt;
  final int version;
  final int serverRevision;
  const HabitScheduleRow(
      {required this.id,
      required this.habitId,
      required this.userId,
      required this.isWeekly,
      required this.daysOfWeekJson,
      this.scheduledDate,
      required this.reminderEnabled,
      this.reminderHour,
      this.reminderMinute,
      this.timeZone,
      required this.updatedAt,
      required this.version,
      required this.serverRevision});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['habit_id'] = Variable<String>(habitId);
    map['user_id'] = Variable<String>(userId);
    map['is_weekly'] = Variable<bool>(isWeekly);
    map['days_of_week_json'] = Variable<String>(daysOfWeekJson);
    if (!nullToAbsent || scheduledDate != null) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate);
    }
    map['reminder_enabled'] = Variable<bool>(reminderEnabled);
    if (!nullToAbsent || reminderHour != null) {
      map['reminder_hour'] = Variable<int>(reminderHour);
    }
    if (!nullToAbsent || reminderMinute != null) {
      map['reminder_minute'] = Variable<int>(reminderMinute);
    }
    if (!nullToAbsent || timeZone != null) {
      map['time_zone'] = Variable<String>(timeZone);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['version'] = Variable<int>(version);
    map['server_revision'] = Variable<int>(serverRevision);
    return map;
  }

  HabitScheduleEntriesCompanion toCompanion(bool nullToAbsent) {
    return HabitScheduleEntriesCompanion(
      id: Value(id),
      habitId: Value(habitId),
      userId: Value(userId),
      isWeekly: Value(isWeekly),
      daysOfWeekJson: Value(daysOfWeekJson),
      scheduledDate: scheduledDate == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledDate),
      reminderEnabled: Value(reminderEnabled),
      reminderHour: reminderHour == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderHour),
      reminderMinute: reminderMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderMinute),
      timeZone: timeZone == null && nullToAbsent
          ? const Value.absent()
          : Value(timeZone),
      updatedAt: Value(updatedAt),
      version: Value(version),
      serverRevision: Value(serverRevision),
    );
  }

  factory HabitScheduleRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitScheduleRow(
      id: serializer.fromJson<String>(json['id']),
      habitId: serializer.fromJson<String>(json['habitId']),
      userId: serializer.fromJson<String>(json['userId']),
      isWeekly: serializer.fromJson<bool>(json['isWeekly']),
      daysOfWeekJson: serializer.fromJson<String>(json['daysOfWeekJson']),
      scheduledDate: serializer.fromJson<DateTime?>(json['scheduledDate']),
      reminderEnabled: serializer.fromJson<bool>(json['reminderEnabled']),
      reminderHour: serializer.fromJson<int?>(json['reminderHour']),
      reminderMinute: serializer.fromJson<int?>(json['reminderMinute']),
      timeZone: serializer.fromJson<String?>(json['timeZone']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
      serverRevision: serializer.fromJson<int>(json['serverRevision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'habitId': serializer.toJson<String>(habitId),
      'userId': serializer.toJson<String>(userId),
      'isWeekly': serializer.toJson<bool>(isWeekly),
      'daysOfWeekJson': serializer.toJson<String>(daysOfWeekJson),
      'scheduledDate': serializer.toJson<DateTime?>(scheduledDate),
      'reminderEnabled': serializer.toJson<bool>(reminderEnabled),
      'reminderHour': serializer.toJson<int?>(reminderHour),
      'reminderMinute': serializer.toJson<int?>(reminderMinute),
      'timeZone': serializer.toJson<String?>(timeZone),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'version': serializer.toJson<int>(version),
      'serverRevision': serializer.toJson<int>(serverRevision),
    };
  }

  HabitScheduleRow copyWith(
          {String? id,
          String? habitId,
          String? userId,
          bool? isWeekly,
          String? daysOfWeekJson,
          Value<DateTime?> scheduledDate = const Value.absent(),
          bool? reminderEnabled,
          Value<int?> reminderHour = const Value.absent(),
          Value<int?> reminderMinute = const Value.absent(),
          Value<String?> timeZone = const Value.absent(),
          DateTime? updatedAt,
          int? version,
          int? serverRevision}) =>
      HabitScheduleRow(
        id: id ?? this.id,
        habitId: habitId ?? this.habitId,
        userId: userId ?? this.userId,
        isWeekly: isWeekly ?? this.isWeekly,
        daysOfWeekJson: daysOfWeekJson ?? this.daysOfWeekJson,
        scheduledDate:
            scheduledDate.present ? scheduledDate.value : this.scheduledDate,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        reminderHour:
            reminderHour.present ? reminderHour.value : this.reminderHour,
        reminderMinute:
            reminderMinute.present ? reminderMinute.value : this.reminderMinute,
        timeZone: timeZone.present ? timeZone.value : this.timeZone,
        updatedAt: updatedAt ?? this.updatedAt,
        version: version ?? this.version,
        serverRevision: serverRevision ?? this.serverRevision,
      );
  HabitScheduleRow copyWithCompanion(HabitScheduleEntriesCompanion data) {
    return HabitScheduleRow(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      userId: data.userId.present ? data.userId.value : this.userId,
      isWeekly: data.isWeekly.present ? data.isWeekly.value : this.isWeekly,
      daysOfWeekJson: data.daysOfWeekJson.present
          ? data.daysOfWeekJson.value
          : this.daysOfWeekJson,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
      reminderEnabled: data.reminderEnabled.present
          ? data.reminderEnabled.value
          : this.reminderEnabled,
      reminderHour: data.reminderHour.present
          ? data.reminderHour.value
          : this.reminderHour,
      reminderMinute: data.reminderMinute.present
          ? data.reminderMinute.value
          : this.reminderMinute,
      timeZone: data.timeZone.present ? data.timeZone.value : this.timeZone,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
      serverRevision: data.serverRevision.present
          ? data.serverRevision.value
          : this.serverRevision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitScheduleRow(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('userId: $userId, ')
          ..write('isWeekly: $isWeekly, ')
          ..write('daysOfWeekJson: $daysOfWeekJson, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('reminderHour: $reminderHour, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('timeZone: $timeZone, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('serverRevision: $serverRevision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      habitId,
      userId,
      isWeekly,
      daysOfWeekJson,
      scheduledDate,
      reminderEnabled,
      reminderHour,
      reminderMinute,
      timeZone,
      updatedAt,
      version,
      serverRevision);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitScheduleRow &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.userId == this.userId &&
          other.isWeekly == this.isWeekly &&
          other.daysOfWeekJson == this.daysOfWeekJson &&
          other.scheduledDate == this.scheduledDate &&
          other.reminderEnabled == this.reminderEnabled &&
          other.reminderHour == this.reminderHour &&
          other.reminderMinute == this.reminderMinute &&
          other.timeZone == this.timeZone &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.serverRevision == this.serverRevision);
}

class HabitScheduleEntriesCompanion extends UpdateCompanion<HabitScheduleRow> {
  final Value<String> id;
  final Value<String> habitId;
  final Value<String> userId;
  final Value<bool> isWeekly;
  final Value<String> daysOfWeekJson;
  final Value<DateTime?> scheduledDate;
  final Value<bool> reminderEnabled;
  final Value<int?> reminderHour;
  final Value<int?> reminderMinute;
  final Value<String?> timeZone;
  final Value<DateTime> updatedAt;
  final Value<int> version;
  final Value<int> serverRevision;
  final Value<int> rowid;
  const HabitScheduleEntriesCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.userId = const Value.absent(),
    this.isWeekly = const Value.absent(),
    this.daysOfWeekJson = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.reminderHour = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.timeZone = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitScheduleEntriesCompanion.insert({
    required String id,
    required String habitId,
    required String userId,
    required bool isWeekly,
    required String daysOfWeekJson,
    this.scheduledDate = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.reminderHour = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.timeZone = const Value.absent(),
    required DateTime updatedAt,
    this.version = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        habitId = Value(habitId),
        userId = Value(userId),
        isWeekly = Value(isWeekly),
        daysOfWeekJson = Value(daysOfWeekJson),
        updatedAt = Value(updatedAt);
  static Insertable<HabitScheduleRow> custom({
    Expression<String>? id,
    Expression<String>? habitId,
    Expression<String>? userId,
    Expression<bool>? isWeekly,
    Expression<String>? daysOfWeekJson,
    Expression<DateTime>? scheduledDate,
    Expression<bool>? reminderEnabled,
    Expression<int>? reminderHour,
    Expression<int>? reminderMinute,
    Expression<String>? timeZone,
    Expression<DateTime>? updatedAt,
    Expression<int>? version,
    Expression<int>? serverRevision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (userId != null) 'user_id': userId,
      if (isWeekly != null) 'is_weekly': isWeekly,
      if (daysOfWeekJson != null) 'days_of_week_json': daysOfWeekJson,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (reminderEnabled != null) 'reminder_enabled': reminderEnabled,
      if (reminderHour != null) 'reminder_hour': reminderHour,
      if (reminderMinute != null) 'reminder_minute': reminderMinute,
      if (timeZone != null) 'time_zone': timeZone,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (serverRevision != null) 'server_revision': serverRevision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitScheduleEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? habitId,
      Value<String>? userId,
      Value<bool>? isWeekly,
      Value<String>? daysOfWeekJson,
      Value<DateTime?>? scheduledDate,
      Value<bool>? reminderEnabled,
      Value<int?>? reminderHour,
      Value<int?>? reminderMinute,
      Value<String?>? timeZone,
      Value<DateTime>? updatedAt,
      Value<int>? version,
      Value<int>? serverRevision,
      Value<int>? rowid}) {
    return HabitScheduleEntriesCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      userId: userId ?? this.userId,
      isWeekly: isWeekly ?? this.isWeekly,
      daysOfWeekJson: daysOfWeekJson ?? this.daysOfWeekJson,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      timeZone: timeZone ?? this.timeZone,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      serverRevision: serverRevision ?? this.serverRevision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<String>(habitId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (isWeekly.present) {
      map['is_weekly'] = Variable<bool>(isWeekly.value);
    }
    if (daysOfWeekJson.present) {
      map['days_of_week_json'] = Variable<String>(daysOfWeekJson.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate.value);
    }
    if (reminderEnabled.present) {
      map['reminder_enabled'] = Variable<bool>(reminderEnabled.value);
    }
    if (reminderHour.present) {
      map['reminder_hour'] = Variable<int>(reminderHour.value);
    }
    if (reminderMinute.present) {
      map['reminder_minute'] = Variable<int>(reminderMinute.value);
    }
    if (timeZone.present) {
      map['time_zone'] = Variable<String>(timeZone.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (serverRevision.present) {
      map['server_revision'] = Variable<int>(serverRevision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitScheduleEntriesCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('userId: $userId, ')
          ..write('isWeekly: $isWeekly, ')
          ..write('daysOfWeekJson: $daysOfWeekJson, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('reminderHour: $reminderHour, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('timeZone: $timeZone, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('serverRevision: $serverRevision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitDayStateEntriesTable extends HabitDayStateEntries
    with TableInfo<$HabitDayStateEntriesTable, HabitDayStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitDayStateEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _habitIdMeta =
      const VerificationMeta('habitId');
  @override
  late final GeneratedColumn<String> habitId = GeneratedColumn<String>(
      'habit_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES habits (id) ON DELETE CASCADE'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localDateMeta =
      const VerificationMeta('localDate');
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
      'local_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _completedMeta =
      const VerificationMeta('completed');
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
      'completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("completed" IN (0, 1))'));
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _serverRevisionMeta =
      const VerificationMeta('serverRevision');
  @override
  late final GeneratedColumn<int> serverRevision = GeneratedColumn<int>(
      'server_revision', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        habitId,
        userId,
        localDate,
        completed,
        completedAt,
        version,
        serverRevision
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_day_states';
  @override
  VerificationContext validateIntegrity(Insertable<HabitDayStateRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('habit_id')) {
      context.handle(_habitIdMeta,
          habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta));
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('local_date')) {
      context.handle(_localDateMeta,
          localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta));
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(_completedMeta,
          completed.isAcceptableOrUnknown(data['completed']!, _completedMeta));
    } else if (isInserting) {
      context.missing(_completedMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('server_revision')) {
      context.handle(
          _serverRevisionMeta,
          serverRevision.isAcceptableOrUnknown(
              data['server_revision']!, _serverRevisionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {userId, habitId, localDate},
      ];
  @override
  HabitDayStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitDayStateRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      habitId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}habit_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      localDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_date'])!,
      completed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}completed'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      serverRevision: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_revision'])!,
    );
  }

  @override
  $HabitDayStateEntriesTable createAlias(String alias) {
    return $HabitDayStateEntriesTable(attachedDatabase, alias);
  }
}

class HabitDayStateRow extends DataClass
    implements Insertable<HabitDayStateRow> {
  final String id;
  final String habitId;
  final String userId;
  final String localDate;
  final bool completed;
  final DateTime? completedAt;
  final int version;
  final int serverRevision;
  const HabitDayStateRow(
      {required this.id,
      required this.habitId,
      required this.userId,
      required this.localDate,
      required this.completed,
      this.completedAt,
      required this.version,
      required this.serverRevision});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['habit_id'] = Variable<String>(habitId);
    map['user_id'] = Variable<String>(userId);
    map['local_date'] = Variable<String>(localDate);
    map['completed'] = Variable<bool>(completed);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['version'] = Variable<int>(version);
    map['server_revision'] = Variable<int>(serverRevision);
    return map;
  }

  HabitDayStateEntriesCompanion toCompanion(bool nullToAbsent) {
    return HabitDayStateEntriesCompanion(
      id: Value(id),
      habitId: Value(habitId),
      userId: Value(userId),
      localDate: Value(localDate),
      completed: Value(completed),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      version: Value(version),
      serverRevision: Value(serverRevision),
    );
  }

  factory HabitDayStateRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitDayStateRow(
      id: serializer.fromJson<String>(json['id']),
      habitId: serializer.fromJson<String>(json['habitId']),
      userId: serializer.fromJson<String>(json['userId']),
      localDate: serializer.fromJson<String>(json['localDate']),
      completed: serializer.fromJson<bool>(json['completed']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      version: serializer.fromJson<int>(json['version']),
      serverRevision: serializer.fromJson<int>(json['serverRevision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'habitId': serializer.toJson<String>(habitId),
      'userId': serializer.toJson<String>(userId),
      'localDate': serializer.toJson<String>(localDate),
      'completed': serializer.toJson<bool>(completed),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'version': serializer.toJson<int>(version),
      'serverRevision': serializer.toJson<int>(serverRevision),
    };
  }

  HabitDayStateRow copyWith(
          {String? id,
          String? habitId,
          String? userId,
          String? localDate,
          bool? completed,
          Value<DateTime?> completedAt = const Value.absent(),
          int? version,
          int? serverRevision}) =>
      HabitDayStateRow(
        id: id ?? this.id,
        habitId: habitId ?? this.habitId,
        userId: userId ?? this.userId,
        localDate: localDate ?? this.localDate,
        completed: completed ?? this.completed,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        version: version ?? this.version,
        serverRevision: serverRevision ?? this.serverRevision,
      );
  HabitDayStateRow copyWithCompanion(HabitDayStateEntriesCompanion data) {
    return HabitDayStateRow(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      userId: data.userId.present ? data.userId.value : this.userId,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      completed: data.completed.present ? data.completed.value : this.completed,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      version: data.version.present ? data.version.value : this.version,
      serverRevision: data.serverRevision.present
          ? data.serverRevision.value
          : this.serverRevision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitDayStateRow(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('userId: $userId, ')
          ..write('localDate: $localDate, ')
          ..write('completed: $completed, ')
          ..write('completedAt: $completedAt, ')
          ..write('version: $version, ')
          ..write('serverRevision: $serverRevision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, habitId, userId, localDate, completed,
      completedAt, version, serverRevision);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitDayStateRow &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.userId == this.userId &&
          other.localDate == this.localDate &&
          other.completed == this.completed &&
          other.completedAt == this.completedAt &&
          other.version == this.version &&
          other.serverRevision == this.serverRevision);
}

class HabitDayStateEntriesCompanion extends UpdateCompanion<HabitDayStateRow> {
  final Value<String> id;
  final Value<String> habitId;
  final Value<String> userId;
  final Value<String> localDate;
  final Value<bool> completed;
  final Value<DateTime?> completedAt;
  final Value<int> version;
  final Value<int> serverRevision;
  final Value<int> rowid;
  const HabitDayStateEntriesCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.userId = const Value.absent(),
    this.localDate = const Value.absent(),
    this.completed = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitDayStateEntriesCompanion.insert({
    required String id,
    required String habitId,
    required String userId,
    required String localDate,
    required bool completed,
    this.completedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        habitId = Value(habitId),
        userId = Value(userId),
        localDate = Value(localDate),
        completed = Value(completed);
  static Insertable<HabitDayStateRow> custom({
    Expression<String>? id,
    Expression<String>? habitId,
    Expression<String>? userId,
    Expression<String>? localDate,
    Expression<bool>? completed,
    Expression<DateTime>? completedAt,
    Expression<int>? version,
    Expression<int>? serverRevision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (userId != null) 'user_id': userId,
      if (localDate != null) 'local_date': localDate,
      if (completed != null) 'completed': completed,
      if (completedAt != null) 'completed_at': completedAt,
      if (version != null) 'version': version,
      if (serverRevision != null) 'server_revision': serverRevision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitDayStateEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? habitId,
      Value<String>? userId,
      Value<String>? localDate,
      Value<bool>? completed,
      Value<DateTime?>? completedAt,
      Value<int>? version,
      Value<int>? serverRevision,
      Value<int>? rowid}) {
    return HabitDayStateEntriesCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      userId: userId ?? this.userId,
      localDate: localDate ?? this.localDate,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      version: version ?? this.version,
      serverRevision: serverRevision ?? this.serverRevision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<String>(habitId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (serverRevision.present) {
      map['server_revision'] = Variable<int>(serverRevision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitDayStateEntriesCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('userId: $userId, ')
          ..write('localDate: $localDate, ')
          ..write('completed: $completed, ')
          ..write('completedAt: $completedAt, ')
          ..write('version: $version, ')
          ..write('serverRevision: $serverRevision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CompletedTaskEntriesTable extends CompletedTaskEntries
    with TableInfo<$CompletedTaskEntriesTable, CompletedTaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompletedTaskEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _wasOneTimeMeta =
      const VerificationMeta('wasOneTime');
  @override
  late final GeneratedColumn<bool> wasOneTime = GeneratedColumn<bool>(
      'was_one_time', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("was_one_time" IN (0, 1))'));
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _serverRevisionMeta =
      const VerificationMeta('serverRevision');
  @override
  late final GeneratedColumn<int> serverRevision = GeneratedColumn<int>(
      'server_revision', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        title,
        category,
        completedAt,
        wasOneTime,
        deletedAt,
        version,
        serverRevision
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'completed_tasks';
  @override
  VerificationContext validateIntegrity(Insertable<CompletedTaskRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('was_one_time')) {
      context.handle(
          _wasOneTimeMeta,
          wasOneTime.isAcceptableOrUnknown(
              data['was_one_time']!, _wasOneTimeMeta));
    } else if (isInserting) {
      context.missing(_wasOneTimeMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('server_revision')) {
      context.handle(
          _serverRevisionMeta,
          serverRevision.isAcceptableOrUnknown(
              data['server_revision']!, _serverRevisionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CompletedTaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompletedTaskRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at'])!,
      wasOneTime: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}was_one_time'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      serverRevision: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_revision'])!,
    );
  }

  @override
  $CompletedTaskEntriesTable createAlias(String alias) {
    return $CompletedTaskEntriesTable(attachedDatabase, alias);
  }
}

class CompletedTaskRow extends DataClass
    implements Insertable<CompletedTaskRow> {
  final String id;
  final String userId;
  final String title;
  final String category;
  final DateTime completedAt;
  final bool wasOneTime;
  final DateTime? deletedAt;
  final int version;
  final int serverRevision;
  const CompletedTaskRow(
      {required this.id,
      required this.userId,
      required this.title,
      required this.category,
      required this.completedAt,
      required this.wasOneTime,
      this.deletedAt,
      required this.version,
      required this.serverRevision});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['title'] = Variable<String>(title);
    map['category'] = Variable<String>(category);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['was_one_time'] = Variable<bool>(wasOneTime);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['version'] = Variable<int>(version);
    map['server_revision'] = Variable<int>(serverRevision);
    return map;
  }

  CompletedTaskEntriesCompanion toCompanion(bool nullToAbsent) {
    return CompletedTaskEntriesCompanion(
      id: Value(id),
      userId: Value(userId),
      title: Value(title),
      category: Value(category),
      completedAt: Value(completedAt),
      wasOneTime: Value(wasOneTime),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      version: Value(version),
      serverRevision: Value(serverRevision),
    );
  }

  factory CompletedTaskRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompletedTaskRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String>(json['category']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      wasOneTime: serializer.fromJson<bool>(json['wasOneTime']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      version: serializer.fromJson<int>(json['version']),
      serverRevision: serializer.fromJson<int>(json['serverRevision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String>(category),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'wasOneTime': serializer.toJson<bool>(wasOneTime),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'version': serializer.toJson<int>(version),
      'serverRevision': serializer.toJson<int>(serverRevision),
    };
  }

  CompletedTaskRow copyWith(
          {String? id,
          String? userId,
          String? title,
          String? category,
          DateTime? completedAt,
          bool? wasOneTime,
          Value<DateTime?> deletedAt = const Value.absent(),
          int? version,
          int? serverRevision}) =>
      CompletedTaskRow(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        category: category ?? this.category,
        completedAt: completedAt ?? this.completedAt,
        wasOneTime: wasOneTime ?? this.wasOneTime,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        version: version ?? this.version,
        serverRevision: serverRevision ?? this.serverRevision,
      );
  CompletedTaskRow copyWithCompanion(CompletedTaskEntriesCompanion data) {
    return CompletedTaskRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      wasOneTime:
          data.wasOneTime.present ? data.wasOneTime.value : this.wasOneTime,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      version: data.version.present ? data.version.value : this.version,
      serverRevision: data.serverRevision.present
          ? data.serverRevision.value
          : this.serverRevision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompletedTaskRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('completedAt: $completedAt, ')
          ..write('wasOneTime: $wasOneTime, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('version: $version, ')
          ..write('serverRevision: $serverRevision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, title, category, completedAt,
      wasOneTime, deletedAt, version, serverRevision);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompletedTaskRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.category == this.category &&
          other.completedAt == this.completedAt &&
          other.wasOneTime == this.wasOneTime &&
          other.deletedAt == this.deletedAt &&
          other.version == this.version &&
          other.serverRevision == this.serverRevision);
}

class CompletedTaskEntriesCompanion extends UpdateCompanion<CompletedTaskRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> title;
  final Value<String> category;
  final Value<DateTime> completedAt;
  final Value<bool> wasOneTime;
  final Value<DateTime?> deletedAt;
  final Value<int> version;
  final Value<int> serverRevision;
  final Value<int> rowid;
  const CompletedTaskEntriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.wasOneTime = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CompletedTaskEntriesCompanion.insert({
    required String id,
    required String userId,
    required String title,
    required String category,
    required DateTime completedAt,
    required bool wasOneTime,
    this.deletedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        title = Value(title),
        category = Value(category),
        completedAt = Value(completedAt),
        wasOneTime = Value(wasOneTime);
  static Insertable<CompletedTaskRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<String>? category,
    Expression<DateTime>? completedAt,
    Expression<bool>? wasOneTime,
    Expression<DateTime>? deletedAt,
    Expression<int>? version,
    Expression<int>? serverRevision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (completedAt != null) 'completed_at': completedAt,
      if (wasOneTime != null) 'was_one_time': wasOneTime,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (version != null) 'version': version,
      if (serverRevision != null) 'server_revision': serverRevision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CompletedTaskEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? title,
      Value<String>? category,
      Value<DateTime>? completedAt,
      Value<bool>? wasOneTime,
      Value<DateTime?>? deletedAt,
      Value<int>? version,
      Value<int>? serverRevision,
      Value<int>? rowid}) {
    return CompletedTaskEntriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      category: category ?? this.category,
      completedAt: completedAt ?? this.completedAt,
      wasOneTime: wasOneTime ?? this.wasOneTime,
      deletedAt: deletedAt ?? this.deletedAt,
      version: version ?? this.version,
      serverRevision: serverRevision ?? this.serverRevision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (wasOneTime.present) {
      map['was_one_time'] = Variable<bool>(wasOneTime.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (serverRevision.present) {
      map['server_revision'] = Variable<int>(serverRevision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompletedTaskEntriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('completedAt: $completedAt, ')
          ..write('wasOneTime: $wasOneTime, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('version: $version, ')
          ..write('serverRevision: $serverRevision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FocusSessionEntriesTable extends FocusSessionEntries
    with TableInfo<$FocusSessionEntriesTable, FocusSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FocusSessionEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endedAtMeta =
      const VerificationMeta('endedAt');
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
      'ended_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _cyclesCompletedMeta =
      const VerificationMeta('cyclesCompleted');
  @override
  late final GeneratedColumn<int> cyclesCompleted = GeneratedColumn<int>(
      'cycles_completed', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _totalMinutesMeta =
      const VerificationMeta('totalMinutes');
  @override
  late final GeneratedColumn<int> totalMinutes = GeneratedColumn<int>(
      'total_minutes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isCompletedMeta =
      const VerificationMeta('isCompleted');
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
      'is_completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_completed" IN (0, 1))'));
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
      'note_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _serverRevisionMeta =
      const VerificationMeta('serverRevision');
  @override
  late final GeneratedColumn<int> serverRevision = GeneratedColumn<int>(
      'server_revision', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        name,
        startedAt,
        endedAt,
        cyclesCompleted,
        totalMinutes,
        isCompleted,
        noteId,
        version,
        serverRevision
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'focus_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<FocusSessionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(_endedAtMeta,
          endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta));
    }
    if (data.containsKey('cycles_completed')) {
      context.handle(
          _cyclesCompletedMeta,
          cyclesCompleted.isAcceptableOrUnknown(
              data['cycles_completed']!, _cyclesCompletedMeta));
    } else if (isInserting) {
      context.missing(_cyclesCompletedMeta);
    }
    if (data.containsKey('total_minutes')) {
      context.handle(
          _totalMinutesMeta,
          totalMinutes.isAcceptableOrUnknown(
              data['total_minutes']!, _totalMinutesMeta));
    } else if (isInserting) {
      context.missing(_totalMinutesMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
          _isCompletedMeta,
          isCompleted.isAcceptableOrUnknown(
              data['is_completed']!, _isCompletedMeta));
    } else if (isInserting) {
      context.missing(_isCompletedMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(_noteIdMeta,
          noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('server_revision')) {
      context.handle(
          _serverRevisionMeta,
          serverRevision.isAcceptableOrUnknown(
              data['server_revision']!, _serverRevisionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FocusSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FocusSessionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      endedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}ended_at']),
      cyclesCompleted: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cycles_completed'])!,
      totalMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_minutes'])!,
      isCompleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_completed'])!,
      noteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note_id']),
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      serverRevision: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_revision'])!,
    );
  }

  @override
  $FocusSessionEntriesTable createAlias(String alias) {
    return $FocusSessionEntriesTable(attachedDatabase, alias);
  }
}

class FocusSessionRow extends DataClass implements Insertable<FocusSessionRow> {
  final String id;
  final String userId;
  final String name;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int cyclesCompleted;
  final int totalMinutes;
  final bool isCompleted;
  final String? noteId;
  final int version;
  final int serverRevision;
  const FocusSessionRow(
      {required this.id,
      required this.userId,
      required this.name,
      required this.startedAt,
      this.endedAt,
      required this.cyclesCompleted,
      required this.totalMinutes,
      required this.isCompleted,
      this.noteId,
      required this.version,
      required this.serverRevision});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['cycles_completed'] = Variable<int>(cyclesCompleted);
    map['total_minutes'] = Variable<int>(totalMinutes);
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || noteId != null) {
      map['note_id'] = Variable<String>(noteId);
    }
    map['version'] = Variable<int>(version);
    map['server_revision'] = Variable<int>(serverRevision);
    return map;
  }

  FocusSessionEntriesCompanion toCompanion(bool nullToAbsent) {
    return FocusSessionEntriesCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      cyclesCompleted: Value(cyclesCompleted),
      totalMinutes: Value(totalMinutes),
      isCompleted: Value(isCompleted),
      noteId:
          noteId == null && nullToAbsent ? const Value.absent() : Value(noteId),
      version: Value(version),
      serverRevision: Value(serverRevision),
    );
  }

  factory FocusSessionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FocusSessionRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      cyclesCompleted: serializer.fromJson<int>(json['cyclesCompleted']),
      totalMinutes: serializer.fromJson<int>(json['totalMinutes']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      noteId: serializer.fromJson<String?>(json['noteId']),
      version: serializer.fromJson<int>(json['version']),
      serverRevision: serializer.fromJson<int>(json['serverRevision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'cyclesCompleted': serializer.toJson<int>(cyclesCompleted),
      'totalMinutes': serializer.toJson<int>(totalMinutes),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'noteId': serializer.toJson<String?>(noteId),
      'version': serializer.toJson<int>(version),
      'serverRevision': serializer.toJson<int>(serverRevision),
    };
  }

  FocusSessionRow copyWith(
          {String? id,
          String? userId,
          String? name,
          DateTime? startedAt,
          Value<DateTime?> endedAt = const Value.absent(),
          int? cyclesCompleted,
          int? totalMinutes,
          bool? isCompleted,
          Value<String?> noteId = const Value.absent(),
          int? version,
          int? serverRevision}) =>
      FocusSessionRow(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt.present ? endedAt.value : this.endedAt,
        cyclesCompleted: cyclesCompleted ?? this.cyclesCompleted,
        totalMinutes: totalMinutes ?? this.totalMinutes,
        isCompleted: isCompleted ?? this.isCompleted,
        noteId: noteId.present ? noteId.value : this.noteId,
        version: version ?? this.version,
        serverRevision: serverRevision ?? this.serverRevision,
      );
  FocusSessionRow copyWithCompanion(FocusSessionEntriesCompanion data) {
    return FocusSessionRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      cyclesCompleted: data.cyclesCompleted.present
          ? data.cyclesCompleted.value
          : this.cyclesCompleted,
      totalMinutes: data.totalMinutes.present
          ? data.totalMinutes.value
          : this.totalMinutes,
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      version: data.version.present ? data.version.value : this.version,
      serverRevision: data.serverRevision.present
          ? data.serverRevision.value
          : this.serverRevision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FocusSessionRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('cyclesCompleted: $cyclesCompleted, ')
          ..write('totalMinutes: $totalMinutes, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('noteId: $noteId, ')
          ..write('version: $version, ')
          ..write('serverRevision: $serverRevision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      name,
      startedAt,
      endedAt,
      cyclesCompleted,
      totalMinutes,
      isCompleted,
      noteId,
      version,
      serverRevision);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FocusSessionRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.cyclesCompleted == this.cyclesCompleted &&
          other.totalMinutes == this.totalMinutes &&
          other.isCompleted == this.isCompleted &&
          other.noteId == this.noteId &&
          other.version == this.version &&
          other.serverRevision == this.serverRevision);
}

class FocusSessionEntriesCompanion extends UpdateCompanion<FocusSessionRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int> cyclesCompleted;
  final Value<int> totalMinutes;
  final Value<bool> isCompleted;
  final Value<String?> noteId;
  final Value<int> version;
  final Value<int> serverRevision;
  final Value<int> rowid;
  const FocusSessionEntriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.cyclesCompleted = const Value.absent(),
    this.totalMinutes = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.noteId = const Value.absent(),
    this.version = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FocusSessionEntriesCompanion.insert({
    required String id,
    required String userId,
    required String name,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    required int cyclesCompleted,
    required int totalMinutes,
    required bool isCompleted,
    this.noteId = const Value.absent(),
    this.version = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        name = Value(name),
        startedAt = Value(startedAt),
        cyclesCompleted = Value(cyclesCompleted),
        totalMinutes = Value(totalMinutes),
        isCompleted = Value(isCompleted);
  static Insertable<FocusSessionRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? cyclesCompleted,
    Expression<int>? totalMinutes,
    Expression<bool>? isCompleted,
    Expression<String>? noteId,
    Expression<int>? version,
    Expression<int>? serverRevision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (cyclesCompleted != null) 'cycles_completed': cyclesCompleted,
      if (totalMinutes != null) 'total_minutes': totalMinutes,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (noteId != null) 'note_id': noteId,
      if (version != null) 'version': version,
      if (serverRevision != null) 'server_revision': serverRevision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FocusSessionEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? name,
      Value<DateTime>? startedAt,
      Value<DateTime?>? endedAt,
      Value<int>? cyclesCompleted,
      Value<int>? totalMinutes,
      Value<bool>? isCompleted,
      Value<String?>? noteId,
      Value<int>? version,
      Value<int>? serverRevision,
      Value<int>? rowid}) {
    return FocusSessionEntriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      cyclesCompleted: cyclesCompleted ?? this.cyclesCompleted,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      noteId: noteId ?? this.noteId,
      version: version ?? this.version,
      serverRevision: serverRevision ?? this.serverRevision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (cyclesCompleted.present) {
      map['cycles_completed'] = Variable<int>(cyclesCompleted.value);
    }
    if (totalMinutes.present) {
      map['total_minutes'] = Variable<int>(totalMinutes.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (serverRevision.present) {
      map['server_revision'] = Variable<int>(serverRevision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FocusSessionEntriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('cyclesCompleted: $cyclesCompleted, ')
          ..write('totalMinutes: $totalMinutes, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('noteId: $noteId, ')
          ..write('version: $version, ')
          ..write('serverRevision: $serverRevision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FocusProgressEntriesTable extends FocusProgressEntries
    with TableInfo<$FocusProgressEntriesTable, FocusProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FocusProgressEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [userId, payloadJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'focus_progress';
  @override
  VerificationContext validateIntegrity(Insertable<FocusProgressRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  FocusProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FocusProgressRow(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $FocusProgressEntriesTable createAlias(String alias) {
    return $FocusProgressEntriesTable(attachedDatabase, alias);
  }
}

class FocusProgressRow extends DataClass
    implements Insertable<FocusProgressRow> {
  final String userId;
  final String payloadJson;
  final DateTime updatedAt;
  const FocusProgressRow(
      {required this.userId,
      required this.payloadJson,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['payload_json'] = Variable<String>(payloadJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FocusProgressEntriesCompanion toCompanion(bool nullToAbsent) {
    return FocusProgressEntriesCompanion(
      userId: Value(userId),
      payloadJson: Value(payloadJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory FocusProgressRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FocusProgressRow(
      userId: serializer.fromJson<String>(json['userId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FocusProgressRow copyWith(
          {String? userId, String? payloadJson, DateTime? updatedAt}) =>
      FocusProgressRow(
        userId: userId ?? this.userId,
        payloadJson: payloadJson ?? this.payloadJson,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  FocusProgressRow copyWithCompanion(FocusProgressEntriesCompanion data) {
    return FocusProgressRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FocusProgressRow(')
          ..write('userId: $userId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, payloadJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FocusProgressRow &&
          other.userId == this.userId &&
          other.payloadJson == this.payloadJson &&
          other.updatedAt == this.updatedAt);
}

class FocusProgressEntriesCompanion extends UpdateCompanion<FocusProgressRow> {
  final Value<String> userId;
  final Value<String> payloadJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FocusProgressEntriesCompanion({
    this.userId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FocusProgressEntriesCompanion.insert({
    required String userId,
    required String payloadJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : userId = Value(userId),
        payloadJson = Value(payloadJson),
        updatedAt = Value(updatedAt);
  static Insertable<FocusProgressRow> custom({
    Expression<String>? userId,
    Expression<String>? payloadJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FocusProgressEntriesCompanion copyWith(
      {Value<String>? userId,
      Value<String>? payloadJson,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return FocusProgressEntriesCompanion(
      userId: userId ?? this.userId,
      payloadJson: payloadJson ?? this.payloadJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FocusProgressEntriesCompanion(')
          ..write('userId: $userId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserPreferenceEntriesTable extends UserPreferenceEntries
    with TableInfo<$UserPreferenceEntriesTable, UserPreferenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserPreferenceEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _themeModeMeta =
      const VerificationMeta('themeMode');
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
      'theme_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('system'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _serverRevisionMeta =
      const VerificationMeta('serverRevision');
  @override
  late final GeneratedColumn<int> serverRevision = GeneratedColumn<int>(
      'server_revision', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [userId, themeMode, updatedAt, version, serverRevision];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_preferences';
  @override
  VerificationContext validateIntegrity(Insertable<UserPreferenceRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('theme_mode')) {
      context.handle(_themeModeMeta,
          themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('server_revision')) {
      context.handle(
          _serverRevisionMeta,
          serverRevision.isAcceptableOrUnknown(
              data['server_revision']!, _serverRevisionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  UserPreferenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserPreferenceRow(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      themeMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}theme_mode'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      serverRevision: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_revision'])!,
    );
  }

  @override
  $UserPreferenceEntriesTable createAlias(String alias) {
    return $UserPreferenceEntriesTable(attachedDatabase, alias);
  }
}

class UserPreferenceRow extends DataClass
    implements Insertable<UserPreferenceRow> {
  final String userId;
  final String themeMode;
  final DateTime updatedAt;
  final int version;
  final int serverRevision;
  const UserPreferenceRow(
      {required this.userId,
      required this.themeMode,
      required this.updatedAt,
      required this.version,
      required this.serverRevision});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['theme_mode'] = Variable<String>(themeMode);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['version'] = Variable<int>(version);
    map['server_revision'] = Variable<int>(serverRevision);
    return map;
  }

  UserPreferenceEntriesCompanion toCompanion(bool nullToAbsent) {
    return UserPreferenceEntriesCompanion(
      userId: Value(userId),
      themeMode: Value(themeMode),
      updatedAt: Value(updatedAt),
      version: Value(version),
      serverRevision: Value(serverRevision),
    );
  }

  factory UserPreferenceRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserPreferenceRow(
      userId: serializer.fromJson<String>(json['userId']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
      serverRevision: serializer.fromJson<int>(json['serverRevision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'themeMode': serializer.toJson<String>(themeMode),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'version': serializer.toJson<int>(version),
      'serverRevision': serializer.toJson<int>(serverRevision),
    };
  }

  UserPreferenceRow copyWith(
          {String? userId,
          String? themeMode,
          DateTime? updatedAt,
          int? version,
          int? serverRevision}) =>
      UserPreferenceRow(
        userId: userId ?? this.userId,
        themeMode: themeMode ?? this.themeMode,
        updatedAt: updatedAt ?? this.updatedAt,
        version: version ?? this.version,
        serverRevision: serverRevision ?? this.serverRevision,
      );
  UserPreferenceRow copyWithCompanion(UserPreferenceEntriesCompanion data) {
    return UserPreferenceRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
      serverRevision: data.serverRevision.present
          ? data.serverRevision.value
          : this.serverRevision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserPreferenceRow(')
          ..write('userId: $userId, ')
          ..write('themeMode: $themeMode, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('serverRevision: $serverRevision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(userId, themeMode, updatedAt, version, serverRevision);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserPreferenceRow &&
          other.userId == this.userId &&
          other.themeMode == this.themeMode &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.serverRevision == this.serverRevision);
}

class UserPreferenceEntriesCompanion
    extends UpdateCompanion<UserPreferenceRow> {
  final Value<String> userId;
  final Value<String> themeMode;
  final Value<DateTime> updatedAt;
  final Value<int> version;
  final Value<int> serverRevision;
  final Value<int> rowid;
  const UserPreferenceEntriesCompanion({
    this.userId = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserPreferenceEntriesCompanion.insert({
    required String userId,
    this.themeMode = const Value.absent(),
    required DateTime updatedAt,
    this.version = const Value.absent(),
    this.serverRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : userId = Value(userId),
        updatedAt = Value(updatedAt);
  static Insertable<UserPreferenceRow> custom({
    Expression<String>? userId,
    Expression<String>? themeMode,
    Expression<DateTime>? updatedAt,
    Expression<int>? version,
    Expression<int>? serverRevision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (themeMode != null) 'theme_mode': themeMode,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (serverRevision != null) 'server_revision': serverRevision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserPreferenceEntriesCompanion copyWith(
      {Value<String>? userId,
      Value<String>? themeMode,
      Value<DateTime>? updatedAt,
      Value<int>? version,
      Value<int>? serverRevision,
      Value<int>? rowid}) {
    return UserPreferenceEntriesCompanion(
      userId: userId ?? this.userId,
      themeMode: themeMode ?? this.themeMode,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      serverRevision: serverRevision ?? this.serverRevision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (serverRevision.present) {
      map['server_revision'] = Variable<int>(serverRevision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserPreferenceEntriesCompanion(')
          ..write('userId: $userId, ')
          ..write('themeMode: $themeMode, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('serverRevision: $serverRevision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOutboxEntriesTable extends SyncOutboxEntries
    with TableInfo<$SyncOutboxEntriesTable, SyncOutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOutboxEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mutationIdMeta =
      const VerificationMeta('mutationId');
  @override
  late final GeneratedColumn<String> mutationId = GeneratedColumn<String>(
      'mutation_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _baseVersionMeta =
      const VerificationMeta('baseVersion');
  @override
  late final GeneratedColumn<int> baseVersion = GeneratedColumn<int>(
      'base_version', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _attemptCountMeta =
      const VerificationMeta('attemptCount');
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
      'attempt_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _nextAttemptAtMeta =
      const VerificationMeta('nextAttemptAt');
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>('next_attempt_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lifecycleMeta =
      const VerificationMeta('lifecycle');
  @override
  late final GeneratedColumn<String> lifecycle = GeneratedColumn<String>(
      'lifecycle', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        mutationId,
        ownerId,
        deviceId,
        entityType,
        entityId,
        operation,
        payloadJson,
        baseVersion,
        createdAt,
        attemptCount,
        nextAttemptAt,
        lifecycle
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox';
  @override
  VerificationContext validateIntegrity(Insertable<SyncOutboxRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('mutation_id')) {
      context.handle(
          _mutationIdMeta,
          mutationId.isAcceptableOrUnknown(
              data['mutation_id']!, _mutationIdMeta));
    } else if (isInserting) {
      context.missing(_mutationIdMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('base_version')) {
      context.handle(
          _baseVersionMeta,
          baseVersion.isAcceptableOrUnknown(
              data['base_version']!, _baseVersionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
          _attemptCountMeta,
          attemptCount.isAcceptableOrUnknown(
              data['attempt_count']!, _attemptCountMeta));
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
          _nextAttemptAtMeta,
          nextAttemptAt.isAcceptableOrUnknown(
              data['next_attempt_at']!, _nextAttemptAtMeta));
    }
    if (data.containsKey('lifecycle')) {
      context.handle(_lifecycleMeta,
          lifecycle.isAcceptableOrUnknown(data['lifecycle']!, _lifecycleMeta));
    } else if (isInserting) {
      context.missing(_lifecycleMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mutationId};
  @override
  SyncOutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOutboxRow(
      mutationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mutation_id'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      baseVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}base_version']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      attemptCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempt_count'])!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}next_attempt_at']),
      lifecycle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lifecycle'])!,
    );
  }

  @override
  $SyncOutboxEntriesTable createAlias(String alias) {
    return $SyncOutboxEntriesTable(attachedDatabase, alias);
  }
}

class SyncOutboxRow extends DataClass implements Insertable<SyncOutboxRow> {
  final String mutationId;
  final String ownerId;
  final String deviceId;
  final String entityType;
  final String entityId;
  final String operation;
  final String payloadJson;
  final int? baseVersion;
  final DateTime createdAt;
  final int attemptCount;
  final DateTime? nextAttemptAt;
  final String lifecycle;
  const SyncOutboxRow(
      {required this.mutationId,
      required this.ownerId,
      required this.deviceId,
      required this.entityType,
      required this.entityId,
      required this.operation,
      required this.payloadJson,
      this.baseVersion,
      required this.createdAt,
      required this.attemptCount,
      this.nextAttemptAt,
      required this.lifecycle});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['mutation_id'] = Variable<String>(mutationId);
    map['owner_id'] = Variable<String>(ownerId);
    map['device_id'] = Variable<String>(deviceId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || baseVersion != null) {
      map['base_version'] = Variable<int>(baseVersion);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    map['lifecycle'] = Variable<String>(lifecycle);
    return map;
  }

  SyncOutboxEntriesCompanion toCompanion(bool nullToAbsent) {
    return SyncOutboxEntriesCompanion(
      mutationId: Value(mutationId),
      ownerId: Value(ownerId),
      deviceId: Value(deviceId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      payloadJson: Value(payloadJson),
      baseVersion: baseVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseVersion),
      createdAt: Value(createdAt),
      attemptCount: Value(attemptCount),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      lifecycle: Value(lifecycle),
    );
  }

  factory SyncOutboxRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOutboxRow(
      mutationId: serializer.fromJson<String>(json['mutationId']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      baseVersion: serializer.fromJson<int?>(json['baseVersion']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      lifecycle: serializer.fromJson<String>(json['lifecycle']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mutationId': serializer.toJson<String>(mutationId),
      'ownerId': serializer.toJson<String>(ownerId),
      'deviceId': serializer.toJson<String>(deviceId),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'baseVersion': serializer.toJson<int?>(baseVersion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'lifecycle': serializer.toJson<String>(lifecycle),
    };
  }

  SyncOutboxRow copyWith(
          {String? mutationId,
          String? ownerId,
          String? deviceId,
          String? entityType,
          String? entityId,
          String? operation,
          String? payloadJson,
          Value<int?> baseVersion = const Value.absent(),
          DateTime? createdAt,
          int? attemptCount,
          Value<DateTime?> nextAttemptAt = const Value.absent(),
          String? lifecycle}) =>
      SyncOutboxRow(
        mutationId: mutationId ?? this.mutationId,
        ownerId: ownerId ?? this.ownerId,
        deviceId: deviceId ?? this.deviceId,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        operation: operation ?? this.operation,
        payloadJson: payloadJson ?? this.payloadJson,
        baseVersion: baseVersion.present ? baseVersion.value : this.baseVersion,
        createdAt: createdAt ?? this.createdAt,
        attemptCount: attemptCount ?? this.attemptCount,
        nextAttemptAt:
            nextAttemptAt.present ? nextAttemptAt.value : this.nextAttemptAt,
        lifecycle: lifecycle ?? this.lifecycle,
      );
  SyncOutboxRow copyWithCompanion(SyncOutboxEntriesCompanion data) {
    return SyncOutboxRow(
      mutationId:
          data.mutationId.present ? data.mutationId.value : this.mutationId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      baseVersion:
          data.baseVersion.present ? data.baseVersion.value : this.baseVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lifecycle: data.lifecycle.present ? data.lifecycle.value : this.lifecycle,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxRow(')
          ..write('mutationId: $mutationId, ')
          ..write('ownerId: $ownerId, ')
          ..write('deviceId: $deviceId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lifecycle: $lifecycle')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      mutationId,
      ownerId,
      deviceId,
      entityType,
      entityId,
      operation,
      payloadJson,
      baseVersion,
      createdAt,
      attemptCount,
      nextAttemptAt,
      lifecycle);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOutboxRow &&
          other.mutationId == this.mutationId &&
          other.ownerId == this.ownerId &&
          other.deviceId == this.deviceId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payloadJson == this.payloadJson &&
          other.baseVersion == this.baseVersion &&
          other.createdAt == this.createdAt &&
          other.attemptCount == this.attemptCount &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lifecycle == this.lifecycle);
}

class SyncOutboxEntriesCompanion extends UpdateCompanion<SyncOutboxRow> {
  final Value<String> mutationId;
  final Value<String> ownerId;
  final Value<String> deviceId;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> payloadJson;
  final Value<int?> baseVersion;
  final Value<DateTime> createdAt;
  final Value<int> attemptCount;
  final Value<DateTime?> nextAttemptAt;
  final Value<String> lifecycle;
  final Value<int> rowid;
  const SyncOutboxEntriesCompanion({
    this.mutationId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.baseVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lifecycle = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncOutboxEntriesCompanion.insert({
    required String mutationId,
    required String ownerId,
    required String deviceId,
    required String entityType,
    required String entityId,
    required String operation,
    required String payloadJson,
    this.baseVersion = const Value.absent(),
    required DateTime createdAt,
    this.attemptCount = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    required String lifecycle,
    this.rowid = const Value.absent(),
  })  : mutationId = Value(mutationId),
        ownerId = Value(ownerId),
        deviceId = Value(deviceId),
        entityType = Value(entityType),
        entityId = Value(entityId),
        operation = Value(operation),
        payloadJson = Value(payloadJson),
        createdAt = Value(createdAt),
        lifecycle = Value(lifecycle);
  static Insertable<SyncOutboxRow> custom({
    Expression<String>? mutationId,
    Expression<String>? ownerId,
    Expression<String>? deviceId,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payloadJson,
    Expression<int>? baseVersion,
    Expression<DateTime>? createdAt,
    Expression<int>? attemptCount,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? lifecycle,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mutationId != null) 'mutation_id': mutationId,
      if (ownerId != null) 'owner_id': ownerId,
      if (deviceId != null) 'device_id': deviceId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (baseVersion != null) 'base_version': baseVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lifecycle != null) 'lifecycle': lifecycle,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncOutboxEntriesCompanion copyWith(
      {Value<String>? mutationId,
      Value<String>? ownerId,
      Value<String>? deviceId,
      Value<String>? entityType,
      Value<String>? entityId,
      Value<String>? operation,
      Value<String>? payloadJson,
      Value<int?>? baseVersion,
      Value<DateTime>? createdAt,
      Value<int>? attemptCount,
      Value<DateTime?>? nextAttemptAt,
      Value<String>? lifecycle,
      Value<int>? rowid}) {
    return SyncOutboxEntriesCompanion(
      mutationId: mutationId ?? this.mutationId,
      ownerId: ownerId ?? this.ownerId,
      deviceId: deviceId ?? this.deviceId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      baseVersion: baseVersion ?? this.baseVersion,
      createdAt: createdAt ?? this.createdAt,
      attemptCount: attemptCount ?? this.attemptCount,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lifecycle: lifecycle ?? this.lifecycle,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mutationId.present) {
      map['mutation_id'] = Variable<String>(mutationId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (baseVersion.present) {
      map['base_version'] = Variable<int>(baseVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lifecycle.present) {
      map['lifecycle'] = Variable<String>(lifecycle.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxEntriesCompanion(')
          ..write('mutationId: $mutationId, ')
          ..write('ownerId: $ownerId, ')
          ..write('deviceId: $deviceId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lifecycle: $lifecycle, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateEntriesTable extends SyncStateEntries
    with TableInfo<$SyncStateEntriesTable, SyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<int> cursor = GeneratedColumn<int>(
      'cursor', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastSuccessfulSyncAtMeta =
      const VerificationMeta('lastSuccessfulSyncAt');
  @override
  late final GeneratedColumn<DateTime> lastSuccessfulSyncAt =
      GeneratedColumn<DateTime>('last_successful_sync_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastAttemptAtMeta =
      const VerificationMeta('lastAttemptAt');
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>('last_attempt_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [ownerId, cursor, lastSuccessfulSyncAt, lastAttemptAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(Insertable<SyncStateRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('cursor')) {
      context.handle(_cursorMeta,
          cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta));
    }
    if (data.containsKey('last_successful_sync_at')) {
      context.handle(
          _lastSuccessfulSyncAtMeta,
          lastSuccessfulSyncAt.isAcceptableOrUnknown(
              data['last_successful_sync_at']!, _lastSuccessfulSyncAtMeta));
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
          _lastAttemptAtMeta,
          lastAttemptAt.isAcceptableOrUnknown(
              data['last_attempt_at']!, _lastAttemptAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId};
  @override
  SyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateRow(
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      cursor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cursor'])!,
      lastSuccessfulSyncAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_successful_sync_at']),
      lastAttemptAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_attempt_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SyncStateEntriesTable createAlias(String alias) {
    return $SyncStateEntriesTable(attachedDatabase, alias);
  }
}

class SyncStateRow extends DataClass implements Insertable<SyncStateRow> {
  final String ownerId;
  final int cursor;
  final DateTime? lastSuccessfulSyncAt;
  final DateTime? lastAttemptAt;
  final DateTime updatedAt;
  const SyncStateRow(
      {required this.ownerId,
      required this.cursor,
      this.lastSuccessfulSyncAt,
      this.lastAttemptAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    map['cursor'] = Variable<int>(cursor);
    if (!nullToAbsent || lastSuccessfulSyncAt != null) {
      map['last_successful_sync_at'] = Variable<DateTime>(lastSuccessfulSyncAt);
    }
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncStateEntriesCompanion toCompanion(bool nullToAbsent) {
    return SyncStateEntriesCompanion(
      ownerId: Value(ownerId),
      cursor: Value(cursor),
      lastSuccessfulSyncAt: lastSuccessfulSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSuccessfulSyncAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncStateRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateRow(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      cursor: serializer.fromJson<int>(json['cursor']),
      lastSuccessfulSyncAt:
          serializer.fromJson<DateTime?>(json['lastSuccessfulSyncAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'cursor': serializer.toJson<int>(cursor),
      'lastSuccessfulSyncAt':
          serializer.toJson<DateTime?>(lastSuccessfulSyncAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncStateRow copyWith(
          {String? ownerId,
          int? cursor,
          Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
          Value<DateTime?> lastAttemptAt = const Value.absent(),
          DateTime? updatedAt}) =>
      SyncStateRow(
        ownerId: ownerId ?? this.ownerId,
        cursor: cursor ?? this.cursor,
        lastSuccessfulSyncAt: lastSuccessfulSyncAt.present
            ? lastSuccessfulSyncAt.value
            : this.lastSuccessfulSyncAt,
        lastAttemptAt:
            lastAttemptAt.present ? lastAttemptAt.value : this.lastAttemptAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SyncStateRow copyWithCompanion(SyncStateEntriesCompanion data) {
    return SyncStateRow(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
      lastSuccessfulSyncAt: data.lastSuccessfulSyncAt.present
          ? data.lastSuccessfulSyncAt.value
          : this.lastSuccessfulSyncAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRow(')
          ..write('ownerId: $ownerId, ')
          ..write('cursor: $cursor, ')
          ..write('lastSuccessfulSyncAt: $lastSuccessfulSyncAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      ownerId, cursor, lastSuccessfulSyncAt, lastAttemptAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateRow &&
          other.ownerId == this.ownerId &&
          other.cursor == this.cursor &&
          other.lastSuccessfulSyncAt == this.lastSuccessfulSyncAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.updatedAt == this.updatedAt);
}

class SyncStateEntriesCompanion extends UpdateCompanion<SyncStateRow> {
  final Value<String> ownerId;
  final Value<int> cursor;
  final Value<DateTime?> lastSuccessfulSyncAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SyncStateEntriesCompanion({
    this.ownerId = const Value.absent(),
    this.cursor = const Value.absent(),
    this.lastSuccessfulSyncAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateEntriesCompanion.insert({
    required String ownerId,
    this.cursor = const Value.absent(),
    this.lastSuccessfulSyncAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : ownerId = Value(ownerId),
        updatedAt = Value(updatedAt);
  static Insertable<SyncStateRow> custom({
    Expression<String>? ownerId,
    Expression<int>? cursor,
    Expression<DateTime>? lastSuccessfulSyncAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (cursor != null) 'cursor': cursor,
      if (lastSuccessfulSyncAt != null)
        'last_successful_sync_at': lastSuccessfulSyncAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateEntriesCompanion copyWith(
      {Value<String>? ownerId,
      Value<int>? cursor,
      Value<DateTime?>? lastSuccessfulSyncAt,
      Value<DateTime?>? lastAttemptAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SyncStateEntriesCompanion(
      ownerId: ownerId ?? this.ownerId,
      cursor: cursor ?? this.cursor,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<int>(cursor.value);
    }
    if (lastSuccessfulSyncAt.present) {
      map['last_successful_sync_at'] =
          Variable<DateTime>(lastSuccessfulSyncAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateEntriesCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('cursor: $cursor, ')
          ..write('lastSuccessfulSyncAt: $lastSuccessfulSyncAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncConflictEntriesTable extends SyncConflictEntries
    with TableInfo<$SyncConflictEntriesTable, SyncConflictRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncConflictEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mutationIdMeta =
      const VerificationMeta('mutationId');
  @override
  late final GeneratedColumn<String> mutationId = GeneratedColumn<String>(
      'mutation_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _localRecordJsonMeta =
      const VerificationMeta('localRecordJson');
  @override
  late final GeneratedColumn<String> localRecordJson = GeneratedColumn<String>(
      'local_record_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _remoteRecordJsonMeta =
      const VerificationMeta('remoteRecordJson');
  @override
  late final GeneratedColumn<String> remoteRecordJson = GeneratedColumn<String>(
      'remote_record_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        ownerId,
        kind,
        entityType,
        entityId,
        mutationId,
        localRecordJson,
        remoteRecordJson,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_conflicts';
  @override
  VerificationContext validateIntegrity(Insertable<SyncConflictRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('mutation_id')) {
      context.handle(
          _mutationIdMeta,
          mutationId.isAcceptableOrUnknown(
              data['mutation_id']!, _mutationIdMeta));
    }
    if (data.containsKey('local_record_json')) {
      context.handle(
          _localRecordJsonMeta,
          localRecordJson.isAcceptableOrUnknown(
              data['local_record_json']!, _localRecordJsonMeta));
    } else if (isInserting) {
      context.missing(_localRecordJsonMeta);
    }
    if (data.containsKey('remote_record_json')) {
      context.handle(
          _remoteRecordJsonMeta,
          remoteRecordJson.isAcceptableOrUnknown(
              data['remote_record_json']!, _remoteRecordJsonMeta));
    } else if (isInserting) {
      context.missing(_remoteRecordJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncConflictRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncConflictRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      mutationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mutation_id']),
      localRecordJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}local_record_json'])!,
      remoteRecordJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}remote_record_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SyncConflictEntriesTable createAlias(String alias) {
    return $SyncConflictEntriesTable(attachedDatabase, alias);
  }
}

class SyncConflictRow extends DataClass implements Insertable<SyncConflictRow> {
  final String id;
  final String ownerId;
  final String kind;
  final String entityType;
  final String entityId;
  final String? mutationId;
  final String localRecordJson;
  final String remoteRecordJson;
  final DateTime createdAt;
  const SyncConflictRow(
      {required this.id,
      required this.ownerId,
      required this.kind,
      required this.entityType,
      required this.entityId,
      this.mutationId,
      required this.localRecordJson,
      required this.remoteRecordJson,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_id'] = Variable<String>(ownerId);
    map['kind'] = Variable<String>(kind);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    if (!nullToAbsent || mutationId != null) {
      map['mutation_id'] = Variable<String>(mutationId);
    }
    map['local_record_json'] = Variable<String>(localRecordJson);
    map['remote_record_json'] = Variable<String>(remoteRecordJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncConflictEntriesCompanion toCompanion(bool nullToAbsent) {
    return SyncConflictEntriesCompanion(
      id: Value(id),
      ownerId: Value(ownerId),
      kind: Value(kind),
      entityType: Value(entityType),
      entityId: Value(entityId),
      mutationId: mutationId == null && nullToAbsent
          ? const Value.absent()
          : Value(mutationId),
      localRecordJson: Value(localRecordJson),
      remoteRecordJson: Value(remoteRecordJson),
      createdAt: Value(createdAt),
    );
  }

  factory SyncConflictRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncConflictRow(
      id: serializer.fromJson<String>(json['id']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      kind: serializer.fromJson<String>(json['kind']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      mutationId: serializer.fromJson<String?>(json['mutationId']),
      localRecordJson: serializer.fromJson<String>(json['localRecordJson']),
      remoteRecordJson: serializer.fromJson<String>(json['remoteRecordJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerId': serializer.toJson<String>(ownerId),
      'kind': serializer.toJson<String>(kind),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'mutationId': serializer.toJson<String?>(mutationId),
      'localRecordJson': serializer.toJson<String>(localRecordJson),
      'remoteRecordJson': serializer.toJson<String>(remoteRecordJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncConflictRow copyWith(
          {String? id,
          String? ownerId,
          String? kind,
          String? entityType,
          String? entityId,
          Value<String?> mutationId = const Value.absent(),
          String? localRecordJson,
          String? remoteRecordJson,
          DateTime? createdAt}) =>
      SyncConflictRow(
        id: id ?? this.id,
        ownerId: ownerId ?? this.ownerId,
        kind: kind ?? this.kind,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        mutationId: mutationId.present ? mutationId.value : this.mutationId,
        localRecordJson: localRecordJson ?? this.localRecordJson,
        remoteRecordJson: remoteRecordJson ?? this.remoteRecordJson,
        createdAt: createdAt ?? this.createdAt,
      );
  SyncConflictRow copyWithCompanion(SyncConflictEntriesCompanion data) {
    return SyncConflictRow(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      kind: data.kind.present ? data.kind.value : this.kind,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      mutationId:
          data.mutationId.present ? data.mutationId.value : this.mutationId,
      localRecordJson: data.localRecordJson.present
          ? data.localRecordJson.value
          : this.localRecordJson,
      remoteRecordJson: data.remoteRecordJson.present
          ? data.remoteRecordJson.value
          : this.remoteRecordJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflictRow(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('kind: $kind, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('mutationId: $mutationId, ')
          ..write('localRecordJson: $localRecordJson, ')
          ..write('remoteRecordJson: $remoteRecordJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ownerId, kind, entityType, entityId,
      mutationId, localRecordJson, remoteRecordJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncConflictRow &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.kind == this.kind &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.mutationId == this.mutationId &&
          other.localRecordJson == this.localRecordJson &&
          other.remoteRecordJson == this.remoteRecordJson &&
          other.createdAt == this.createdAt);
}

class SyncConflictEntriesCompanion extends UpdateCompanion<SyncConflictRow> {
  final Value<String> id;
  final Value<String> ownerId;
  final Value<String> kind;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String?> mutationId;
  final Value<String> localRecordJson;
  final Value<String> remoteRecordJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SyncConflictEntriesCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.kind = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.mutationId = const Value.absent(),
    this.localRecordJson = const Value.absent(),
    this.remoteRecordJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncConflictEntriesCompanion.insert({
    required String id,
    required String ownerId,
    required String kind,
    required String entityType,
    required String entityId,
    this.mutationId = const Value.absent(),
    required String localRecordJson,
    required String remoteRecordJson,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        ownerId = Value(ownerId),
        kind = Value(kind),
        entityType = Value(entityType),
        entityId = Value(entityId),
        localRecordJson = Value(localRecordJson),
        remoteRecordJson = Value(remoteRecordJson),
        createdAt = Value(createdAt);
  static Insertable<SyncConflictRow> custom({
    Expression<String>? id,
    Expression<String>? ownerId,
    Expression<String>? kind,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? mutationId,
    Expression<String>? localRecordJson,
    Expression<String>? remoteRecordJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (kind != null) 'kind': kind,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (mutationId != null) 'mutation_id': mutationId,
      if (localRecordJson != null) 'local_record_json': localRecordJson,
      if (remoteRecordJson != null) 'remote_record_json': remoteRecordJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncConflictEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? ownerId,
      Value<String>? kind,
      Value<String>? entityType,
      Value<String>? entityId,
      Value<String?>? mutationId,
      Value<String>? localRecordJson,
      Value<String>? remoteRecordJson,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return SyncConflictEntriesCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      kind: kind ?? this.kind,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      mutationId: mutationId ?? this.mutationId,
      localRecordJson: localRecordJson ?? this.localRecordJson,
      remoteRecordJson: remoteRecordJson ?? this.remoteRecordJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (mutationId.present) {
      map['mutation_id'] = Variable<String>(mutationId.value);
    }
    if (localRecordJson.present) {
      map['local_record_json'] = Variable<String>(localRecordJson.value);
    }
    if (remoteRecordJson.present) {
      map['remote_record_json'] = Variable<String>(remoteRecordJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflictEntriesCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('kind: $kind, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('mutationId: $mutationId, ')
          ..write('localRecordJson: $localRecordJson, ')
          ..write('remoteRecordJson: $remoteRecordJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalOwnerLinkEntriesTable extends LocalOwnerLinkEntries
    with TableInfo<$LocalOwnerLinkEntriesTable, LocalOwnerLinkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalOwnerLinkEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localOwnerIdMeta =
      const VerificationMeta('localOwnerId');
  @override
  late final GeneratedColumn<String> localOwnerId = GeneratedColumn<String>(
      'local_owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _remoteUserIdMeta =
      const VerificationMeta('remoteUserId');
  @override
  late final GeneratedColumn<String> remoteUserId = GeneratedColumn<String>(
      'remote_user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
      'state', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [localOwnerId, remoteUserId, state, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_owner_links';
  @override
  VerificationContext validateIntegrity(Insertable<LocalOwnerLinkRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_owner_id')) {
      context.handle(
          _localOwnerIdMeta,
          localOwnerId.isAcceptableOrUnknown(
              data['local_owner_id']!, _localOwnerIdMeta));
    } else if (isInserting) {
      context.missing(_localOwnerIdMeta);
    }
    if (data.containsKey('remote_user_id')) {
      context.handle(
          _remoteUserIdMeta,
          remoteUserId.isAcceptableOrUnknown(
              data['remote_user_id']!, _remoteUserIdMeta));
    }
    if (data.containsKey('state')) {
      context.handle(
          _stateMeta, state.isAcceptableOrUnknown(data['state']!, _stateMeta));
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localOwnerId};
  @override
  LocalOwnerLinkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalOwnerLinkRow(
      localOwnerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_owner_id'])!,
      remoteUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remote_user_id']),
      state: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LocalOwnerLinkEntriesTable createAlias(String alias) {
    return $LocalOwnerLinkEntriesTable(attachedDatabase, alias);
  }
}

class LocalOwnerLinkRow extends DataClass
    implements Insertable<LocalOwnerLinkRow> {
  final String localOwnerId;
  final String? remoteUserId;
  final String state;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalOwnerLinkRow(
      {required this.localOwnerId,
      this.remoteUserId,
      required this.state,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_owner_id'] = Variable<String>(localOwnerId);
    if (!nullToAbsent || remoteUserId != null) {
      map['remote_user_id'] = Variable<String>(remoteUserId);
    }
    map['state'] = Variable<String>(state);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalOwnerLinkEntriesCompanion toCompanion(bool nullToAbsent) {
    return LocalOwnerLinkEntriesCompanion(
      localOwnerId: Value(localOwnerId),
      remoteUserId: remoteUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteUserId),
      state: Value(state),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalOwnerLinkRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalOwnerLinkRow(
      localOwnerId: serializer.fromJson<String>(json['localOwnerId']),
      remoteUserId: serializer.fromJson<String?>(json['remoteUserId']),
      state: serializer.fromJson<String>(json['state']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localOwnerId': serializer.toJson<String>(localOwnerId),
      'remoteUserId': serializer.toJson<String?>(remoteUserId),
      'state': serializer.toJson<String>(state),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalOwnerLinkRow copyWith(
          {String? localOwnerId,
          Value<String?> remoteUserId = const Value.absent(),
          String? state,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      LocalOwnerLinkRow(
        localOwnerId: localOwnerId ?? this.localOwnerId,
        remoteUserId:
            remoteUserId.present ? remoteUserId.value : this.remoteUserId,
        state: state ?? this.state,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalOwnerLinkRow copyWithCompanion(LocalOwnerLinkEntriesCompanion data) {
    return LocalOwnerLinkRow(
      localOwnerId: data.localOwnerId.present
          ? data.localOwnerId.value
          : this.localOwnerId,
      remoteUserId: data.remoteUserId.present
          ? data.remoteUserId.value
          : this.remoteUserId,
      state: data.state.present ? data.state.value : this.state,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalOwnerLinkRow(')
          ..write('localOwnerId: $localOwnerId, ')
          ..write('remoteUserId: $remoteUserId, ')
          ..write('state: $state, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(localOwnerId, remoteUserId, state, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalOwnerLinkRow &&
          other.localOwnerId == this.localOwnerId &&
          other.remoteUserId == this.remoteUserId &&
          other.state == this.state &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalOwnerLinkEntriesCompanion
    extends UpdateCompanion<LocalOwnerLinkRow> {
  final Value<String> localOwnerId;
  final Value<String?> remoteUserId;
  final Value<String> state;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalOwnerLinkEntriesCompanion({
    this.localOwnerId = const Value.absent(),
    this.remoteUserId = const Value.absent(),
    this.state = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalOwnerLinkEntriesCompanion.insert({
    required String localOwnerId,
    this.remoteUserId = const Value.absent(),
    required String state,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : localOwnerId = Value(localOwnerId),
        state = Value(state),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<LocalOwnerLinkRow> custom({
    Expression<String>? localOwnerId,
    Expression<String>? remoteUserId,
    Expression<String>? state,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localOwnerId != null) 'local_owner_id': localOwnerId,
      if (remoteUserId != null) 'remote_user_id': remoteUserId,
      if (state != null) 'state': state,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalOwnerLinkEntriesCompanion copyWith(
      {Value<String>? localOwnerId,
      Value<String?>? remoteUserId,
      Value<String>? state,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LocalOwnerLinkEntriesCompanion(
      localOwnerId: localOwnerId ?? this.localOwnerId,
      remoteUserId: remoteUserId ?? this.remoteUserId,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localOwnerId.present) {
      map['local_owner_id'] = Variable<String>(localOwnerId.value);
    }
    if (remoteUserId.present) {
      map['remote_user_id'] = Variable<String>(remoteUserId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalOwnerLinkEntriesCompanion(')
          ..write('localOwnerId: $localOwnerId, ')
          ..write('remoteUserId: $remoteUserId, ')
          ..write('state: $state, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalNotificationBindingEntriesTable
    extends LocalNotificationBindingEntries
    with
        TableInfo<$LocalNotificationBindingEntriesTable,
            LocalNotificationBindingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalNotificationBindingEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _logicalIdMeta =
      const VerificationMeta('logicalId');
  @override
  late final GeneratedColumn<String> logicalId = GeneratedColumn<String>(
      'logical_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notificationIdMeta =
      const VerificationMeta('notificationId');
  @override
  late final GeneratedColumn<int> notificationId = GeneratedColumn<int>(
      'notification_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [logicalId, ownerId, deviceId, notificationId, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_notification_bindings';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalNotificationBindingRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('logical_id')) {
      context.handle(_logicalIdMeta,
          logicalId.isAcceptableOrUnknown(data['logical_id']!, _logicalIdMeta));
    } else if (isInserting) {
      context.missing(_logicalIdMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('notification_id')) {
      context.handle(
          _notificationIdMeta,
          notificationId.isAcceptableOrUnknown(
              data['notification_id']!, _notificationIdMeta));
    } else if (isInserting) {
      context.missing(_notificationIdMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {logicalId, ownerId, deviceId};
  @override
  LocalNotificationBindingRow map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalNotificationBindingRow(
      logicalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}logical_id'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      notificationId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}notification_id'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LocalNotificationBindingEntriesTable createAlias(String alias) {
    return $LocalNotificationBindingEntriesTable(attachedDatabase, alias);
  }
}

class LocalNotificationBindingRow extends DataClass
    implements Insertable<LocalNotificationBindingRow> {
  final String logicalId;
  final String ownerId;
  final String deviceId;
  final int notificationId;
  final DateTime updatedAt;
  const LocalNotificationBindingRow(
      {required this.logicalId,
      required this.ownerId,
      required this.deviceId,
      required this.notificationId,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['logical_id'] = Variable<String>(logicalId);
    map['owner_id'] = Variable<String>(ownerId);
    map['device_id'] = Variable<String>(deviceId);
    map['notification_id'] = Variable<int>(notificationId);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalNotificationBindingEntriesCompanion toCompanion(bool nullToAbsent) {
    return LocalNotificationBindingEntriesCompanion(
      logicalId: Value(logicalId),
      ownerId: Value(ownerId),
      deviceId: Value(deviceId),
      notificationId: Value(notificationId),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalNotificationBindingRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalNotificationBindingRow(
      logicalId: serializer.fromJson<String>(json['logicalId']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      notificationId: serializer.fromJson<int>(json['notificationId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'logicalId': serializer.toJson<String>(logicalId),
      'ownerId': serializer.toJson<String>(ownerId),
      'deviceId': serializer.toJson<String>(deviceId),
      'notificationId': serializer.toJson<int>(notificationId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalNotificationBindingRow copyWith(
          {String? logicalId,
          String? ownerId,
          String? deviceId,
          int? notificationId,
          DateTime? updatedAt}) =>
      LocalNotificationBindingRow(
        logicalId: logicalId ?? this.logicalId,
        ownerId: ownerId ?? this.ownerId,
        deviceId: deviceId ?? this.deviceId,
        notificationId: notificationId ?? this.notificationId,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalNotificationBindingRow copyWithCompanion(
      LocalNotificationBindingEntriesCompanion data) {
    return LocalNotificationBindingRow(
      logicalId: data.logicalId.present ? data.logicalId.value : this.logicalId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      notificationId: data.notificationId.present
          ? data.notificationId.value
          : this.notificationId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalNotificationBindingRow(')
          ..write('logicalId: $logicalId, ')
          ..write('ownerId: $ownerId, ')
          ..write('deviceId: $deviceId, ')
          ..write('notificationId: $notificationId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(logicalId, ownerId, deviceId, notificationId, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalNotificationBindingRow &&
          other.logicalId == this.logicalId &&
          other.ownerId == this.ownerId &&
          other.deviceId == this.deviceId &&
          other.notificationId == this.notificationId &&
          other.updatedAt == this.updatedAt);
}

class LocalNotificationBindingEntriesCompanion
    extends UpdateCompanion<LocalNotificationBindingRow> {
  final Value<String> logicalId;
  final Value<String> ownerId;
  final Value<String> deviceId;
  final Value<int> notificationId;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalNotificationBindingEntriesCompanion({
    this.logicalId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.notificationId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalNotificationBindingEntriesCompanion.insert({
    required String logicalId,
    required String ownerId,
    required String deviceId,
    required int notificationId,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : logicalId = Value(logicalId),
        ownerId = Value(ownerId),
        deviceId = Value(deviceId),
        notificationId = Value(notificationId),
        updatedAt = Value(updatedAt);
  static Insertable<LocalNotificationBindingRow> custom({
    Expression<String>? logicalId,
    Expression<String>? ownerId,
    Expression<String>? deviceId,
    Expression<int>? notificationId,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (logicalId != null) 'logical_id': logicalId,
      if (ownerId != null) 'owner_id': ownerId,
      if (deviceId != null) 'device_id': deviceId,
      if (notificationId != null) 'notification_id': notificationId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalNotificationBindingEntriesCompanion copyWith(
      {Value<String>? logicalId,
      Value<String>? ownerId,
      Value<String>? deviceId,
      Value<int>? notificationId,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LocalNotificationBindingEntriesCompanion(
      logicalId: logicalId ?? this.logicalId,
      ownerId: ownerId ?? this.ownerId,
      deviceId: deviceId ?? this.deviceId,
      notificationId: notificationId ?? this.notificationId,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (logicalId.present) {
      map['logical_id'] = Variable<String>(logicalId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (notificationId.present) {
      map['notification_id'] = Variable<int>(notificationId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalNotificationBindingEntriesCompanion(')
          ..write('logicalId: $logicalId, ')
          ..write('ownerId: $ownerId, ')
          ..write('deviceId: $deviceId, ')
          ..write('notificationId: $notificationId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMigrationStateEntriesTable extends LocalMigrationStateEntries
    with TableInfo<$LocalMigrationStateEntriesTable, LocalMigrationStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMigrationStateEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _migrationNameMeta =
      const VerificationMeta('migrationName');
  @override
  late final GeneratedColumn<String> migrationName = GeneratedColumn<String>(
      'migration_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceChecksumMeta =
      const VerificationMeta('sourceChecksum');
  @override
  late final GeneratedColumn<String> sourceChecksum = GeneratedColumn<String>(
      'source_checksum', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _targetChecksumMeta =
      const VerificationMeta('targetChecksum');
  @override
  late final GeneratedColumn<String> targetChecksum = GeneratedColumn<String>(
      'target_checksum', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceCountsJsonMeta =
      const VerificationMeta('sourceCountsJson');
  @override
  late final GeneratedColumn<String> sourceCountsJson = GeneratedColumn<String>(
      'source_counts_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _targetCountsJsonMeta =
      const VerificationMeta('targetCountsJson');
  @override
  late final GeneratedColumn<String> targetCountsJson = GeneratedColumn<String>(
      'target_counts_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _failureReasonMeta =
      const VerificationMeta('failureReason');
  @override
  late final GeneratedColumn<String> failureReason = GeneratedColumn<String>(
      'failure_reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        ownerId,
        migrationName,
        status,
        sourceChecksum,
        targetChecksum,
        sourceCountsJson,
        targetCountsJson,
        startedAt,
        completedAt,
        failureReason
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_migration_state';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalMigrationStateRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('migration_name')) {
      context.handle(
          _migrationNameMeta,
          migrationName.isAcceptableOrUnknown(
              data['migration_name']!, _migrationNameMeta));
    } else if (isInserting) {
      context.missing(_migrationNameMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('source_checksum')) {
      context.handle(
          _sourceChecksumMeta,
          sourceChecksum.isAcceptableOrUnknown(
              data['source_checksum']!, _sourceChecksumMeta));
    }
    if (data.containsKey('target_checksum')) {
      context.handle(
          _targetChecksumMeta,
          targetChecksum.isAcceptableOrUnknown(
              data['target_checksum']!, _targetChecksumMeta));
    }
    if (data.containsKey('source_counts_json')) {
      context.handle(
          _sourceCountsJsonMeta,
          sourceCountsJson.isAcceptableOrUnknown(
              data['source_counts_json']!, _sourceCountsJsonMeta));
    }
    if (data.containsKey('target_counts_json')) {
      context.handle(
          _targetCountsJsonMeta,
          targetCountsJson.isAcceptableOrUnknown(
              data['target_counts_json']!, _targetCountsJsonMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('failure_reason')) {
      context.handle(
          _failureReasonMeta,
          failureReason.isAcceptableOrUnknown(
              data['failure_reason']!, _failureReasonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId, migrationName};
  @override
  LocalMigrationStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMigrationStateRow(
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      migrationName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}migration_name'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      sourceChecksum: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_checksum']),
      targetChecksum: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_checksum']),
      sourceCountsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_counts_json']),
      targetCountsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}target_counts_json']),
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      failureReason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}failure_reason']),
    );
  }

  @override
  $LocalMigrationStateEntriesTable createAlias(String alias) {
    return $LocalMigrationStateEntriesTable(attachedDatabase, alias);
  }
}

class LocalMigrationStateRow extends DataClass
    implements Insertable<LocalMigrationStateRow> {
  final String ownerId;
  final String migrationName;
  final String status;
  final String? sourceChecksum;
  final String? targetChecksum;
  final String? sourceCountsJson;
  final String? targetCountsJson;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? failureReason;
  const LocalMigrationStateRow(
      {required this.ownerId,
      required this.migrationName,
      required this.status,
      this.sourceChecksum,
      this.targetChecksum,
      this.sourceCountsJson,
      this.targetCountsJson,
      required this.startedAt,
      this.completedAt,
      this.failureReason});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    map['migration_name'] = Variable<String>(migrationName);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || sourceChecksum != null) {
      map['source_checksum'] = Variable<String>(sourceChecksum);
    }
    if (!nullToAbsent || targetChecksum != null) {
      map['target_checksum'] = Variable<String>(targetChecksum);
    }
    if (!nullToAbsent || sourceCountsJson != null) {
      map['source_counts_json'] = Variable<String>(sourceCountsJson);
    }
    if (!nullToAbsent || targetCountsJson != null) {
      map['target_counts_json'] = Variable<String>(targetCountsJson);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || failureReason != null) {
      map['failure_reason'] = Variable<String>(failureReason);
    }
    return map;
  }

  LocalMigrationStateEntriesCompanion toCompanion(bool nullToAbsent) {
    return LocalMigrationStateEntriesCompanion(
      ownerId: Value(ownerId),
      migrationName: Value(migrationName),
      status: Value(status),
      sourceChecksum: sourceChecksum == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceChecksum),
      targetChecksum: targetChecksum == null && nullToAbsent
          ? const Value.absent()
          : Value(targetChecksum),
      sourceCountsJson: sourceCountsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceCountsJson),
      targetCountsJson: targetCountsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(targetCountsJson),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      failureReason: failureReason == null && nullToAbsent
          ? const Value.absent()
          : Value(failureReason),
    );
  }

  factory LocalMigrationStateRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMigrationStateRow(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      migrationName: serializer.fromJson<String>(json['migrationName']),
      status: serializer.fromJson<String>(json['status']),
      sourceChecksum: serializer.fromJson<String?>(json['sourceChecksum']),
      targetChecksum: serializer.fromJson<String?>(json['targetChecksum']),
      sourceCountsJson: serializer.fromJson<String?>(json['sourceCountsJson']),
      targetCountsJson: serializer.fromJson<String?>(json['targetCountsJson']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      failureReason: serializer.fromJson<String?>(json['failureReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'migrationName': serializer.toJson<String>(migrationName),
      'status': serializer.toJson<String>(status),
      'sourceChecksum': serializer.toJson<String?>(sourceChecksum),
      'targetChecksum': serializer.toJson<String?>(targetChecksum),
      'sourceCountsJson': serializer.toJson<String?>(sourceCountsJson),
      'targetCountsJson': serializer.toJson<String?>(targetCountsJson),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'failureReason': serializer.toJson<String?>(failureReason),
    };
  }

  LocalMigrationStateRow copyWith(
          {String? ownerId,
          String? migrationName,
          String? status,
          Value<String?> sourceChecksum = const Value.absent(),
          Value<String?> targetChecksum = const Value.absent(),
          Value<String?> sourceCountsJson = const Value.absent(),
          Value<String?> targetCountsJson = const Value.absent(),
          DateTime? startedAt,
          Value<DateTime?> completedAt = const Value.absent(),
          Value<String?> failureReason = const Value.absent()}) =>
      LocalMigrationStateRow(
        ownerId: ownerId ?? this.ownerId,
        migrationName: migrationName ?? this.migrationName,
        status: status ?? this.status,
        sourceChecksum:
            sourceChecksum.present ? sourceChecksum.value : this.sourceChecksum,
        targetChecksum:
            targetChecksum.present ? targetChecksum.value : this.targetChecksum,
        sourceCountsJson: sourceCountsJson.present
            ? sourceCountsJson.value
            : this.sourceCountsJson,
        targetCountsJson: targetCountsJson.present
            ? targetCountsJson.value
            : this.targetCountsJson,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        failureReason:
            failureReason.present ? failureReason.value : this.failureReason,
      );
  LocalMigrationStateRow copyWithCompanion(
      LocalMigrationStateEntriesCompanion data) {
    return LocalMigrationStateRow(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      migrationName: data.migrationName.present
          ? data.migrationName.value
          : this.migrationName,
      status: data.status.present ? data.status.value : this.status,
      sourceChecksum: data.sourceChecksum.present
          ? data.sourceChecksum.value
          : this.sourceChecksum,
      targetChecksum: data.targetChecksum.present
          ? data.targetChecksum.value
          : this.targetChecksum,
      sourceCountsJson: data.sourceCountsJson.present
          ? data.sourceCountsJson.value
          : this.sourceCountsJson,
      targetCountsJson: data.targetCountsJson.present
          ? data.targetCountsJson.value
          : this.targetCountsJson,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      failureReason: data.failureReason.present
          ? data.failureReason.value
          : this.failureReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMigrationStateRow(')
          ..write('ownerId: $ownerId, ')
          ..write('migrationName: $migrationName, ')
          ..write('status: $status, ')
          ..write('sourceChecksum: $sourceChecksum, ')
          ..write('targetChecksum: $targetChecksum, ')
          ..write('sourceCountsJson: $sourceCountsJson, ')
          ..write('targetCountsJson: $targetCountsJson, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('failureReason: $failureReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      ownerId,
      migrationName,
      status,
      sourceChecksum,
      targetChecksum,
      sourceCountsJson,
      targetCountsJson,
      startedAt,
      completedAt,
      failureReason);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMigrationStateRow &&
          other.ownerId == this.ownerId &&
          other.migrationName == this.migrationName &&
          other.status == this.status &&
          other.sourceChecksum == this.sourceChecksum &&
          other.targetChecksum == this.targetChecksum &&
          other.sourceCountsJson == this.sourceCountsJson &&
          other.targetCountsJson == this.targetCountsJson &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.failureReason == this.failureReason);
}

class LocalMigrationStateEntriesCompanion
    extends UpdateCompanion<LocalMigrationStateRow> {
  final Value<String> ownerId;
  final Value<String> migrationName;
  final Value<String> status;
  final Value<String?> sourceChecksum;
  final Value<String?> targetChecksum;
  final Value<String?> sourceCountsJson;
  final Value<String?> targetCountsJson;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  final Value<String?> failureReason;
  final Value<int> rowid;
  const LocalMigrationStateEntriesCompanion({
    this.ownerId = const Value.absent(),
    this.migrationName = const Value.absent(),
    this.status = const Value.absent(),
    this.sourceChecksum = const Value.absent(),
    this.targetChecksum = const Value.absent(),
    this.sourceCountsJson = const Value.absent(),
    this.targetCountsJson = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.failureReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMigrationStateEntriesCompanion.insert({
    required String ownerId,
    required String migrationName,
    required String status,
    this.sourceChecksum = const Value.absent(),
    this.targetChecksum = const Value.absent(),
    this.sourceCountsJson = const Value.absent(),
    this.targetCountsJson = const Value.absent(),
    required DateTime startedAt,
    this.completedAt = const Value.absent(),
    this.failureReason = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : ownerId = Value(ownerId),
        migrationName = Value(migrationName),
        status = Value(status),
        startedAt = Value(startedAt);
  static Insertable<LocalMigrationStateRow> custom({
    Expression<String>? ownerId,
    Expression<String>? migrationName,
    Expression<String>? status,
    Expression<String>? sourceChecksum,
    Expression<String>? targetChecksum,
    Expression<String>? sourceCountsJson,
    Expression<String>? targetCountsJson,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<String>? failureReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (migrationName != null) 'migration_name': migrationName,
      if (status != null) 'status': status,
      if (sourceChecksum != null) 'source_checksum': sourceChecksum,
      if (targetChecksum != null) 'target_checksum': targetChecksum,
      if (sourceCountsJson != null) 'source_counts_json': sourceCountsJson,
      if (targetCountsJson != null) 'target_counts_json': targetCountsJson,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (failureReason != null) 'failure_reason': failureReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMigrationStateEntriesCompanion copyWith(
      {Value<String>? ownerId,
      Value<String>? migrationName,
      Value<String>? status,
      Value<String?>? sourceChecksum,
      Value<String?>? targetChecksum,
      Value<String?>? sourceCountsJson,
      Value<String?>? targetCountsJson,
      Value<DateTime>? startedAt,
      Value<DateTime?>? completedAt,
      Value<String?>? failureReason,
      Value<int>? rowid}) {
    return LocalMigrationStateEntriesCompanion(
      ownerId: ownerId ?? this.ownerId,
      migrationName: migrationName ?? this.migrationName,
      status: status ?? this.status,
      sourceChecksum: sourceChecksum ?? this.sourceChecksum,
      targetChecksum: targetChecksum ?? this.targetChecksum,
      sourceCountsJson: sourceCountsJson ?? this.sourceCountsJson,
      targetCountsJson: targetCountsJson ?? this.targetCountsJson,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      failureReason: failureReason ?? this.failureReason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (migrationName.present) {
      map['migration_name'] = Variable<String>(migrationName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (sourceChecksum.present) {
      map['source_checksum'] = Variable<String>(sourceChecksum.value);
    }
    if (targetChecksum.present) {
      map['target_checksum'] = Variable<String>(targetChecksum.value);
    }
    if (sourceCountsJson.present) {
      map['source_counts_json'] = Variable<String>(sourceCountsJson.value);
    }
    if (targetCountsJson.present) {
      map['target_counts_json'] = Variable<String>(targetCountsJson.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (failureReason.present) {
      map['failure_reason'] = Variable<String>(failureReason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMigrationStateEntriesCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('migrationName: $migrationName, ')
          ..write('status: $status, ')
          ..write('sourceChecksum: $sourceChecksum, ')
          ..write('targetChecksum: $targetChecksum, ')
          ..write('sourceCountsJson: $sourceCountsJson, ')
          ..write('targetCountsJson: $targetCountsJson, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('failureReason: $failureReason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ZentraDatabase extends GeneratedDatabase {
  _$ZentraDatabase(QueryExecutor e) : super(e);
  $ZentraDatabaseManager get managers => $ZentraDatabaseManager(this);
  late final $NoteEntriesTable noteEntries = $NoteEntriesTable(this);
  late final $NoteTagEntriesTable noteTagEntries = $NoteTagEntriesTable(this);
  late final $NoteReminderEntriesTable noteReminderEntries =
      $NoteReminderEntriesTable(this);
  late final $NoteReviewEntriesTable noteReviewEntries =
      $NoteReviewEntriesTable(this);
  late final $ProfileEntriesTable profileEntries = $ProfileEntriesTable(this);
  late final $HabitEntriesTable habitEntries = $HabitEntriesTable(this);
  late final $HabitScheduleEntriesTable habitScheduleEntries =
      $HabitScheduleEntriesTable(this);
  late final $HabitDayStateEntriesTable habitDayStateEntries =
      $HabitDayStateEntriesTable(this);
  late final $CompletedTaskEntriesTable completedTaskEntries =
      $CompletedTaskEntriesTable(this);
  late final $FocusSessionEntriesTable focusSessionEntries =
      $FocusSessionEntriesTable(this);
  late final $FocusProgressEntriesTable focusProgressEntries =
      $FocusProgressEntriesTable(this);
  late final $UserPreferenceEntriesTable userPreferenceEntries =
      $UserPreferenceEntriesTable(this);
  late final $SyncOutboxEntriesTable syncOutboxEntries =
      $SyncOutboxEntriesTable(this);
  late final $SyncStateEntriesTable syncStateEntries =
      $SyncStateEntriesTable(this);
  late final $SyncConflictEntriesTable syncConflictEntries =
      $SyncConflictEntriesTable(this);
  late final $LocalOwnerLinkEntriesTable localOwnerLinkEntries =
      $LocalOwnerLinkEntriesTable(this);
  late final $LocalNotificationBindingEntriesTable
      localNotificationBindingEntries =
      $LocalNotificationBindingEntriesTable(this);
  late final $LocalMigrationStateEntriesTable localMigrationStateEntries =
      $LocalMigrationStateEntriesTable(this);
  late final Index noteOwnerArchiveUpdatedIdx = Index(
      'note_owner_archive_updated_idx',
      'CREATE INDEX note_owner_archive_updated_idx ON notes (user_id, is_archived, updated_at)');
  late final Index noteTagOwnerValueIdx = Index('note_tag_owner_value_idx',
      'CREATE INDEX note_tag_owner_value_idx ON note_tags (user_id, value)');
  late final Index noteReminderOwnerScheduleIdx = Index(
      'note_reminder_owner_schedule_idx',
      'CREATE INDEX note_reminder_owner_schedule_idx ON note_reminders (user_id, status, scheduled_at_utc)');
  late final Index noteReviewOwnerReviewedIdx = Index(
      'note_review_owner_reviewed_idx',
      'CREATE INDEX note_review_owner_reviewed_idx ON note_reviews (user_id, reviewed_at)');
  late final Index profileOwnerIdx = Index('profile_owner_idx',
      'CREATE UNIQUE INDEX profile_owner_idx ON profiles (user_id)');
  late final Index habitOwnerArchiveCreatedIdx = Index(
      'habit_owner_archive_created_idx',
      'CREATE INDEX habit_owner_archive_created_idx ON habits (user_id, is_archived, created_at)');
  late final Index habitScheduleOwnerHabitIdx = Index(
      'habit_schedule_owner_habit_idx',
      'CREATE UNIQUE INDEX habit_schedule_owner_habit_idx ON habit_schedules (user_id, habit_id)');
  late final Index habitDayStateOwnerDateIdx = Index(
      'habit_day_state_owner_date_idx',
      'CREATE INDEX habit_day_state_owner_date_idx ON habit_day_states (user_id, local_date)');
  late final Index completedTaskOwnerCompletedIdx = Index(
      'completed_task_owner_completed_idx',
      'CREATE INDEX completed_task_owner_completed_idx ON completed_tasks (user_id, completed_at)');
  late final Index focusSessionOwnerStartedIdx = Index(
      'focus_session_owner_started_idx',
      'CREATE INDEX focus_session_owner_started_idx ON focus_sessions (user_id, started_at)');
  late final Index syncOutboxOwnerLifecycleAttemptIdx = Index(
      'sync_outbox_owner_lifecycle_attempt_idx',
      'CREATE INDEX sync_outbox_owner_lifecycle_attempt_idx ON sync_outbox (owner_id, lifecycle, next_attempt_at, created_at)');
  late final Index syncConflictOwnerCreatedIdx = Index(
      'sync_conflict_owner_created_idx',
      'CREATE INDEX sync_conflict_owner_created_idx ON sync_conflicts (owner_id, created_at)');
  late final Index localOwnerRemoteUserIdx = Index(
      'local_owner_remote_user_idx',
      'CREATE UNIQUE INDEX local_owner_remote_user_idx ON local_owner_links (remote_user_id)');
  late final Index localNotificationOwnerDeviceIdx = Index(
      'local_notification_owner_device_idx',
      'CREATE INDEX local_notification_owner_device_idx ON local_notification_bindings (owner_id, device_id)');
  late final Index localMigrationOwnerStatusIdx = Index(
      'local_migration_owner_status_idx',
      'CREATE INDEX local_migration_owner_status_idx ON local_migration_state (owner_id, status)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        noteEntries,
        noteTagEntries,
        noteReminderEntries,
        noteReviewEntries,
        profileEntries,
        habitEntries,
        habitScheduleEntries,
        habitDayStateEntries,
        completedTaskEntries,
        focusSessionEntries,
        focusProgressEntries,
        userPreferenceEntries,
        syncOutboxEntries,
        syncStateEntries,
        syncConflictEntries,
        localOwnerLinkEntries,
        localNotificationBindingEntries,
        localMigrationStateEntries,
        noteOwnerArchiveUpdatedIdx,
        noteTagOwnerValueIdx,
        noteReminderOwnerScheduleIdx,
        noteReviewOwnerReviewedIdx,
        profileOwnerIdx,
        habitOwnerArchiveCreatedIdx,
        habitScheduleOwnerHabitIdx,
        habitDayStateOwnerDateIdx,
        completedTaskOwnerCompletedIdx,
        focusSessionOwnerStartedIdx,
        syncOutboxOwnerLifecycleAttemptIdx,
        syncConflictOwnerCreatedIdx,
        localOwnerRemoteUserIdx,
        localNotificationOwnerDeviceIdx,
        localMigrationOwnerStatusIdx
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('notes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('note_tags', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('notes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('note_reminders', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('notes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('note_reviews', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('habits',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('habit_schedules', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('habits',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('habit_day_states', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$NoteEntriesTableCreateCompanionBuilder = NoteEntriesCompanion
    Function({
  required String id,
  required String userId,
  required String title,
  required String body,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String?> category,
  required String accentKey,
  Value<bool> isPinned,
  Value<bool> isArchived,
  Value<DateTime?> archivedAt,
  Value<DateTime?> deletedAt,
  Value<int> formatVersion,
  Value<int> version,
  Value<int> serverRevision,
  Value<int> rowid,
});
typedef $$NoteEntriesTableUpdateCompanionBuilder = NoteEntriesCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> title,
  Value<String> body,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String?> category,
  Value<String> accentKey,
  Value<bool> isPinned,
  Value<bool> isArchived,
  Value<DateTime?> archivedAt,
  Value<DateTime?> deletedAt,
  Value<int> formatVersion,
  Value<int> version,
  Value<int> serverRevision,
  Value<int> rowid,
});

final class $$NoteEntriesTableReferences
    extends BaseReferences<_$ZentraDatabase, $NoteEntriesTable, NoteRow> {
  $$NoteEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$NoteTagEntriesTable, List<NoteTagRow>>
      _noteTagEntriesRefsTable(_$ZentraDatabase db) =>
          MultiTypedResultKey.fromTable(db.noteTagEntries,
              aliasName: 'notes__id__note_tags__note_id');

  $$NoteTagEntriesTableProcessedTableManager get noteTagEntriesRefs {
    final manager = $$NoteTagEntriesTableTableManager($_db, $_db.noteTagEntries)
        .filter((f) => f.noteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_noteTagEntriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$NoteReminderEntriesTable, List<NoteReminderRow>>
      _noteReminderEntriesRefsTable(_$ZentraDatabase db) =>
          MultiTypedResultKey.fromTable(db.noteReminderEntries,
              aliasName: 'notes__id__note_reminders__note_id');

  $$NoteReminderEntriesTableProcessedTableManager get noteReminderEntriesRefs {
    final manager =
        $$NoteReminderEntriesTableTableManager($_db, $_db.noteReminderEntries)
            .filter((f) => f.noteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_noteReminderEntriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$NoteReviewEntriesTable, List<NoteReviewRow>>
      _noteReviewEntriesRefsTable(_$ZentraDatabase db) =>
          MultiTypedResultKey.fromTable(db.noteReviewEntries,
              aliasName: 'notes__id__note_reviews__note_id');

  $$NoteReviewEntriesTableProcessedTableManager get noteReviewEntriesRefs {
    final manager =
        $$NoteReviewEntriesTableTableManager($_db, $_db.noteReviewEntries)
            .filter((f) => f.noteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_noteReviewEntriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$NoteEntriesTableFilterComposer
    extends Composer<_$ZentraDatabase, $NoteEntriesTable> {
  $$NoteEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accentKey => $composableBuilder(
      column: $table.accentKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get formatVersion => $composableBuilder(
      column: $table.formatVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision,
      builder: (column) => ColumnFilters(column));

  Expression<bool> noteTagEntriesRefs(
      Expression<bool> Function($$NoteTagEntriesTableFilterComposer f) f) {
    final $$NoteTagEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.noteTagEntries,
        getReferencedColumn: (t) => t.noteId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NoteTagEntriesTableFilterComposer(
              $db: $db,
              $table: $db.noteTagEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> noteReminderEntriesRefs(
      Expression<bool> Function($$NoteReminderEntriesTableFilterComposer f) f) {
    final $$NoteReminderEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.noteReminderEntries,
        getReferencedColumn: (t) => t.noteId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NoteReminderEntriesTableFilterComposer(
              $db: $db,
              $table: $db.noteReminderEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> noteReviewEntriesRefs(
      Expression<bool> Function($$NoteReviewEntriesTableFilterComposer f) f) {
    final $$NoteReviewEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.noteReviewEntries,
        getReferencedColumn: (t) => t.noteId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NoteReviewEntriesTableFilterComposer(
              $db: $db,
              $table: $db.noteReviewEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$NoteEntriesTableOrderingComposer
    extends Composer<_$ZentraDatabase, $NoteEntriesTable> {
  $$NoteEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accentKey => $composableBuilder(
      column: $table.accentKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get formatVersion => $composableBuilder(
      column: $table.formatVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision,
      builder: (column) => ColumnOrderings(column));
}

class $$NoteEntriesTableAnnotationComposer
    extends Composer<_$ZentraDatabase, $NoteEntriesTable> {
  $$NoteEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get accentKey =>
      $composableBuilder(column: $table.accentKey, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get formatVersion => $composableBuilder(
      column: $table.formatVersion, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision, builder: (column) => column);

  Expression<T> noteTagEntriesRefs<T extends Object>(
      Expression<T> Function($$NoteTagEntriesTableAnnotationComposer a) f) {
    final $$NoteTagEntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.noteTagEntries,
        getReferencedColumn: (t) => t.noteId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NoteTagEntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.noteTagEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> noteReminderEntriesRefs<T extends Object>(
      Expression<T> Function($$NoteReminderEntriesTableAnnotationComposer a)
          f) {
    final $$NoteReminderEntriesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.noteReminderEntries,
            getReferencedColumn: (t) => t.noteId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$NoteReminderEntriesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.noteReminderEntries,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> noteReviewEntriesRefs<T extends Object>(
      Expression<T> Function($$NoteReviewEntriesTableAnnotationComposer a) f) {
    final $$NoteReviewEntriesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.noteReviewEntries,
            getReferencedColumn: (t) => t.noteId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$NoteReviewEntriesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.noteReviewEntries,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$NoteEntriesTableTableManager extends RootTableManager<
    _$ZentraDatabase,
    $NoteEntriesTable,
    NoteRow,
    $$NoteEntriesTableFilterComposer,
    $$NoteEntriesTableOrderingComposer,
    $$NoteEntriesTableAnnotationComposer,
    $$NoteEntriesTableCreateCompanionBuilder,
    $$NoteEntriesTableUpdateCompanionBuilder,
    (NoteRow, $$NoteEntriesTableReferences),
    NoteRow,
    PrefetchHooks Function(
        {bool noteTagEntriesRefs,
        bool noteReminderEntriesRefs,
        bool noteReviewEntriesRefs})> {
  $$NoteEntriesTableTableManager(_$ZentraDatabase db, $NoteEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NoteEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NoteEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NoteEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String> accentKey = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<DateTime?> archivedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> formatVersion = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> serverRevision = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NoteEntriesCompanion(
            id: id,
            userId: userId,
            title: title,
            body: body,
            createdAt: createdAt,
            updatedAt: updatedAt,
            category: category,
            accentKey: accentKey,
            isPinned: isPinned,
            isArchived: isArchived,
            archivedAt: archivedAt,
            deletedAt: deletedAt,
            formatVersion: formatVersion,
            version: version,
            serverRevision: serverRevision,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String title,
            required String body,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<String?> category = const Value.absent(),
            required String accentKey,
            Value<bool> isPinned = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<DateTime?> archivedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> formatVersion = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> serverRevision = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NoteEntriesCompanion.insert(
            id: id,
            userId: userId,
            title: title,
            body: body,
            createdAt: createdAt,
            updatedAt: updatedAt,
            category: category,
            accentKey: accentKey,
            isPinned: isPinned,
            isArchived: isArchived,
            archivedAt: archivedAt,
            deletedAt: deletedAt,
            formatVersion: formatVersion,
            version: version,
            serverRevision: serverRevision,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$NoteEntriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {noteTagEntriesRefs = false,
              noteReminderEntriesRefs = false,
              noteReviewEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (noteTagEntriesRefs) db.noteTagEntries,
                if (noteReminderEntriesRefs) db.noteReminderEntries,
                if (noteReviewEntriesRefs) db.noteReviewEntries
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (noteTagEntriesRefs)
                    await $_getPrefetchedData<NoteRow, $NoteEntriesTable,
                            NoteTagRow>(
                        currentTable: table,
                        referencedTable: $$NoteEntriesTableReferences
                            ._noteTagEntriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$NoteEntriesTableReferences(db, table, p0)
                                .noteTagEntriesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.noteId == item.id),
                        typedResults: items),
                  if (noteReminderEntriesRefs)
                    await $_getPrefetchedData<NoteRow, $NoteEntriesTable,
                            NoteReminderRow>(
                        currentTable: table,
                        referencedTable: $$NoteEntriesTableReferences
                            ._noteReminderEntriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$NoteEntriesTableReferences(db, table, p0)
                                .noteReminderEntriesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.noteId == item.id),
                        typedResults: items),
                  if (noteReviewEntriesRefs)
                    await $_getPrefetchedData<NoteRow, $NoteEntriesTable,
                            NoteReviewRow>(
                        currentTable: table,
                        referencedTable: $$NoteEntriesTableReferences
                            ._noteReviewEntriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$NoteEntriesTableReferences(db, table, p0)
                                .noteReviewEntriesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.noteId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$NoteEntriesTableProcessedTableManager = ProcessedTableManager<
    _$ZentraDatabase,
    $NoteEntriesTable,
    NoteRow,
    $$NoteEntriesTableFilterComposer,
    $$NoteEntriesTableOrderingComposer,
    $$NoteEntriesTableAnnotationComposer,
    $$NoteEntriesTableCreateCompanionBuilder,
    $$NoteEntriesTableUpdateCompanionBuilder,
    (NoteRow, $$NoteEntriesTableReferences),
    NoteRow,
    PrefetchHooks Function(
        {bool noteTagEntriesRefs,
        bool noteReminderEntriesRefs,
        bool noteReviewEntriesRefs})>;
typedef $$NoteTagEntriesTableCreateCompanionBuilder = NoteTagEntriesCompanion
    Function({
  required String noteId,
  required String userId,
  required String value,
  Value<int> rowid,
});
typedef $$NoteTagEntriesTableUpdateCompanionBuilder = NoteTagEntriesCompanion
    Function({
  Value<String> noteId,
  Value<String> userId,
  Value<String> value,
  Value<int> rowid,
});

final class $$NoteTagEntriesTableReferences
    extends BaseReferences<_$ZentraDatabase, $NoteTagEntriesTable, NoteTagRow> {
  $$NoteTagEntriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $NoteEntriesTable _noteIdTable(_$ZentraDatabase db) =>
      db.noteEntries.createAlias('note_tags__note_id__notes__id');

  $$NoteEntriesTableProcessedTableManager get noteId {
    final $_column = $_itemColumn<String>('note_id')!;

    final manager = $$NoteEntriesTableTableManager($_db, $_db.noteEntries)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_noteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$NoteTagEntriesTableFilterComposer
    extends Composer<_$ZentraDatabase, $NoteTagEntriesTable> {
  $$NoteTagEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  $$NoteEntriesTableFilterComposer get noteId {
    final $$NoteEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.noteEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NoteEntriesTableFilterComposer(
              $db: $db,
              $table: $db.noteEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NoteTagEntriesTableOrderingComposer
    extends Composer<_$ZentraDatabase, $NoteTagEntriesTable> {
  $$NoteTagEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  $$NoteEntriesTableOrderingComposer get noteId {
    final $$NoteEntriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.noteEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NoteEntriesTableOrderingComposer(
              $db: $db,
              $table: $db.noteEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NoteTagEntriesTableAnnotationComposer
    extends Composer<_$ZentraDatabase, $NoteTagEntriesTable> {
  $$NoteTagEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  $$NoteEntriesTableAnnotationComposer get noteId {
    final $$NoteEntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.noteEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NoteEntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.noteEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NoteTagEntriesTableTableManager extends RootTableManager<
    _$ZentraDatabase,
    $NoteTagEntriesTable,
    NoteTagRow,
    $$NoteTagEntriesTableFilterComposer,
    $$NoteTagEntriesTableOrderingComposer,
    $$NoteTagEntriesTableAnnotationComposer,
    $$NoteTagEntriesTableCreateCompanionBuilder,
    $$NoteTagEntriesTableUpdateCompanionBuilder,
    (NoteTagRow, $$NoteTagEntriesTableReferences),
    NoteTagRow,
    PrefetchHooks Function({bool noteId})> {
  $$NoteTagEntriesTableTableManager(
      _$ZentraDatabase db, $NoteTagEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NoteTagEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NoteTagEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NoteTagEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> noteId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NoteTagEntriesCompanion(
            noteId: noteId,
            userId: userId,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String noteId,
            required String userId,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              NoteTagEntriesCompanion.insert(
            noteId: noteId,
            userId: userId,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$NoteTagEntriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({noteId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (noteId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.noteId,
                    referencedTable:
                        $$NoteTagEntriesTableReferences._noteIdTable(db),
                    referencedColumn:
                        $$NoteTagEntriesTableReferences._noteIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$NoteTagEntriesTableProcessedTableManager = ProcessedTableManager<
    _$ZentraDatabase,
    $NoteTagEntriesTable,
    NoteTagRow,
    $$NoteTagEntriesTableFilterComposer,
    $$NoteTagEntriesTableOrderingComposer,
    $$NoteTagEntriesTableAnnotationComposer,
    $$NoteTagEntriesTableCreateCompanionBuilder,
    $$NoteTagEntriesTableUpdateCompanionBuilder,
    (NoteTagRow, $$NoteTagEntriesTableReferences),
    NoteTagRow,
    PrefetchHooks Function({bool noteId})>;
typedef $$NoteReminderEntriesTableCreateCompanionBuilder
    = NoteReminderEntriesCompanion Function({
  required String id,
  required String noteId,
  required String userId,
  required DateTime scheduledAtUtc,
  required String timezoneName,
  required String status,
  required int notificationId,
  required String privacyMode,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> version,
  Value<int> serverRevision,
  Value<int> rowid,
});
typedef $$NoteReminderEntriesTableUpdateCompanionBuilder
    = NoteReminderEntriesCompanion Function({
  Value<String> id,
  Value<String> noteId,
  Value<String> userId,
  Value<DateTime> scheduledAtUtc,
  Value<String> timezoneName,
  Value<String> status,
  Value<int> notificationId,
  Value<String> privacyMode,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> version,
  Value<int> serverRevision,
  Value<int> rowid,
});

final class $$NoteReminderEntriesTableReferences extends BaseReferences<
    _$ZentraDatabase, $NoteReminderEntriesTable, NoteReminderRow> {
  $$NoteReminderEntriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $NoteEntriesTable _noteIdTable(_$ZentraDatabase db) =>
      db.noteEntries.createAlias('note_reminders__note_id__notes__id');

  $$NoteEntriesTableProcessedTableManager get noteId {
    final $_column = $_itemColumn<String>('note_id')!;

    final manager = $$NoteEntriesTableTableManager($_db, $_db.noteEntries)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_noteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$NoteReminderEntriesTableFilterComposer
    extends Composer<_$ZentraDatabase, $NoteReminderEntriesTable> {
  $$NoteReminderEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get scheduledAtUtc => $composableBuilder(
      column: $table.scheduledAtUtc,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get timezoneName => $composableBuilder(
      column: $table.timezoneName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get notificationId => $composableBuilder(
      column: $table.notificationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get privacyMode => $composableBuilder(
      column: $table.privacyMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision,
      builder: (column) => ColumnFilters(column));

  $$NoteEntriesTableFilterComposer get noteId {
    final $$NoteEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.noteEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NoteEntriesTableFilterComposer(
              $db: $db,
              $table: $db.noteEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NoteReminderEntriesTableOrderingComposer
    extends Composer<_$ZentraDatabase, $NoteReminderEntriesTable> {
  $$NoteReminderEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get scheduledAtUtc => $composableBuilder(
      column: $table.scheduledAtUtc,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get timezoneName => $composableBuilder(
      column: $table.timezoneName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get notificationId => $composableBuilder(
      column: $table.notificationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get privacyMode => $composableBuilder(
      column: $table.privacyMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision,
      builder: (column) => ColumnOrderings(column));

  $$NoteEntriesTableOrderingComposer get noteId {
    final $$NoteEntriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.noteEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NoteEntriesTableOrderingComposer(
              $db: $db,
              $table: $db.noteEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NoteReminderEntriesTableAnnotationComposer
    extends Composer<_$ZentraDatabase, $NoteReminderEntriesTable> {
  $$NoteReminderEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledAtUtc => $composableBuilder(
      column: $table.scheduledAtUtc, builder: (column) => column);

  GeneratedColumn<String> get timezoneName => $composableBuilder(
      column: $table.timezoneName, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get notificationId => $composableBuilder(
      column: $table.notificationId, builder: (column) => column);

  GeneratedColumn<String> get privacyMode => $composableBuilder(
      column: $table.privacyMode, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision, builder: (column) => column);

  $$NoteEntriesTableAnnotationComposer get noteId {
    final $$NoteEntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.noteEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NoteEntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.noteEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NoteReminderEntriesTableTableManager extends RootTableManager<
    _$ZentraDatabase,
    $NoteReminderEntriesTable,
    NoteReminderRow,
    $$NoteReminderEntriesTableFilterComposer,
    $$NoteReminderEntriesTableOrderingComposer,
    $$NoteReminderEntriesTableAnnotationComposer,
    $$NoteReminderEntriesTableCreateCompanionBuilder,
    $$NoteReminderEntriesTableUpdateCompanionBuilder,
    (NoteReminderRow, $$NoteReminderEntriesTableReferences),
    NoteReminderRow,
    PrefetchHooks Function({bool noteId})> {
  $$NoteReminderEntriesTableTableManager(
      _$ZentraDatabase db, $NoteReminderEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NoteReminderEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NoteReminderEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NoteReminderEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> noteId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<DateTime> scheduledAtUtc = const Value.absent(),
            Value<String> timezoneName = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> notificationId = const Value.absent(),
            Value<String> privacyMode = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> serverRevision = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NoteReminderEntriesCompanion(
            id: id,
            noteId: noteId,
            userId: userId,
            scheduledAtUtc: scheduledAtUtc,
            timezoneName: timezoneName,
            status: status,
            notificationId: notificationId,
            privacyMode: privacyMode,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            version: version,
            serverRevision: serverRevision,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String noteId,
            required String userId,
            required DateTime scheduledAtUtc,
            required String timezoneName,
            required String status,
            required int notificationId,
            required String privacyMode,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> serverRevision = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NoteReminderEntriesCompanion.insert(
            id: id,
            noteId: noteId,
            userId: userId,
            scheduledAtUtc: scheduledAtUtc,
            timezoneName: timezoneName,
            status: status,
            notificationId: notificationId,
            privacyMode: privacyMode,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            version: version,
            serverRevision: serverRevision,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$NoteReminderEntriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({noteId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (noteId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.noteId,
                    referencedTable:
                        $$NoteReminderEntriesTableReferences._noteIdTable(db),
                    referencedColumn: $$NoteReminderEntriesTableReferences
                        ._noteIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$NoteReminderEntriesTableProcessedTableManager = ProcessedTableManager<
    _$ZentraDatabase,
    $NoteReminderEntriesTable,
    NoteReminderRow,
    $$NoteReminderEntriesTableFilterComposer,
    $$NoteReminderEntriesTableOrderingComposer,
    $$NoteReminderEntriesTableAnnotationComposer,
    $$NoteReminderEntriesTableCreateCompanionBuilder,
    $$NoteReminderEntriesTableUpdateCompanionBuilder,
    (NoteReminderRow, $$NoteReminderEntriesTableReferences),
    NoteReminderRow,
    PrefetchHooks Function({bool noteId})>;
typedef $$NoteReviewEntriesTableCreateCompanionBuilder
    = NoteReviewEntriesCompanion Function({
  required String id,
  required String noteId,
  required String userId,
  required DateTime reviewedAt,
  Value<String?> focusSessionId,
  required String outcome,
  Value<DateTime?> deletedAt,
  Value<int> version,
  Value<int> serverRevision,
  Value<int> rowid,
});
typedef $$NoteReviewEntriesTableUpdateCompanionBuilder
    = NoteReviewEntriesCompanion Function({
  Value<String> id,
  Value<String> noteId,
  Value<String> userId,
  Value<DateTime> reviewedAt,
  Value<String?> focusSessionId,
  Value<String> outcome,
  Value<DateTime?> deletedAt,
  Value<int> version,
  Value<int> serverRevision,
  Value<int> rowid,
});

final class $$NoteReviewEntriesTableReferences extends BaseReferences<
    _$ZentraDatabase, $NoteReviewEntriesTable, NoteReviewRow> {
  $$NoteReviewEntriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $NoteEntriesTable _noteIdTable(_$ZentraDatabase db) =>
      db.noteEntries.createAlias('note_reviews__note_id__notes__id');

  $$NoteEntriesTableProcessedTableManager get noteId {
    final $_column = $_itemColumn<String>('note_id')!;

    final manager = $$NoteEntriesTableTableManager($_db, $_db.noteEntries)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_noteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$NoteReviewEntriesTableFilterComposer
    extends Composer<_$ZentraDatabase, $NoteReviewEntriesTable> {
  $$NoteReviewEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
      column: $table.reviewedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get focusSessionId => $composableBuilder(
      column: $table.focusSessionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get outcome => $composableBuilder(
      column: $table.outcome, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision,
      builder: (column) => ColumnFilters(column));

  $$NoteEntriesTableFilterComposer get noteId {
    final $$NoteEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.noteEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NoteEntriesTableFilterComposer(
              $db: $db,
              $table: $db.noteEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NoteReviewEntriesTableOrderingComposer
    extends Composer<_$ZentraDatabase, $NoteReviewEntriesTable> {
  $$NoteReviewEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
      column: $table.reviewedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get focusSessionId => $composableBuilder(
      column: $table.focusSessionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get outcome => $composableBuilder(
      column: $table.outcome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision,
      builder: (column) => ColumnOrderings(column));

  $$NoteEntriesTableOrderingComposer get noteId {
    final $$NoteEntriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.noteEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NoteEntriesTableOrderingComposer(
              $db: $db,
              $table: $db.noteEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NoteReviewEntriesTableAnnotationComposer
    extends Composer<_$ZentraDatabase, $NoteReviewEntriesTable> {
  $$NoteReviewEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
      column: $table.reviewedAt, builder: (column) => column);

  GeneratedColumn<String> get focusSessionId => $composableBuilder(
      column: $table.focusSessionId, builder: (column) => column);

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision, builder: (column) => column);

  $$NoteEntriesTableAnnotationComposer get noteId {
    final $$NoteEntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.noteEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NoteEntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.noteEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NoteReviewEntriesTableTableManager extends RootTableManager<
    _$ZentraDatabase,
    $NoteReviewEntriesTable,
    NoteReviewRow,
    $$NoteReviewEntriesTableFilterComposer,
    $$NoteReviewEntriesTableOrderingComposer,
    $$NoteReviewEntriesTableAnnotationComposer,
    $$NoteReviewEntriesTableCreateCompanionBuilder,
    $$NoteReviewEntriesTableUpdateCompanionBuilder,
    (NoteReviewRow, $$NoteReviewEntriesTableReferences),
    NoteReviewRow,
    PrefetchHooks Function({bool noteId})> {
  $$NoteReviewEntriesTableTableManager(
      _$ZentraDatabase db, $NoteReviewEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NoteReviewEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NoteReviewEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NoteReviewEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> noteId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<DateTime> reviewedAt = const Value.absent(),
            Value<String?> focusSessionId = const Value.absent(),
            Value<String> outcome = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> serverRevision = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NoteReviewEntriesCompanion(
            id: id,
            noteId: noteId,
            userId: userId,
            reviewedAt: reviewedAt,
            focusSessionId: focusSessionId,
            outcome: outcome,
            deletedAt: deletedAt,
            version: version,
            serverRevision: serverRevision,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String noteId,
            required String userId,
            required DateTime reviewedAt,
            Value<String?> focusSessionId = const Value.absent(),
            required String outcome,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> serverRevision = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NoteReviewEntriesCompanion.insert(
            id: id,
            noteId: noteId,
            userId: userId,
            reviewedAt: reviewedAt,
            focusSessionId: focusSessionId,
            outcome: outcome,
            deletedAt: deletedAt,
            version: version,
            serverRevision: serverRevision,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$NoteReviewEntriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({noteId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (noteId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.noteId,
                    referencedTable:
                        $$NoteReviewEntriesTableReferences._noteIdTable(db),
                    referencedColumn:
                        $$NoteReviewEntriesTableReferences._noteIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$NoteReviewEntriesTableProcessedTableManager = ProcessedTableManager<
    _$ZentraDatabase,
    $NoteReviewEntriesTable,
    NoteReviewRow,
    $$NoteReviewEntriesTableFilterComposer,
    $$NoteReviewEntriesTableOrderingComposer,
    $$NoteReviewEntriesTableAnnotationComposer,
    $$NoteReviewEntriesTableCreateCompanionBuilder,
    $$NoteReviewEntriesTableUpdateCompanionBuilder,
    (NoteReviewRow, $$NoteReviewEntriesTableReferences),
    NoteReviewRow,
    PrefetchHooks Function({bool noteId})>;
typedef $$ProfileEntriesTableCreateCompanionBuilder = ProfileEntriesCompanion
    Function({
  required String id,
  required String userId,
  required String payloadJson,
  required DateTime updatedAt,
  Value<int> version,
  Value<int> serverRevision,
  Value<int> rowid,
});
typedef $$ProfileEntriesTableUpdateCompanionBuilder = ProfileEntriesCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> payloadJson,
  Value<DateTime> updatedAt,
  Value<int> version,
  Value<int> serverRevision,
  Value<int> rowid,
});

class $$ProfileEntriesTableFilterComposer
    extends Composer<_$ZentraDatabase, $ProfileEntriesTable> {
  $$ProfileEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision,
      builder: (column) => ColumnFilters(column));
}

class $$ProfileEntriesTableOrderingComposer
    extends Composer<_$ZentraDatabase, $ProfileEntriesTable> {
  $$ProfileEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision,
      builder: (column) => ColumnOrderings(column));
}

class $$ProfileEntriesTableAnnotationComposer
    extends Composer<_$ZentraDatabase, $ProfileEntriesTable> {
  $$ProfileEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision, builder: (column) => column);
}

class $$ProfileEntriesTableTableManager extends RootTableManager<
    _$ZentraDatabase,
    $ProfileEntriesTable,
    ProfileRow,
    $$ProfileEntriesTableFilterComposer,
    $$ProfileEntriesTableOrderingComposer,
    $$ProfileEntriesTableAnnotationComposer,
    $$ProfileEntriesTableCreateCompanionBuilder,
    $$ProfileEntriesTableUpdateCompanionBuilder,
    (
      ProfileRow,
      BaseReferences<_$ZentraDatabase, $ProfileEntriesTable, ProfileRow>
    ),
    ProfileRow,
    PrefetchHooks Function()> {
  $$ProfileEntriesTableTableManager(
      _$ZentraDatabase db, $ProfileEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfileEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfileEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfileEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> serverRevision = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProfileEntriesCompanion(
            id: id,
            userId: userId,
            payloadJson: payloadJson,
            updatedAt: updatedAt,
            version: version,
            serverRevision: serverRevision,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String payloadJson,
            required DateTime updatedAt,
            Value<int> version = const Value.absent(),
            Value<int> serverRevision = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProfileEntriesCompanion.insert(
            id: id,
            userId: userId,
            payloadJson: payloadJson,
            updatedAt: updatedAt,
            version: version,
            serverRevision: serverRevision,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProfileEntriesTableProcessedTableManager = ProcessedTableManager<
    _$ZentraDatabase,
    $ProfileEntriesTable,
    ProfileRow,
    $$ProfileEntriesTableFilterComposer,
    $$ProfileEntriesTableOrderingComposer,
    $$ProfileEntriesTableAnnotationComposer,
    $$ProfileEntriesTableCreateCompanionBuilder,
    $$ProfileEntriesTableUpdateCompanionBuilder,
    (
      ProfileRow,
      BaseReferences<_$ZentraDatabase, $ProfileEntriesTable, ProfileRow>
    ),
    ProfileRow,
    PrefetchHooks Function()>;
typedef $$HabitEntriesTableCreateCompanionBuilder = HabitEntriesCompanion
    Function({
  required String id,
  required String userId,
  required String title,
  required String category,
  required DateTime createdAt,
  Value<bool> isArchived,
  Value<bool> isOneTime,
  Value<DateTime?> deletedAt,
  Value<int> version,
  Value<int> serverRevision,
  Value<int> rowid,
});
typedef $$HabitEntriesTableUpdateCompanionBuilder = HabitEntriesCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> title,
  Value<String> category,
  Value<DateTime> createdAt,
  Value<bool> isArchived,
  Value<bool> isOneTime,
  Value<DateTime?> deletedAt,
  Value<int> version,
  Value<int> serverRevision,
  Value<int> rowid,
});

final class $$HabitEntriesTableReferences
    extends BaseReferences<_$ZentraDatabase, $HabitEntriesTable, HabitRow> {
  $$HabitEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$HabitScheduleEntriesTable, List<HabitScheduleRow>>
      _habitScheduleEntriesRefsTable(_$ZentraDatabase db) =>
          MultiTypedResultKey.fromTable(db.habitScheduleEntries,
              aliasName: 'habits__id__habit_schedules__habit_id');

  $$HabitScheduleEntriesTableProcessedTableManager
      get habitScheduleEntriesRefs {
    final manager =
        $$HabitScheduleEntriesTableTableManager($_db, $_db.habitScheduleEntries)
            .filter((f) => f.habitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_habitScheduleEntriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$HabitDayStateEntriesTable, List<HabitDayStateRow>>
      _habitDayStateEntriesRefsTable(_$ZentraDatabase db) =>
          MultiTypedResultKey.fromTable(db.habitDayStateEntries,
              aliasName: 'habits__id__habit_day_states__habit_id');

  $$HabitDayStateEntriesTableProcessedTableManager
      get habitDayStateEntriesRefs {
    final manager =
        $$HabitDayStateEntriesTableTableManager($_db, $_db.habitDayStateEntries)
            .filter((f) => f.habitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_habitDayStateEntriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$HabitEntriesTableFilterComposer
    extends Composer<_$ZentraDatabase, $HabitEntriesTable> {
  $$HabitEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isOneTime => $composableBuilder(
      column: $table.isOneTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision,
      builder: (column) => ColumnFilters(column));

  Expression<bool> habitScheduleEntriesRefs(
      Expression<bool> Function($$HabitScheduleEntriesTableFilterComposer f)
          f) {
    final $$HabitScheduleEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.habitScheduleEntries,
        getReferencedColumn: (t) => t.habitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HabitScheduleEntriesTableFilterComposer(
              $db: $db,
              $table: $db.habitScheduleEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> habitDayStateEntriesRefs(
      Expression<bool> Function($$HabitDayStateEntriesTableFilterComposer f)
          f) {
    final $$HabitDayStateEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.habitDayStateEntries,
        getReferencedColumn: (t) => t.habitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HabitDayStateEntriesTableFilterComposer(
              $db: $db,
              $table: $db.habitDayStateEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$HabitEntriesTableOrderingComposer
    extends Composer<_$ZentraDatabase, $HabitEntriesTable> {
  $$HabitEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isOneTime => $composableBuilder(
      column: $table.isOneTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision,
      builder: (column) => ColumnOrderings(column));
}

class $$HabitEntriesTableAnnotationComposer
    extends Composer<_$ZentraDatabase, $HabitEntriesTable> {
  $$HabitEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<bool> get isOneTime =>
      $composableBuilder(column: $table.isOneTime, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision, builder: (column) => column);

  Expression<T> habitScheduleEntriesRefs<T extends Object>(
      Expression<T> Function($$HabitScheduleEntriesTableAnnotationComposer a)
          f) {
    final $$HabitScheduleEntriesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.habitScheduleEntries,
            getReferencedColumn: (t) => t.habitId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$HabitScheduleEntriesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.habitScheduleEntries,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> habitDayStateEntriesRefs<T extends Object>(
      Expression<T> Function($$HabitDayStateEntriesTableAnnotationComposer a)
          f) {
    final $$HabitDayStateEntriesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.habitDayStateEntries,
            getReferencedColumn: (t) => t.habitId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$HabitDayStateEntriesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.habitDayStateEntries,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$HabitEntriesTableTableManager extends RootTableManager<
    _$ZentraDatabase,
    $HabitEntriesTable,
    HabitRow,
    $$HabitEntriesTableFilterComposer,
    $$HabitEntriesTableOrderingComposer,
    $$HabitEntriesTableAnnotationComposer,
    $$HabitEntriesTableCreateCompanionBuilder,
    $$HabitEntriesTableUpdateCompanionBuilder,
    (HabitRow, $$HabitEntriesTableReferences),
    HabitRow,
    PrefetchHooks Function(
        {bool habitScheduleEntriesRefs, bool habitDayStateEntriesRefs})> {
  $$HabitEntriesTableTableManager(_$ZentraDatabase db, $HabitEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<bool> isOneTime = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> serverRevision = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HabitEntriesCompanion(
            id: id,
            userId: userId,
            title: title,
            category: category,
            createdAt: createdAt,
            isArchived: isArchived,
            isOneTime: isOneTime,
            deletedAt: deletedAt,
            version: version,
            serverRevision: serverRevision,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String title,
            required String category,
            required DateTime createdAt,
            Value<bool> isArchived = const Value.absent(),
            Value<bool> isOneTime = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> serverRevision = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HabitEntriesCompanion.insert(
            id: id,
            userId: userId,
            title: title,
            category: category,
            createdAt: createdAt,
            isArchived: isArchived,
            isOneTime: isOneTime,
            deletedAt: deletedAt,
            version: version,
            serverRevision: serverRevision,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$HabitEntriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {habitScheduleEntriesRefs = false,
              habitDayStateEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (habitScheduleEntriesRefs) db.habitScheduleEntries,
                if (habitDayStateEntriesRefs) db.habitDayStateEntries
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (habitScheduleEntriesRefs)
                    await $_getPrefetchedData<HabitRow, $HabitEntriesTable,
                            HabitScheduleRow>(
                        currentTable: table,
                        referencedTable: $$HabitEntriesTableReferences
                            ._habitScheduleEntriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$HabitEntriesTableReferences(db, table, p0)
                                .habitScheduleEntriesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.habitId == item.id),
                        typedResults: items),
                  if (habitDayStateEntriesRefs)
                    await $_getPrefetchedData<HabitRow, $HabitEntriesTable,
                            HabitDayStateRow>(
                        currentTable: table,
                        referencedTable: $$HabitEntriesTableReferences
                            ._habitDayStateEntriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$HabitEntriesTableReferences(db, table, p0)
                                .habitDayStateEntriesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.habitId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$HabitEntriesTableProcessedTableManager = ProcessedTableManager<
    _$ZentraDatabase,
    $HabitEntriesTable,
    HabitRow,
    $$HabitEntriesTableFilterComposer,
    $$HabitEntriesTableOrderingComposer,
    $$HabitEntriesTableAnnotationComposer,
    $$HabitEntriesTableCreateCompanionBuilder,
    $$HabitEntriesTableUpdateCompanionBuilder,
    (HabitRow, $$HabitEntriesTableReferences),
    HabitRow,
    PrefetchHooks Function(
        {bool habitScheduleEntriesRefs, bool habitDayStateEntriesRefs})>;
typedef $$HabitScheduleEntriesTableCreateCompanionBuilder
    = HabitScheduleEntriesCompanion Function({
  required String id,
  required String habitId,
  required String userId,
  required bool isWeekly,
  required String daysOfWeekJson,
  Value<DateTime?> scheduledDate,
  Value<bool> reminderEnabled,
  Value<int?> reminderHour,
  Value<int?> reminderMinute,
  Value<String?> timeZone,
  required DateTime updatedAt,
  Value<int> version,
  Value<int> serverRevision,
  Value<int> rowid,
});
typedef $$HabitScheduleEntriesTableUpdateCompanionBuilder
    = HabitScheduleEntriesCompanion Function({
  Value<String> id,
  Value<String> habitId,
  Value<String> userId,
  Value<bool> isWeekly,
  Value<String> daysOfWeekJson,
  Value<DateTime?> scheduledDate,
  Value<bool> reminderEnabled,
  Value<int?> reminderHour,
  Value<int?> reminderMinute,
  Value<String?> timeZone,
  Value<DateTime> updatedAt,
  Value<int> version,
  Value<int> serverRevision,
  Value<int> rowid,
});

final class $$HabitScheduleEntriesTableReferences extends BaseReferences<
    _$ZentraDatabase, $HabitScheduleEntriesTable, HabitScheduleRow> {
  $$HabitScheduleEntriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $HabitEntriesTable _habitIdTable(_$ZentraDatabase db) =>
      db.habitEntries.createAlias('habit_schedules__habit_id__habits__id');

  $$HabitEntriesTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<String>('habit_id')!;

    final manager = $$HabitEntriesTableTableManager($_db, $_db.habitEntries)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$HabitScheduleEntriesTableFilterComposer
    extends Composer<_$ZentraDatabase, $HabitScheduleEntriesTable> {
  $$HabitScheduleEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isWeekly => $composableBuilder(
      column: $table.isWeekly, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get daysOfWeekJson => $composableBuilder(
      column: $table.daysOfWeekJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get scheduledDate => $composableBuilder(
      column: $table.scheduledDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get reminderEnabled => $composableBuilder(
      column: $table.reminderEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reminderHour => $composableBuilder(
      column: $table.reminderHour, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reminderMinute => $composableBuilder(
      column: $table.reminderMinute,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get timeZone => $composableBuilder(
      column: $table.timeZone, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision,
      builder: (column) => ColumnFilters(column));

  $$HabitEntriesTableFilterComposer get habitId {
    final $$HabitEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.habitId,
        referencedTable: $db.habitEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HabitEntriesTableFilterComposer(
              $db: $db,
              $table: $db.habitEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$HabitScheduleEntriesTableOrderingComposer
    extends Composer<_$ZentraDatabase, $HabitScheduleEntriesTable> {
  $$HabitScheduleEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isWeekly => $composableBuilder(
      column: $table.isWeekly, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get daysOfWeekJson => $composableBuilder(
      column: $table.daysOfWeekJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get scheduledDate => $composableBuilder(
      column: $table.scheduledDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get reminderEnabled => $composableBuilder(
      column: $table.reminderEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reminderHour => $composableBuilder(
      column: $table.reminderHour,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reminderMinute => $composableBuilder(
      column: $table.reminderMinute,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get timeZone => $composableBuilder(
      column: $table.timeZone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision,
      builder: (column) => ColumnOrderings(column));

  $$HabitEntriesTableOrderingComposer get habitId {
    final $$HabitEntriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.habitId,
        referencedTable: $db.habitEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HabitEntriesTableOrderingComposer(
              $db: $db,
              $table: $db.habitEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$HabitScheduleEntriesTableAnnotationComposer
    extends Composer<_$ZentraDatabase, $HabitScheduleEntriesTable> {
  $$HabitScheduleEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<bool> get isWeekly =>
      $composableBuilder(column: $table.isWeekly, builder: (column) => column);

  GeneratedColumn<String> get daysOfWeekJson => $composableBuilder(
      column: $table.daysOfWeekJson, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledDate => $composableBuilder(
      column: $table.scheduledDate, builder: (column) => column);

  GeneratedColumn<bool> get reminderEnabled => $composableBuilder(
      column: $table.reminderEnabled, builder: (column) => column);

  GeneratedColumn<int> get reminderHour => $composableBuilder(
      column: $table.reminderHour, builder: (column) => column);

  GeneratedColumn<int> get reminderMinute => $composableBuilder(
      column: $table.reminderMinute, builder: (column) => column);

  GeneratedColumn<String> get timeZone =>
      $composableBuilder(column: $table.timeZone, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision, builder: (column) => column);

  $$HabitEntriesTableAnnotationComposer get habitId {
    final $$HabitEntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.habitId,
        referencedTable: $db.habitEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HabitEntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.habitEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$HabitScheduleEntriesTableTableManager extends RootTableManager<
    _$ZentraDatabase,
    $HabitScheduleEntriesTable,
    HabitScheduleRow,
    $$HabitScheduleEntriesTableFilterComposer,
    $$HabitScheduleEntriesTableOrderingComposer,
    $$HabitScheduleEntriesTableAnnotationComposer,
    $$HabitScheduleEntriesTableCreateCompanionBuilder,
    $$HabitScheduleEntriesTableUpdateCompanionBuilder,
    (HabitScheduleRow, $$HabitScheduleEntriesTableReferences),
    HabitScheduleRow,
    PrefetchHooks Function({bool habitId})> {
  $$HabitScheduleEntriesTableTableManager(
      _$ZentraDatabase db, $HabitScheduleEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitScheduleEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitScheduleEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitScheduleEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> habitId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<bool> isWeekly = const Value.absent(),
            Value<String> daysOfWeekJson = const Value.absent(),
            Value<DateTime?> scheduledDate = const Value.absent(),
            Value<bool> reminderEnabled = const Value.absent(),
            Value<int?> reminderHour = const Value.absent(),
            Value<int?> reminderMinute = const Value.absent(),
            Value<String?> timeZone = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> serverRevision = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HabitScheduleEntriesCompanion(
            id: id,
            habitId: habitId,
            userId: userId,
            isWeekly: isWeekly,
            daysOfWeekJson: daysOfWeekJson,
            scheduledDate: scheduledDate,
            reminderEnabled: reminderEnabled,
            reminderHour: reminderHour,
            reminderMinute: reminderMinute,
            timeZone: timeZone,
            updatedAt: updatedAt,
            version: version,
            serverRevision: serverRevision,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String habitId,
            required String userId,
            required bool isWeekly,
            required String daysOfWeekJson,
            Value<DateTime?> scheduledDate = const Value.absent(),
            Value<bool> reminderEnabled = const Value.absent(),
            Value<int?> reminderHour = const Value.absent(),
            Value<int?> reminderMinute = const Value.absent(),
            Value<String?> timeZone = const Value.absent(),
            required DateTime updatedAt,
            Value<int> version = const Value.absent(),
            Value<int> serverRevision = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HabitScheduleEntriesCompanion.insert(
            id: id,
            habitId: habitId,
            userId: userId,
            isWeekly: isWeekly,
            daysOfWeekJson: daysOfWeekJson,
            scheduledDate: scheduledDate,
            reminderEnabled: reminderEnabled,
            reminderHour: reminderHour,
            reminderMinute: reminderMinute,
            timeZone: timeZone,
            updatedAt: updatedAt,
            version: version,
            serverRevision: serverRevision,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$HabitScheduleEntriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({habitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (habitId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.habitId,
                    referencedTable:
                        $$HabitScheduleEntriesTableReferences._habitIdTable(db),
                    referencedColumn: $$HabitScheduleEntriesTableReferences
                        ._habitIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$HabitScheduleEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$ZentraDatabase,
        $HabitScheduleEntriesTable,
        HabitScheduleRow,
        $$HabitScheduleEntriesTableFilterComposer,
        $$HabitScheduleEntriesTableOrderingComposer,
        $$HabitScheduleEntriesTableAnnotationComposer,
        $$HabitScheduleEntriesTableCreateCompanionBuilder,
        $$HabitScheduleEntriesTableUpdateCompanionBuilder,
        (HabitScheduleRow, $$HabitScheduleEntriesTableReferences),
        HabitScheduleRow,
        PrefetchHooks Function({bool habitId})>;
typedef $$HabitDayStateEntriesTableCreateCompanionBuilder
    = HabitDayStateEntriesCompanion Function({
  required String id,
  required String habitId,
  required String userId,
  required String localDate,
  required bool completed,
  Value<DateTime?> completedAt,
  Value<int> version,
  Value<int> serverRevision,
  Value<int> rowid,
});
typedef $$HabitDayStateEntriesTableUpdateCompanionBuilder
    = HabitDayStateEntriesCompanion Function({
  Value<String> id,
  Value<String> habitId,
  Value<String> userId,
  Value<String> localDate,
  Value<bool> completed,
  Value<DateTime?> completedAt,
  Value<int> version,
  Value<int> serverRevision,
  Value<int> rowid,
});

final class $$HabitDayStateEntriesTableReferences extends BaseReferences<
    _$ZentraDatabase, $HabitDayStateEntriesTable, HabitDayStateRow> {
  $$HabitDayStateEntriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $HabitEntriesTable _habitIdTable(_$ZentraDatabase db) =>
      db.habitEntries.createAlias('habit_day_states__habit_id__habits__id');

  $$HabitEntriesTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<String>('habit_id')!;

    final manager = $$HabitEntriesTableTableManager($_db, $_db.habitEntries)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$HabitDayStateEntriesTableFilterComposer
    extends Composer<_$ZentraDatabase, $HabitDayStateEntriesTable> {
  $$HabitDayStateEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localDate => $composableBuilder(
      column: $table.localDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision,
      builder: (column) => ColumnFilters(column));

  $$HabitEntriesTableFilterComposer get habitId {
    final $$HabitEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.habitId,
        referencedTable: $db.habitEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HabitEntriesTableFilterComposer(
              $db: $db,
              $table: $db.habitEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$HabitDayStateEntriesTableOrderingComposer
    extends Composer<_$ZentraDatabase, $HabitDayStateEntriesTable> {
  $$HabitDayStateEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localDate => $composableBuilder(
      column: $table.localDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision,
      builder: (column) => ColumnOrderings(column));

  $$HabitEntriesTableOrderingComposer get habitId {
    final $$HabitEntriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.habitId,
        referencedTable: $db.habitEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HabitEntriesTableOrderingComposer(
              $db: $db,
              $table: $db.habitEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$HabitDayStateEntriesTableAnnotationComposer
    extends Composer<_$ZentraDatabase, $HabitDayStateEntriesTable> {
  $$HabitDayStateEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision, builder: (column) => column);

  $$HabitEntriesTableAnnotationComposer get habitId {
    final $$HabitEntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.habitId,
        referencedTable: $db.habitEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HabitEntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.habitEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$HabitDayStateEntriesTableTableManager extends RootTableManager<
    _$ZentraDatabase,
    $HabitDayStateEntriesTable,
    HabitDayStateRow,
    $$HabitDayStateEntriesTableFilterComposer,
    $$HabitDayStateEntriesTableOrderingComposer,
    $$HabitDayStateEntriesTableAnnotationComposer,
    $$HabitDayStateEntriesTableCreateCompanionBuilder,
    $$HabitDayStateEntriesTableUpdateCompanionBuilder,
    (HabitDayStateRow, $$HabitDayStateEntriesTableReferences),
    HabitDayStateRow,
    PrefetchHooks Function({bool habitId})> {
  $$HabitDayStateEntriesTableTableManager(
      _$ZentraDatabase db, $HabitDayStateEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitDayStateEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitDayStateEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitDayStateEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> habitId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> localDate = const Value.absent(),
            Value<bool> completed = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> serverRevision = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HabitDayStateEntriesCompanion(
            id: id,
            habitId: habitId,
            userId: userId,
            localDate: localDate,
            completed: completed,
            completedAt: completedAt,
            version: version,
            serverRevision: serverRevision,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String habitId,
            required String userId,
            required String localDate,
            required bool completed,
            Value<DateTime?> completedAt = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> serverRevision = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HabitDayStateEntriesCompanion.insert(
            id: id,
            habitId: habitId,
            userId: userId,
            localDate: localDate,
            completed: completed,
            completedAt: completedAt,
            version: version,
            serverRevision: serverRevision,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$HabitDayStateEntriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({habitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (habitId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.habitId,
                    referencedTable:
                        $$HabitDayStateEntriesTableReferences._habitIdTable(db),
                    referencedColumn: $$HabitDayStateEntriesTableReferences
                        ._habitIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$HabitDayStateEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$ZentraDatabase,
        $HabitDayStateEntriesTable,
        HabitDayStateRow,
        $$HabitDayStateEntriesTableFilterComposer,
        $$HabitDayStateEntriesTableOrderingComposer,
        $$HabitDayStateEntriesTableAnnotationComposer,
        $$HabitDayStateEntriesTableCreateCompanionBuilder,
        $$HabitDayStateEntriesTableUpdateCompanionBuilder,
        (HabitDayStateRow, $$HabitDayStateEntriesTableReferences),
        HabitDayStateRow,
        PrefetchHooks Function({bool habitId})>;
typedef $$CompletedTaskEntriesTableCreateCompanionBuilder
    = CompletedTaskEntriesCompanion Function({
  required String id,
  required String userId,
  required String title,
  required String category,
  required DateTime completedAt,
  required bool wasOneTime,
  Value<DateTime?> deletedAt,
  Value<int> version,
  Value<int> serverRevision,
  Value<int> rowid,
});
typedef $$CompletedTaskEntriesTableUpdateCompanionBuilder
    = CompletedTaskEntriesCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> title,
  Value<String> category,
  Value<DateTime> completedAt,
  Value<bool> wasOneTime,
  Value<DateTime?> deletedAt,
  Value<int> version,
  Value<int> serverRevision,
  Value<int> rowid,
});

class $$CompletedTaskEntriesTableFilterComposer
    extends Composer<_$ZentraDatabase, $CompletedTaskEntriesTable> {
  $$CompletedTaskEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get wasOneTime => $composableBuilder(
      column: $table.wasOneTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision,
      builder: (column) => ColumnFilters(column));
}

class $$CompletedTaskEntriesTableOrderingComposer
    extends Composer<_$ZentraDatabase, $CompletedTaskEntriesTable> {
  $$CompletedTaskEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get wasOneTime => $composableBuilder(
      column: $table.wasOneTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision,
      builder: (column) => ColumnOrderings(column));
}

class $$CompletedTaskEntriesTableAnnotationComposer
    extends Composer<_$ZentraDatabase, $CompletedTaskEntriesTable> {
  $$CompletedTaskEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<bool> get wasOneTime => $composableBuilder(
      column: $table.wasOneTime, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision, builder: (column) => column);
}

class $$CompletedTaskEntriesTableTableManager extends RootTableManager<
    _$ZentraDatabase,
    $CompletedTaskEntriesTable,
    CompletedTaskRow,
    $$CompletedTaskEntriesTableFilterComposer,
    $$CompletedTaskEntriesTableOrderingComposer,
    $$CompletedTaskEntriesTableAnnotationComposer,
    $$CompletedTaskEntriesTableCreateCompanionBuilder,
    $$CompletedTaskEntriesTableUpdateCompanionBuilder,
    (
      CompletedTaskRow,
      BaseReferences<_$ZentraDatabase, $CompletedTaskEntriesTable,
          CompletedTaskRow>
    ),
    CompletedTaskRow,
    PrefetchHooks Function()> {
  $$CompletedTaskEntriesTableTableManager(
      _$ZentraDatabase db, $CompletedTaskEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompletedTaskEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompletedTaskEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompletedTaskEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<DateTime> completedAt = const Value.absent(),
            Value<bool> wasOneTime = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> serverRevision = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CompletedTaskEntriesCompanion(
            id: id,
            userId: userId,
            title: title,
            category: category,
            completedAt: completedAt,
            wasOneTime: wasOneTime,
            deletedAt: deletedAt,
            version: version,
            serverRevision: serverRevision,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String title,
            required String category,
            required DateTime completedAt,
            required bool wasOneTime,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> serverRevision = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CompletedTaskEntriesCompanion.insert(
            id: id,
            userId: userId,
            title: title,
            category: category,
            completedAt: completedAt,
            wasOneTime: wasOneTime,
            deletedAt: deletedAt,
            version: version,
            serverRevision: serverRevision,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CompletedTaskEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$ZentraDatabase,
        $CompletedTaskEntriesTable,
        CompletedTaskRow,
        $$CompletedTaskEntriesTableFilterComposer,
        $$CompletedTaskEntriesTableOrderingComposer,
        $$CompletedTaskEntriesTableAnnotationComposer,
        $$CompletedTaskEntriesTableCreateCompanionBuilder,
        $$CompletedTaskEntriesTableUpdateCompanionBuilder,
        (
          CompletedTaskRow,
          BaseReferences<_$ZentraDatabase, $CompletedTaskEntriesTable,
              CompletedTaskRow>
        ),
        CompletedTaskRow,
        PrefetchHooks Function()>;
typedef $$FocusSessionEntriesTableCreateCompanionBuilder
    = FocusSessionEntriesCompanion Function({
  required String id,
  required String userId,
  required String name,
  required DateTime startedAt,
  Value<DateTime?> endedAt,
  required int cyclesCompleted,
  required int totalMinutes,
  required bool isCompleted,
  Value<String?> noteId,
  Value<int> version,
  Value<int> serverRevision,
  Value<int> rowid,
});
typedef $$FocusSessionEntriesTableUpdateCompanionBuilder
    = FocusSessionEntriesCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> name,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  Value<int> cyclesCompleted,
  Value<int> totalMinutes,
  Value<bool> isCompleted,
  Value<String?> noteId,
  Value<int> version,
  Value<int> serverRevision,
  Value<int> rowid,
});

class $$FocusSessionEntriesTableFilterComposer
    extends Composer<_$ZentraDatabase, $FocusSessionEntriesTable> {
  $$FocusSessionEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cyclesCompleted => $composableBuilder(
      column: $table.cyclesCompleted,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalMinutes => $composableBuilder(
      column: $table.totalMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get noteId => $composableBuilder(
      column: $table.noteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision,
      builder: (column) => ColumnFilters(column));
}

class $$FocusSessionEntriesTableOrderingComposer
    extends Composer<_$ZentraDatabase, $FocusSessionEntriesTable> {
  $$FocusSessionEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cyclesCompleted => $composableBuilder(
      column: $table.cyclesCompleted,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalMinutes => $composableBuilder(
      column: $table.totalMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get noteId => $composableBuilder(
      column: $table.noteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision,
      builder: (column) => ColumnOrderings(column));
}

class $$FocusSessionEntriesTableAnnotationComposer
    extends Composer<_$ZentraDatabase, $FocusSessionEntriesTable> {
  $$FocusSessionEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get cyclesCompleted => $composableBuilder(
      column: $table.cyclesCompleted, builder: (column) => column);

  GeneratedColumn<int> get totalMinutes => $composableBuilder(
      column: $table.totalMinutes, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => column);

  GeneratedColumn<String> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision, builder: (column) => column);
}

class $$FocusSessionEntriesTableTableManager extends RootTableManager<
    _$ZentraDatabase,
    $FocusSessionEntriesTable,
    FocusSessionRow,
    $$FocusSessionEntriesTableFilterComposer,
    $$FocusSessionEntriesTableOrderingComposer,
    $$FocusSessionEntriesTableAnnotationComposer,
    $$FocusSessionEntriesTableCreateCompanionBuilder,
    $$FocusSessionEntriesTableUpdateCompanionBuilder,
    (
      FocusSessionRow,
      BaseReferences<_$ZentraDatabase, $FocusSessionEntriesTable,
          FocusSessionRow>
    ),
    FocusSessionRow,
    PrefetchHooks Function()> {
  $$FocusSessionEntriesTableTableManager(
      _$ZentraDatabase db, $FocusSessionEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FocusSessionEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FocusSessionEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FocusSessionEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime?> endedAt = const Value.absent(),
            Value<int> cyclesCompleted = const Value.absent(),
            Value<int> totalMinutes = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<String?> noteId = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> serverRevision = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FocusSessionEntriesCompanion(
            id: id,
            userId: userId,
            name: name,
            startedAt: startedAt,
            endedAt: endedAt,
            cyclesCompleted: cyclesCompleted,
            totalMinutes: totalMinutes,
            isCompleted: isCompleted,
            noteId: noteId,
            version: version,
            serverRevision: serverRevision,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String name,
            required DateTime startedAt,
            Value<DateTime?> endedAt = const Value.absent(),
            required int cyclesCompleted,
            required int totalMinutes,
            required bool isCompleted,
            Value<String?> noteId = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> serverRevision = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FocusSessionEntriesCompanion.insert(
            id: id,
            userId: userId,
            name: name,
            startedAt: startedAt,
            endedAt: endedAt,
            cyclesCompleted: cyclesCompleted,
            totalMinutes: totalMinutes,
            isCompleted: isCompleted,
            noteId: noteId,
            version: version,
            serverRevision: serverRevision,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FocusSessionEntriesTableProcessedTableManager = ProcessedTableManager<
    _$ZentraDatabase,
    $FocusSessionEntriesTable,
    FocusSessionRow,
    $$FocusSessionEntriesTableFilterComposer,
    $$FocusSessionEntriesTableOrderingComposer,
    $$FocusSessionEntriesTableAnnotationComposer,
    $$FocusSessionEntriesTableCreateCompanionBuilder,
    $$FocusSessionEntriesTableUpdateCompanionBuilder,
    (
      FocusSessionRow,
      BaseReferences<_$ZentraDatabase, $FocusSessionEntriesTable,
          FocusSessionRow>
    ),
    FocusSessionRow,
    PrefetchHooks Function()>;
typedef $$FocusProgressEntriesTableCreateCompanionBuilder
    = FocusProgressEntriesCompanion Function({
  required String userId,
  required String payloadJson,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$FocusProgressEntriesTableUpdateCompanionBuilder
    = FocusProgressEntriesCompanion Function({
  Value<String> userId,
  Value<String> payloadJson,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$FocusProgressEntriesTableFilterComposer
    extends Composer<_$ZentraDatabase, $FocusProgressEntriesTable> {
  $$FocusProgressEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$FocusProgressEntriesTableOrderingComposer
    extends Composer<_$ZentraDatabase, $FocusProgressEntriesTable> {
  $$FocusProgressEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$FocusProgressEntriesTableAnnotationComposer
    extends Composer<_$ZentraDatabase, $FocusProgressEntriesTable> {
  $$FocusProgressEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FocusProgressEntriesTableTableManager extends RootTableManager<
    _$ZentraDatabase,
    $FocusProgressEntriesTable,
    FocusProgressRow,
    $$FocusProgressEntriesTableFilterComposer,
    $$FocusProgressEntriesTableOrderingComposer,
    $$FocusProgressEntriesTableAnnotationComposer,
    $$FocusProgressEntriesTableCreateCompanionBuilder,
    $$FocusProgressEntriesTableUpdateCompanionBuilder,
    (
      FocusProgressRow,
      BaseReferences<_$ZentraDatabase, $FocusProgressEntriesTable,
          FocusProgressRow>
    ),
    FocusProgressRow,
    PrefetchHooks Function()> {
  $$FocusProgressEntriesTableTableManager(
      _$ZentraDatabase db, $FocusProgressEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FocusProgressEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FocusProgressEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FocusProgressEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> userId = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FocusProgressEntriesCompanion(
            userId: userId,
            payloadJson: payloadJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String userId,
            required String payloadJson,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              FocusProgressEntriesCompanion.insert(
            userId: userId,
            payloadJson: payloadJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FocusProgressEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$ZentraDatabase,
        $FocusProgressEntriesTable,
        FocusProgressRow,
        $$FocusProgressEntriesTableFilterComposer,
        $$FocusProgressEntriesTableOrderingComposer,
        $$FocusProgressEntriesTableAnnotationComposer,
        $$FocusProgressEntriesTableCreateCompanionBuilder,
        $$FocusProgressEntriesTableUpdateCompanionBuilder,
        (
          FocusProgressRow,
          BaseReferences<_$ZentraDatabase, $FocusProgressEntriesTable,
              FocusProgressRow>
        ),
        FocusProgressRow,
        PrefetchHooks Function()>;
typedef $$UserPreferenceEntriesTableCreateCompanionBuilder
    = UserPreferenceEntriesCompanion Function({
  required String userId,
  Value<String> themeMode,
  required DateTime updatedAt,
  Value<int> version,
  Value<int> serverRevision,
  Value<int> rowid,
});
typedef $$UserPreferenceEntriesTableUpdateCompanionBuilder
    = UserPreferenceEntriesCompanion Function({
  Value<String> userId,
  Value<String> themeMode,
  Value<DateTime> updatedAt,
  Value<int> version,
  Value<int> serverRevision,
  Value<int> rowid,
});

class $$UserPreferenceEntriesTableFilterComposer
    extends Composer<_$ZentraDatabase, $UserPreferenceEntriesTable> {
  $$UserPreferenceEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get themeMode => $composableBuilder(
      column: $table.themeMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision,
      builder: (column) => ColumnFilters(column));
}

class $$UserPreferenceEntriesTableOrderingComposer
    extends Composer<_$ZentraDatabase, $UserPreferenceEntriesTable> {
  $$UserPreferenceEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get themeMode => $composableBuilder(
      column: $table.themeMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision,
      builder: (column) => ColumnOrderings(column));
}

class $$UserPreferenceEntriesTableAnnotationComposer
    extends Composer<_$ZentraDatabase, $UserPreferenceEntriesTable> {
  $$UserPreferenceEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get serverRevision => $composableBuilder(
      column: $table.serverRevision, builder: (column) => column);
}

class $$UserPreferenceEntriesTableTableManager extends RootTableManager<
    _$ZentraDatabase,
    $UserPreferenceEntriesTable,
    UserPreferenceRow,
    $$UserPreferenceEntriesTableFilterComposer,
    $$UserPreferenceEntriesTableOrderingComposer,
    $$UserPreferenceEntriesTableAnnotationComposer,
    $$UserPreferenceEntriesTableCreateCompanionBuilder,
    $$UserPreferenceEntriesTableUpdateCompanionBuilder,
    (
      UserPreferenceRow,
      BaseReferences<_$ZentraDatabase, $UserPreferenceEntriesTable,
          UserPreferenceRow>
    ),
    UserPreferenceRow,
    PrefetchHooks Function()> {
  $$UserPreferenceEntriesTableTableManager(
      _$ZentraDatabase db, $UserPreferenceEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserPreferenceEntriesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$UserPreferenceEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserPreferenceEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> userId = const Value.absent(),
            Value<String> themeMode = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> serverRevision = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserPreferenceEntriesCompanion(
            userId: userId,
            themeMode: themeMode,
            updatedAt: updatedAt,
            version: version,
            serverRevision: serverRevision,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String userId,
            Value<String> themeMode = const Value.absent(),
            required DateTime updatedAt,
            Value<int> version = const Value.absent(),
            Value<int> serverRevision = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserPreferenceEntriesCompanion.insert(
            userId: userId,
            themeMode: themeMode,
            updatedAt: updatedAt,
            version: version,
            serverRevision: serverRevision,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserPreferenceEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$ZentraDatabase,
        $UserPreferenceEntriesTable,
        UserPreferenceRow,
        $$UserPreferenceEntriesTableFilterComposer,
        $$UserPreferenceEntriesTableOrderingComposer,
        $$UserPreferenceEntriesTableAnnotationComposer,
        $$UserPreferenceEntriesTableCreateCompanionBuilder,
        $$UserPreferenceEntriesTableUpdateCompanionBuilder,
        (
          UserPreferenceRow,
          BaseReferences<_$ZentraDatabase, $UserPreferenceEntriesTable,
              UserPreferenceRow>
        ),
        UserPreferenceRow,
        PrefetchHooks Function()>;
typedef $$SyncOutboxEntriesTableCreateCompanionBuilder
    = SyncOutboxEntriesCompanion Function({
  required String mutationId,
  required String ownerId,
  required String deviceId,
  required String entityType,
  required String entityId,
  required String operation,
  required String payloadJson,
  Value<int?> baseVersion,
  required DateTime createdAt,
  Value<int> attemptCount,
  Value<DateTime?> nextAttemptAt,
  required String lifecycle,
  Value<int> rowid,
});
typedef $$SyncOutboxEntriesTableUpdateCompanionBuilder
    = SyncOutboxEntriesCompanion Function({
  Value<String> mutationId,
  Value<String> ownerId,
  Value<String> deviceId,
  Value<String> entityType,
  Value<String> entityId,
  Value<String> operation,
  Value<String> payloadJson,
  Value<int?> baseVersion,
  Value<DateTime> createdAt,
  Value<int> attemptCount,
  Value<DateTime?> nextAttemptAt,
  Value<String> lifecycle,
  Value<int> rowid,
});

class $$SyncOutboxEntriesTableFilterComposer
    extends Composer<_$ZentraDatabase, $SyncOutboxEntriesTable> {
  $$SyncOutboxEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get mutationId => $composableBuilder(
      column: $table.mutationId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get baseVersion => $composableBuilder(
      column: $table.baseVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lifecycle => $composableBuilder(
      column: $table.lifecycle, builder: (column) => ColumnFilters(column));
}

class $$SyncOutboxEntriesTableOrderingComposer
    extends Composer<_$ZentraDatabase, $SyncOutboxEntriesTable> {
  $$SyncOutboxEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mutationId => $composableBuilder(
      column: $table.mutationId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get baseVersion => $composableBuilder(
      column: $table.baseVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lifecycle => $composableBuilder(
      column: $table.lifecycle, builder: (column) => ColumnOrderings(column));
}

class $$SyncOutboxEntriesTableAnnotationComposer
    extends Composer<_$ZentraDatabase, $SyncOutboxEntriesTable> {
  $$SyncOutboxEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get mutationId => $composableBuilder(
      column: $table.mutationId, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<int> get baseVersion => $composableBuilder(
      column: $table.baseVersion, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
      column: $table.nextAttemptAt, builder: (column) => column);

  GeneratedColumn<String> get lifecycle =>
      $composableBuilder(column: $table.lifecycle, builder: (column) => column);
}

class $$SyncOutboxEntriesTableTableManager extends RootTableManager<
    _$ZentraDatabase,
    $SyncOutboxEntriesTable,
    SyncOutboxRow,
    $$SyncOutboxEntriesTableFilterComposer,
    $$SyncOutboxEntriesTableOrderingComposer,
    $$SyncOutboxEntriesTableAnnotationComposer,
    $$SyncOutboxEntriesTableCreateCompanionBuilder,
    $$SyncOutboxEntriesTableUpdateCompanionBuilder,
    (
      SyncOutboxRow,
      BaseReferences<_$ZentraDatabase, $SyncOutboxEntriesTable, SyncOutboxRow>
    ),
    SyncOutboxRow,
    PrefetchHooks Function()> {
  $$SyncOutboxEntriesTableTableManager(
      _$ZentraDatabase db, $SyncOutboxEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOutboxEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOutboxEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOutboxEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> mutationId = const Value.absent(),
            Value<String> ownerId = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<int?> baseVersion = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> attemptCount = const Value.absent(),
            Value<DateTime?> nextAttemptAt = const Value.absent(),
            Value<String> lifecycle = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncOutboxEntriesCompanion(
            mutationId: mutationId,
            ownerId: ownerId,
            deviceId: deviceId,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payloadJson: payloadJson,
            baseVersion: baseVersion,
            createdAt: createdAt,
            attemptCount: attemptCount,
            nextAttemptAt: nextAttemptAt,
            lifecycle: lifecycle,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String mutationId,
            required String ownerId,
            required String deviceId,
            required String entityType,
            required String entityId,
            required String operation,
            required String payloadJson,
            Value<int?> baseVersion = const Value.absent(),
            required DateTime createdAt,
            Value<int> attemptCount = const Value.absent(),
            Value<DateTime?> nextAttemptAt = const Value.absent(),
            required String lifecycle,
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncOutboxEntriesCompanion.insert(
            mutationId: mutationId,
            ownerId: ownerId,
            deviceId: deviceId,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payloadJson: payloadJson,
            baseVersion: baseVersion,
            createdAt: createdAt,
            attemptCount: attemptCount,
            nextAttemptAt: nextAttemptAt,
            lifecycle: lifecycle,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncOutboxEntriesTableProcessedTableManager = ProcessedTableManager<
    _$ZentraDatabase,
    $SyncOutboxEntriesTable,
    SyncOutboxRow,
    $$SyncOutboxEntriesTableFilterComposer,
    $$SyncOutboxEntriesTableOrderingComposer,
    $$SyncOutboxEntriesTableAnnotationComposer,
    $$SyncOutboxEntriesTableCreateCompanionBuilder,
    $$SyncOutboxEntriesTableUpdateCompanionBuilder,
    (
      SyncOutboxRow,
      BaseReferences<_$ZentraDatabase, $SyncOutboxEntriesTable, SyncOutboxRow>
    ),
    SyncOutboxRow,
    PrefetchHooks Function()>;
typedef $$SyncStateEntriesTableCreateCompanionBuilder
    = SyncStateEntriesCompanion Function({
  required String ownerId,
  Value<int> cursor,
  Value<DateTime?> lastSuccessfulSyncAt,
  Value<DateTime?> lastAttemptAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$SyncStateEntriesTableUpdateCompanionBuilder
    = SyncStateEntriesCompanion Function({
  Value<String> ownerId,
  Value<int> cursor,
  Value<DateTime?> lastSuccessfulSyncAt,
  Value<DateTime?> lastAttemptAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SyncStateEntriesTableFilterComposer
    extends Composer<_$ZentraDatabase, $SyncStateEntriesTable> {
  $$SyncStateEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cursor => $composableBuilder(
      column: $table.cursor, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
      column: $table.lastSuccessfulSyncAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SyncStateEntriesTableOrderingComposer
    extends Composer<_$ZentraDatabase, $SyncStateEntriesTable> {
  $$SyncStateEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cursor => $composableBuilder(
      column: $table.cursor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
      column: $table.lastSuccessfulSyncAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncStateEntriesTableAnnotationComposer
    extends Composer<_$ZentraDatabase, $SyncStateEntriesTable> {
  $$SyncStateEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<int> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
      column: $table.lastSuccessfulSyncAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncStateEntriesTableTableManager extends RootTableManager<
    _$ZentraDatabase,
    $SyncStateEntriesTable,
    SyncStateRow,
    $$SyncStateEntriesTableFilterComposer,
    $$SyncStateEntriesTableOrderingComposer,
    $$SyncStateEntriesTableAnnotationComposer,
    $$SyncStateEntriesTableCreateCompanionBuilder,
    $$SyncStateEntriesTableUpdateCompanionBuilder,
    (
      SyncStateRow,
      BaseReferences<_$ZentraDatabase, $SyncStateEntriesTable, SyncStateRow>
    ),
    SyncStateRow,
    PrefetchHooks Function()> {
  $$SyncStateEntriesTableTableManager(
      _$ZentraDatabase db, $SyncStateEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> ownerId = const Value.absent(),
            Value<int> cursor = const Value.absent(),
            Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
            Value<DateTime?> lastAttemptAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncStateEntriesCompanion(
            ownerId: ownerId,
            cursor: cursor,
            lastSuccessfulSyncAt: lastSuccessfulSyncAt,
            lastAttemptAt: lastAttemptAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String ownerId,
            Value<int> cursor = const Value.absent(),
            Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
            Value<DateTime?> lastAttemptAt = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncStateEntriesCompanion.insert(
            ownerId: ownerId,
            cursor: cursor,
            lastSuccessfulSyncAt: lastSuccessfulSyncAt,
            lastAttemptAt: lastAttemptAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncStateEntriesTableProcessedTableManager = ProcessedTableManager<
    _$ZentraDatabase,
    $SyncStateEntriesTable,
    SyncStateRow,
    $$SyncStateEntriesTableFilterComposer,
    $$SyncStateEntriesTableOrderingComposer,
    $$SyncStateEntriesTableAnnotationComposer,
    $$SyncStateEntriesTableCreateCompanionBuilder,
    $$SyncStateEntriesTableUpdateCompanionBuilder,
    (
      SyncStateRow,
      BaseReferences<_$ZentraDatabase, $SyncStateEntriesTable, SyncStateRow>
    ),
    SyncStateRow,
    PrefetchHooks Function()>;
typedef $$SyncConflictEntriesTableCreateCompanionBuilder
    = SyncConflictEntriesCompanion Function({
  required String id,
  required String ownerId,
  required String kind,
  required String entityType,
  required String entityId,
  Value<String?> mutationId,
  required String localRecordJson,
  required String remoteRecordJson,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$SyncConflictEntriesTableUpdateCompanionBuilder
    = SyncConflictEntriesCompanion Function({
  Value<String> id,
  Value<String> ownerId,
  Value<String> kind,
  Value<String> entityType,
  Value<String> entityId,
  Value<String?> mutationId,
  Value<String> localRecordJson,
  Value<String> remoteRecordJson,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$SyncConflictEntriesTableFilterComposer
    extends Composer<_$ZentraDatabase, $SyncConflictEntriesTable> {
  $$SyncConflictEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mutationId => $composableBuilder(
      column: $table.mutationId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localRecordJson => $composableBuilder(
      column: $table.localRecordJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteRecordJson => $composableBuilder(
      column: $table.remoteRecordJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$SyncConflictEntriesTableOrderingComposer
    extends Composer<_$ZentraDatabase, $SyncConflictEntriesTable> {
  $$SyncConflictEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mutationId => $composableBuilder(
      column: $table.mutationId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localRecordJson => $composableBuilder(
      column: $table.localRecordJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteRecordJson => $composableBuilder(
      column: $table.remoteRecordJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncConflictEntriesTableAnnotationComposer
    extends Composer<_$ZentraDatabase, $SyncConflictEntriesTable> {
  $$SyncConflictEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get mutationId => $composableBuilder(
      column: $table.mutationId, builder: (column) => column);

  GeneratedColumn<String> get localRecordJson => $composableBuilder(
      column: $table.localRecordJson, builder: (column) => column);

  GeneratedColumn<String> get remoteRecordJson => $composableBuilder(
      column: $table.remoteRecordJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncConflictEntriesTableTableManager extends RootTableManager<
    _$ZentraDatabase,
    $SyncConflictEntriesTable,
    SyncConflictRow,
    $$SyncConflictEntriesTableFilterComposer,
    $$SyncConflictEntriesTableOrderingComposer,
    $$SyncConflictEntriesTableAnnotationComposer,
    $$SyncConflictEntriesTableCreateCompanionBuilder,
    $$SyncConflictEntriesTableUpdateCompanionBuilder,
    (
      SyncConflictRow,
      BaseReferences<_$ZentraDatabase, $SyncConflictEntriesTable,
          SyncConflictRow>
    ),
    SyncConflictRow,
    PrefetchHooks Function()> {
  $$SyncConflictEntriesTableTableManager(
      _$ZentraDatabase db, $SyncConflictEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncConflictEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncConflictEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncConflictEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> ownerId = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String?> mutationId = const Value.absent(),
            Value<String> localRecordJson = const Value.absent(),
            Value<String> remoteRecordJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncConflictEntriesCompanion(
            id: id,
            ownerId: ownerId,
            kind: kind,
            entityType: entityType,
            entityId: entityId,
            mutationId: mutationId,
            localRecordJson: localRecordJson,
            remoteRecordJson: remoteRecordJson,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String ownerId,
            required String kind,
            required String entityType,
            required String entityId,
            Value<String?> mutationId = const Value.absent(),
            required String localRecordJson,
            required String remoteRecordJson,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncConflictEntriesCompanion.insert(
            id: id,
            ownerId: ownerId,
            kind: kind,
            entityType: entityType,
            entityId: entityId,
            mutationId: mutationId,
            localRecordJson: localRecordJson,
            remoteRecordJson: remoteRecordJson,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncConflictEntriesTableProcessedTableManager = ProcessedTableManager<
    _$ZentraDatabase,
    $SyncConflictEntriesTable,
    SyncConflictRow,
    $$SyncConflictEntriesTableFilterComposer,
    $$SyncConflictEntriesTableOrderingComposer,
    $$SyncConflictEntriesTableAnnotationComposer,
    $$SyncConflictEntriesTableCreateCompanionBuilder,
    $$SyncConflictEntriesTableUpdateCompanionBuilder,
    (
      SyncConflictRow,
      BaseReferences<_$ZentraDatabase, $SyncConflictEntriesTable,
          SyncConflictRow>
    ),
    SyncConflictRow,
    PrefetchHooks Function()>;
typedef $$LocalOwnerLinkEntriesTableCreateCompanionBuilder
    = LocalOwnerLinkEntriesCompanion Function({
  required String localOwnerId,
  Value<String?> remoteUserId,
  required String state,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$LocalOwnerLinkEntriesTableUpdateCompanionBuilder
    = LocalOwnerLinkEntriesCompanion Function({
  Value<String> localOwnerId,
  Value<String?> remoteUserId,
  Value<String> state,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LocalOwnerLinkEntriesTableFilterComposer
    extends Composer<_$ZentraDatabase, $LocalOwnerLinkEntriesTable> {
  $$LocalOwnerLinkEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localOwnerId => $composableBuilder(
      column: $table.localOwnerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteUserId => $composableBuilder(
      column: $table.remoteUserId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LocalOwnerLinkEntriesTableOrderingComposer
    extends Composer<_$ZentraDatabase, $LocalOwnerLinkEntriesTable> {
  $$LocalOwnerLinkEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localOwnerId => $composableBuilder(
      column: $table.localOwnerId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteUserId => $composableBuilder(
      column: $table.remoteUserId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalOwnerLinkEntriesTableAnnotationComposer
    extends Composer<_$ZentraDatabase, $LocalOwnerLinkEntriesTable> {
  $$LocalOwnerLinkEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localOwnerId => $composableBuilder(
      column: $table.localOwnerId, builder: (column) => column);

  GeneratedColumn<String> get remoteUserId => $composableBuilder(
      column: $table.remoteUserId, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalOwnerLinkEntriesTableTableManager extends RootTableManager<
    _$ZentraDatabase,
    $LocalOwnerLinkEntriesTable,
    LocalOwnerLinkRow,
    $$LocalOwnerLinkEntriesTableFilterComposer,
    $$LocalOwnerLinkEntriesTableOrderingComposer,
    $$LocalOwnerLinkEntriesTableAnnotationComposer,
    $$LocalOwnerLinkEntriesTableCreateCompanionBuilder,
    $$LocalOwnerLinkEntriesTableUpdateCompanionBuilder,
    (
      LocalOwnerLinkRow,
      BaseReferences<_$ZentraDatabase, $LocalOwnerLinkEntriesTable,
          LocalOwnerLinkRow>
    ),
    LocalOwnerLinkRow,
    PrefetchHooks Function()> {
  $$LocalOwnerLinkEntriesTableTableManager(
      _$ZentraDatabase db, $LocalOwnerLinkEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalOwnerLinkEntriesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalOwnerLinkEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalOwnerLinkEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> localOwnerId = const Value.absent(),
            Value<String?> remoteUserId = const Value.absent(),
            Value<String> state = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalOwnerLinkEntriesCompanion(
            localOwnerId: localOwnerId,
            remoteUserId: remoteUserId,
            state: state,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String localOwnerId,
            Value<String?> remoteUserId = const Value.absent(),
            required String state,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalOwnerLinkEntriesCompanion.insert(
            localOwnerId: localOwnerId,
            remoteUserId: remoteUserId,
            state: state,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalOwnerLinkEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$ZentraDatabase,
        $LocalOwnerLinkEntriesTable,
        LocalOwnerLinkRow,
        $$LocalOwnerLinkEntriesTableFilterComposer,
        $$LocalOwnerLinkEntriesTableOrderingComposer,
        $$LocalOwnerLinkEntriesTableAnnotationComposer,
        $$LocalOwnerLinkEntriesTableCreateCompanionBuilder,
        $$LocalOwnerLinkEntriesTableUpdateCompanionBuilder,
        (
          LocalOwnerLinkRow,
          BaseReferences<_$ZentraDatabase, $LocalOwnerLinkEntriesTable,
              LocalOwnerLinkRow>
        ),
        LocalOwnerLinkRow,
        PrefetchHooks Function()>;
typedef $$LocalNotificationBindingEntriesTableCreateCompanionBuilder
    = LocalNotificationBindingEntriesCompanion Function({
  required String logicalId,
  required String ownerId,
  required String deviceId,
  required int notificationId,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$LocalNotificationBindingEntriesTableUpdateCompanionBuilder
    = LocalNotificationBindingEntriesCompanion Function({
  Value<String> logicalId,
  Value<String> ownerId,
  Value<String> deviceId,
  Value<int> notificationId,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LocalNotificationBindingEntriesTableFilterComposer
    extends Composer<_$ZentraDatabase, $LocalNotificationBindingEntriesTable> {
  $$LocalNotificationBindingEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get logicalId => $composableBuilder(
      column: $table.logicalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get notificationId => $composableBuilder(
      column: $table.notificationId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LocalNotificationBindingEntriesTableOrderingComposer
    extends Composer<_$ZentraDatabase, $LocalNotificationBindingEntriesTable> {
  $$LocalNotificationBindingEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get logicalId => $composableBuilder(
      column: $table.logicalId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get notificationId => $composableBuilder(
      column: $table.notificationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalNotificationBindingEntriesTableAnnotationComposer
    extends Composer<_$ZentraDatabase, $LocalNotificationBindingEntriesTable> {
  $$LocalNotificationBindingEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get logicalId =>
      $composableBuilder(column: $table.logicalId, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get notificationId => $composableBuilder(
      column: $table.notificationId, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalNotificationBindingEntriesTableTableManager
    extends RootTableManager<
        _$ZentraDatabase,
        $LocalNotificationBindingEntriesTable,
        LocalNotificationBindingRow,
        $$LocalNotificationBindingEntriesTableFilterComposer,
        $$LocalNotificationBindingEntriesTableOrderingComposer,
        $$LocalNotificationBindingEntriesTableAnnotationComposer,
        $$LocalNotificationBindingEntriesTableCreateCompanionBuilder,
        $$LocalNotificationBindingEntriesTableUpdateCompanionBuilder,
        (
          LocalNotificationBindingRow,
          BaseReferences<
              _$ZentraDatabase,
              $LocalNotificationBindingEntriesTable,
              LocalNotificationBindingRow>
        ),
        LocalNotificationBindingRow,
        PrefetchHooks Function()> {
  $$LocalNotificationBindingEntriesTableTableManager(
      _$ZentraDatabase db, $LocalNotificationBindingEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalNotificationBindingEntriesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalNotificationBindingEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalNotificationBindingEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> logicalId = const Value.absent(),
            Value<String> ownerId = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<int> notificationId = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalNotificationBindingEntriesCompanion(
            logicalId: logicalId,
            ownerId: ownerId,
            deviceId: deviceId,
            notificationId: notificationId,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String logicalId,
            required String ownerId,
            required String deviceId,
            required int notificationId,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalNotificationBindingEntriesCompanion.insert(
            logicalId: logicalId,
            ownerId: ownerId,
            deviceId: deviceId,
            notificationId: notificationId,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalNotificationBindingEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$ZentraDatabase,
        $LocalNotificationBindingEntriesTable,
        LocalNotificationBindingRow,
        $$LocalNotificationBindingEntriesTableFilterComposer,
        $$LocalNotificationBindingEntriesTableOrderingComposer,
        $$LocalNotificationBindingEntriesTableAnnotationComposer,
        $$LocalNotificationBindingEntriesTableCreateCompanionBuilder,
        $$LocalNotificationBindingEntriesTableUpdateCompanionBuilder,
        (
          LocalNotificationBindingRow,
          BaseReferences<
              _$ZentraDatabase,
              $LocalNotificationBindingEntriesTable,
              LocalNotificationBindingRow>
        ),
        LocalNotificationBindingRow,
        PrefetchHooks Function()>;
typedef $$LocalMigrationStateEntriesTableCreateCompanionBuilder
    = LocalMigrationStateEntriesCompanion Function({
  required String ownerId,
  required String migrationName,
  required String status,
  Value<String?> sourceChecksum,
  Value<String?> targetChecksum,
  Value<String?> sourceCountsJson,
  Value<String?> targetCountsJson,
  required DateTime startedAt,
  Value<DateTime?> completedAt,
  Value<String?> failureReason,
  Value<int> rowid,
});
typedef $$LocalMigrationStateEntriesTableUpdateCompanionBuilder
    = LocalMigrationStateEntriesCompanion Function({
  Value<String> ownerId,
  Value<String> migrationName,
  Value<String> status,
  Value<String?> sourceChecksum,
  Value<String?> targetChecksum,
  Value<String?> sourceCountsJson,
  Value<String?> targetCountsJson,
  Value<DateTime> startedAt,
  Value<DateTime?> completedAt,
  Value<String?> failureReason,
  Value<int> rowid,
});

class $$LocalMigrationStateEntriesTableFilterComposer
    extends Composer<_$ZentraDatabase, $LocalMigrationStateEntriesTable> {
  $$LocalMigrationStateEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get migrationName => $composableBuilder(
      column: $table.migrationName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceChecksum => $composableBuilder(
      column: $table.sourceChecksum,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetChecksum => $composableBuilder(
      column: $table.targetChecksum,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceCountsJson => $composableBuilder(
      column: $table.sourceCountsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetCountsJson => $composableBuilder(
      column: $table.targetCountsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get failureReason => $composableBuilder(
      column: $table.failureReason, builder: (column) => ColumnFilters(column));
}

class $$LocalMigrationStateEntriesTableOrderingComposer
    extends Composer<_$ZentraDatabase, $LocalMigrationStateEntriesTable> {
  $$LocalMigrationStateEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get migrationName => $composableBuilder(
      column: $table.migrationName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceChecksum => $composableBuilder(
      column: $table.sourceChecksum,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetChecksum => $composableBuilder(
      column: $table.targetChecksum,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceCountsJson => $composableBuilder(
      column: $table.sourceCountsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetCountsJson => $composableBuilder(
      column: $table.targetCountsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get failureReason => $composableBuilder(
      column: $table.failureReason,
      builder: (column) => ColumnOrderings(column));
}

class $$LocalMigrationStateEntriesTableAnnotationComposer
    extends Composer<_$ZentraDatabase, $LocalMigrationStateEntriesTable> {
  $$LocalMigrationStateEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get migrationName => $composableBuilder(
      column: $table.migrationName, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get sourceChecksum => $composableBuilder(
      column: $table.sourceChecksum, builder: (column) => column);

  GeneratedColumn<String> get targetChecksum => $composableBuilder(
      column: $table.targetChecksum, builder: (column) => column);

  GeneratedColumn<String> get sourceCountsJson => $composableBuilder(
      column: $table.sourceCountsJson, builder: (column) => column);

  GeneratedColumn<String> get targetCountsJson => $composableBuilder(
      column: $table.targetCountsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<String> get failureReason => $composableBuilder(
      column: $table.failureReason, builder: (column) => column);
}

class $$LocalMigrationStateEntriesTableTableManager extends RootTableManager<
    _$ZentraDatabase,
    $LocalMigrationStateEntriesTable,
    LocalMigrationStateRow,
    $$LocalMigrationStateEntriesTableFilterComposer,
    $$LocalMigrationStateEntriesTableOrderingComposer,
    $$LocalMigrationStateEntriesTableAnnotationComposer,
    $$LocalMigrationStateEntriesTableCreateCompanionBuilder,
    $$LocalMigrationStateEntriesTableUpdateCompanionBuilder,
    (
      LocalMigrationStateRow,
      BaseReferences<_$ZentraDatabase, $LocalMigrationStateEntriesTable,
          LocalMigrationStateRow>
    ),
    LocalMigrationStateRow,
    PrefetchHooks Function()> {
  $$LocalMigrationStateEntriesTableTableManager(
      _$ZentraDatabase db, $LocalMigrationStateEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMigrationStateEntriesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalMigrationStateEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalMigrationStateEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> ownerId = const Value.absent(),
            Value<String> migrationName = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> sourceChecksum = const Value.absent(),
            Value<String?> targetChecksum = const Value.absent(),
            Value<String?> sourceCountsJson = const Value.absent(),
            Value<String?> targetCountsJson = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<String?> failureReason = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalMigrationStateEntriesCompanion(
            ownerId: ownerId,
            migrationName: migrationName,
            status: status,
            sourceChecksum: sourceChecksum,
            targetChecksum: targetChecksum,
            sourceCountsJson: sourceCountsJson,
            targetCountsJson: targetCountsJson,
            startedAt: startedAt,
            completedAt: completedAt,
            failureReason: failureReason,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String ownerId,
            required String migrationName,
            required String status,
            Value<String?> sourceChecksum = const Value.absent(),
            Value<String?> targetChecksum = const Value.absent(),
            Value<String?> sourceCountsJson = const Value.absent(),
            Value<String?> targetCountsJson = const Value.absent(),
            required DateTime startedAt,
            Value<DateTime?> completedAt = const Value.absent(),
            Value<String?> failureReason = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalMigrationStateEntriesCompanion.insert(
            ownerId: ownerId,
            migrationName: migrationName,
            status: status,
            sourceChecksum: sourceChecksum,
            targetChecksum: targetChecksum,
            sourceCountsJson: sourceCountsJson,
            targetCountsJson: targetCountsJson,
            startedAt: startedAt,
            completedAt: completedAt,
            failureReason: failureReason,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalMigrationStateEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$ZentraDatabase,
        $LocalMigrationStateEntriesTable,
        LocalMigrationStateRow,
        $$LocalMigrationStateEntriesTableFilterComposer,
        $$LocalMigrationStateEntriesTableOrderingComposer,
        $$LocalMigrationStateEntriesTableAnnotationComposer,
        $$LocalMigrationStateEntriesTableCreateCompanionBuilder,
        $$LocalMigrationStateEntriesTableUpdateCompanionBuilder,
        (
          LocalMigrationStateRow,
          BaseReferences<_$ZentraDatabase, $LocalMigrationStateEntriesTable,
              LocalMigrationStateRow>
        ),
        LocalMigrationStateRow,
        PrefetchHooks Function()>;

class $ZentraDatabaseManager {
  final _$ZentraDatabase _db;
  $ZentraDatabaseManager(this._db);
  $$NoteEntriesTableTableManager get noteEntries =>
      $$NoteEntriesTableTableManager(_db, _db.noteEntries);
  $$NoteTagEntriesTableTableManager get noteTagEntries =>
      $$NoteTagEntriesTableTableManager(_db, _db.noteTagEntries);
  $$NoteReminderEntriesTableTableManager get noteReminderEntries =>
      $$NoteReminderEntriesTableTableManager(_db, _db.noteReminderEntries);
  $$NoteReviewEntriesTableTableManager get noteReviewEntries =>
      $$NoteReviewEntriesTableTableManager(_db, _db.noteReviewEntries);
  $$ProfileEntriesTableTableManager get profileEntries =>
      $$ProfileEntriesTableTableManager(_db, _db.profileEntries);
  $$HabitEntriesTableTableManager get habitEntries =>
      $$HabitEntriesTableTableManager(_db, _db.habitEntries);
  $$HabitScheduleEntriesTableTableManager get habitScheduleEntries =>
      $$HabitScheduleEntriesTableTableManager(_db, _db.habitScheduleEntries);
  $$HabitDayStateEntriesTableTableManager get habitDayStateEntries =>
      $$HabitDayStateEntriesTableTableManager(_db, _db.habitDayStateEntries);
  $$CompletedTaskEntriesTableTableManager get completedTaskEntries =>
      $$CompletedTaskEntriesTableTableManager(_db, _db.completedTaskEntries);
  $$FocusSessionEntriesTableTableManager get focusSessionEntries =>
      $$FocusSessionEntriesTableTableManager(_db, _db.focusSessionEntries);
  $$FocusProgressEntriesTableTableManager get focusProgressEntries =>
      $$FocusProgressEntriesTableTableManager(_db, _db.focusProgressEntries);
  $$UserPreferenceEntriesTableTableManager get userPreferenceEntries =>
      $$UserPreferenceEntriesTableTableManager(_db, _db.userPreferenceEntries);
  $$SyncOutboxEntriesTableTableManager get syncOutboxEntries =>
      $$SyncOutboxEntriesTableTableManager(_db, _db.syncOutboxEntries);
  $$SyncStateEntriesTableTableManager get syncStateEntries =>
      $$SyncStateEntriesTableTableManager(_db, _db.syncStateEntries);
  $$SyncConflictEntriesTableTableManager get syncConflictEntries =>
      $$SyncConflictEntriesTableTableManager(_db, _db.syncConflictEntries);
  $$LocalOwnerLinkEntriesTableTableManager get localOwnerLinkEntries =>
      $$LocalOwnerLinkEntriesTableTableManager(_db, _db.localOwnerLinkEntries);
  $$LocalNotificationBindingEntriesTableTableManager
      get localNotificationBindingEntries =>
          $$LocalNotificationBindingEntriesTableTableManager(
              _db, _db.localNotificationBindingEntries);
  $$LocalMigrationStateEntriesTableTableManager
      get localMigrationStateEntries =>
          $$LocalMigrationStateEntriesTableTableManager(
              _db, _db.localMigrationStateEntries);
}
