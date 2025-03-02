import 'dart:math';

import 'package:characters/characters.dart';

import '../characters_render.dart';
import '../file_buffer/file_buffer.dart';
import '../file_buffer/file_buffer_index.dart';
import '../position.dart';
import '../regex.dart';
import '../string_ext.dart';
import '../utils.dart';

class Motions {
  static Position moveLine(FileBuffer f, Position p, int nextLine) {
    int curlen = f.lines[p.l].text.characters.renderLength(p.c);
    int nextlen = 0;
    Characters chars = f.lines[nextLine].text.characters.takeWhile((c) {
      nextlen += c.charWidth;
      return nextlen <= curlen;
    });
    int char = clamp(chars.length, 0, f.lines[nextLine].charLen - 1);
    return Position(l: nextLine, c: char);
  }

  // find the first match after the cursor position
  static Position regexNext(
    FileBuffer f,
    Position p,
    RegExp pattern, {
    int skip = 0,
  }) {
    int start = f.indexFromPosition(p);
    final matches = pattern.allMatches(f.text, start + skip);
    if (matches.isEmpty) return p;
    final m = matches.firstWhere(
      (ma) => ma.start > start,
      orElse: () => matches.first,
    );
    return f.positionFromIndex(m.start == start ? m.end : m.start);
  }

  // find the first match before the cursor position
  static Position regexPrev(FileBuffer f, Position p, RegExp pattern) {
    final int start = f.indexFromPosition(p);
    final matches = pattern.allMatches(f.text.substring(0, start));
    if (matches.isEmpty) return p;
    return f.positionFromIndex(matches.last.start);
  }

  static Position matchCursorWord(
    FileBuffer f,
    Position p, {
    required bool forward,
  }) {
    // find word on cursor
    int start = f.indexFromPosition(p);
    final matches = Regex.word.allMatches(f.text);
    if (matches.isEmpty) return p;
    Match? match = matches.firstWhere(
      (m) => start < m.end,
      orElse: () => matches.first,
    );
    // we are not on the word
    if (start < match.start || start >= match.end) {
      return f.positionFromIndex(match.start);
    }
    // we are on the word and we want to find the next same word
    final String wordToMatch = f.text.substring(match.start, match.end);
    final RegExp pattern = RegExp(RegExp.escape(wordToMatch));
    // find the next same word
    final int index =
        forward
            ? f.text.indexOf(pattern, match.end)
            : f.text.lastIndexOf(pattern, max(0, match.start - 1));
    return index == -1
        ? f.positionFromIndex(match.start)
        : f.positionFromIndex(index);
  }
}
