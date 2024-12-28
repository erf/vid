class IntRange {
  final int start;
  final int end;

  const IntRange(this.start, this.end);

  factory IntRange.single(int value) => IntRange(value, value);

  bool contains(int value) => value >= start && value <= end;

  @override
  String toString() => ('IntRange($start, $end)');
}

class RangeList {
  final List<IntRange> ranges;

  const RangeList(this.ranges);

  void addRange(IntRange range) {
    ranges.add(range);
  }

  void sortRanges() {
    ranges.sort((a, b) => a.start.compareTo(b.start));
  }

  bool contains(int value) {
    // Check if ranges is empty
    if (ranges.isEmpty) {
      return false;
    }

    // Check if the value is outside the overall range
    if (value < ranges.first.start || value > ranges.last.end) {
      return false;
    }

    // Bisection search for efficient lookups
    int low = 0, high = ranges.length - 1;
    while (low <= high) {
      int mid = (low + high) ~/ 2;
      if (ranges[mid].contains(value)) {
        return true;
      } else if (value < ranges[mid].start) {
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }
    return false;
  }

  int get length => ranges.length;
}
