// lib/presentation/widgets/note_block_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../domain/markdown_document.dart';
import '../../domain/markdown_inline.dart';
import '../design_tokens.dart';
import '../utils/feedback_utils.dart';
import 'markdown_inline_spans.dart';

/// Minimum touch target, in logical points, for the checklist box.
const double _checkboxTarget = 44;

/// What assistive technology is told a tap on a block does. Without it a tap
/// only looks like a way to move the reading cursor.
const String _editHint = 'Toca dos veces para editar el bloque';

/// Everything a span list is built from. Blocks and text styles are immutable
/// with value equality, so two equal keys always describe the same spans.
typedef _SpanKey = (MarkdownBlock, TextStyle, Color);

/// Tokenizing is the expensive half of rendering a block, and the editor
/// rebuilds every block on every keystroke on purpose: its column keeps the
/// active field's element, and therefore its focus, when the caret moves. The
/// cache is what keeps that decision from costing a full pass over a long note
/// each time a character is typed.
final Map<_SpanKey, List<InlineSpan>> _spanCache = {};

/// Roughly a screenful of blocks in each of the styles a note uses.
const int _spanCacheLimit = 240;

/// How many span lists were actually built, as opposed to reused. Only counted
/// in debug builds.
@visibleForTesting
int debugNoteBlockSpanBuilds = 0;

@visibleForTesting
void debugResetNoteBlockSpanCache() {
  _spanCache.clear();
  debugNoteBlockSpanBuilds = 0;
}

/// Text style for the name of a note, wherever the note is shown.
///
/// One step of the type scale above the `#` block, which is the tallest thing
/// the body can hold. Both used to be `headlineSmall`, so a note opening with
/// a heading showed two titles of the same size stacked on each other.
///
/// The heading ramp below is left alone rather than demoted: every level of it
/// already sits at or above the body text it introduces, and pushing it down a
/// step would put `###` under the paragraphs it heads.
TextStyle? noteTitleTextStyle(BuildContext context) =>
    Theme.of(context).textTheme.headlineMedium;

/// Text style for a block, shared by the rendered view and the active editor
/// so switching between them never shifts the text.
TextStyle noteBlockTextStyle(BuildContext context, MarkdownBlock block) {
  final theme = Theme.of(context);
  final body = theme.textTheme.bodyLarge!.copyWith(height: 1.55);
  return switch (block.type) {
    MarkdownBlockType.heading => switch (block.headingLevel) {
        1 => theme.textTheme.headlineSmall!,
        2 => theme.textTheme.titleLarge!,
        _ => theme.textTheme.titleMedium!,
      },
    MarkdownBlockType.codeFence => body.copyWith(
        fontFamily: monospaceFontFamilies.first,
        fontFamilyFallback: monospaceFontFamilies.sublist(1),
      ),
    MarkdownBlockType.quote => body.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    _ => body,
  };
}

/// A single rendered block of a note. Not editable: the editor swaps this for
/// a text field on the block that holds the caret.
class NoteBlockView extends StatelessWidget {
  final MarkdownBlock block;
  final int? displayNumber;
  final VoidCallback? onToggleCheck;
  final ValueChanged<int>? onTapAtOffset;

  const NoteBlockView({
    required this.block,
    this.displayNumber,
    this.onToggleCheck,
    this.onTapAtOffset,
    super.key,
  });

  /// Code fences and unsupported syntax are shown verbatim. Styling them would
  /// swallow the markers the author is deliberately displaying, and the domain
  /// already treats both as literal everywhere else.
  bool get _isLiteral =>
      block.type == MarkdownBlockType.codeFence ||
      block.type == MarkdownBlockType.raw;

  /// The visible text of a literal block, and where it starts on the source.
  (String, int) get _literalText {
    if (block.type != MarkdownBlockType.codeFence) return (block.text, 0);
    // The fence body starts on the line after the opening marker.
    final headerLength =
        block.leading.length + block.prefix.length + block.language.length;
    return (block.codeLines.join('\n'), headerLength + 1);
  }

