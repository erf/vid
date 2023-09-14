import 'dart:io';

Set<int> defaultEmojiPresentation = {};

void loadDefaultEmojiPresentation(String path) {
  List<String> lines = File(path).readAsLinesSync();

  for (String line in lines) {
    if (line.contains('Emoji_Presentation') && !line.startsWith('#')) {
      List<String> parts = line.split(';');
      String codePointRange = parts[0].trim();

      if (codePointRange.contains('..')) {
        List<String> rangeParts = codePointRange.split('..');
        int start = int.parse(rangeParts[0], radix: 16);
        int end = int.parse(rangeParts[1], radix: 16);
        for (int code = start; code <= end; code++) {
          defaultEmojiPresentation.add(code);
        }
      } else {
        defaultEmojiPresentation.add(int.parse(codePointRange, radix: 16));
      }
    }
  }
}

bool shouldBeRenderedAsEmoji(String character) {
  //int codePoint = character.codeUnitAt(0);
  int codePoint = character.runes.first;
  if (defaultEmojiPresentation.contains(codePoint)) {
    return true;
  }
  if (character.length > 1 && character.codeUnitAt(1) == 0xFE0F) {
    return true;
  }
  return false;
}

void main(List<String> args) {
  //final String path = args.first;
  final path = 'data/15.0/emoji-data.txt';
  loadDefaultEmojiPresentation(path);
  print(shouldBeRenderedAsEmoji('😀')); // True
  print(shouldBeRenderedAsEmoji(
      '©️')); // True for copyright with emoji variation selector
}
