import 'range.dart';

extension RangeExt on Range {
  // make sure start is before end
  Range normalized() {
    if (start.l < end.l) {
      return clone;
    }
    if (start.l == end.l && start.c <= end.c) {
      return clone;
    }
    return Range(start: end.clone, end: start.clone);
  }
}
