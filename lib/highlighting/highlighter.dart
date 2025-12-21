import 'dart_tokenizer.dart';
import 'token.dart';

export 'token.dart' show Token, TokenType, Theme, SyntaxColors;

/// Main syntax highlighter that tokenizes text and applies styling.
class Highlighter {
  Theme theme;
  final _dartTokenizer = DartTokenizer();

  /// Cached tokens for the current visible range.
  List<Token> _tokens = [];
  int _tokenizedStart = 0;
  int _tokenizedEnd = 0;
  String? _tokenizedPath;

  Highlighter({this.theme = Theme.dark});

  /// Detect language from file extension.
  String? detectLanguage(String? path) {
    if (path == null) return null;
    final dot = path.lastIndexOf('.');
    if (dot == -1) return null;
    final ext = path.substring(dot + 1).toLowerCase();
    return ext == 'dart' ? 'dart' : null;
  }

  /// Check if highlighting is available for a file.
  bool canHighlight(String? path) => detectLanguage(path) != null;

  /// Tokenize a range of the document.
  ///
  /// Call this once before rendering visible lines. Tokens are cached
  /// and reused for applying styles to individual lines.
  void tokenizeRange(
    String text,
    int startByte,
    int endByte,
    String? filePath,
  ) {
    final language = detectLanguage(filePath);
    if (language == null) {
      _tokens = [];
      return;
    }

    // Check cache - avoid re-tokenizing if range hasn't changed much
    if (filePath == _tokenizedPath &&
        startByte >= _tokenizedStart &&
        endByte <= _tokenizedEnd) {
      return;
    }

    // Find multiline state before visible range
    final state = _dartTokenizer.findMultilineState(text, startByte);

    // Tokenize the visible range
    _tokens = _dartTokenizer.tokenize(
      text,
      startByte,
      endByte,
      initialState: state,
    );
    _tokenizedStart = startByte;
    _tokenizedEnd = endByte;
    _tokenizedPath = filePath;
  }

  /// Clear the token cache.
  void invalidateCache() {
    _tokens = [];
    _tokenizedStart = 0;
    _tokenizedEnd = 0;
    _tokenizedPath = null;
  }

  /// Apply syntax highlighting to a line.
  ///
  /// [lineText] is the text of the line (after tab expansion).
  /// [lineStartByte] is the byte offset where this line starts in the document.
  /// [lineEndByte] is the byte offset where this line ends.
  ///
  /// Returns the styled text with ANSI codes.
  String styleLine(String lineText, int lineStartByte, int lineEndByte) {
    if (_tokens.isEmpty || lineText.isEmpty) return lineText;

    // Find tokens that overlap this line
    final overlapping = <Token>[];
    for (final token in _tokens) {
      if (token.start >= lineEndByte) break; // Past this line
      if (token.overlaps(lineStartByte, lineEndByte)) {
        overlapping.add(token);
      }
    }

    if (overlapping.isEmpty) return lineText;

    // Build styled output
    final buffer = StringBuffer();
    var pos = 0; // Position in lineText

    for (final token in overlapping) {
      // Calculate token's position relative to line
      final tokenStartInLine = token.start <= lineStartByte
          ? 0
          : token.start - lineStartByte;
      final tokenEndInLine = token.end >= lineEndByte
          ? lineText.length
          : token.end - lineStartByte;

      // Add unstyled text before token
      if (tokenStartInLine > pos) {
        buffer.write(lineText.substring(pos, tokenStartInLine));
      }

      // Add styled token (skip plain tokens)
      if (token.type != TokenType.plain) {
        buffer.write(theme.colorFor(token.type));
        buffer.write(lineText.substring(tokenStartInLine, tokenEndInLine));
        buffer.write(SyntaxColors.reset);
      } else {
        buffer.write(lineText.substring(tokenStartInLine, tokenEndInLine));
      }

      pos = tokenEndInLine;
    }

    // Add remaining unstyled text
    if (pos < lineText.length) {
      buffer.write(lineText.substring(pos));
    }

    return buffer.toString();
  }

  /// Apply styling to a substring of a line (for horizontal scroll or wrap).
  ///
  /// [lineText] is the full line text.
  /// [substring] is the visible portion.
  /// [substringStartInLine] is where the substring starts in lineText.
  /// [lineStartByte] is the byte offset of the line in the document.
  String styleSubstring(
    String lineText,
    String substring,
    int substringStartInLine,
    int lineStartByte,
  ) {
    if (_tokens.isEmpty || substring.isEmpty) return substring;

    final substringStartByte = lineStartByte + substringStartInLine;
    final substringEndByte = substringStartByte + substring.length;

    // Find tokens that overlap this substring
    final overlapping = <Token>[];
    for (final token in _tokens) {
      if (token.start >= substringEndByte) break;
      if (token.overlaps(substringStartByte, substringEndByte)) {
        overlapping.add(token);
      }
    }

    if (overlapping.isEmpty) return substring;

    // Build styled output
    final buffer = StringBuffer();
    var pos = 0; // Position in substring

    for (final token in overlapping) {
      // Calculate token's position relative to substring
      final tokenStartInSub = token.start <= substringStartByte
          ? 0
          : token.start - substringStartByte;
      final tokenEndInSub = token.end >= substringEndByte
          ? substring.length
          : token.end - substringStartByte;

      // Add unstyled text before token
      if (tokenStartInSub > pos) {
        buffer.write(substring.substring(pos, tokenStartInSub));
      }

      // Add styled token
      if (token.type != TokenType.plain) {
        buffer.write(theme.colorFor(token.type));
        buffer.write(substring.substring(tokenStartInSub, tokenEndInSub));
        buffer.write(SyntaxColors.reset);
      } else {
        buffer.write(substring.substring(tokenStartInSub, tokenEndInSub));
      }

      pos = tokenEndInSub;
    }

    // Add remaining unstyled text
    if (pos < substring.length) {
      buffer.write(substring.substring(pos));
    }

    return buffer.toString();
  }
}
