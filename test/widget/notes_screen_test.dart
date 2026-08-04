import 'dart:ui' show Tristate;

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

    await tester.ensureVisible(find.text('Repasar Álgebra lineal'));
    await tester.pumpAndSettle();
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

  testWidgets('a phone spends its height on notes, not on a second title',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    final harness = await createHarness();
    addTearDown(harness.database.close);

    await tester.pumpWidget(buildApp(harness, const NotesScreen()));
    await tester.pumpAndSettle();

    // The app bar already names the screen, so the hero that repeated the
    // idea is gone, and with it the card that only duplicated the create
    // button below it.
    expect(find.text('Notas'), findsOneWidget);
    expect(find.text('Ideas que vuelven cuando sirven'), findsNothing);
    expect(find.text('Captura una idea'), findsNothing);

    // Creating a note stays one tap away, from a control the list cannot
    // scroll out of reach.
    final add = find.byKey(const ValueKey('notes-add'));
    expect(add, findsOneWidget);
    expect(add.hitTestable(), findsOneWidget);

    // The point of all of the above: a note is visible without scrolling.
    // Half the window is the loosest bar that still fails the old layout,
    // which pushed the first card past three quarters of the height.
    final firstCard = tester.getRect(find.text('Repasar Álgebra lineal'));
    expect(firstCard.top, lessThan(844 / 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the live section stays in sight when the strip has to scroll',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    final harness = await createHarness();
    addTearDown(harness.database.close);

    await tester.pumpWidget(buildApp(harness, const NotesScreen()));
    await tester.pumpAndSettle();

    // The library opens on 'Recientes', the third of four chips, which on a
    // phone starts past the right edge of the strip. Leaving it there would
    // show a list filtered by a section the reader cannot see.
    final rect = tester.getRect(
      find.byKey(const ValueKey('notes-section-recent')),
    );
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(390));
  });

  testWidgets('a window with room to spare still opens with the hero',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(834, 1194));
    final harness = await createHarness();
    addTearDown(harness.database.close);

    await tester.pumpWidget(buildApp(harness, const NotesScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Ideas que vuelven cuando sirven'), findsOneWidget);
    // The header carries its own create button here, so the floating one
    // would be a second control for the same job.
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byKey(const ValueKey('notes-add')), findsOneWidget);
  });

  testWidgets('an expanded window uses one shared list-detail route',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(1024, 1366));
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

  // The library used to split into two panes at 800 while the note surface
  // waited for the repo's expanded class at 840, so an 11 inch iPad in
  // portrait got a two pane library and a note with no side column at all.
  testWidgets('iPad Pro portrait keeps the library and the note in step',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(834, 1194));
    final harness = await createHarness();
    addTearDown(harness.database.close);

    await tester.pumpWidget(buildApp(harness, const NotesScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('notes-compact-layout')), findsOneWidget);
    expect(find.byKey(const ValueKey('notes-expanded-layout')), findsNothing);

    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('note-details-column')), findsNothing);
    expect(find.byKey(const ValueKey('note-details-action')), findsOneWidget);
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

    await tester.pumpWidget(
      buildApp(harness, NoteSurface(noteId: harness.algebraId)),
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

  testWidgets('tag filter narrows the library and never traps the reader',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    final harness = await createHarness();
    addTearDown(harness.database.close);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(buildApp(harness, const NotesScreen()));
    await tester.pumpAndSettle();

    final filterBar = find.byKey(const ValueKey('notes-tag-filter'));
    final producto = find.byKey(const ValueKey('notes-tag-filter-producto'));
    expect(filterBar, findsOneWidget);
    expect(producto, findsOneWidget);
    expect(tester.getSize(producto).height, greaterThanOrEqualTo(44));

    await tester.ensureVisible(producto);
    await tester.pumpAndSettle();
    await tester.tap(producto);
    await tester.pumpAndSettle();

    expect(find.text('Ideas para Zentra'), findsOneWidget);
    expect(find.text('Repasar Álgebra lineal'), findsNothing);
    expect(
      tester
          .getSemantics(producto)
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );

    // Pinned holds only the algebra note, which does not carry this tag, so
    // the reader lands on an empty list and must still see the way back.
    await tester.tap(find.byKey(const ValueKey('notes-section-pinned')));
    await tester.pumpAndSettle();

    expect(find.text('Ideas para Zentra'), findsNothing);
    expect(find.text('Repasar Álgebra lineal'), findsNothing);
    expect(filterBar, findsOneWidget);

    final all = find.byKey(const ValueKey('notes-tag-filter-all'));
    await tester.ensureVisible(all);
    await tester.pumpAndSettle();
    await tester.tap(all);
    await tester.pumpAndSettle();

    expect(find.text('Repasar Álgebra lineal'), findsOneWidget);
    expect(
      tester
          .getSemantics(producto)
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      Tristate.isFalse,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  // `Todas` used to ride inside the scrolling strip, so reaching a tag on the
  // right pushed the only control that clears the filter off the window.
  testWidgets('the clear-filter chip survives a long strip of tags',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(390, 844));
    final harness = await createHarness();
    addTearDown(harness.database.close);
    await harness.repository.upsertNote(
      Note(
        id: 'note-etiquetada',
        userId: 'uri',
        title: 'Nota con muchas etiquetas',
        body: 'Cuerpo de la nota.',
        createdAt: DateTime.utc(2026, 7, 25, 8),
        updatedAt: DateTime.utc(2026, 7, 26, 8),
        accentKey: 'focus',
        tags: const [
          'arquitectura',
          'diseño',
          'entrevistas',
          'finanzas',
          'investigación',
          'lecturas',
          'mercadotecnia',
          'pendientes',
        ],
      ),
    );

    await tester.pumpWidget(buildApp(harness, const NotesScreen()));
    await tester.pumpAndSettle();

    final all = find.byKey(const ValueKey('notes-tag-filter-all'));
    final strip = find.byKey(const ValueKey('notes-tag-filter-scroll'));
    // Brings the strip up the page. Everything after this is about the strip's
    // own horizontal scrolling, which is where `Todas` used to disappear.
    await tester.ensureVisible(strip);
    await tester.pumpAndSettle();
    expect(all.hitTestable(), findsOneWidget);

    final farTag = find.byKey(const ValueKey('notes-tag-filter-pendientes'));
    await tester.scrollUntilVisible(
      farTag,
      300,
      scrollable: find.descendant(of: strip, matching: find.byType(Scrollable)),
    );
    await tester.pumpAndSettle();

    expect(all.hitTestable(), findsOneWidget);
    expect(tester.getRect(all).right, lessThanOrEqualTo(390));

    await tester.tap(farTag);
    await tester.pumpAndSettle();

    expect(find.text('Repasar Álgebra lineal'), findsNothing);
    // No `ensureVisible` here on purpose: the way out of an emptied library
    // has to be one tap away, not one scroll and one tap.
    expect(all.hitTestable(), findsOneWidget);
    await tester.tap(all);
    await tester.pumpAndSettle();

    expect(find.text('Repasar Álgebra lineal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the library holds together at 320dp and 200 percent text',
      (tester) async {
    await configureDevice(tester, logicalSize: const Size(320, 640));
    final harness = await createHarness();
    addTearDown(harness.database.close);

    await tester.pumpWidget(
      buildApp(harness, const NotesScreen(), textScale: 2),
    );
    await tester.pumpAndSettle();

    // Nothing overflowed on the way here, including the loading placeholders
    // the screen shows before the first note arrives.
    expect(tester.takeException(), isNull);

    final all = find.byKey(const ValueKey('notes-tag-filter-all'));
    await tester.scrollUntilVisible(
      all,
      240,
      // The library itself, not the horizontal tag strip nested inside it,
      // which is a second scrollable under the same root. Depth first order
      // puts the vertical list ahead of anything it contains.
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('notes-compact-layout')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(all.hitTestable(), findsOneWidget);
    expect(tester.getRect(all).right, lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tag filter offers every tag the owner has used', (tester) async {
    await configureDevice(tester, logicalSize: const Size(834, 1194));
    final harness = await createHarness();
    addTearDown(harness.database.close);

    await tester.pumpWidget(buildApp(harness, const NotesScreen()));
    await tester.pumpAndSettle();

    for (final tag in const ['estudio', 'examen', 'producto']) {
      expect(
        find.byKey(ValueKey('notes-tag-filter-$tag')),
        findsOneWidget,
        reason: 'expected a filter chip for $tag',
      );
    }
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
