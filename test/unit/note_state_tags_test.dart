import 'package:flutter_test/flutter_test.dart';
import 'package:zentra/application/note_state.dart';
import 'package:zentra/domain/note_models.dart';

void main() {
  final now = DateTime.utc(2026, 8, 3);

  Note noteWith(String id, List<String> tags) => Note(
        id: id,
        userId: 'uri',
        title: id,
        body: '',
        createdAt: now,
        updatedAt: now,
        accentKey: 'mint',
        tags: tags,
      );

  test('allTags is sorted, deduplicated and normalized', () {
    final state = NoteState(
      ownerId: 'uri',
      notes: [
        noteWith('1', const ['Examen', 'estudio']),
        noteWith('2', const ['examen', 'bio']),
      ],
    );

    expect(state.allTags, ['bio', 'estudio', 'examen']);
  });

  test('allTags drops blank tags and collapses inner whitespace', () {
    final state = NoteState(
      ownerId: 'uri',
      notes: [
        noteWith('1', const ['   ', '', 'Segundo  Parcial']),
      ],
    );

    expect(state.allTags, ['segundo parcial']);
  });

  test('allTags is empty when the owner has no notes', () {
    expect(NoteState(ownerId: 'uri').allTags, isEmpty);
  });
}
