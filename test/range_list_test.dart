import 'package:test/test.dart';
import 'package:vid/range_list.dart';

void main() {
  group('RangeList', () {
    test('should find values inside the ranges', () {
      var rList = RangeList([Range(1, 4), Range(5, 8), Range(10, 15)]);
      expect(rList.contains(1), true);
      expect(rList.contains(3), true);
      expect(rList.contains(5), true);
      expect(rList.contains(10), true);
      expect(rList.contains(15), true);
      expect(rList.length, 3);
    });

    test('should not find values outside the ranges', () {
      var rList = RangeList([Range(1, 4), Range(5, 8), Range(10, 15)]);
      expect(rList.contains(0), false);
      expect(rList.contains(9), false);
      expect(rList.contains(16), false);
    });

    test('should merge overlapping or adjacent ranges', () {
      var rList = RangeList([Range(10, 15), Range(1, 4), Range(4, 8)]);
      rList.sort();
      rList.merge();
      expect(rList.contains(3), true);
      expect(rList.contains(7), true);
      expect(rList.length, 2);
    });

    test('should handle an empty list', () {
      var rList = RangeList([]);
      expect(rList.contains(1), false);
    });
  });
}
