import '../token.dart';
import '../tokenizer.dart';

/// Regex-based tokenizer for XML/HTML files.
///
/// Produces tokens with absolute byte positions for a given text range.
class XmlTokenizer extends Tokenizer {
  // DOCTYPE <!DOCTYPE ...>
  static final _doctypeStart = RegExp(r'<!DOCTYPE\b', caseSensitive: false);
  // Tag name after < or </
  static final _tagStart = RegExp(r'</?');
  static final _tagName = RegExp(r'[a-zA-Z_:][\w:.-]*');
  // Attribute name
  static final _attrName = RegExp(r'[a-zA-Z_:][\w:.-]*');
  // Quoted strings (attribute values)
  static final _doubleString = RegExp(r'"[^"]*"');
  static final _singleString = RegExp(r"'[^']*'");
  // Entity reference &...; or &#...;
  static final _entityRef = RegExp(
    r'&(?:#[xX]?[0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]*);',
  );

  @override
  List<Token> tokenize(String text, int start, int end) {
    final tokens = <Token>[];
    var pos = start;
    var state = findMultiline(text, start);

    // If starting inside a comment, find its end
    if (state != null && state.isComment) {
      final endPos = _findCommentEnd(text, pos, end);
      tokens.add(Token(.blockComment, pos, endPos));
      pos = endPos;
      if (endPos < end && _endsWithCommentClose(text, endPos)) {
        state = null;
      }
    }

    // If starting inside CDATA, find its end
    if (state != null && state.delimiter == 'CDATA') {
      final endPos = _findCdataEnd(text, pos, end);
      tokens.add(Token(.string, pos, endPos));
      pos = endPos;
      if (endPos < end && _endsWithCdataClose(text, endPos)) {
        state = null;
      }
    }

    while (pos < end) {
      // Skip whitespace
      if (isWhitespace(text, pos)) {
        pos++;
        continue;
      }

      // XML comment <!--
      if (matchesAt(text, pos, '<!--')) {
        final endPos = _findCommentEnd(text, pos + 4, end);
        tokens.add(Token(.blockComment, pos, endPos));
        pos = endPos;
        continue;
      }

      // CDATA section
      if (matchesAt(text, pos, '<![CDATA[')) {
        final endPos = _findCdataEnd(text, pos + 9, end);
        tokens.add(Token(.string, pos, endPos));
        pos = endPos;
        continue;
      }

      // Processing instruction <?xml ... ?>
      if (matchesAt(text, pos, '<?')) {
        final endPos = _findPiEnd(text, pos + 2, end);
        tokens.add(Token(.keyword, pos, endPos));
        pos = endPos;
        continue;
      }

      // DOCTYPE
      final doctypeMatch = _doctypeStart.matchAsPrefix(text, pos);
      if (doctypeMatch != null) {
        final endPos = _findDoctypeEnd(text, doctypeMatch.end, end);
        tokens.add(Token(.keyword, pos, endPos));
        pos = endPos;
        continue;
      }

      // Tag start (< or </)
      final tagStartMatch = _tagStart.matchAsPrefix(text, pos);
      if (tagStartMatch != null) {
        final tagStartEnd = tagStartMatch.end;

        // Match tag name
        final nameMatch = _tagName.matchAsPrefix(text, tagStartEnd);
        if (nameMatch != null) {
          // Highlight the tag name (including < or </)
          tokens.add(Token(.keyword, pos, nameMatch.end));
          pos = nameMatch.end;

          // Parse attributes until > or />
          while (pos < end) {
            // Skip whitespace
            while (pos < end && isWhitespace(text, pos)) {
              pos++;
            }

            // Check for tag end
            if (pos < end && text[pos] == '>') {
              pos++;
              break;
            }
            if (matchesAt(text, pos, '/>')) {
              pos += 2;
              break;
            }

            // Attribute name
            final attrMatch = _attrName.matchAsPrefix(text, pos);
            if (attrMatch != null) {
              tokens.add(Token(.type, pos, attrMatch.end));
              pos = attrMatch.end;

              // Skip whitespace around =
              while (pos < end && isWhitespace(text, pos)) {
                pos++;
              }

              // Check for =
              if (pos < end && text[pos] == '=') {
                pos++;

                // Skip whitespace after =
                while (pos < end && isWhitespace(text, pos)) {
                  pos++;
                }

                // Attribute value (quoted string)
                final dblMatch = _doubleString.matchAsPrefix(text, pos);
                if (dblMatch != null) {
                  tokens.add(Token(.string, pos, dblMatch.end));
                  pos = dblMatch.end;
                  continue;
                }
                final sglMatch = _singleString.matchAsPrefix(text, pos);
                if (sglMatch != null) {
                  tokens.add(Token(.string, pos, sglMatch.end));
                  pos = sglMatch.end;
                  continue;
                }
              }
              continue;
            }

            // If nothing matched, move forward to avoid infinite loop
            pos++;
          }
          continue;
        }
      }

      // Closing tag marker >
      if (text[pos] == '>') {
        pos++;
        continue;
      }

      // Entity reference
      final entityMatch = _entityRef.matchAsPrefix(text, pos);
      if (entityMatch != null) {
        tokens.add(Token(.literal, pos, entityMatch.end));
        pos = entityMatch.end;
        continue;
      }

      pos++;
    }

    return tokens;
  }

