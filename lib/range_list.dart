import 'dart:math';

class Range {
  int low, high;
  Range(this.low, this.high);
}

class RangeList {
  List<Range> ranges;

  RangeList(this.ranges);

  int get length => ranges.length;

  // Sort the ranges based on their 'low' values
  void sort() {
    ranges.sort((a, b) => a.low.compareTo(b.low));
  }

  // Merge overlapping ranges
  void merge() {
    if (ranges.isEmpty) return;

    List<Range> merged = [];
    merged.add(ranges[0]);

    for (int i = 1; i < ranges.length; i++) {
      var currentRange = ranges[i];
      var lastMergedRange = merged.last;

      if (currentRange.low <= lastMergedRange.high) {
        // Overlapping or adjacent ranges, so merge them
        lastMergedRange.high = max(lastMergedRange.high, currentRange.high);
      } else {
        merged.add(currentRange);
      }
    }

    ranges = merged;
  }

  // Check if a value is in any of the ranges
  bool contains(int value) {
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

// void main() {
//   var ranges = RangeList([Range(10, 15), Range(1, 4), Range(4, 8)]);

//   ranges.sort();
//   ranges.merge();

//   print(ranges.contains(3)); // true (because 3 is in the merged range [1,8])
//   print(ranges.contains(6)); // true (because 6 is in the merged range [1,8])
//   print(ranges.contains(9)); // false (no range contains 9)
// }
