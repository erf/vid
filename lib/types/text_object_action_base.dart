import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer.dart';
import 'package:vid/range.dart';

/// Base class for text object actions.
///
/// Text objects define ranges of text (word, paragraph, quoted string, etc.)
/// that can be operated on with operators like delete, change, yank.
/// Implement [call] to define the text object behavior.
///
/// All text object actions should be const-constructible for zero allocation.
abstract class TextObjectAction {
  const TextObjectAction();

  /// Execute the text object to get a range.
  ///
  /// [e] Editor instance
  /// [f] FileBuffer instance
  /// [offset] Current byte offset (cursor position)
  /// Returns the Range representing this text object, or an empty range
  /// (start == end) if the text object is not found.
  Range call(Editor e, FileBuffer f, int offset);

  // ===== Utility methods for text object implementations =====

  /// Find matching bracket pair containing offset.
  /// Returns (openPos, closePos) or (-1, -1) if not found.
  (int, int) findMatchingPair(
    FileBuffer f,
    int offset,
    String open,
    String close,
  ) {
    final text = f.text;

    // Search backwards for opening bracket, counting nesting
    int openPos = -1;
    int depth = 0;
    int pos = offset;

    // First check if cursor is on a bracket
    if (pos < text.length) {
      final char = text[pos];
      if (char == open) {
        // Cursor is on opening bracket, search forward from here
        openPos = pos;
      } else if (char == close) {
        // Cursor is on closing bracket, treat it as being inside
        // Start search from before the closing bracket with depth 1
        depth = 1;
        pos = offset - 1;
        while (pos >= 0) {
          final c = text[pos];
          if (c == close) {
            depth++;
          } else if (c == open) {
            depth--;
            if (depth == 0) {
              openPos = pos;
              break;
            }
          }
          pos--;
        }
        if (openPos != -1) {
          return (openPos, offset);
        }
        return (-1, -1);
      }
    }

    // Search backwards for opening bracket
    if (openPos == -1) {
      pos = offset - 1;
      while (pos >= 0) {
        final char = text[pos];
        if (char == close) {
          depth++;
        } else if (char == open) {
          if (depth == 0) {
            openPos = pos;
            break;
          }
          depth--;
        }
        pos--;
      }
    }

    if (openPos == -1) return (-1, -1);

    // Search forward from opening bracket for matching close
    depth = 1;
    pos = openPos + 1;
    while (pos < text.length) {
      final char = text[pos];
      if (char == open) {
        depth++;
      } else if (char == close) {
        depth--;
        if (depth == 0) {
          return (openPos, pos);
        }
      }
      pos++;
    }

    return (-1, -1);
  }

  /// Find quote pair on same line containing offset.
  /// Returns (openPos, closePos) or (-1, -1) if not found.
  (int, int) findQuotePair(FileBuffer f, int offset, String quote) {
    final text = f.text;

    // Find line boundaries
    int lineStart = offset;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }
    int lineEnd = offset;
    while (lineEnd < text.length && text[lineEnd] != '\n') {
      lineEnd++;
    }

    // Find all quote positions on the line
    final quotePositions = <int>[];
    for (int i = lineStart; i < lineEnd; i++) {
      if (text[i] == quote) {
        // Skip escaped quotes (simple check for backslash before)
        if (i > lineStart && text[i - 1] == '\\') continue;
        quotePositions.add(i);
      }
    }

    // Find pair that contains offset
    for (int i = 0; i < quotePositions.length - 1; i += 2) {
      final open = quotePositions[i];
      final close = quotePositions[i + 1];
      if (offset >= open && offset <= close) {
        return (open, close);
      }
    }

    // If cursor is on a quote, try to use it as start or end
    if (quotePositions.contains(offset)) {
      final idx = quotePositions.indexOf(offset);
      if (idx % 2 == 0 && idx + 1 < quotePositions.length) {
        // Cursor on opening quote
        return (quotePositions[idx], quotePositions[idx + 1]);
      } else if (idx % 2 == 1) {
        // Cursor on closing quote
        return (quotePositions[idx - 1], quotePositions[idx]);
      }
    }

    return (-1, -1);
  }

  /// Word character check (same as vim: letters, digits, underscore)
  bool isWordChar(String char) {
    final c = char.codeUnitAt(0);
    return (c >= 0x41 && c <= 0x5A) || // A-Z
        (c >= 0x61 && c <= 0x7A) || // a-z
        (c >= 0x30 && c <= 0x39) || // 0-9
        c == 0x5F; // _
  }

  /// Whitespace check
  bool isWhitespace(String char) {
    return char == ' ' || char == '\t';
  }
}
