import 'dart:math';

import 'package:characters/characters.dart';
import 'package:vid/editor.dart';
import 'package:vid/file_buffer/file_buffer.dart';
import 'package:vid/regex.dart';
import 'package:vid/regex_ext.dart';
import 'package:vid/string_ext.dart';

/// Base class for motion actions.
///
/// Motions calculate a new cursor position from the current offset.
/// Implement [call] to define the motion behavior.
///
/// All motion actions should be const-constructible for zero allocation.
abstract class MotionAction {
  const MotionAction();

  /// Execute the motion.
  ///
  /// [e] Editor instance
  /// [f] FileBuffer instance
  /// [offset] Current byte offset
  /// Returns the new byte offset (cursor position)
  int call(Editor e, FileBuffer f, int offset);

  /// Sentinel value for desiredColumn meaning "end of line".
  static const int endOfLineColumn = 0x7FFFFFFF;

  // ===== Utility methods for motion implementations =====

  /// Compute the visual column for the cursor at the given offset.
  int computeVisualColumn(Editor e, FileBuffer f, int offset, int currentLine) {
    int lineStartOff = f.lines[currentLine].start;
    String beforeCursor = f.text.substring(lineStartOff, offset);
    return beforeCursor.renderLength(e.config.tabWidth);
  }

  /// Move to a specific visual column on the target line.
  /// Returns the byte offset of the resulting cursor position.
  int moveToLineWithColumn(
    Editor e,
    FileBuffer f,
    int targetLine,
    int targetCol,
  ) {
    int targetLineStart = f.lines[targetLine].start;
    int targetLineEnd = f.lines[targetLine].end;
    String targetLineText = f.text.substring(targetLineStart, targetLineEnd);

    // Find position in target line with similar visual column
    int nextlen = 0;
    Characters chars = targetLineText.characters.takeWhile((c) {
      nextlen += c.charWidth(e.config.tabWidth);
      return nextlen <= targetCol;
    });

    // Clamp to valid position in target line
    int targetCharLen = targetLineText.characters.length;
    int charIndex = chars.length.clamp(0, max<int>(0, targetCharLen));

    // Convert char index to byte offset
    return targetLineStart +
        targetLineText.characters.take(charIndex).string.length;
  }

  /// Move to a different line, maintaining approximate visual column position.
  /// Legacy helper that computes column from offset (used when sticky column disabled).
  int moveToLineKeepColumn(
    Editor e,
    FileBuffer f,
    int offset,
    int currentLine,
    int targetLine,
  ) {
    int curVisualCol = computeVisualColumn(e, f, offset, currentLine);
    return moveToLineWithColumn(e, f, targetLine, curVisualCol);
  }

  /// Find the first match after the given byte offset.
  int regexNext(FileBuffer f, int offset, RegExp pattern, {int skip = 0}) {
    final matches = pattern.allMatches(f.text, offset + skip);
    if (matches.isEmpty) return offset;
    final m = matches.firstWhere(
      (ma) => ma.start > offset,
      orElse: () => matches.first,
    );
    return m.start == offset ? m.end : m.start;
  }

  /// Find the first match before the given byte offset.
  /// Searches back in chunks of [chunkSize] until a match is found or start of file.
  int regexPrev(
    FileBuffer f,
    int offset,
    RegExp pattern, {
    int chunkSize = 1000,
  }) {
    int searchStart = max(0, offset - chunkSize);

    while (true) {
      final matches = pattern.allMatchesInRange(
        f.text,
        start: searchStart,
        end: offset,
      );
      final lastMatch = matches.lastOrNull;
      if (lastMatch != null) return lastMatch.start;

      // No match found - expand search or give up
      if (searchStart == 0) return offset;
      searchStart = max(0, searchStart - chunkSize);
    }
  }

  /// Find next/prev occurrence of the word under cursor.
  /// Returns (destinationOffset, matchedWord) or null if no word found.
  (int, String)? matchCursorWord(
    FileBuffer f,
    int offset, {
    required bool forward,
    int chunkSize = 1000,
  }) {
    // Find word containing cursor - search backwards in chunks
    int searchStart = max(0, offset - chunkSize);

    while (true) {
      final matches = Regex.word.allMatches(f.text, searchStart);
      Match? match;
      for (final m in matches) {
        if (offset < m.end) {
          match = m;
          break;
        }
      }

      if (match != null) {
        // We are not on the word
        if (offset < match.start || offset >= match.end) {
          final wordToMatch = f.text.substring(match.start, match.end);
          return (match.start, wordToMatch);
        }
        // We are on the word - find the next/prev same word
        final wordToMatch = f.text.substring(match.start, match.end);
        final pattern = RegExp(RegExp.escape(wordToMatch));
        final int index = forward
            ? f.text.indexOf(pattern, match.end)
            : f.text.lastIndexOf(pattern, max(0, match.start - 1));
        return (index == -1 ? match.start : index, wordToMatch);
      }

      // No match found - expand search or give up
      if (searchStart == 0) return null;
      searchStart = max(0, searchStart - chunkSize);
    }
  }
}