  /// The role a screen reader announces in front of the block's own text.
  ///
  /// Null where another node already says it: a checklist item is announced by
  /// its box, which also carries the checked state, and a paragraph has no
  /// role to announce.
  String? get _semanticRole => switch (block.type) {
        MarkdownBlockType.heading => 'Encabezado nivel ${block.headingLevel}',
        MarkdownBlockType.bulletItem => 'Elemento de lista',
        MarkdownBlockType.numberedItem =>
          'Elemento ${displayNumber ?? 1} de lista numerada',
        MarkdownBlockType.quote => 'Cita',
        MarkdownBlockType.codeFence => 'Bloque de código',
        MarkdownBlockType.raw => 'Contenido sin formato',
        MarkdownBlockType.checkItem ||
        MarkdownBlockType.paragraph ||
        MarkdownBlockType.divider =>
          null,
      };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (block.type == MarkdownBlockType.divider) {
      return Semantics(
        label: 'Separador',
        child: Padding(
          key: const ValueKey('note-block-divider'),
          padding: EdgeInsets.symmetric(vertical: context.spacing.sm),
          child: Divider(height: 1, color: colorScheme.outlineVariant),
        ),
      );
    }

    final style = noteBlockTextStyle(context, block);
    final baseStyle = block.checked
        ? style.copyWith(
            decoration: TextDecoration.lineThrough,
            color: colorScheme.onSurfaceVariant,
          )
        : style;
    final spans = _spansFor(baseStyle, colorScheme.onSurfaceVariant);

    final text = Text.rich(
      TextSpan(children: spans),
      key: const ValueKey('note-block-text'),
    );

    final visibleText = TextSpan(children: spans).toPlainText().trim();
    final role = _semanticRole;
    final label = role == null
        ? null
        : (visibleText.isEmpty ? role : '$role: $visibleText');

    final content = Padding(
      padding: EdgeInsets.only(
        left: block.indentLevel * context.spacing.md,
        top: context.spacing.xxs,
        bottom: context.spacing.xxs,
      ),
      child: _withLeadingAffordance(
        context,
        _tappable(context, text, spans, semantic: label == null),
        visibleText,
      ),
    );
    // Wrapped only when there is something to say. An annotation with no
    // properties still publishes a node, and an empty one is one more stop a
    // screen reader user has to swipe through.
    if (label == null) return content;

