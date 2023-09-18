import 'dart:math';

class IntRange {
  final int low, high;
  const IntRange(this.low, this.high);

  @override
  String toString() {
    return '($low, $high)';
  }
}

class RangeList extends Iterable<IntRange> {
  final List<IntRange> ranges;

  // Default constructor takes the list as-is
  const RangeList(this.ranges);

  // Factory constructor to return a merged version of the list
  factory RangeList.merged(List<IntRange> inputRanges) =>
      RangeList(_mergeRanges(inputRanges));

  get length => ranges.length;

  static List<IntRange> _mergeRanges(List<IntRange> inputRanges) {
    if (inputRanges.isEmpty) return [];

    final List<IntRange> sortedRanges = [...inputRanges]
      ..sort((a, b) => a.low.compareTo(b.low));

    final List<IntRange> merged = [sortedRanges.first];

    for (int i = 1; i < sortedRanges.length; i++) {
      final IntRange currentRange = sortedRanges[i];
      final IntRange lastMergedRange = merged.last;

      if (currentRange.low <= lastMergedRange.high) {
        merged[merged.length - 1] = IntRange(
          lastMergedRange.low,
          max(lastMergedRange.high, currentRange.high),
        );
      } else {
        merged.add(currentRange);
      }
    }

    return merged;
  }

  @override
  bool contains(Object? obj) {
    final value = obj as int;
    if (ranges.isEmpty) return false;

    // Check against the overall range first
    if (value < ranges.first.low || value > ranges.last.high) {
      return false;
    }

    int start = 0, end = ranges.length - 1;

    while (start <= end) {
      int mid = start + (end - start) ~/ 2;
      if (ranges[mid].low <= value && ranges[mid].high >= value) {
        return true;
      }
      if (ranges[mid].low > value) {
        end = mid - 1;
      } else {
        start = mid + 1;
      }
    }
    return false;
  }

  @override
  Iterator<IntRange> get iterator {
    return ranges.iterator;
  }
}
