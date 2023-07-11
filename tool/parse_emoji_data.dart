import 'dart:io';

// This script parses a list of emoji code points from the 'emoji-data.txt' file
// downloaded from unicode.org
// https://unicode.org/Public/UCD/latest/ucd/emoji/emoji-data.txt
// https://unicode.org/Public/emoji/1.0/emoji-data.txt
//
// The script is used to generate the list of emoji code points used in
// lib/emojis.dart
int main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart parse_emoji_data.dart <path to emoji-data.txt>');
    return 1;
  }
  final path = args.first;
  if (Uri.tryParse(path) == null) {
    print('Invalid path: $path');
    return 1;
  }
  final file = File(path);
  if (!file.path.endsWith('emoji-data.txt')) {
    print('File must be named emoji-data.txt');
    return 1;
  }
  final lines = file.readAsLinesSync();

  final emojis = <int>[];
  for (var line in lines) {
    if (line.startsWith('#')) {
      continue;
    }
    final parts = line.split(';');
    if (parts.length < 2) {
      continue;
    }
    final name = parts[1].trim();
    if (!name.contains('Emoji_Presentation') && !name.contains('emoji')) {
      continue;
    }
    final value = parts[0].trim();

    // The unicode docs > 1.0, can have a range of code points
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
      final List<int> codePoints =
          value.split(' ').map((e) => int.parse(e, radix: 16)).toList();
      emojis.add(codePoints.first);
    }
  }
  // print emojis as a comma separated list
  print(StringBuffer()..writeAll(emojis, ', '));
  print('Total numer of emojis: ${emojis.length}');
  return 0;
}
