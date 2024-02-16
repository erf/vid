import 'dart:math';

import 'package:characters/characters.dart';

import 'characters_render.dart';
import 'file_buffer.dart';
import 'file_buffer_text.dart';
import 'position.dart';
import 'regex.dart';
import 'string_ext.dart';
import 'utils.dart';

class Motions {
  static Position charNext(FileBuffer f, Position p, [bool incl = false]) {
    int c = p.c + 1;
    if (c < f.lines[p.l].charLen) {
      return Position(l: p.l, c: c);
    }
    int l = p.l + 1;
    if (l >= f.lines.length) {
      return p;
    }
    return Position(l: l, c: 0);
  }

  static Position charPrev(FileBuffer f, Position p, [bool incl = false]) {
    int c = p.c - 1;
    if (c >= 0) {
      return Position(l: p.l, c: c);
    }
    int l = p.l - 1;
    if (l < 0) {
      return p;
    }
    return Position(l: l, c: f.lines[l].charLen - 1);
  }

  static Position moveLine(FileBuffer f, Position p, int nextLine) {
    int curlen = f.lines[p.l].str.characters.renderLength(p.c);
    int nextlen = 0;
    Characters chars = f.lines[nextLine].str.characters.takeWhile((c) {
      nextlen += c.renderWidth;
      return nextlen <= curlen;
    });
    int char = clamp(chars.length, 0, f.lines[nextLine].charLen - 1);
    return Position(l: nextLine, c: char);
  }

  static Position lineUp(FileBuffer f, Position p, [bool incl = false]) {
    if (p.l == 0) return p;
    return moveLine(f, p, p.l - 1);
  }

  static Position lineDown(FileBuffer f, Position p, [bool incl = false]) {
    if (p.l == f.lines.length - 1) return p;
    return moveLine(f, p, p.l + 1);
  }

  static Position fileStart(FileBuffer f, Position p, [bool incl = false]) {
    int line = f.editEvent.count == null
        ? 0
        : clamp(f.editEvent.count! - 1, 0, f.lines.length - 1);
    return Motions.firstNonBlank(f, Position(l: line, c: 0), incl);
  }

  static Position fileEnd(FileBuffer f, Position p, [bool incl = false]) {
    int line = f.editEvent.count == null
        ? max(0, f.lines.length - 1)
        : clamp(f.editEvent.count! - 1, 0, f.lines.length - 1);
    return Motions.firstNonBlank(f, Position(l: line, c: 0), incl);
  }

  static Position lineStart(FileBuffer f, Position p, [bool incl = false]) {
    return Position(l: p.l, c: 0);
  }

  static Position lineEnd(FileBuffer f, Position p, [bool incl = false]) {
    if (incl) {
      if (p.l + 1 < f.lines.length) {
        return Position(l: p.l + 1, c: 0);
      } else {
        return Position(l: p.l, c: f.lines[p.l].charLen);
      }
    }
    return Position(l: p.l, c: f.lines[p.l].charLen - 1);
  }

  // find the first non blank character on the line
  static Position firstNonBlank(FileBuffer f, Position p, [bool incl = false]) {
    final firstNonBlank = f.lines[p.l].str.indexOf(Regex.nonSpace);
    return Position(l: p.l, c: firstNonBlank == -1 ? 0 : firstNonBlank);
  }

  // find the next word from the cursor position
  static Position wordNext(FileBuffer f, Position p, [bool incl = false]) {
    return regexNext(f, p, Regex.word);
  }

  // find the next WORD from the cursor position
  static Position wordCapNext(FileBuffer f, Position p, [bool incl = false]) {
    return regexNext(f, p, Regex.wordCap);
  }

  // find the prev word from the cursor position
  static Position wordPrev(FileBuffer f, Position p, [bool incl = false]) {
    return regexPrev(f, p, Regex.word);
  }

