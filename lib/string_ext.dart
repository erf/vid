import 'package:characters/characters.dart';
import 'package:vid/keys.dart';

import 'grapheme/unicode.dart';

extension StringExt on String {
  // Shorthand for characters (Characters(this))
  Characters get ch => characters;

  // replace all tabs with spaces
  String tabsToSpaces(int tabWidth) => replaceAll(Keys.tab, ' ' * tabWidth);

  // Try to determine the rendered width of a single character/grapheme
  int charWidth([int tabWidth = 1]) =>
      Unicode.charWidth(this, tabWidth: tabWidth);

  /// Get the rendered width of this string (sum of all grapheme widths).
  /// For simple ASCII, this equals string length.
  /// For unicode with wide chars (CJK, emoji), this accounts for double-width.
  /// Use [tabWidth] if string may contain tabs (default 1).
  int renderLength([int tabWidth = 1]) {
    // Fast path: for simple ASCII (no tabs, no unicode), render width == length
    if (Unicode.isSimpleAscii(this)) return length;
    return characters.fold(0, (prev, curr) => prev + curr.charWidth(tabWidth));
  }

  /// Get the visible portion of this string for the given viewport.
  /// [start] is the horizontal scroll offset (render width to skip).
  /// [width] is the viewport width (max render width to show).
  /// Assumes tabs are already converted to spaces.
  String renderLine(int start, int width) {
    return renderLineStart(start).renderLineEnd(width);
  }

  /// Skip characters until [start] render width is reached.
  /// Returns the remaining string for display.
  /// If a double-width char is split, a space is prepended.
  String renderLineStart(int start) {
    // Fast path: for simple ASCII, render width == string length
    if (Unicode.isSimpleAscii(this)) {
      if (start >= length) return '';
      return substring(start);
    }

    int total = 0;
    bool space = false;
    final line = characters.skipWhile((char) {
      int charWidth = char.charWidth();
      total += charWidth;
      // add a space to the beginning of the line if the first character is a
      // double width character and start is 1 then
      if (charWidth == 2) {
        if (total - 1 == start) {
          space = true;
        }
        return total - 1 <= start;
      }
      return total <= start;
    });
    return space ? ' ${line.string}' : line.string;
  }

  /// Take characters until [width] render width is reached.
  /// Returns the visible portion of the string.
  String renderLineEnd(int width) {
    // Fast path: for simple ASCII, render width == string length
    if (Unicode.isSimpleAscii(this)) {
      if (width >= length) return this;
      return substring(0, width);
    }

    int total = 0;
    return characters.takeWhile((char) {
      total += char.charWidth();
      return total <= width;
    }).string;
  }
}
