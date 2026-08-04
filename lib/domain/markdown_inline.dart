// lib/domain/markdown_inline.dart

enum MarkdownInlineStyle { bold, italic, code, strikethrough, link }

/// A slice of a block's text. Concatenating [text] over all segments of a
/// tokenization always rebuilds the original input exactly, and every segment
/// satisfies `input.substring(start, end) == text`. The editor relies on both
/// to dim markers in place without disturbing the caret.
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MarkdownInlineSegment &&
        other.start == start &&
        other.end == end &&
        other.text == text &&
        other.isMarker == isMarker &&
        other.href == href &&
        other.styles.length == styles.length &&
        other.styles.containsAll(styles);
  }

  @override
  int get hashCode => Object.hash(
        start,
        end,
        text,
        isMarker,
        href,
        Object.hashAllUnordered(styles),
      );

  @override
  String toString() {
    final names = styles.map((style) => style.name).toList()..sort();
    return 'MarkdownInlineSegment($start..$end '
        '${isMarker ? 'marker' : 'text'} "$text" $names'
        '${href == null ? '' : ' -> $href'})';
  }
}

// Longest markers first: _delimiterAt returns the first entry that matches, so
// reordering this map would turn `**bold**` into two nested italics.
const _delimiters = <String, MarkdownInlineStyle>{
  '**': MarkdownInlineStyle.bold,
  '__': MarkdownInlineStyle.bold,
  '~~': MarkdownInlineStyle.strikethrough,
  '`': MarkdownInlineStyle.code,
  '*': MarkdownInlineStyle.italic,
  '_': MarkdownInlineStyle.italic,
};

const _escapable = r'\`*_{}[]()#+-.!~>|';

final _linkPattern = RegExp(r'\[([^\]\n]*)\]\(([^)\s]*)\)');
final _wordPattern = RegExp(r'[\p{L}\p{N}]', unicode: true);

/// Splits [text] into styled segments, keeping the exact source offsets so the
/// editor can dim markers in place.
List<MarkdownInlineSegment> tokenizeInline(String text) =>
    _tokenize(text, 0, const <MarkdownInlineStyle>{}, null);

List<MarkdownInlineSegment> _tokenize(
  String source,
  int base,
  Set<MarkdownInlineStyle> inherited,
  String? href,
) {
  if (source.isEmpty) return const [];

  final segments = <MarkdownInlineSegment>[];
  final active = <MarkdownInlineStyle>{...inherited};
  // Where each currently open style started, so a candidate closer can be
  // judged against its own opener rather than against whatever came last.
  final openIndexOf = <MarkdownInlineStyle, int>{};
  final openMarkerOf = <MarkdownInlineStyle, String>{};
  // Links are located once up front. Two reasons: scanning for them at every
  // index is quadratic on a line full of unmatched brackets, and a delimiter
  // must never close inside a span the link pass is going to swallow.
  final links = <int, RegExpMatch>{
    for (final match in _linkPattern.allMatches(source)) match.start: match,
  };
  // A marker with no closer from index i also has none from any later index,
  // so remembering the first failure keeps a long run of openers linear.
  final firstUnclosed = <String, int>{};

  final buffer = StringBuffer();
  var bufferStart = 0;
  var index = 0;

  void flush(int end) {
    if (buffer.isEmpty) return;
    segments.add(
      MarkdownInlineSegment(
        start: base + bufferStart,
        end: base + end,
        text: buffer.toString(),
        styles: Set.unmodifiable(active),
        href: href,
      ),
    );
    buffer.clear();
    bufferStart = end;
  }

  void addMarker(int at, int to, Set<MarkdownInlineStyle> styles,
      [String? markerHref]) {
    segments.add(
      MarkdownInlineSegment(
        start: base + at,
        end: base + to,
        text: source.substring(at, to),
        styles: Set.unmodifiable(styles),
        isMarker: true,
        href: markerHref ?? href,
      ),
    );
  }

  while (index < source.length) {
    final char = source[index];

    if (char == r'\' &&
        index + 1 < source.length &&
        _escapable.contains(source[index + 1])) {
      flush(index);
      addMarker(index, index + 1, active);
      bufferStart = index + 1;
      buffer.write(source[index + 1]);
      index += 2;
      continue;
    }

    final link = links[index];
    if (link != null) {
      flush(index);
      final label = link.group(1)!;
      final target = link.group(2)!;
      final linkStyles = {...active, MarkdownInlineStyle.link};
      addMarker(index, index + 1, linkStyles, target);
      segments.addAll(_tokenize(label, base + index + 1, linkStyles, target));
      addMarker(index + 1 + label.length, link.end, linkStyles, target);
      index = link.end;
      bufferStart = index;
      continue;
    }

    final delimiter = _delimiterAt(source, index);
    if (delimiter != null) {
      final marker = delimiter.key;
      final style = delimiter.value;
      final openedAt = openIndexOf[style];

      if (openedAt != null &&
          openMarkerOf[style] == marker &&
          _closesAt(source, marker, openedAt, index)) {
        flush(index);
        addMarker(index, index + marker.length, active);
        active.remove(style);
        openIndexOf.remove(style);
        openMarkerOf.remove(style);
        index += marker.length;
        bufferStart = index;
        continue;
      }

      final knownUnclosed = firstUnclosed[marker];
      if (openedAt == null &&
          (knownUnclosed == null || index < knownUnclosed) &&
          _opensAt(source, marker, index)) {
        final closeAt = _findCloser(source, marker, index, links);
        if (closeAt == -1) {
          firstUnclosed[marker] = index;
        } else if (style == MarkdownInlineStyle.code) {
          // Code wins over every other construct: its content is literal, so
          // it is emitted whole instead of being walked marker by marker.
          flush(index);
          final codeStyles = {...active, MarkdownInlineStyle.code};
          addMarker(index, index + marker.length, codeStyles);
          segments.add(
            MarkdownInlineSegment(
              start: base + index + marker.length,
              end: base + closeAt,
              text: source.substring(index + marker.length, closeAt),
              styles: Set.unmodifiable(codeStyles),
              href: href,
            ),
          );
          addMarker(closeAt, closeAt + marker.length, codeStyles);
          index = closeAt + marker.length;
          bufferStart = index;
          continue;
        } else {
          flush(index);
          active.add(style);
          openIndexOf[style] = index;
          openMarkerOf[style] = marker;
          addMarker(index, index + marker.length, active);
          index += marker.length;
          bufferStart = index;
          continue;
        }
      }
    }

    buffer.write(char);
    index++;
  }

  flush(source.length);
  return List.unmodifiable(segments);
}

