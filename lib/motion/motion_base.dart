import 'dart:math';

import '../editor.dart';
import '../file_buffer/file_buffer.dart';
import '../regex.dart';
import '../regex_ext.dart';

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
