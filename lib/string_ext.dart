import 'package:characters/characters.dart';

import 'config.dart';
import 'grapheme/unicode.dart';

extension StringExt on String {
  // Shorthand for characters (Characters(this))
  Characters get ch => characters;

  // generate a string of spaces the same length as the tab width
  static String tabSpaces = List.generate(Config.tabWidth, (_) => ' ').join();

  // replace all tabs with spaces
  String get tabsToSpaces => replaceAll('\t', tabSpaces);

  // Try to determine the rendered width of a single character
  int get charWidth => Unicode.charWidth(this);
}
