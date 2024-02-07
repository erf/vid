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
  factory RangeList.from(Iterable<IntRange> ranges) {
    return RangeList(ranges.toList(growable: false));
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

    // Binary search for the range containing the value
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

  // Returns the number of ranges
  get length => ranges.length;
}
