import 'package:characters/characters.dart';
import 'package:termio/termio.dart';

import 'grapheme/unicode.dart';

extension StringExt on String {
  /// Shorthand for characters (Characters(this))
  Characters get ch => characters;

  /// replace all tabs with spaces
  String tabsToSpaces(int tabWidth) => replaceAll(Keys.tab, ' ' * tabWidth);

  /// Try to determine the rendered width of a single character/grapheme
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
  ///
  /// If a wide char straddles the left edge (starts before [scrollOffset]
  /// and extends past it), it is replaced by a single space. If a wide char
  /// straddles the right edge, it is dropped entirely (asymmetric with the
  /// left edge, which pads).
  ///
  /// Single-pass implementation: one ASCII scan, one grapheme segmentation,
  /// one substring allocation.
  String visibleLine(int scrollOffset, int viewportWidth) {
    // Fast path: for simple ASCII, render width == string length
    if (Unicode.isSimpleAscii(this)) {
      if (scrollOffset >= length) return '';
      final end = scrollOffset + viewportWidth;
      return end >= length
          ? substring(scrollOffset)
          : substring(scrollOffset, end);
    }

    int col = 0;
    int skipCount = 0;
    bool needSpace = false;

    // Phase 1: find start boundary
    if (scrollOffset > 0) {
      for (final char in characters) {
        final w = char.charWidth();
        if (col + w > scrollOffset) {
          // This char crosses the scroll boundary.
          // Split if char starts before offset.
          needSpace = (col < scrollOffset);
          break;
        }
        col += w;
        skipCount++;
      }
    }

    final rest = characters.skip(skipCount + (needSpace ? 1 : 0));

    // Phase 2: take chars within the width budget.
    // The padding space (if any) consumes 1 column of the budget.
    int total = needSpace ? 1 : 0;
    final taken = rest.takeWhile((char) {
      total += char.charWidth();
      return total <= viewportWidth;
    });

    return needSpace ? ' ${taken.string}' : taken.string;
  }

  /// Map a position in the rendered (tab-expanded) version of this string to
  /// a byte offset in the original string.
  int renderedToOriginalOffset(int renderedPos, int tabWidth) {
    int rendered = 0;
    int origBytes = 0;

    for (var i = 0; i < length && rendered < renderedPos; i++) {
      final c = codeUnitAt(i);
      if (c == 0x09) {
        // tab
        rendered += tabWidth;
      } else {
        rendered++;
      }
      origBytes++;
    }
    return origBytes;
  }

  /// Get the substring of this (original) string that corresponds to a
  /// rendered position and length in its tab-expanded version.
  String originalSlice(int renderedStart, int renderedLen, int tabWidth) {
    // Find start byte offset
    int rendered = 0;
    int startByte = 0;

    for (var i = 0; i < length && rendered < renderedStart; i++) {
      final c = codeUnitAt(i);
      if (c == 0x09) {
        rendered += tabWidth;
      } else {
        rendered++;
      }
      startByte++;
    }

    // Find end byte offset
    int endByte = startByte;
    int sliceRenderedLen = 0;

    for (var i = startByte; i < length && sliceRenderedLen < renderedLen; i++) {
      final c = codeUnitAt(i);
      if (c == 0x09) {
        sliceRenderedLen += tabWidth;
      } else {
        sliceRenderedLen++;
      }
      endByte++;
    }

    if (startByte >= length) return '';
    return substring(startByte, endByte.clamp(0, length));
  }
}
