import 'package:characters/characters.dart';

import 'config.dart';
import 'emoji.dart';
import 'int_ext.dart';

extension StringExt on String {
  // Shorthand for characters (Characters(this))
  Characters get ch => characters;

  // Shorthand for Emoji checking a String
  bool get isEmoji => Emoji.isEmoji(this);

  // Try to determine the rendered width of a single character
  int get renderWidth {
    // if the string is empty, return 0
    if (isEmpty) {
      return 0;
    }

    // if the string is a single space, return 1
    if (this == ' ') {
      return 1;
    }

    // if the string is a single tab, return 4 ?
    if ('\t'.contains(this)) {
      return Config.tabWidth;
    }

    // If the string is a emoji, return 2
    if (isEmoji) {
      return 2;
    }

    return 1;
  }

  // Print out some info about a string (for testing)
  void info() {
    print(this);
    print('length $length');
    print('codeUnits.length ${codeUnits.length}');
    print('codeUnits ${codeUnits.map((e) => e.hex).join(' ')}');
    print('runes.length ${runes.length}');
    print('runes ${runes.map((e) => e.hex).join(' ')}');
    print('renderWidth $renderWidth');
  }
}
