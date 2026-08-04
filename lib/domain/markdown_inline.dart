// lib/domain/markdown_inline.dart

enum MarkdownInlineStyle { bold, italic, code, strikethrough, link }

/// A slice of a block's text. Concatenating [text] over all segments of a
/// tokenization always rebuilds the original input exactly.
class MarkdownInlineSegment {
  final int start;
  final int end;
  final String text;
  final Set<MarkdownInlineStyle> styles;
  final bool isMarker;
  final String? href;

  const MarkdownInlineSegment({
    required this.start,
    required this.end,
    required this.text,
    this.styles = const {},
    this.isMarker = false,
    this.href,
  });
}

const _delimiters = <String, MarkdownInlineStyle>{
  '**': MarkdownInlineStyle.bold,
  '__': MarkdownInlineStyle.bold,
  '~~': MarkdownInlineStyle.strikethrough,
  '`': MarkdownInlineStyle.code,
  '*': MarkdownInlineStyle.italic,
  '_': MarkdownInlineStyle.italic,
};

final _linkPattern = RegExp(r'\[([^\]\n]*)\]\(([^)\s]*)\)');

/// Splits [text] into styled segments, keeping the exact source offsets so the
/// editor can dim markers in place.
List<MarkdownInlineSegment> tokenizeInline(String text) {
  if (text.isEmpty) return const [];
  final segments = <MarkdownInlineSegment>[];
  final active = <MarkdownInlineStyle>{};
  final buffer = StringBuffer();
  var bufferStart = 0;
  var index = 0;

  void flush(int end) {
    if (buffer.isEmpty) return;
    segments.add(
      MarkdownInlineSegment(
        start: bufferStart,
        end: end,
        text: buffer.toString(),
        styles: Set.unmodifiable(active),
      ),
    );
    buffer.clear();
    bufferStart = end;
  }

  void addMarker(String marker, MarkdownInlineStyle style, int at) {
    segments.add(
      MarkdownInlineSegment(
        start: at,
        end: at + marker.length,
        text: marker,
        styles: {style},
        isMarker: true,
      ),
    );
  }

  while (index < text.length) {
    final link = _linkPattern.matchAsPrefix(text, index);
    if (link != null) {
      flush(index);
      final label = link.group(1)!;
      final href = link.group(2)!;
      addMarker('[', MarkdownInlineStyle.link, index);
      segments.add(
        MarkdownInlineSegment(
          start: index + 1,
          end: index + 1 + label.length,
          text: label,
          styles: {...active, MarkdownInlineStyle.link},
          href: href,
        ),
      );
      final tailStart = index + 1 + label.length;
      segments.add(
        MarkdownInlineSegment(
          start: tailStart,
          end: link.end,
          text: text.substring(tailStart, link.end),
          styles: {MarkdownInlineStyle.link},
          isMarker: true,
        ),
      );
      index = link.end;
      bufferStart = index;
      continue;
    }

    final opener = _delimiterAt(text, index);
    if (opener != null) {
      final marker = opener.key;
      final style = opener.value;
      final closeAt = text.indexOf(marker, index + marker.length);
      final opens = !active.contains(style) &&
          closeAt != -1 &&
          closeAt > index + marker.length;
      if (opens) {
        flush(index);
        addMarker(marker, style, index);
        active.add(style);
        index += marker.length;
        bufferStart = index;
        continue;
      }
      if (active.contains(style)) {
        flush(index);
        addMarker(marker, style, index);
        active.remove(style);
        index += marker.length;
        bufferStart = index;
        continue;
      }
    }

    buffer.write(text[index]);
    index++;
  }
  flush(text.length);
  return List.unmodifiable(segments);
}

MapEntry<String, MarkdownInlineStyle>? _delimiterAt(String text, int index) {
  for (final entry in _delimiters.entries) {
    if (text.startsWith(entry.key, index)) return entry;
  }
  return null;
}
