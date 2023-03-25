import 'file_buffer.dart';
import 'range.dart';

Range normalizedRange(Range range) {
  Range r = Range.from(range);
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

void deleteRange(Range range) {
  Range r = normalizedRange(range);
  if (r.p0.line == r.p1.line) {
    lines[r.p0.line] = lines[r.p0.line].replaceRange(r.p0.char, r.p1.char, '');
  } else {
    lines[r.p0.line] = lines[r.p0.line].replaceRange(r.p0.char, null, '');
    lines[r.p1.line] = lines[r.p1.line].replaceRange(0, r.p1.char, '');
    lines.removeRange(r.p0.line + 1, r.p1.line);
  }
}

String replaceCharAt(String line, int index, String char) {
  return line.replaceRange(index, index + 1, char);
}

String deleteCharAt(String line, int index) {
  return replaceCharAt(line, index, '');
}
