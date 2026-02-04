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
    return allMatches(
      text,
      start,
    ).takeWhile((m) => end == null || m.start < end);
  }
}
