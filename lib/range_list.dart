import 'dart:math';

class IntRange {
  final int low, high;

  const IntRange(this.low, this.high);

  factory IntRange.single(int value) {
    return IntRange(value, value);
  }

  @override
  String toString() => ('IntRange($low, $high)');
}

class RangeList {
  final List<IntRange> ranges;

  // Constructor from a list of ranges
  const RangeList(this.ranges);

  // Factory constructor from an iterable of ranges
  factory RangeList.from(Iterable<IntRange> inputRanges) {
    return RangeList(inputRanges.toList(growable: false));
  }

  // Factory constructor merges the ranges
  factory RangeList.merged(Iterable<IntRange> inputRanges) {
    return RangeList(_mergeRanges(inputRanges));
  }

  static List<IntRange> _mergeRanges(Iterable<IntRange> inputRanges) {
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

  // Returns true if the value is contained in any of the ranges
  bool contains(int value) {
    if (ranges.isEmpty) {
      return false;
    }

    // Check against the overall range first
    if (value < ranges.first.low || value > ranges.last.high) {
      return false;
    }

    int start = 0, end = ranges.length - 1;

    while (start <= end) {
      final int mid = start + (end - start) ~/ 2;
      final IntRange range = ranges[mid];
      if (range.low <= value && range.high >= value) {
        return true;
      }
      if (range.low > value) {
        end = mid - 1;
      } else {
        start = mid + 1;
      }
    }
    return false;
  }

  get length => ranges.length;
}
