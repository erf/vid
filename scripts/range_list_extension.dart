import 'package:vid/range_list.dart';

extension RangeListWrite on RangeList {
  void write(StringBuffer buffer, String variableName) {
    buffer.writeln('import \'range_list.dart\';');
    buffer.writeln();
    buffer.writeln('const $variableName = RangeList([');
    for (IntRange range in ranges) {
      buffer.writeln('  $range,');
    }
    buffer.writeln(']);');
    buffer.writeln();
    buffer.writeln('// length: $length');
    print(buffer.toString());
  }
}
