import '../token.dart';
import '../tokenizer.dart';

/// Regex-based tokenizer for YAML files.
///
/// Produces tokens with absolute byte positions for a given text range.
class YamlTokenizer extends Tokenizer {
  // Line comment (# to end of line)
  static final _lineComment = RegExp(r'#.*');
  // Quoted strings
  static final _doubleString = RegExp(r'"(?:[^"\\]|\\.)*"');
  static final _singleString = RegExp(r"'(?:[^'\\]|\\.)*'");
  // Numbers (integers, floats, hex, octal, infinity, NaN)
  static final _number = RegExp(
    r'(?<![a-zA-Z_])(?:[-+]?(?:0x[0-9a-fA-F]+|0o[0-7]+|[0-9]+(?:\.[0-9]*)?(?:[eE][+-]?[0-9]+)?)|[-+]?\.(?:inf|Inf|INF)|\.(?:nan|NaN|NAN))(?![a-zA-Z_])',
  );
  // Boolean and null literals
  static final _literal = RegExp(
    r'\b(?:true|false|True|False|TRUE|FALSE|yes|no|Yes|No|YES|NO|null|Null|NULL|~)\b',
  );
  // Anchors (&name) and aliases (*name)
  static final _anchor = RegExp(r'[&*][a-zA-Z_][a-zA-Z0-9_]*');
  // Tags (!!str, !custom, etc.)
  static final _tag = RegExp(r'!(?:![a-zA-Z]+|[a-zA-Z][a-zA-Z0-9]*)?');
  // Key pattern (identifier followed by colon, at various positions)
  static final _key = RegExp(r'[a-zA-Z_][a-zA-Z0-9_]*(?=\s*:)');
  // List item marker at start of line (with optional leading whitespace)
  static final _listItem = RegExp(r'-\s');
  // Block scalar indicators (| or >)
  static final _blockScalar = RegExp(r'[|>][+-]?[0-9]*');
  // Directive (%YAML, %TAG)
  static final _directive = RegExp(r'%[A-Z]+\s.*');

  @override
  List<Token> tokenize(String text, int start, int end) {
    final tokens = <Token>[];
    var pos = start;

    // Note: YAML block scalars are complex (indentation-based).
    // For simplicity, we don't track multiline state for block scalars.
    // They will be highlighted line-by-line as plain text after the indicator.

    while (pos < end) {
      // Skip whitespace
      if (isWhitespace(text, pos)) {
        pos++;
        continue;
      }

      // Line comment (# to end of line)
      if (text[pos] == '#') {
        final match = _lineComment.matchAsPrefix(text, pos);
        if (match != null) {
          final endPos = match.end > end ? end : match.end;
          tokens.add(Token(.lineComment, pos, endPos));
          pos = endPos;
          continue;
        }
      }

      // Directive at start of line
      if (isLineStart(text, pos) && text[pos] == '%') {
        final match = _directive.matchAsPrefix(text, pos);
        if (match != null) {
          final endPos = match.end > end ? end : match.end;
          tokens.add(Token(.keyword, pos, endPos));
          pos = endPos;
          continue;
        }
      }

      // List item marker
      if (text[pos] == '-' && pos + 1 < text.length) {
        final match = _listItem.matchAsPrefix(text, pos);
        if (match != null) {
          // Just highlight the dash
          tokens.add(Token(.number, pos, pos + 1));
          pos++;
          continue;
        }
      }

      // Block scalar indicator
      if (text[pos] == '|' || text[pos] == '>') {
        final match = _blockScalar.matchAsPrefix(text, pos);
        if (match != null) {
          tokens.add(Token(.keyword, pos, match.end));
          pos = match.end;
          continue;
        }
      }

      // Double-quoted string
      if (text[pos] == '"') {
        final match = _doubleString.matchAsPrefix(text, pos);
        if (match != null) {
          tokens.add(Token(.string, pos, match.end));
          pos = match.end;
          continue;
        }
      }

      // Single-quoted string
      if (text[pos] == "'") {
        final match = _singleString.matchAsPrefix(text, pos);
        if (match != null) {
          tokens.add(Token(.string, pos, match.end));
          pos = match.end;
          continue;
        }
      }

      // Anchor or alias
      if (text[pos] == '&' || text[pos] == '*') {
        final match = _anchor.matchAsPrefix(text, pos);
        if (match != null) {
          tokens.add(Token(.type, pos, match.end));
          pos = match.end;
          continue;
        }
      }

      // Tag
      if (text[pos] == '!') {
        final match = _tag.matchAsPrefix(text, pos);
        if (match != null) {
          tokens.add(Token(.type, pos, match.end));
          pos = match.end;
          continue;
        }
      }

      // Literal (boolean, null)
      final literalMatch = _literal.matchAsPrefix(text, pos);
      if (literalMatch != null) {
        tokens.add(Token(.literal, pos, literalMatch.end));
        pos = literalMatch.end;
        continue;
      }

      // Number
      final numMatch = _number.matchAsPrefix(text, pos);
      if (numMatch != null) {
        tokens.add(Token(.number, pos, numMatch.end));
        pos = numMatch.end;
        continue;
      }

      // Key (identifier before colon)
      final keyMatch = _key.matchAsPrefix(text, pos);
      if (keyMatch != null) {
        tokens.add(Token(.keyword, pos, keyMatch.end));
        pos = keyMatch.end;
        continue;
      }

      pos++;
    }

    return tokens;
  }

  @override
  Multiline? findMultiline(String text, int startByte) {
    // YAML block scalars use indentation to determine boundaries,
    // which is complex to track. For now, we don't track multiline state.
    // Each line is tokenized independently.
    return null;
  }
}
