import 'package:http/http.dart' as http;

import 'package:vid/range_list.dart';

// Parse latest EastAsianWidth.txt code point ranges of type 'W' and 'F'
const eawUrl = 'https://www.unicode.org/Public/UNIDATA/EastAsianWidth.txt';

void main(List<String> args) async {
  // fetch the latest EastAsianWidth code point ranges
  http.Response response = await http.get(Uri.parse(eawUrl));

  if (response.statusCode != 200) {
    print('Failed to fetch EastAsianWidth.txt');
    return;
  }
  List<String> lines = response.body.split('\n');

  // extract filename
  String filename = lines.first.substring(2);

  // parse
  Iterable<IntRange> ranges = lines
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .map((line) => line.split(';'))
      .where((fields) {
    String property = fields.last.trimLeft()[0];
    return property == 'W' || property == 'F';
  }).map((fields) {
    String codePoints = fields.first.trimRight();
    if (codePoints.contains('..')) {
      List<String> range = codePoints.split('..');
      return IntRange(
        int.parse(range.first, radix: 16),
        int.parse(range.last, radix: 16),
      );
    }
    return IntRange.single(int.parse(codePoints, radix: 16));
  });

  writeRangeList(ranges, filename);
  //writeSwitchExpression(ranges, filename);
}

void writeRangeList(Iterable<IntRange> ranges, String filename) {
  // merge ranges
  final rangeList = RangeList.merged(ranges);

  // print eastAsianWidth as a comma separated list
  final buffer = StringBuffer();

  buffer.writeln('import \'range_list.dart\';');
  buffer.writeln();
  buffer.writeln('// $filename');
  buffer.writeln('// Autogenerated from $eawUrl');
  buffer.writeln('const eastAsianWidthRangeList = RangeList([');
  buffer.writeAll(rangeList.ranges, ',\n');
  buffer.writeln(',\n]);');
  buffer.writeln();
  buffer.writeln('// length: ${rangeList.length}');

  print(buffer.toString());
}

void writeSwitchExpression(Iterable<IntRange> ranges, String filename) {
  // merge ranges
  final rangeList = RangeList.merged(ranges);

  // print eastAsianWidth as a switch expression
  final buffer = StringBuffer();

  buffer.writeln('// $filename');
  buffer.writeln('// Autogenerated from $eawUrl');
  buffer.writeln('bool eastAsianWidthSwitch(int codePoint) {');
  buffer.writeln('  switch (codePoint) {');
  for (IntRange range in rangeList.ranges) {
    if (range.low == range.high) {
      buffer.writeln('    case ${range.low}:\n      return true;');
    } else {
      buffer.writeln(
          '    case >= ${range.low} && <= ${range.high}:\n      return true;');
    }
  }
  buffer.writeln('    default: return false;');
  buffer.writeln('  }');
  buffer.writeln('}');
  buffer.writeln();
  buffer.writeln('// length: ${rangeList.length}');

  print(buffer.toString());
}