  // find the prev WORD from the cursor position
  static Position wordCapPrev(FileBuffer f, Position p, [bool incl = false]) {
    return regexPrev(f, p, Regex.wordCap);
  }

  // find the next same word from the cursor position
  static Position sameWordNext(FileBuffer f, Position p, [bool incl = false]) {
    return matchCursorWord(f, p, true);
  }

  // find the prev same word from the cursor position
  static Position sameWordPrev(FileBuffer f, Position p, [bool incl = false]) {
    return matchCursorWord(f, p, false);
  }

  // find the first match after the cursor position
  static Position regexNext(FileBuffer f, Position p, RegExp regExp) {
    int start = f.byteIndexFromPosition(p);
    final matches = regExp.allMatches(f.text, start);
    if (matches.isEmpty) return p;
    final m = matches.firstWhere((ma) => ma.start > start,
        orElse: () => matches.first);
    return f.positionFromByteIndex(m.start == start ? m.end : m.start);
  }

  // find the first match before the cursor position
  static Position regexPrev(FileBuffer f, Position p, RegExp regex) {
    final start = f.byteIndexFromPosition(p);
    final matches = regex.allMatches(f.text.substring(0, start));
    if (matches.isEmpty) return p;
    return f.positionFromByteIndex(matches.last.start);
  }

  // find the end of the word from the cursor position
  static Position wordEnd(FileBuffer f, Position p, [bool incl = false]) {
    final start = f.byteIndexFromPosition(p);
    final matches = Regex.word.allMatches(f.text, start);
    if (matches.isEmpty) return p;
    final match = matches.firstWhere((m) => start < m.end - 1,
        orElse: () => matches.first);
    return f.positionFromByteIndex(match.end - (incl ? 0 : 1));
  }

  // find the end of the prev word from the cursor position
  static Position wordEndPrev(FileBuffer f, Position p, [bool incl = false]) {
    final start = f.byteIndexFromPosition(p);
    final matches = Regex.word.allMatches(f.text);
    if (matches.isEmpty) return p;
    final match =
        matches.lastWhere((m) => start > m.end, orElse: () => matches.last);
    return f.positionFromByteIndex(match.end - 1);
  }

  static Position matchCursorWord(FileBuffer f, Position p, bool forward) {
    // find word on cursor
    int start = f.byteIndexFromPosition(p);
    final matches = Regex.word.allMatches(f.text);
    if (matches.isEmpty) return p;
    Match? match =
        matches.firstWhere((m) => start < m.end, orElse: () => matches.first);
    // we are not on the word
    if (start < match.start || start >= match.end) {
      return f.positionFromByteIndex(match.start);
    }
    // we are on the word and we want to find the next same word
    final wordToMatch = f.text.substring(match.start, match.end);
    final regExp = RegExp(RegExp.escape(wordToMatch));
    // find the next same word
    final index = forward
        ? f.text.indexOf(regExp, match.end)
        : f.text.lastIndexOf(regExp, max(0, match.start - 1));
    return index == -1
        ? f.positionFromByteIndex(match.start)
        : f.positionFromByteIndex(index);
  }

  // "A paragraph begins after each empty line" - vim
  // "A paragraph also ends at the end of the file." - copilot
  static Position paragraphNext(FileBuffer f, Position p, [bool incl = false]) {
    return regexNext(f, p, Regex.paragraph);
  }

  static Position paragraphPrev(FileBuffer f, Position p, [bool incl = false]) {
    return regexPrev(f, p, Regex.paragraphPrev);
  }

  // "defined as ending at a '.', '!' or '?' followed by either the
  // end of a line, or by a space or tab" - vim
  static Position sentenceNext(FileBuffer f, Position p, [bool incl = false]) {
    return regexNext(f, p, Regex.sentence);
  }

  static Position sentencePrev(FileBuffer f, Position p, [bool incl = false]) {
    return regexPrev(f, p, Regex.sentence);
  }
}
