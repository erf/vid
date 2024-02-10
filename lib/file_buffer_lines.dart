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
    int lineNo = 0;
    for (int i = 0; i < textLines.length; i++) {
      final String line = textLines[i];
      switch (Config.wrapMode) {
        case WrapMode.none:
          lines.add(Line('$line ', no: i, start: pos));
          break;
        case WrapMode.word:
          final newLines = _wordWrapLine(line, lineNo, pos, width);
          lines.addAll(newLines);
          lineNo += newLines.length;
          break;
        case WrapMode.char:
          // TODO
          break;
      }
      pos += line.length + 1;
    }
  }

  // iterate characters until the line is longer than the terminal width or the
  // end of the line is reached. if the line is shorter than the terminal width,
  // return the line. if the line is longer than the terminal width, split the
  // line at the last space or at the terminal width. continue splitting the
  // line until the end of the whole line is reached
  Iterable<Line> _wordWrapLine(String line, int lineNo, int pos, int width) {
    // if line is empty, return a line with a single space
    if (line.isEmpty) {
      return [Line(' ', no: lineNo, start: pos)];
    }
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
        lines.add(Line('$line ', no: lineNo, start: pos));
        break;
      }

      if (lastSpaceIndex == -1) {
        lastSpaceIndex = width;
      }

      String subLine = line.substring(0, lastSpaceIndex);
      lines.add(Line(subLine, no: lineNo, start: pos));

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
