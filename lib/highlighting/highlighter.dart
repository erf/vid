import 'dart_tokenizer.dart';
import 'token.dart';

export 'token.dart' show Token, TokenType, Theme, SyntaxColors;

/// Main syntax highlighter that tokenizes text and applies styling.
class Highlighter {
  Theme theme;
  final _dartTokenizer = DartTokenizer();
  List<Token> _tokens = [];

  Highlighter({this.theme = Theme.dark});

  /// Detect language from file extension.
  String? detectLanguage(String? path) {
    if (path == null) return null;
    final dot = path.lastIndexOf('.');
    if (dot == -1) return null;
    final ext = path.substring(dot + 1).toLowerCase();
    return ext == 'dart' ? 'dart' : null;
  }

  /// Tokenize a range of the document.
  void tokenizeRange(String text, int startByte, int endByte, String? filePath) {
    if (detectLanguage(filePath) == null) {
      _tokens = [];
      return;
    }

    final state = _dartTokenizer.findMultilineState(text, startByte);
    _tokens = _dartTokenizer.tokenize(text, startByte, endByte, initialState: state);
  }

  /// Apply styling to a visible substring.
  ///
  /// [text] is the visible text to style.
  /// [textStartByte] is the byte offset where this text starts in the document.
  String style(String text, int textStartByte) {
    if (_tokens.isEmpty || text.isEmpty) return text;

    final textEndByte = textStartByte + text.length;

    // Find tokens that overlap this text
    final overlapping = <Token>[];
    for (final token in _tokens) {
      if (token.start >= textEndByte) break;
      if (token.overlaps(textStartByte, textEndByte)) {
        overlapping.add(token);
      }
    }

    if (overlapping.isEmpty) return text;

    // Build styled output
    final buffer = StringBuffer();
    var pos = 0;

    for (final token in overlapping) {
      final tokenStart = token.start <= textStartByte ? 0 : token.start - textStartByte;
      final tokenEnd = token.end >= textEndByte ? text.length : token.end - textStartByte;

      // Add unstyled text before token
      if (tokenStart > pos) {
        buffer.write(text.substring(pos, tokenStart));
      }

      // Add styled token
      if (token.type != TokenType.plain) {
        buffer.write(theme.colorFor(token.type));
        buffer.write(text.substring(tokenStart, tokenEnd));
        buffer.write(SyntaxColors.reset);
      } else {
        buffer.write(text.substring(tokenStart, tokenEnd));
      }

      pos = tokenEnd;
    }

    // Add remaining unstyled text
    if (pos < text.length) {
      buffer.write(text.substring(pos));
    }

    return buffer.toString();
  }
}
