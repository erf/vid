import 'package:test/test.dart';
import 'package:vid/range.dart';

void main() {
  test('Range.norm range is ahead', () {
    final r = Range(5, 0).norm;
    final expected = Range(0, 5);
    expect(r.start, expected.start);
    expect(r.end, expected.end);
  });

  test('Range.norm range is behind', () {
    final r = Range(0, 5).norm;
    final expected = Range(0, 5);
    expect(r.start, expected.start);
    expect(r.end, expected.end);
  });

  test('Range.norm range with same values', () {
    final r = Range(5, 5).norm;
    final expected = Range(5, 5);
    expect(r.start, expected.start);
    expect(r.end, expected.end);
  });
}
