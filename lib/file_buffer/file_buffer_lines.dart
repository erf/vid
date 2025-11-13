import 'dart:math' as math;

import 'package:characters/characters.dart';

import '../config.dart';
import '../editor.dart';
import '../keys.dart';
import '../line.dart';
import '../string_ext.dart';
import 'file_buffer.dart';

extension FileBufferLines on FileBuffer {
  // check if file is empty, only one line with empty string
  bool get empty => lines.length == 1 && lines.first.isEmpty;

  // split text into lines
  void createLines(Editor e, {WrapMode wrapMode = .none}) {
    // split text into lines (remove last empty line)
    final List<String> textLines = text.split(Keys.newline)..removeLast();

    // split text into lines with metadata used for cursor positioning etc.
    lines.clear();
    int start = 0;
    int width = e.terminal.width;
    for (int i = 0; i < textLines.length; i++) {
      String line = textLines[i];
      switch (wrapMode) {
        case .none:
          _noWrapLine(lines, line, start, width);
        case .char:
          _charWrapLine(lines, line, start, width, e.config);
        case .word:
          _wordWrapLine(lines, line, start, width, e.config);
      }
      start = lines.last.end;
    }
  }

  // split long line into smaller lines by character
  void _noWrapLine(List<Line> lines, String line, int start, int width) {
    lines.add(Line('$line ', start: start, no: lines.length));
  }

  // split long line into smaller lines by word
  void _wordWrapLine(
    List<Line> lines,
    String line,
    int start,
    int width,
    Config config,
  ) {
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

      int charWidth = char.charWidth(config.tabWidth);
      lineWidth += charWidth;
      lineWidthAtBreakIndex += charWidth;

      if (config.breakat.contains(char)) {
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

  void _charWrapLine(
    List<Line> lines,
    String line,
    int start,
    int width,
    Config config,
  ) {
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
      int charWidth = char.charWidth(config.tabWidth);
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
