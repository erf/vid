import 'package:characters/characters.dart';
import 'package:vid/keys.dart';

import 'grapheme/unicode.dart';

extension StringExt on String {
  // Shorthand for characters (Characters(this))
  Characters get ch => characters;

  // generate a string of spaces the same length as the tab width
  String tabSpaces(int tabWidth) => List.generate(tabWidth, (_) => ' ').join();

  // replace all tabs with spaces
  String tabsToSpaces(int tabWidth) =>
      replaceAll(Keys.tab, tabSpaces(tabWidth));

  // Try to determine the rendered width of a single character
  int charWidth(int tabWidth) => Unicode.charWidth(this, tabWidth: tabWidth);
}
