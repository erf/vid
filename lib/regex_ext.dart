import 'dart:math';

/// Extension on [RegExp] for range-limited matching.
extension RegExpExt on RegExp {
  /// Returns all non-overlapping matches within the given range.
  ///
  /// Uses [start] as the starting string index (default 0).
  /// If [end] is provided, only matches starting before [end] are included.
  /// Uses `takeWhile` for efficient early termination.
  Iterable<RegExpMatch> allMatchesInRange(
    String text, {
    int start = 0,
    int? end,
  }) {
    final matches = allMatches(text, start);
    if (end == null) return matches;
    return matches.takeWhile((m) => m.start < end);
  }

  /// Returns all matches ending before or at [endBefore].
  ///
  /// Uses [start] as the starting string index (default 0).
  /// If [endBefore] is provided, only matches with `m.end <= endBefore` are included.
  /// Useful for backward search where we need matches that fully complete before a position.
  Iterable<RegExpMatch> allMatchesEndingBefore(
    String text, {
    int start = 0,
    int? endBefore,
  }) {
    final matches = allMatches(text, start);
    if (endBefore == null) return matches;
    return matches.takeWhile((m) => m.end <= endBefore);
  }

  /// Find the first match at or after the given offset.
  ///
  /// If a match starts exactly at [offset], its *end* is returned (moving
  /// off the current match); otherwise the next match's start is returned.
  /// Matches that merely *contain* [offset] are not seen — scanning starts
  /// at `offset + skip`.
  ///
  /// Returns [offset] unchanged if no match is found. [skip] must be >= 0.
  int nextMatch(String text, int offset, {int skip = 0}) {
    final matches = allMatches(text, offset + skip);
    if (matches.isEmpty) return offset;
    final m = matches.firstWhere(
      (ma) => ma.start > offset,
      orElse: () => matches.first,
    );
    return m.start == offset ? m.end : m.start;
  }

  /// Find the last match before the given offset.
  ///
  /// If [offset] is *inside* a match (starts before it, ends after it),
  /// that match's start is returned. For "previous fully completed match"
  /// semantics, use [allMatchesEndingBefore] instead.
  ///
  /// Returns [offset] unchanged if no match is found. Searches back in
  /// chunks of [chunkSize] for efficiency.
  int prevMatch(String text, int offset, {int chunkSize = 1000}) {
    int searchStart = max(0, offset - chunkSize);

    while (true) {
      final matches = allMatchesInRange(text, start: searchStart, end: offset);
      final lastMatch = matches.lastOrNull;
      if (lastMatch != null) return lastMatch.start;

      // No match found - expand search or give up
      if (searchStart == 0) return offset;
      searchStart = max(0, searchStart - chunkSize);
    }
  }
}
