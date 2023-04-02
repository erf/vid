import 'range.dart';

extension RangeExt on Range {
  Range normalized() {
    Range r = Range.from(this);
    if (r.p0.line > r.p1.line) {
      final tmp = r.p0;
      r.p0 = r.p1;
      r.p1 = tmp;
    } else if (r.p0.line == r.p1.line && r.p0.char > r.p1.char) {
      final tmp = r.p0.char;
      r.p0.char = r.p1.char;
      r.p1.char = tmp;
    }
    return r;
  }
}