MapEntry<String, MarkdownInlineStyle>? _delimiterAt(String source, int index) {
  for (final entry in _delimiters.entries) {
    if (source.startsWith(entry.key, index)) return entry;
  }
  return null;
}

/// Finds the first offset after [from] where [marker] would legitimately close,
/// skipping escapes, links and code spans so a closer is never borrowed from a
/// span that another rule owns.
int _findCloser(
  String source,
  String marker,
  int from,
  Map<int, RegExpMatch> links,
) {
  var index = from + marker.length;
  while (index < source.length) {
    if (source[index] == r'\' && index + 1 < source.length) {
      index += 2;
      continue;
    }
    final link = links[index];
    if (link != null) {
      index = link.end;
      continue;
    }
    if (marker != '`' && source[index] == '`') {
      final codeEnd = source.indexOf('`', index + 1);
      if (codeEnd != -1) {
        index = codeEnd + 1;
        continue;
      }
    }
    final here = _delimiterAt(source, index);
    if (here == null) {
      index++;
      continue;
    }
    if (here.key != marker) {
      index += here.key.length;
      continue;
    }
    if (_closesAt(source, marker, from, index)) return index;
    index += marker.length;
  }
  return -1;
}

/// Emphasis needs content and must hug it. Underscores additionally refuse to
/// open or close against a word character, which is what keeps identifiers
/// such as `reporte_final_v2` out of italics.
bool _opensAt(String source, String marker, int index) {
  final after = _charAt(source, index + marker.length);
  if (after == null) return false;
  if (marker != '`' && _isSpace(after)) return false;
  if (marker.startsWith('_') && _isWord(_charAt(source, index - 1))) {
    return false;
  }
  return true;
}

bool _closesAt(String source, String marker, int openIndex, int closeIndex) {
  if (closeIndex <= openIndex + marker.length) return false;
  if (marker != '`' && _isSpace(_charAt(source, closeIndex - 1))) return false;
  if (marker.startsWith('_') &&
      _isWord(_charAt(source, closeIndex + marker.length))) {
    return false;
  }
  return true;
}

String? _charAt(String source, int index) =>
    index < 0 || index >= source.length ? null : source[index];

bool _isSpace(String? character) =>
    character == null || character.trim().isEmpty;

bool _isWord(String? character) =>
    character != null && _wordPattern.hasMatch(character);
