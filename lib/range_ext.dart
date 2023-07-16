import 'range.dart';

extension RangeExt on Range {
  // make the range in correct order from top to bottom
  Range normalized() {
    Range r = Range.from(this);
    if (r.start.y > r.end.y) {
      final tmp = r.start;
      r.start = r.end;
      r.end = tmp;
    } else if (r.start.y == r.end.y && r.start.x > r.end.x) {
      final tmp = r.start.x;
      r.start.x = r.end.x;
      r.end.x = tmp;
    }
    return r;
  }
}
