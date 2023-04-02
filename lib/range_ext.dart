import 'range.dart';

extension RangeExt on Range {
  Range normalized() {
    Range r = Range.from(this);
    if (r.p0.y > r.p1.y) {
      final tmp = r.p0;
      r.p0 = r.p1;
      r.p1 = tmp;
    } else if (r.p0.y == r.p1.y && r.p0.x > r.p1.x) {
      final tmp = r.p0.x;
      r.p0.x = r.p1.x;
      r.p1.x = tmp;
    }
    return r;
  }

// check if line is inside range
  bool lineInside(int line) {
    return line > p0.y && line < p1.y;
  }
}
