import 'languages/dart_tokenizer.dart';
import 'languages/json_tokenizer.dart';
import 'languages/markdown_tokenizer.dart';
import 'languages/yaml_tokenizer.dart';
import 'token.dart';

export 'token.dart' show Token, TokenType, Theme, ThemeType;

/// Main syntax highlighter that tokenizes text and applies styling.
class Highlighter {
  Theme theme;
  final _dartTokenizer = DartTokenizer();
  final _jsonTokenizer = JsonTokenizer();
  final _markdownTokenizer = MarkdownTokenizer();
  final _yamlTokenizer = YamlTokenizer();
  List<Token> _tokens = [];

  Highlighter({ThemeType themeType = ThemeType.dark}) : theme = themeType.theme;

  set themeType(ThemeType type) => theme = type.theme;

  /// Detect language from file extension.
  String? detectLanguage(String? path) {
    if (path == null) return null;
    final dot = path.lastIndexOf('.');
    if (dot == -1) return null;
    final ext = path.substring(dot + 1).toLowerCase();
    return switch (ext) {
      'dart' => 'dart',
      'md' || 'markdown' => 'markdown',
      'yaml' || 'yml' => 'yaml',
      'json' => 'json',
      _ => null,
    };
  }

  /// Tokenize a range of the document.
  void tokenizeRange(String text, int start, int end, String? path) {
    final lang = detectLanguage(path);
    if (lang == null) {
      _tokens = [];
      return;
    }

    _tokens = switch (lang) {
      'dart' => _dartTokenizer.tokenize(text, start, end),
      'markdown' => _markdownTokenizer.tokenize(text, start, end),
      'yaml' => _yamlTokenizer.tokenize(text, start, end),
      'json' => _jsonTokenizer.tokenize(text, start, end),
      _ => [],
    };
  }

  /// Apply styling to a visible substring.
  ///
  /// [text] is the visible text to style.
  /// [start] is the byte offset where this text starts in the document.
  String style(String text, int start) {
    if (_tokens.isEmpty || text.isEmpty) return text;

    final textEndByte = start + text.length;

    // Find tokens that overlap this text
    final overlapping = <Token>[];
    for (final token in _tokens) {
      if (token.start >= textEndByte) break;
      if (token.overlaps(start, textEndByte)) {
        overlapping.add(token);
      }
    }

    if (overlapping.isEmpty) return text;

    // Build styled output
    final buffer = StringBuffer();
    var pos = 0;

    for (final token in overlapping) {
      final tokenStart = token.start <= start ? 0 : token.start - start;
      final tokenEnd = token.end >= textEndByte
          ? text.length
          : token.end - start;

      // Add unstyled text before token
      if (tokenStart > pos) {
        buffer.write(text.substring(pos, tokenStart));
      }

      // Add styled token
      if (token.type != TokenType.plain) {
        buffer.write(theme.colorFor(token.type));
        buffer.write(text.substring(tokenStart, tokenEnd));
        buffer.write(Theme.reset);
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
