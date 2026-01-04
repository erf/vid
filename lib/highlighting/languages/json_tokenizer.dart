import '../token.dart';
import '../tokenizer.dart';

/// Regex-based tokenizer for JSON files.
///
/// Produces tokens with absolute byte positions for a given text range.
class JsonTokenizer extends Tokenizer {
  // Double-quoted strings (JSON only supports double quotes)
  static final _string = RegExp(r'"(?:[^"\\]|\\.)*"');
  // Numbers (integers, floats, negative, exponents)
  static final _number = RegExp(r'-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?');
  // Boolean and null literals
  static final _literal = RegExp(r'\b(?:true|false|null)\b');
  // Key pattern (string followed by colon) - we'll handle this specially
  static final _keyLookahead = RegExp(r'"(?:[^"\\]|\\.)*"\s*:');

  @override
  List<Token> tokenize(String text, int start, int end) {
    final tokens = <Token>[];
    var pos = start;

    while (pos < end) {
      // Skip whitespace
      if (isWhitespace(text, pos)) {
        pos++;
        continue;
      }

      // Skip structural characters (braces, brackets, colons, commas)
      final char = text[pos];
      if (char == '{' ||
          char == '}' ||
          char == '[' ||
          char == ']' ||
          char == ':' ||
          char == ',') {
        pos++;
        continue;
      }

      // Double-quoted string (check if it's a key first)
      if (char == '"') {
        final keyMatch = _keyLookahead.matchAsPrefix(text, pos);
        if (keyMatch != null) {
          // This is a key - find just the string part
          final stringMatch = _string.matchAsPrefix(text, pos);
          if (stringMatch != null) {
            tokens.add(Token(.keyword, pos, stringMatch.end));
            pos = stringMatch.end;
            continue;
          }
        }

        // Regular string value
        final stringMatch = _string.matchAsPrefix(text, pos);
        if (stringMatch != null) {
          tokens.add(Token(.string, pos, stringMatch.end));
          pos = stringMatch.end;
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
      if (char == '-' ||
          (char.codeUnitAt(0) >= 0x30 && char.codeUnitAt(0) <= 0x39)) {
        final numMatch = _number.matchAsPrefix(text, pos);
        if (numMatch != null) {
          tokens.add(Token(.number, pos, numMatch.end));
          pos = numMatch.end;
          continue;
        }
      }

      pos++;
    }

    return tokens;
  }

  @override
  Multiline? findMultiline(String text, int startByte) {
    // JSON doesn't have multiline constructs that span across tokenization
    // boundaries (strings must be on a single line in standard JSON).
    return null;
  }
}
