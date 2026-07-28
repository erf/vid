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
  /// [offset] Current string index (UTF-16 code unit index into [FileBuffer.text])
  /// Returns the new string index (cursor position)
  int call(Editor e, FileBuffer f, int offset);

  /// Sentinel value for desiredColumn meaning "end of line".
  static const int endOfLineColumn = 0x7FFFFFFF;

  /// Find the first match at or after the given offset.
  ///
  /// Scanning starts at `offset + skip`, so a match merely *containing*
  /// [offset] (starting before it) is never seen — this is the opposite
  /// of [regexPrev], which lands on the enclosing match's start.
  ///
  /// If the first match starts exactly at [offset], its *end* is returned
  /// (moving off the current match). Otherwise the match start is returned.
  /// Returns [offset] unchanged if no match is found (no-op motion).
  ///
  /// Note: patterns that can match empty (e.g. `x*`) will match at every
  /// position, making this a no-op (unlike [regexPrev], which steps back
  /// one char at a time).
  ///
  /// [offset] is a Dart string index (UTF-16 code unit index), matching
  /// how [FileBuffer.text] is indexed. [skip] must be >= 0.
  int regexNext(FileBuffer f, int offset, RegExp pattern, {int skip = 0}) {
    final matches = pattern.allMatches(f.text, offset + skip);
    if (matches.isEmpty) return offset;
    final m = matches.firstWhere(
      (ma) => ma.start > offset,
      orElse: () => matches.first,
    );
    return m.start == offset ? m.end : m.start;
  }

  /// Find the first match before the given offset.
  ///
  /// Searches back in chunks of [chunkSize] until a match is found or the
  /// start of the file is reached. Returns [offset] unchanged if no match
  /// is found (making the motion a no-op).
  ///
  /// If the cursor is *inside* a match (match starts before [offset] but
  /// ends after it), that match's start is returned. Callers that need
  /// "previous fully completed match" semantics should use
  /// [RegExpExt.allMatchesEndingBefore] instead.
  ///
  /// Note: patterns that can match empty (e.g. `x*`) will match at every
  /// position, causing the motion to step back one char at a time.
  ///
  /// [offset] is a Dart string index (UTF-16 code unit index), matching
  /// how [FileBuffer.text] is indexed.
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
  ///
  /// If the cursor is not on a word, returns the start of the next word
  /// after [offset]. If the cursor is on a word, finds the next (or
  /// previous) occurrence of that exact word.
  ///
  /// Note: matching is a plain substring search without word boundaries,
  /// so a word like `cat` also matches inside `concat` (unlike vim's `*`,
  /// which uses `\<word\>` boundaries).
  ///
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
