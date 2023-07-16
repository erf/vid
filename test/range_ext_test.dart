import 'package:test/test.dart';
import 'package:vid/position.dart';
import 'package:vid/range.dart';
import 'package:vid/range_ext.dart';

void main() {
  test('Range.normalized', () {
    final rNorm = Range(
      start: Position(x: 1, y: 1),
      end: Position(x: 0, y: 0),
    ).normalized();

    final expected = Range(
      start: Position(x: 0, y: 0),
      end: Position(x: 1, y: 1),
    );

    expect(rNorm.start, expected.start);
    expect(rNorm.end, expected.end);
  });
}
