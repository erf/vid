import 'dart:math';

class Range {
  final int low, high;
  const Range(this.low, this.high);
}

class RangeList {
  final List<Range> ranges;

  // Default constructor takes the list as-is
  const RangeList(this.ranges);

  // Factory constructor to return a merged version of the list
  factory RangeList.merged(List<Range> inputRanges) =>
      RangeList(_mergeRanges(inputRanges));

  get length => ranges.length;

  static List<Range> _mergeRanges(List<Range> inputRanges) {
    if (inputRanges.isEmpty) return [];

    final sortedRanges = [...inputRanges]
      ..sort((a, b) => a.low.compareTo(b.low));

    final merged = [sortedRanges.first];

    for (int i = 1; i < sortedRanges.length; i++) {
      final currentRange = sortedRanges[i];
      final lastMergedRange = merged.last;

      if (currentRange.low <= lastMergedRange.high) {
        merged[merged.length - 1] = Range(
            lastMergedRange.low, max(lastMergedRange.high, currentRange.high));
      } else {
        merged.add(currentRange);
      }
    }

    return merged;
  }

  bool contains(int value) {
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
}
