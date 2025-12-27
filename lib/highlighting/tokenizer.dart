import 'token.dart';

/// State for tracking position inside a multiline construct.
class Multiline {
  final String? delimiter; // '"""', "'''", '```', or null for block comment
  final bool isRaw;

  const Multiline(this.delimiter, {this.isRaw = false});

  bool get isComment => delimiter == null;

  static const blockComment = Multiline(null);
}

/// Base class for language tokenizers.
abstract class Tokenizer {
  /// Tokenize a range of text, returning tokens with absolute byte positions.
  ///
  /// [text] is the full document text.
  /// [start] and [end] define the range to tokenize.
  List<Token> tokenize(String text, int start, int end);

  /// Scan backwards from [start] to find if we're inside a multiline construct.
  Multiline? findMultiline(String text, int start);
  // Common utility methods

  /// Check if [pattern] matches at [pos] in [text].
  bool matchesAt(String text, int pos, String pattern) {
    if (pos + pattern.length > text.length) return false;
    return text.substring(pos, pos + pattern.length) == pattern;
  }

  /// Check if position is whitespace.
  bool isWhitespace(String text, int pos) {
    if (pos >= text.length) return false;
    final c = text.codeUnitAt(pos);
    return c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D;
  }

  /// Check if position is at start of line.
  bool isLineStart(String text, int pos) {
    return pos == 0 || (pos > 0 && text.codeUnitAt(pos - 1) == 0x0A);
  }

  /// Find end of line from position.
  int findLineEnd(String text, int pos, int endByte) {
    final nlPos = text.indexOf('\n', pos);
    return (nlPos == -1 || nlPos > endByte) ? endByte : nlPos;
  }
}
