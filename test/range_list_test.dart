import 'package:test/test.dart';
import 'package:vid/range_list.dart';

void main() {
  group('RangeList', () {
    test('should find values inside the ranges', () {
      final l = RangeList([IntRange(1, 4), IntRange(5, 8), IntRange(10, 15)]);
      expect(l.contains(1), true);
      expect(l.contains(3), true);
      expect(l.contains(5), true);
      expect(l.contains(10), true);
      expect(l.contains(15), true);
      expect(l.length, 3);
    });

    test('should not find values outside the ranges', () {
      final l = RangeList([IntRange(1, 4), IntRange(5, 8), IntRange(10, 15)]);
      expect(l.contains(0), false);
      expect(l.contains(9), false);
      expect(l.contains(16), false);
    });

    test('should merge overlapping or adjacent ranges', () {
      final l =
          RangeList.merged([IntRange(10, 15), IntRange(1, 4), IntRange(4, 8)]);
      expect(l.contains(3), true);
      expect(l.contains(7), true);
      expect(l.length, 2);
    });

    test('should handle an empty list', () {
      final l = RangeList([]);
      expect(l.contains(1), false);
    });
  });
}
