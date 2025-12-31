/// Token types for syntax highlighting.
enum TokenType {
  keyword,
  lineComment,
  blockComment,
  string,
  number,
  literal,
  type,
  plain,
}

/// A token representing a span of text with absolute byte positions.
class Token {
  final TokenType type;
  final int start; // byte offset (inclusive)
  final int end; // byte offset (exclusive)

  const Token(this.type, this.start, this.end);

  int get length => end - start;

  /// Check if this token overlaps with a byte range.
  bool overlaps(int rangeStart, int rangeEnd) {
    return start < rangeEnd && end > rangeStart;
  }

  @override
  String toString() => 'Token($type, $start-$end)';
}
