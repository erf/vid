import 'package:test/test.dart';
import 'package:vid/position.dart';
import 'package:vid/range.dart';

void main() {
  test('Range.normalized range is ahead', () {
    final rNormalized = Range(
      start: Position(l: 1, c: 1),
      end: Position(l: 0, c: 0),
    ).normalized();
    final rExpected = Range(
      start: Position(l: 0, c: 0),
      end: Position(l: 1, c: 1),
    );
    expect(rNormalized.start, rExpected.start);
    expect(rNormalized.end, rExpected.end);
  });

  test('Range.normalized range is behind', () {
    final rNormalized = Range(
      start: Position(l: 0, c: 0),
      end: Position(l: 1, c: 1),
    ).normalized();
    final rExpected = Range(
      start: Position(l: 0, c: 0),
      end: Position(l: 1, c: 1),
    );
    expect(rNormalized.start, rExpected.start);
    expect(rNormalized.end, rExpected.end);
  });

  test('Range.normalized range is on same line but ahead', () {
    final rNormalized = Range(
      start: Position(l: 0, c: 1),
      end: Position(l: 0, c: 0),
    ).normalized();
    final rExpected = Range(
      start: Position(l: 0, c: 0),
      end: Position(l: 0, c: 1),
    );
    expect(rNormalized.start, rExpected.start);
    expect(rNormalized.end, rExpected.end);
  });

  test('Range.normalized range is on same line and behind', () {
    final rNormalized = Range(
      start: Position(l: 1, c: 0),
      end: Position(l: 1, c: 1),
    ).normalized();
    final rExpected = Range(
      start: Position(l: 1, c: 0),
      end: Position(l: 1, c: 1),
    );
    expect(rNormalized.start, rExpected.start);
    expect(rNormalized.end, rExpected.end);
  });

  test('Range.normalized range is the same', () {
    final rNormalized = Range(
      start: Position(l: 1, c: 1),
      end: Position(l: 1, c: 1),
    ).normalized();
    final rExpected = Range(
      start: Position(l: 1, c: 1),
      end: Position(l: 1, c: 1),
    );
    expect(rNormalized.start, rExpected.start);
    expect(rNormalized.end, rExpected.end);
  });
}
