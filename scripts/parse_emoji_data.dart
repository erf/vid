import 'dart:io';

// This script parses a list of emoji code points from:
// https://unicode.org/Public/UCD/latest/ucd/emoji/emoji-data.txt
int main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart parse_emoji_data.dart <path to emoji-data.txt>');
    return 1;
  }
  final String path = args.first;
  if (Uri.tryParse(path) == null) {
    print('Invalid path: $path');
    return 1;
  }
  final file = File(path);
  if (!file.path.endsWith('emoji-data.txt')) {
    print('File must be named emoji-data.txt');
    return 1;
  }
  final List<String> lines = file.readAsLinesSync();

  final List<int> emojis = [];
  for (final String line in lines) {
    if (line.startsWith('#')) {
      continue;
    }
    final List<String> parts = line.split(';');
    if (parts.length < 2) {
      continue;
    }
    final String name = parts[1].trim();
    if (!name.contains('Emoji_Presentation') && !name.contains('emoji')) {
      continue;
    }
    final String value = parts[0].trim();

    // Unicode v15.0 can have a range of code points
    if (value.contains('..')) {
      final List<String> codePointRange = value.split('..');
      final int codePointFirst = int.parse(codePointRange.first, radix: 16);
      emojis.add(codePointFirst);
      if (codePointRange.length > 1) {
        final int codePointLast = int.parse(codePointRange.last, radix: 16);
        for (int i = codePointFirst + 1; i <= codePointLast; i++) {
          emojis.add(i);
        }
      }
    } else {
      // Unicode v1.0 can have 1 or 2 code points (15.0 has 1 here)
      final Iterable<int> codePoints =
          value.split(' ').map((e) => int.parse(e, radix: 16));
      emojis.add(codePoints.first);
    }
  }
  // print emojis as a comma separated list
  print(StringBuffer()..writeAll(emojis, ', '));
  print('Total numer of emojis: ${emojis.length}');
  return 0;
}
