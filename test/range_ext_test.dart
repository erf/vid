import 'package:test/test.dart';
import 'package:vid/position.dart';
import 'package:vid/range.dart';

void main() {
  test('Range.norm range is ahead', () {
    final r = Range(Position(l: 1, c: 1), Position(l: 0, c: 0)).norm;
    final expected = Range(Position(l: 0, c: 0), Position(l: 1, c: 1));
    expect(r.start, expected.start);
    expect(r.end, expected.end);
  });

  test('Range.norm range is behind', () {
    final r = Range(Position(l: 0, c: 0), Position(l: 1, c: 1)).norm;
    final expected = Range(Position(l: 0, c: 0), Position(l: 1, c: 1));
    expect(r.start, expected.start);
    expect(r.end, expected.end);
  });

  test('Range.norm range is on same line but ahead', () {
    final r = Range(Position(l: 0, c: 1), Position(l: 0, c: 0)).norm;
    final expected = Range(Position(l: 0, c: 0), Position(l: 0, c: 1));
    expect(r.start, expected.start);
    expect(r.end, expected.end);
  });

  test('Range.norm range is on same line and behind', () {
    final r = Range(Position(l: 1, c: 0), Position(l: 1, c: 1)).norm;
    final expected = Range(Position(l: 1, c: 0), Position(l: 1, c: 1));
    expect(r.start, expected.start);
    expect(r.end, expected.end);
  });

  test('Range.norm range is the same', () {
    final r = Range(Position(l: 1, c: 1), Position(l: 1, c: 1)).norm;
    final expected = Range(Position(l: 1, c: 1), Position(l: 1, c: 1));
    expect(r.start, expected.start);
    expect(r.end, expected.end);
  });
}
