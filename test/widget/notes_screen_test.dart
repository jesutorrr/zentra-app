import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/application/note_controller.dart';
import 'package:zentra/application/session_controller.dart';
import 'package:zentra/domain/note_models.dart';
import 'package:zentra/infrastructure/database/zentra_database.dart';
import 'package:zentra/infrastructure/drift_note_repository.dart';
import 'package:zentra/presentation/note_reminder_screen.dart';
import 'package:zentra/presentation/note_surface.dart';
import 'package:zentra/presentation/notes_screen.dart';
import 'package:zentra/presentation/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> configureDevice(
    WidgetTester tester, {
    required Size logicalSize,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = logicalSize;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  Future<_NotesHarness> createHarness() async {
    final database = ZentraDatabase(NativeDatabase.memory());
    final repository = DriftNoteRepository.forOwner(
      database,
      ownerId: 'uri',
    );
    final algebra = Note(
      id: 'note-algebra',
      userId: 'uri',
      title: 'Repasar Álgebra lineal',
      body: 'Transformaciones, matrices y espacios vectoriales.',
      createdAt: DateTime.utc(2026, 7, 25, 10),
      updatedAt: DateTime.utc(2026, 7, 26, 10),
      accentKey: 'focus',
      isPinned: true,
      tags: const ['examen', 'estudio'],
    );
    await repository.upsertNote(algebra);
    await repository.upsertNote(
      Note(
        id: 'note-zentra',
        userId: 'uri',
        title: 'Ideas para Zentra',
        body: 'Un espacio cálido, sobrio y útil.',
        createdAt: DateTime.utc(2026, 7, 25, 9),
        updatedAt: DateTime.utc(2026, 7, 26, 9),
        accentKey: 'peach',
        tags: const ['producto'],
      ),
    );
    return _NotesHarness(
      database: database,
      repository: repository,
      algebraId: algebra.id,
    );
  }

  Widget buildApp(
    _NotesHarness harness,
    Widget home, {
    double textScale = 1,
    bool reduceMotion = true,
  }) {
    return ProviderScope(
      overrides: [
        activeOwnerIdProvider.overrideWithValue('uri'),
        noteRepositoryFactoryProvider.overrideWithValue((ownerId) {
          if (ownerId != 'uri') {
            throw StateError('Unexpected owner $ownerId');
          }
          return harness.repository;
        }),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: reduceMotion,
              accessibleNavigation: reduceMotion,
            ),
            child: child!,
          );
        },
        home: home,
      ),
    );
  }

  testWidgets('library is compact, searchable and opens the exact note',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    final harness = await createHarness();
    addTearDown(harness.database.close);

    await tester.pumpWidget(buildApp(harness, const NotesScreen()));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('notes-compact-layout')),
      findsOneWidget,
    );
    expect(find.text('Repasar Álgebra lineal'), findsOneWidget);
    for (final section in const [
      'Para repasar',
      'Fijadas',
      'Recientes',
      'Archivadas',
    ]) {
      expect(find.text(section), findsOneWidget);
    }

    await tester.enterText(
      find.byKey(const ValueKey('notes-search')),
      'ideas',
    );
    await tester.pump();

    expect(find.text('Ideas para Zentra'), findsOneWidget);
    expect(find.text('Repasar Álgebra lineal'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('notes-search')),
      'algebra',
    );
    await tester.pump();

    expect(find.text('Repasar Álgebra lineal'), findsOneWidget);
    expect(find.text('Ideas para Zentra'), findsNothing);

    await tester.tap(find.text('Repasar Álgebra lineal'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('note-surface')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('note-title-heading')),
        matching: find.text('Repasar Álgebra lineal'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('iPad Pro portrait uses one shared list-detail route',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(834, 1194));
    final harness = await createHarness();
    addTearDown(harness.database.close);

    await tester.pumpWidget(buildApp(harness, const NotesScreen()));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('notes-expanded-layout')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('note-detail-${harness.algebraId}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('editor and reminder remain usable at 320dp and 200 percent text',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(320, 640));
    final harness = await createHarness();
    addTearDown(harness.database.close);

    await tester.pumpWidget(
      buildApp(
        harness,
        NoteSurface(noteId: harness.algebraId),
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('note-surface')), findsOneWidget);
    expect(find.byKey(const ValueKey('note-title-heading')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      buildApp(
        harness,
        NoteReminderScreen(noteId: harness.algebraId),
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('note-reminder-screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('note-reminder-later-today')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('editor autosaves content through the shared controller',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    final harness = await createHarness();
    addTearDown(harness.database.close);

    // Reduced Motion collapses the format bar animation to zero, and an
    // AnimatedSize of that duration re-dirties itself while the bar appears.
    await tester.pumpWidget(
      buildApp(
        harness,
        NoteSurface(noteId: harness.algebraId),
        reduceMotion: false,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('note-block-0')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('note-active-block')),
      '\u200BContenido actualizado desde el editor.',
    );
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump();

    final saved = await harness.repository.getNote(harness.algebraId);
    expect(saved?.body, 'Contenido actualizado desde el editor.');
    expect(tester.takeException(), isNull);
  });
}

class _NotesHarness {
  final ZentraDatabase database;
  final DriftNoteRepository repository;
  final String algebraId;

  const _NotesHarness({
    required this.database,
    required this.repository,
    required this.algebraId,
  });
}
