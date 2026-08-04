// lib/presentation/widgets/note_tag_field.dart
import 'package:flutter/material.dart';

import '../../domain/note_models.dart';
import '../design_tokens.dart';

/// How many suggestions still read as a glance rather than a second list.
const int _maxSuggestions = 5;

/// Room the helper sentence is allowed to take.
///
/// A decoration helper is one line by default, and one line is not enough in
/// the 320 point details column: the sentence came out as `para agre…`. It is
/// fixed copy with nothing interpolated into it, so the only thing this has to
/// clear is the largest text size, not a runaway string.
const int _helperMaxLines = 6;

/// Tag editor: what the note already carries as chips, and what the owner has
/// written elsewhere as suggestions.
///
/// Every list that leaves through [onChanged] has gone through
/// [normalizeNoteTags], so the same tag can never be stored twice under two
/// spellings and blank text never becomes a tag.
class NoteTagField extends StatefulWidget {
  final List<String> value;

  /// The owner's whole tag vocabulary, already normalized.
  final List<String> suggestions;
  final ValueChanged<List<String>> onChanged;

  const NoteTagField({
    required this.value,
    required this.suggestions,
    required this.onChanged,
    super.key,
  });

  @override
  State<NoteTagField> createState() => _NoteTagFieldState();
}

class _NoteTagFieldState extends State<NoteTagField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _draft = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    // Detached before the node goes away: disposing a focused node drops
    // focus, and committing from there would touch a tree being torn down.
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Tags the owner already knows that start with what is being typed.
  List<String> get _matches {
    final draft = _draft.trim().toLowerCase();
    if (draft.isEmpty) return const [];
    return widget.suggestions
        .where((tag) => tag.startsWith(draft) && !widget.value.contains(tag))
        .take(_maxSuggestions)
        .toList(growable: false);
  }

  /// Turns [raw] into tags and hands the result back.
  ///
  /// Commas separate, so a whole line pasted from somewhere else still lands
  /// as several tags, and the field is cleared either way: a repeat of a tag
  /// already on the note is nothing to keep typing.
  void _commit(String raw) {
    final next = normalizeNoteTags([...widget.value, ...raw.split(',')]);
    _controller.clear();
    setState(() => _draft = '');
    if (_sameTags(next, widget.value)) return;
    widget.onChanged(next);
  }

  void _remove(String tag) {
    widget.onChanged(
      widget.value.where((value) => value != tag).toList(growable: false),
    );
  }

  void _handleDraftChanged(String value) {
    // A comma is how the owner says "that one is done" without leaving the
    // field, and it is also what arrives when a list is pasted in.
    if (value.contains(',')) {
      _commit(value);
      return;
    }
    setState(() => _draft = value);
  }

  /// Someone who typed a tag and then closed the panel meant to keep it, so
  /// leaving the field counts as confirming what is in it.
  void _handleFocusChange() {
    if (_focusNode.hasFocus) return;
    if (_controller.text.trim().isEmpty) return;
    _commit(_controller.text);
  }

  bool _sameTags(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    final hasDraft = _draft.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.value.isNotEmpty) ...[
          Semantics(
            label: 'Etiquetas de la nota',
            child: Wrap(
              key: const ValueKey('note-tag-chips'),
              spacing: context.spacing.xs,
              runSpacing: context.spacing.xs,
              children: [
                for (final tag in widget.value)
                  InputChip(
                    key: ValueKey('note-tag-chip-$tag'),
                    label: Text(tag),
                    deleteIcon: Icon(
                      Icons.close_rounded,
                      key: ValueKey('note-tag-remove-$tag'),
                      size: 18,
                    ),
                    deleteButtonTooltipMessage: 'Quitar la etiqueta $tag',
                    tooltip: 'Quitar la etiqueta $tag',
                    onDeleted: () => _remove(tag),
                    // The glyph alone is a narrow aim inside the chip, and a
                    // chip here means one thing only, so the whole target
                    // removes the tag the cross is pointing at.
                    onPressed: () => _remove(tag),
                  ),
              ],
            ),
          ),
          SizedBox(height: context.spacing.xs),
        ],
        TextField(
          key: const ValueKey('note-tag-input'),
          controller: _controller,
          focusNode: _focusNode,
          textInputAction: TextInputAction.done,
          onChanged: _handleDraftChanged,
          onSubmitted: _commit,
          decoration: InputDecoration(
            labelText: 'Etiquetas',
            hintText: 'estudio',
            helperText: 'Escribe una y confirma para agregarla.',
            helperMaxLines: _helperMaxLines,
            prefixIcon: const Icon(Icons.sell_outlined),
            suffixIcon: hasDraft
                ? IconButton(
                    key: const ValueKey('note-tag-add'),
                    tooltip: 'Agregar la etiqueta ${_draft.trim()}',
                    onPressed: () => _commit(_controller.text),
                    icon: const Icon(Icons.add_rounded),
                  )
                : null,
          ),
        ),
        if (matches.isNotEmpty) ...[
          SizedBox(height: context.spacing.xs),
          Semantics(
            label: 'Etiquetas que ya usas',
            child: Wrap(
              spacing: context.spacing.xs,
              runSpacing: context.spacing.xs,
              children: [
                for (final match in matches)
                  ActionChip(
                    key: ValueKey('note-tag-suggestion-$match'),
                    avatar: const Icon(Icons.add_rounded, size: 18),
                    label: Text(match),
                    tooltip: 'Agregar la etiqueta $match',
                    onPressed: () => _commit(match),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
