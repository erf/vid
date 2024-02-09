import 'package:characters/characters.dart';
import 'package:vid/config.dart';
import 'package:vid/string_ext.dart';

import 'keys.dart';
import 'file_buffer.dart';
import 'line.dart';
import 'terminal.dart';

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
  void createLines() {
    // ensure that the text ends with a newline
    ensureNewlineAtEnd();

    // split text into lines (remove last empty line)
    final textLines = text.split(Keys.newline)..removeLast();

    int width = Terminal.instance.width;

    // split text into lines with metadata used for cursor positioning etc.
    lines.clear();
    int pos = 0;
    for (int lineNo = 0; lineNo < textLines.length; lineNo++) {
      final String line = textLines[lineNo];
      switch (Config.wrapMode) {
        case WrapMode.none:
          lines.add(Line('$line ', lineNo: lineNo, byteStart: pos));
          break;
        case WrapMode.word:
          lines.addAll(_wordWrapLine(line, lineNo, pos, width));
          break;
        case WrapMode.char:
          // TODO
          break;
      }
      pos += line.length + 1;
    }
  }

  Iterable<Line> _wordWrapLine(String line, int lineNo, int pos, int width) {
    if (line.isEmpty) {
      return [
        Line(
          ' ',
          lineNo: lineNo,
          byteStart: pos,
        )
      ];
    }

    // iterate characters until the line is longer than the terminal width or
    // the end of the line is reached
    // if the line is shorter than the terminal width, return the line
    // if the line is longer than the terminal width, split the line at the last space
    // if there is no space, split the line at the terminal width
    // continue splitting the line at the last space until the end of the line is reached
    int index = 0; // index of whole line
    int lineRenderWidth = 0;
    int lastSpaceIndex = -1;
    List<Line> lines = [];
    while (line.isNotEmpty) {
      line.characters.takeWhile((String char) {
        if (char == ' ') {
          lastSpaceIndex = index;
        }
        index += char.length;
        lineRenderWidth += char.renderWidth;
        return lineRenderWidth <= width;
      });

      if (lineRenderWidth < width) {
        lines.add(Line(
          line,
          lineNo: lineNo,
          byteStart: pos,
        ));
        break;
      }

      if (lastSpaceIndex == -1) {
        lastSpaceIndex = width;
      }

      String lineString = line.substring(0, lastSpaceIndex);
      lines.add(Line(
        lineString,
        lineNo: lineNo,
        byteStart: pos,
      ));

      line = line.substring(lastSpaceIndex);
      lineNo++;
      pos += lastSpaceIndex;
      index = 0;
      lineRenderWidth = 0;
      lastSpaceIndex = -1;
    }

    return lines;
  }
}
