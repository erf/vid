/// Extension on [RegExp] for range-limited matching.
extension RegExpExt on RegExp {
  /// Returns all non-overlapping matches within the given range.
  ///
  /// Uses [start] as the starting byte offset (default 0).
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
  /// Uses [start] as the starting byte offset (default 0).
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
}
