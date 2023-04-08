import 'dart:io';

// This script parses the emoji-data.txt file from the Unicode Consortium
// and outputs a list of code points that are emoji.
//
// We support all emoji in the Emoji 1.0 spec, plus all emoji in the latest spec.
//
// The emoji-data.txt files can be downloaded from:
// https://unicode.org/Public/UCD/latest/ucd/emoji/emoji-data.txt
// https://unicode.org/Public/emoji/1.0/emoji-data.txt
int main(List<String> args) {
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

  final emojiCodePoints = <int>[];
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

    // Unicode 15.0 has a range of code points for emoji
    if (value.contains('..')) {
      final codePoints = value.split('..');
      final codePoint = int.parse(codePoints.first, radix: 16);
      emojiCodePoints.add(codePoint);
      if (codePoints.length > 1) {
        final endCodePoint = int.parse(codePoints.last, radix: 16);
        for (var i = codePoint + 1; i <= endCodePoint; i++) {
          emojiCodePoints.add(i);
        }
      }
    } else {
      // Unicode 1.0 has a single code point for emoji
      final codePoints = value.split(' ');
      final codePoint = int.parse(codePoints.first, radix: 16);
      emojiCodePoints.add(codePoint);
    }
  }
  // write out the code points as a list of ints in hex
  final sb = StringBuffer();
  sb.write('const emojiCodePoints = <int>[');
  for (var i = 0; i < emojiCodePoints.length; i++) {
    if (i % 10 == 0) {
      sb.write('\n  ');
    }
    sb.write('0x${emojiCodePoints[i].toRadixString(16).padLeft(4, '0')}, ');
  }
  sb.write('];');
  print(sb.toString());
  print('DONE!');
  return 0;
}
