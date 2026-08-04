// lib/presentation/widgets/markdown_highlight_controller.dart
import 'package:flutter/material.dart';

import 'markdown_inline_spans.dart';

/// Paints the active block's raw Markdown with dimmed markers, using the same
/// span engine as the rendered blocks so the text never shifts.
class MarkdownHighlightController extends TextEditingController {
  /// Colour of the syntax characters. Read while painting rather than stored
  /// as widget state, and deliberately without notifying listeners: the editor
  /// assigns it from the theme during the same build that creates the field,
  /// and a notification there would be read as a keystroke.
  Color markerColor;

  MarkdownHighlightController({required this.markerColor, super.text});

  /// The concatenated text of the returned spans is [text] character for
  /// character, which is what keeps the caret and the selection on the letters
  /// the user pointed at.
  ///
  /// [withComposing] is accepted for the base contract but not honoured: the
  /// composing underline would have to cut across the marker spans, and the
  /// platforms that show one already draw their own candidate strip.
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    required bool withComposing,
    TextStyle? style,
  }) {
    final base = style ?? const TextStyle();
    return TextSpan(
      style: base,
      children: buildMarkdownSpans(
        text: text,
        baseStyle: base,
        markerColor: markerColor,
        showMarkers: true,
      ),
    );
  }
}
