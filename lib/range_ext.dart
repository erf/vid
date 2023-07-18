import 'range.dart';

extension RangeExt on Range {
  // make the range in correct order from top to bottom
  Range normalized() {
    Range r = Range.from(this);
    if (r.start.l > r.end.l) {
      final tmp = r.start;
      r.start = r.end;
      r.end = tmp;
    } else if (r.start.l == r.end.l && r.start.c > r.end.c) {
      final tmp = r.start.c;
      r.start.c = r.end.c;
      r.end.c = tmp;
    }
    return r;
  }
}
