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

  // ensure that the text ends with a newline
  void ensureNewlineAtEnd() {
    if (!text.endsWith(Keys.newline)) {
      text += Keys.newline;
    }
  }

  // split text into lines
  void createLines(WrapMode wrapMode, int width, int height) {
    // ensure that the text ends with a newline
    ensureNewlineAtEnd();

    // split text into lines (remove last empty line)
    final textLines = text.split(Keys.newline)..removeLast();

    // split text into lines with metadata used for cursor positioning etc.
    lines.clear();
    int lineNo = 0;
    int start = 0;
    for (int i = 0; i < textLines.length; i++) {
      final String line = textLines[i];
      switch (wrapMode) {
        case WrapMode.none:
          lines.add(Line('$line ', no: i, start: start));
          break;
        case WrapMode.word:
          final newLines = _wordWrapLine(line, lineNo, start, width);
          lines.addAll(newLines);
          lineNo += newLines.length;
          break;
      }
      start += line.length + 1;
    }
  }

  Iterable<Line> _wordWrapLine(String line, int lineNo, int start, int width) {
    // if line is empty, return a line with a single space
    if (line.isEmpty) {
      return [Line(' ', no: lineNo, start: start)];
    }

    // limit very small width to avoid rendering issues
    width = math.max(width, 8);

    // split long line into lines
    List<Line> lines = [];

    while (line.isNotEmpty) {
      int index = 0;
      int breakIndex = -1;
      int lineWidth = 0;
      Characters lineCh = line.characters.takeWhile((String char) {
        index += char.length;
        if (Config.breakat.contains(char)) {
          breakIndex = index;
        }
        lineWidth += char.renderWidth;
        return lineWidth < width;
      });
      // if line is shorter than the terminal width, return the line
      if (lineWidth < width) {
        lines.add(Line('$line ', no: lineNo, start: start));
        break;
      }
      // if we didn't find a breakat, break at the eol / terminal width
      if (breakIndex == -1) {
        breakIndex = lineCh.string.length;
      }
      final String subLine = line.substring(0, breakIndex);
      lines.add(Line(subLine, no: lineNo, start: start));

      line = line.substring(breakIndex);
      lineNo++;
      start += breakIndex;
    }

    return lines;
  }
}
