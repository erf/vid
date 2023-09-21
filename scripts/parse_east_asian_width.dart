import 'dart:io';

import 'package:vid/range_list.dart';

// Parse EastAsianWidth code point ranges of type 'W' and 'F' from
// https://www.unicode.org/Public/15.0.0/ucd/EastAsianWidth.txt
int main(List<String> args) {
  // validate
  if (args.isEmpty) {
    print(
        'Usage: dart parse_east_asian_width.dart <path to EastAsianWidth.txt>');
    return 1;
  }
  String path = args.first;
  if (Uri.tryParse(path) == null) {
    print('Invalid path: $path');
    return 1;
  }
  File file = File(path);
  if (!file.path.endsWith('EastAsianWidth.txt')) {
    print('File must be named EastAsianWidth.txt');
    return 1;
  }
  List<String> lines;
  try {
    lines = file.readAsLinesSync();
  } catch (e) {
    print('Error reading file: $e');
    return 1;
  }

  // parse
  List<IntRange> ranges = [];
  for (final String line in lines) {
    if (line.isEmpty) {
      continue;
    }
    if (line.startsWith('#')) {
      continue;
    }
    List<String> parts = line.split(';');
    if (parts.length < 2) {
      continue;
    }
    String property = parts[1][0];

    if (property != 'W' && property != 'F') {
      continue;
    }
    String codePointRange = parts[0].trim();

    // Unicode 15.0 can have a range of code points
    if (codePointRange.contains('..')) {
      List<String> rangeParts = codePointRange.split('..');
      int start = int.parse(rangeParts.first, radix: 16);
      int end = int.parse(rangeParts.last, radix: 16);
      ranges.add(IntRange(start, end));
    } else {
      final value = int.parse(codePointRange, radix: 16);
      ranges.add(IntRange(value, value));
    }
  }
  // print eastAsianWidth as a comma separated list
  final rangeList = RangeList.merged(ranges);
  print('final eastAsianWidth = RangeList.merged([');
  for (final IntRange range in rangeList.ranges) {
    print('  ${range.toString()},');
  }
  print(']);');
  // print length
  print('final eastAsianWidthLength = ${rangeList.length};');
  return 0;
}
