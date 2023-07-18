import 'package:test/test.dart';
import 'package:vid/position.dart';
import 'package:vid/range.dart';
import 'package:vid/range_ext.dart';

void main() {
  test('Range.normalized', () {
    final rNorm = Range(
      start: Position(c: 1, l: 1),
      end: Position(c: 0, l: 0),
    ).normalized();

    final expected = Range(
      start: Position(c: 0, l: 0),
      end: Position(c: 1, l: 1),
    );

    expect(rNorm.start, expected.start);
    expect(rNorm.end, expected.end);
  });
}
