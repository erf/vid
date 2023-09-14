import 'dart:io';

// Parse default emoji presentation code points from:
// https://unicode.org/Public/UCD/latest/ucd/emoji/emoji-data.txt
int main(List<String> args) {
  // validate
  if (args.isEmpty) {
    print('Usage: dart parse_emoji_data.dart <path to emoji-data.txt>');
    return 1;
  }
  String path = args.first;
  if (Uri.tryParse(path) == null) {
    print('Invalid path: $path');
    return 1;
  }
  File file = File(path);
  if (!file.path.endsWith('emoji-data.txt')) {
    print('File must be named emoji-data.txt');
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
  List<int> emojis = [];
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
    String name = parts[1].trim();
    if (!name.contains('Emoji_Presentation')) {
      continue;
    }
    String codePointRange = parts[0].trim();

    // Unicode 15.0 can have a range of code points
    if (codePointRange.contains('..')) {
      List<String> rangeParts = codePointRange.split('..');
      int start = int.parse(rangeParts.first, radix: 16);
      int end = int.parse(rangeParts.last, radix: 16);
      for (int code = start; code <= end; code++) {
        emojis.add(code);
      }
    } else {
      emojis.add(int.parse(codePointRange, radix: 16));
    }
  }
  // print emojis as a comma separated list
  print(StringBuffer()..writeAll(emojis, ', '));
  print('Total numer of emojis: ${emojis.length}');
  return 0;
}
