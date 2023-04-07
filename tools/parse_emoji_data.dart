import 'dart:io';

// This script parses the emoji-data.txt file from the Unicode Consortium
// and outputs a list of code points that are emoji.
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
    if (!name.contains('Emoji_Presentation')) {
      continue;
    }
    final codePoints = parts[0].trim().split('..');
    final codePoint = int.parse(codePoints.first, radix: 16);
    emojiCodePoints.add(codePoint);
    if (codePoints.length > 1) {
      final endCodePoint = int.parse(codePoints.last, radix: 16);
      for (var i = codePoint + 1; i <= endCodePoint; i++) {
        emojiCodePoints.add(i);
      }
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
