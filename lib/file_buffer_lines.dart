import 'dart:math' as math;

import 'package:characters/characters.dart';

import 'config.dart';
import 'file_buffer.dart';
import 'keys.dart';
import 'line.dart';
import 'string_ext.dart';

extension FileBufferLines on FileBuffer {
  // check if file is empty, only one line with empty string
  bool get empty => lines.length == 1 && lines.first.isEmpty;

  // split text into lines
  void createLines(WrapMode wrapMode, int width, int height) {
    // ensure that the text ends with a newline
    if (!text.endsWith(Keys.newline)) {
      text += Keys.newline;
    }

    // split text into lines (remove last empty line)
    final textLines = text.split(Keys.newline)..removeLast();

    // split text into lines with metadata used for cursor positioning etc.
    lines.clear();
    int start = 0;
    for (int i = 0; i < textLines.length; i++) {
      final String line = textLines[i];
      switch (wrapMode) {
        case WrapMode.none:
          lines.add(Line('$line ', start: start, no: i));
          start += line.length + 1;
        case WrapMode.word:
          wordWrapLine(lines, line, start, width);
          start = lines.last.end;
        case WrapMode.char:
          charWrapLine(lines, line, start, width);
          start = lines.last.end;
      }
    }
  }

  // split long line into smaller lines by word
  void wordWrapLine(List<Line> lines, String line, int start, int width) {
    // if line is empty add an empty line
    if (line.isEmpty) {
      lines.add(Line(' ', start: start, no: lines.length));
      return;
    }
    // limit small width to avoid rendering issues
    width = math.max(width, 8);

    int index = 0;
    int lineStart = 0;
    int breakIndex = -1;
    int lineWidth = 0;
    int lineWidthAtBreakIndex = 0;

    for (String char in line.characters) {
      index += char.length;

      int charWidth = char.charWidth;
      lineWidth += charWidth;
      lineWidthAtBreakIndex += charWidth;

      if (Config.breakat.contains(char)) {
        breakIndex = index;
        lineWidthAtBreakIndex = 0;
      }
      // if we exceeded the width, add a line break
      if (lineWidth >= width) {
        // if we didn't find a breakat, break at terminal width
        if (breakIndex == -1) {
          breakIndex = index;
          lineWidthAtBreakIndex = 0;
        }
        String subline = line.substring(lineStart, breakIndex);
        lines.add(Line(subline, start: start + lineStart, no: lines.length));

        lineStart = breakIndex;
        breakIndex = -1;
        lineWidth = lineWidthAtBreakIndex;
      }
    }
    // add the last part of the line
    if (lineStart < line.length) {
      String subline = line.substring(lineStart);
      lines.add(Line('$subline ', start: start + lineStart, no: lines.length));
    }
  }

  void charWrapLine(List<Line> lines, String line, int start, int width) {
    // if line is empty add an empty line
    if (line.isEmpty) {
      lines.add(Line(' ', start: start, no: lines.length));
      return;
    }
    // limit small width to avoid rendering issues
    width = math.max(width, 8);

    int index = 0;
    int lineStart = 0;
    int lineWidth = 0;

    for (String char in line.characters) {
      int charLength = char.length;
      int charWidth = char.charWidth;
      index += charLength;
      lineWidth += charWidth;

      // if we exceeded the width, add a line break
      if (lineWidth >= width) {
        String subline = line.substring(lineStart, index - charLength);
        lines.add(Line(subline, start: start + lineStart, no: lines.length));

        lineStart = index - charLength;
        lineWidth = charWidth;
      }
    }
    // add the last part of the line
    if (lineStart < line.length) {
      String subline = line.substring(lineStart);
      lines.add(Line('$subline ', start: start + lineStart, no: lines.length));
    }
  }
}