    return Semantics(
      header: block.type == MarkdownBlockType.heading,
      label: label,
      hint: onTapAtOffset == null ? null : _editHint,
      onTap: onTapAtOffset == null ? null : _activateFromSemantics,
      // A block with a role reads as one line: its marker, its bullet glyph
      // and its number are decoration the label already accounts for.
      excludeSemantics: true,
      child: content,
    );
  }

  /// The spans for this block, built once per block, style and marker colour.
  List<InlineSpan> _spansFor(TextStyle baseStyle, Color markerColor) {
    final key = (block, baseStyle, markerColor);
    final cached = _spanCache[key];
    if (cached != null) return cached;
    final spans = List<InlineSpan>.unmodifiable(
      _isLiteral
          ? <InlineSpan>[TextSpan(text: _literalText.$1, style: baseStyle)]
          : buildMarkdownSpans(
              text: block.text,
              baseStyle: baseStyle,
              markerColor: markerColor,
              showMarkers: false,
            ),
    );
    assert(() {
      debugNoteBlockSpanBuilds++;
      return true;
    }());
    if (_spanCache.length >= _spanCacheLimit) {
      _spanCache.remove(_spanCache.keys.first);
    }
    _spanCache[key] = spans;
    return spans;
  }

  /// A semantic activation carries no position, so it lands at the start of
  /// the block's text rather than nowhere at all.
  void _activateFromSemantics() => onTapAtOffset?.call(_sourceOffsetFor(0));

  /// Wraps the rendered text so a tap reports where the caret should land on
  /// the source line. Only the text is wrapped: the checklist box owns its own
  /// gesture and must not be shadowed by this one.
  ///
  /// [semantic] adds the assistive tap here, for the blocks whose own node
  /// does not carry one.
  Widget _tappable(
    BuildContext context,
    Widget text,
    List<InlineSpan> spans, {
    required bool semantic,
  }) {
    final handler = onTapAtOffset;
    if (handler == null) return text;
    final detector = LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Its own semantic tap would report the centre of the block as the
          // position, dropping an assistive user in the middle of a word. The
          // action published below lands on the first character instead.
          excludeFromSemantics: true,
          onTapUp: (details) => handler(
            _sourceOffsetForTap(
              context,
              details.localPosition,
              spans,
              constraints.maxWidth,
            ),
          ),
          child: text,
        );
      },
    );
    if (!semantic) return detector;
    // `onTapUp` alone publishes no semantic action, so the block would be
    // unreachable by anything but a real finger.
    return MergeSemantics(
      child: Semantics(
        hint: _editHint,
        onTap: _activateFromSemantics,
        child: detector,
      ),
    );
  }

  Widget _withLeadingAffordance(
    BuildContext context,
    Widget text,
    String visibleText,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (block.type) {
      case MarkdownBlockType.checkItem:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MergeSemantics(
              child: Semantics(
                key: const ValueKey('note-block-checkbox'),
                checked: block.checked,
                label: visibleText.isEmpty
                    ? 'Casilla vacía'
                    : 'Casilla: $visibleText',
                child: SizedBox(
                  width: _checkboxTarget,
                  height: _checkboxTarget,
                  child: InkWell(
                    onTap: onToggleCheck == null
                        ? null
                        : () {
                            triggerHaptic(HapticType.light);
                            // VoiceOver reads the flipped state on its own,
                            // TalkBack and Switch Control do not always.
                            SemanticsService.sendAnnouncement(
                              View.of(context),
                              block.checked
                                  ? 'Casilla sin marcar'
                                  : 'Casilla marcada',
                              Directionality.of(context),
                            );
                            onToggleCheck!();
                          },
                    customBorder: const CircleBorder(),
                    child: Icon(
                      block.checked
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      color: block.checked
                          ? context.zentraPalette.brandTeal
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: context.spacing.sm),
                child: text,
              ),
            ),
          ],
        );
      case MarkdownBlockType.bulletItem:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(right: context.spacing.xs),
              child: Text('•', style: noteBlockTextStyle(context, block)),
            ),
            Expanded(child: text),
          ],
        );
      case MarkdownBlockType.numberedItem:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(right: context.spacing.xs),
              child: Text(
                '${displayNumber ?? 1}.',
                style: noteBlockTextStyle(context, block),
              ),
            ),
            Expanded(child: text),
          ],
        );
      case MarkdownBlockType.quote:
        return Container(
          padding: EdgeInsets.only(left: context.spacing.sm),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: colorScheme.outlineVariant, width: 3),
            ),
          ),
          child: text,
        );
      case MarkdownBlockType.codeFence:
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.spacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(context.radii.small),
          ),
          child: text,
        );
      default:
        return text;
    }
  }

  /// Maps a tap inside the rendered text to an offset on the source line, so
  /// entering edit mode lands the caret where the user actually pointed.
  int _sourceOffsetForTap(
    BuildContext context,
    Offset localPosition,
    List<InlineSpan> spans,
    double maxWidth,
  ) {
    // Everything a `Text` resolves from its context, resolved the same way
    // here. The two agree today only because the Material text theme styles
    // do not inherit; an ancestor `DefaultTextStyle` would otherwise lay the
    // line out differently and put the caret a character off.
    final defaults = DefaultTextStyle.of(context);
    var style = defaults.style;
    if (MediaQuery.boldTextOf(context)) {
      style = style.merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    final painter = TextPainter(
      text: TextSpan(style: style, children: spans),
      textAlign: defaults.textAlign ?? TextAlign.start,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: defaults.maxLines,
      locale: Localizations.maybeLocaleOf(context),
      textWidthBasis: defaults.textWidthBasis,
      textHeightBehavior: defaults.textHeightBehavior ??
          DefaultTextHeightBehavior.maybeOf(context),
    )..layout(maxWidth: maxWidth);
    final visibleOffset = painter.getPositionForOffset(localPosition).offset;
    painter.dispose();
    return _sourceOffsetFor(visibleOffset);
  }

  /// Translates an offset on the rendered text into one on the source line.
  ///
  /// The two disagree by every marker the renderer dropped, so the offset is
  /// walked back through the same tokenization rather than shifted by the
  /// block prefix alone.
  int _sourceOffsetFor(int visibleOffset) {
    final maximum = block.toSourceLine().length;
    if (_isLiteral) {
      return _clamp(_literalText.$2 + visibleOffset, maximum);
    }
    final prefixLength = block.leading.length + block.prefix.length;
    var consumed = 0;
    for (final segment in tokenizeInline(block.text)) {
      if (segment.isMarker) continue;
      final length = segment.text.length;
      if (visibleOffset <= consumed + length) {
        return _clamp(
          prefixLength + segment.start + visibleOffset - consumed,
          maximum,
        );
      }
      consumed += length;
    }
    return _clamp(prefixLength + block.text.length, maximum);
  }

  static int _clamp(int value, int maximum) {
    if (value < 0) return 0;
    return value > maximum ? maximum : value;
  }
}
