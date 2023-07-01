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

  final emojis = <String>[];
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

    // Unicode 15.0 document can have a range of code points
    if (value.contains('..')) {
      final List<String> codePoints = value.split('..');
      final int codePointFirst = int.parse(codePoints.first, radix: 16);
      emojis.add(String.fromCharCode(codePointFirst));
      if (codePoints.length > 1) {
        final int codePointLast = int.parse(codePoints.last, radix: 16);
        for (int i = codePointFirst + 1; i <= codePointLast; i++) {
          emojis.add(String.fromCharCode(i));
        }
      }
    } else {
      final List<int> codePoints =
          value.split(' ').map((e) => int.parse(e, radix: 16)).toList();
      if (codePoints.length == 1) {
        emojis.add(String.fromCharCode(codePoints.first));
      } else {
        emojis.add(String.fromCharCodes(codePoints));
      }
    }
  }
  // print emojis as a comma separated list
  final sb = StringBuffer();
  for (var i = 0; i < emojis.length; i++) {
    sb.write('\'${emojis[i]}\', ');
  }
  print(sb.toString());
  return 0;
}
