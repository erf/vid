import 'range.dart';

extension RangeExt on Range {
  Range normalized() {
    Range r = Range.from(this);
    if (r.start.line > r.end.line) {
      final tmp = r.start;
      r.start = r.end;
      r.end = tmp;
    } else if (r.start.line == r.end.line && r.start.char > r.end.char) {
      final tmp = r.start.char;
      r.start.char = r.end.char;
      r.end.char = tmp;
    }
    return r;
  }
}
