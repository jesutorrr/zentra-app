// lib/presentation/widgets/markdown_inline_spans.dart
import 'package:flutter/material.dart';

import '../../domain/markdown_inline.dart';

/// Families tried for code spans. `monospace` covers Android, `Menlo` covers
/// iOS and macOS, where `monospace` is not a resolvable family name.
const _monospaceFallback = <String>['monospace', 'Menlo', 'Courier New'];

/// Builds the inline spans for a block of note text.
///
/// The active block calls this with [showMarkers] true so the user sees the
/// Markdown syntax dimmed in place. Rendered blocks call it with false. Both
/// share this function so content never shifts between the two states.
///
/// With [showMarkers] on, the concatenated span text equals [text] character
/// for character, which is what a `TextField` needs to keep its caret aligned.
/// With it off, the result is [text] minus the marker slices, and nothing else.
List<InlineSpan> buildMarkdownSpans({
  required String text,
  required TextStyle baseStyle,
  required Color markerColor,
  required bool showMarkers,
}) {
  final spans = <InlineSpan>[];
  for (final segment in tokenizeInline(text)) {
    if (segment.isMarker) {
      if (!showMarkers) continue;
      spans.add(
        TextSpan(
          text: segment.text,
          style: baseStyle.copyWith(color: markerColor),
        ),
      );
      continue;
    }
    spans.add(
      TextSpan(text: segment.text, style: _styleFor(segment, baseStyle)),
    );
  }
  // A line that is nothing but markers (`[]()`, say) leaves no span at all once
  // they are hidden, and an empty span list would break the callers that hand
  // the result to a rich text field.
  if (spans.isEmpty) spans.add(TextSpan(text: '', style: baseStyle));
  return spans;
}

TextStyle _styleFor(MarkdownInlineSegment segment, TextStyle baseStyle) {
  var style = baseStyle;
  if (segment.styles.contains(MarkdownInlineStyle.bold)) {
    style = style.copyWith(fontWeight: FontWeight.w700);
  }
  if (segment.styles.contains(MarkdownInlineStyle.italic)) {
    style = style.copyWith(fontStyle: FontStyle.italic);
  }
  if (segment.styles.contains(MarkdownInlineStyle.code)) {
    style = style.copyWith(
      fontFamily: _monospaceFallback.first,
      fontFamilyFallback: _monospaceFallback.sublist(1),
    );
  }
  // Both decorations can land on the same segment, so they are merged instead
  // of overwriting each other.
  final decorations = <TextDecoration>[
    if (segment.styles.contains(MarkdownInlineStyle.strikethrough))
      TextDecoration.lineThrough,
    if (segment.styles.contains(MarkdownInlineStyle.link))
      TextDecoration.underline,
  ];
  if (decorations.isNotEmpty) {
    style = style.copyWith(decoration: TextDecoration.combine(decorations));
  }
  return style;
}
