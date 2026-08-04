import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/presentation/widgets/notes_components.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

List<TextSpan> previewSpans(WidgetTester tester) {
  final preview = tester.widget<Text>(
    find.byKey(const ValueKey('note-card-preview')),
  );
  return (preview.textSpan! as TextSpan).children!.cast<TextSpan>();
}

void main() {
  testWidgets('shows checklist progress when the note has boxes',
      (tester) async {
    await tester.pumpWidget(
      host(
        NoteLibraryCard(
          title: 'Examen',
          body: 'leer el capítulo',
          updatedLabel: 'Editada hoy',
          accent: const Color(0xFF00796B),
          checkedCount: 3,
          checkItemCount: 7,
          onTap: () {},
        ),
      ),
    );

    expect(find.text('3 de 7'), findsOneWidget);
    expect(find.byKey(const ValueKey('note-card-progress')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides progress when there are no boxes', (tester) async {
    await tester.pumpWidget(
      host(
        NoteLibraryCard(
          title: 'Apunte',
          body: 'texto',
          updatedLabel: 'Editada hoy',
          accent: const Color(0xFF00796B),
          onTap: () {},
        ),
      ),
    );

    expect(find.byKey(const ValueKey('note-card-progress')), findsNothing);
  });

  testWidgets('announces the checklist progress with words, not colour',
      (tester) async {
    await tester.pumpWidget(
      host(
        NoteLibraryCard(
          title: 'Examen',
          body: 'leer el capítulo',
          updatedLabel: 'Editada hoy',
          accent: const Color(0xFF00796B),
          checkedCount: 3,
          checkItemCount: 7,
          onTap: () {},
        ),
      ),
    );

    final semantics = tester.widget<Semantics>(
      find
          .descendant(
            of: find.byType(NoteLibraryCard),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(semantics.properties.label, 'Examen, 3 de 7 completadas');
  });

  testWidgets('highlights the matched query inside the preview',
      (tester) async {
    await tester.pumpWidget(
      host(
        NoteLibraryCard(
          title: 'Bio',
          body: 'repasar mitosis con calma',
          updatedLabel: 'Editada hoy',
          accent: const Color(0xFF00796B),
          highlightQuery: 'mitosis',
          onTap: () {},
        ),
      ),
    );

    final highlighted = previewSpans(tester).firstWhere(
      (span) => span.text == 'mitosis',
    );
    expect(highlighted.style!.fontWeight, FontWeight.w700);
  });

  testWidgets('highlights a query made of regular expression characters',
      (tester) async {
    await tester.pumpWidget(
      host(
        NoteLibraryCard(
          title: 'Compras',
          body: 'comprar pan (1) y leche',
          updatedLabel: 'Editada hoy',
          accent: const Color(0xFF00796B),
          highlightQuery: '(1)',
          onTap: () {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final highlighted = previewSpans(tester).firstWhere(
      (span) => span.text == '(1)',
    );
    expect(highlighted.style!.fontWeight, FontWeight.w700);
  });

  testWidgets('leaves the preview whole when the query is not in it',
      (tester) async {
    await tester.pumpWidget(
      host(
        NoteLibraryCard(
          title: 'Bio',
          body: 'repasar mitosis con calma',
          updatedLabel: 'Editada hoy',
          accent: const Color(0xFF00796B),
          highlightQuery: 'meiosis',
          onTap: () {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final spans = previewSpans(tester);
    expect(spans, hasLength(1));
    expect(spans.single.text, 'repasar mitosis con calma');
    expect(spans.single.style!.fontWeight, isNot(FontWeight.w700));
  });

  testWidgets('progress survives a narrow card at maximum text size',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(3.2)),
          child: Scaffold(
            body: NoteLibraryCard(
              title: 'Examen de fisiología comparada',
              body: 'leer el capítulo completo antes del viernes',
              updatedLabel: 'Editada hoy',
              accent: const Color(0xFF00796B),
              checkedCount: 12,
              checkItemCount: 30,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('note-card-progress')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
