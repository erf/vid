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
  /// [scrollOffset] is the number of columns to skip (horizontal scroll).
  /// [viewportWidth] is the maximum columns to display.
  /// Assumes tabs are already converted to spaces.
  String renderLine(int scrollOffset, int viewportWidth) {
    return renderLineStart(scrollOffset).renderLineEnd(viewportWidth);
  }

  /// Skip characters until [scrollOffset] render width is reached.
  /// Returns the remaining string for display.
  /// If a double-width char is split, a space is prepended.
  String renderLineStart(int scrollOffset) {
    if (scrollOffset <= 0) return this;

    // Fast path: for simple ASCII, render width == string length
    if (Unicode.isSimpleAscii(this)) {
      return scrollOffset >= length ? '' : substring(scrollOffset);
    }

    int col = 0;
    int skipCount = 0;
    bool needSpace = false;

    for (final char in characters) {
      final w = char.charWidth();
      if (col + w > scrollOffset) {
        // This char crosses the scroll boundary
        needSpace = (col < scrollOffset); // Split if char starts before offset
        break;
      }
      col += w;
      skipCount++;
    }

    final remaining = characters.skip(skipCount + (needSpace ? 1 : 0)).string;
    return needSpace ? ' $remaining' : remaining;
  }

  /// Take characters until [viewportWidth] render width is reached.
  /// Returns the visible portion of the string.
  String renderLineEnd(int viewportWidth) {
    // Fast path: for simple ASCII, render width == string length
    if (Unicode.isSimpleAscii(this)) {
      if (viewportWidth >= length) return this;
      return substring(0, viewportWidth);
    }

    int total = 0;
    return characters.takeWhile((char) {
      total += char.charWidth();
      return total <= viewportWidth;
    }).string;
  }
}
