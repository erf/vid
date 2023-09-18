import 'dart:math';

class IntRange {
  final int low, high;
  const IntRange(this.low, this.high);

  @override
  String toString() => '($low, $high)';
}

class RangeList {
  final List<IntRange> ranges;

  // Constructor does not merge the ranges
  const RangeList(this.ranges);

  // Factory constructor merges the ranges
  factory RangeList.merged(List<IntRange> inputRanges) {
    return RangeList(_mergeRanges(inputRanges));
  }

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

  get length => ranges.length;
}
