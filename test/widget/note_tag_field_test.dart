import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/presentation/theme.dart';
import 'package:zentra/presentation/widgets/note_tag_field.dart';

void main() {
  /// Hosts the field the way the details panel does: the caller owns the tags
  /// and keeps whatever the field reports.
  Future<_TagsHost> pumpField(
    WidgetTester tester, {
    List<String> initial = const [],
    List<String> suggestions = const [],
    double textScale = 1,
  }) async {
    final host = _TagsHost(initial);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => NoteTagField(
              value: host.tags,
              suggestions: suggestions,
              onChanged: (next) => setState(() => host.tags = next),
            ),
          ),
        ),
      ),
    );
    return host;
  }

  String draftOf(WidgetTester tester) {
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('note-tag-input')),
    );
    return field.controller?.text ?? '';
  }

  testWidgets('shows current tags as removable chips', (tester) async {
    final semantics = tester.ensureSemantics();
    final host = await pumpField(
      tester,
      initial: const ['estudio', 'examen'],
      suggestions: const ['bio'],
    );

    expect(find.byType(InputChip), findsNWidgets(2));

    // The whole chip removes, so the aim is the chip and not just the cross.
    final chip = find.byKey(const ValueKey('note-tag-chip-examen'));
    final size = tester.getSize(chip);
    expect(size.height, greaterThanOrEqualTo(44));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(
      tester.getSemantics(chip).getSemanticsData().tooltip,
      contains('Quitar la etiqueta examen'),
    );

    await tester.tap(find.byKey(const ValueKey('note-tag-remove-examen')));
    await tester.pumpAndSettle();

    expect(host.tags, ['estudio']);
    expect(find.byType(InputChip), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('suggests existing tags while typing', (tester) async {
    final host = await pumpField(
      tester,
      suggestions: const ['biología', 'bitácora', 'estudio'],
    );

    await tester.enterText(
      find.byKey(const ValueKey('note-tag-input')),
      'bi',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('note-tag-suggestion-biología')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('note-tag-suggestion-estudio')),
      findsNothing,
    );

    await tester
        .tap(find.byKey(const ValueKey('note-tag-suggestion-biología')));
    await tester.pumpAndSettle();

    expect(host.tags, ['biología']);
    expect(
      find.byKey(const ValueKey('note-tag-suggestion-biología')),
      findsNothing,
    );
    expect(draftOf(tester), isEmpty);
  });

  testWidgets('never adds the same tag twice, whatever the casing',
      (tester) async {
    final host = await pumpField(tester, initial: const ['examen']);

    await tester.enterText(
      find.byKey(const ValueKey('note-tag-input')),
      'Examen',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(host.tags, ['examen']);
    expect(find.byType(InputChip), findsOneWidget);
    expect(draftOf(tester), isEmpty);
  });

  testWidgets('refuses a tag that is only whitespace', (tester) async {
    final host = await pumpField(tester);

    await tester.enterText(
      find.byKey(const ValueKey('note-tag-input')),
      '   ',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(host.tags, isEmpty);
    expect(find.byType(InputChip), findsNothing);
  });

  testWidgets('keeps a tag typed but not confirmed when the panel closes',
      (tester) async {
    final host = _TagsHost(const []);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (sheetContext) => StatefulBuilder(
                    builder: (context, setSheetState) => NoteTagField(
                      value: host.tags,
                      suggestions: const [],
                      onChanged: (next) => setSheetState(
                        () => host.tags = next,
                      ),
                    ),
                  ),
                ),
                child: const Text('Detalles'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Detalles'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('note-tag-input')),
      'biología',
    );
    await tester.pumpAndSettle();
    expect(host.tags, isEmpty);

    // Tapping the barrier is how a reader dismisses the details sheet.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(host.tags, ['biología']);
  });

  testWidgets('stays laid out at 200 percent text', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await pumpField(
      tester,
      initial: const ['segundo parcial', 'estudio profundo'],
      suggestions: const ['biología'],
      textScale: 2,
    );

    await tester.enterText(
      find.byKey(const ValueKey('note-tag-input')),
      'bi',
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

class _TagsHost {
  List<String> tags;

  _TagsHost(this.tags);
}