  @override
  Multiline? findMultiline(String text, int startByte) {
    var pos = 0;
    Multiline? state;

    while (pos < startByte) {
      if (isWhitespace(text, pos)) {
        pos++;
        continue;
      }

      // XML comment
      if (matchesAt(text, pos, '<!--')) {
        final endIdx = text.indexOf('-->', pos + 4);
        if (endIdx == -1 || endIdx + 3 > startByte) {
          state = Multiline.blockComment;
          pos += 4;
        } else {
          pos = endIdx + 3;
          state = null;
        }
        continue;
      }

      // CDATA section
      if (matchesAt(text, pos, '<![CDATA[')) {
        final endIdx = text.indexOf(']]>', pos + 9);
        if (endIdx == -1 || endIdx + 3 > startByte) {
          state = const Multiline('CDATA');
          pos += 9;
        } else {
          pos = endIdx + 3;
          state = null;
        }
        continue;
      }

      pos++;
    }

    return state;
  }

  int _findCommentEnd(String text, int pos, int endByte) {
    final endIdx = text.indexOf('-->', pos);
    if (endIdx == -1 || endIdx + 3 > endByte) {
      return endByte;
    }
    return endIdx + 3;
  }

  bool _endsWithCommentClose(String text, int endPos) {
    return endPos >= 3 && text.substring(endPos - 3, endPos) == '-->';
  }

  int _findCdataEnd(String text, int pos, int endByte) {
    final endIdx = text.indexOf(']]>', pos);
    if (endIdx == -1 || endIdx + 3 > endByte) {
      return endByte;
    }
    return endIdx + 3;
  }

  bool _endsWithCdataClose(String text, int endPos) {
    return endPos >= 3 && text.substring(endPos - 3, endPos) == ']]>';
  }

  int _findPiEnd(String text, int pos, int endByte) {
    final endIdx = text.indexOf('?>', pos);
    if (endIdx == -1 || endIdx + 2 > endByte) {
      return endByte;
    }
    return endIdx + 2;
  }

  int _findDoctypeEnd(String text, int pos, int endByte) {
    // DOCTYPE can contain internal subset in brackets
    var depth = 0;
    while (pos < endByte) {
      final c = text[pos];
      if (c == '[') {
        depth++;
      } else if (c == ']') {
        depth--;
      } else if (c == '>' && depth == 0) {
        return pos + 1;
      }
      pos++;
    }
    return endByte;
  }
}
