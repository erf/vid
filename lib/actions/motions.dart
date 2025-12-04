import 'dart:math';

import 'package:characters/characters.dart';
import 'package:vid/editor.dart';

import '../characters_render.dart';
import '../file_buffer/file_buffer.dart';
import '../file_buffer/file_buffer_nav.dart';
import '../regex.dart';
import '../string_ext.dart';
import '../utils.dart';

class Motions {
  /// Move to a different line, maintaining approximate visual column position
  static int moveLine(Editor e, FileBuffer f, int offset, int targetLineNum) {
    // Get current visual column position
    int lineStartOff = f.lineStart(offset);
    String beforeCursor = f.text.substring(lineStartOff, offset);
    int curVisualCol = beforeCursor.characters.renderLength(
      beforeCursor.characters.length,
      e.config.tabWidth,
    );

    // Get target line
    int targetLineStart = f.offsetOfLine(targetLineNum);
    int targetLineEnd = f.lineEnd(targetLineStart);
    String targetLineText = f.text.substring(targetLineStart, targetLineEnd);

    // Find position in target line with similar visual column
    int nextlen = 0;
    Characters chars = targetLineText.characters.takeWhile((c) {
      nextlen += c.charWidth(e.config.tabWidth);
      return nextlen <= curVisualCol;
    });

    // Clamp to valid position in target line
    int targetCharLen = targetLineText.characters.length;
    int charIndex = clamp(chars.length, 0, max(0, targetCharLen - 1));

    // Convert char index to byte offset
    return targetLineStart +
        targetLineText.characters.take(charIndex).string.length;
  }

  /// Find the first match after the given byte offset
  static int regexNext(
    FileBuffer f,
    int offset,
    RegExp pattern, {
    int skip = 0,
  }) {
    final matches = pattern.allMatches(f.text, offset + skip);
    if (matches.isEmpty) return offset;
    final m = matches.firstWhere(
      (ma) => ma.start > offset,
      orElse: () => matches.first,
    );
    return m.start == offset ? m.end : m.start;
  }

  /// Find the first match before the given byte offset
  static int regexPrev(FileBuffer f, int offset, RegExp pattern) {
    final matches = pattern.allMatches(f.text.substring(0, offset));
    if (matches.isEmpty) return offset;
    return matches.last.start;
  }

  /// Find next/prev occurrence of the word under cursor
  static int matchCursorWord(
    FileBuffer f,
    int offset, {
    required bool forward,
  }) {
    // Find word on cursor
    final matches = Regex.word.allMatches(f.text);
    if (matches.isEmpty) return offset;
    Match? match = matches.firstWhere(
      (m) => offset < m.end,
      orElse: () => matches.first,
    );
    // We are not on the word
    if (offset < match.start || offset >= match.end) {
      return match.start;
    }
    // We are on the word and we want to find the next same word
    final wordToMatch = f.text.substring(match.start, match.end);
    final pattern = RegExp(RegExp.escape(wordToMatch));
    // Find the next same word
    final int index = forward
        ? f.text.indexOf(pattern, match.end)
        : f.text.lastIndexOf(pattern, max(0, match.start - 1));
    return index == -1 ? match.start : index;
  }
}
