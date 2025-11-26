import 'package:characters/characters.dart';
import 'package:vid/keys.dart';

import 'grapheme/unicode.dart';

extension StringExt on String {
  // Shorthand for characters (Characters(this))
  Characters get ch => characters;

  // replace all tabs with spaces
  String tabsToSpaces(int tabWidth) => replaceAll(Keys.tab, ' ' * tabWidth);

  // Try to determine the rendered width of a single character
  int charWidth(int tabWidth) => Unicode.charWidth(this, tabWidth: tabWidth);
}
