import 'dart:math';

import 'action.dart';
import 'file_buffer.dart';
import 'file_buffer_text.dart';
import 'modes.dart';
import 'position.dart';
import 'utils.dart';

class Motions {
  static final wordRegex = RegExp(r'(\w+|[^\w\s]+|(?<=\n)\n)');

  static Position charNext(FileBuffer f, Position p, [bool incl = false]) {
    int c = p.c + 1;
    if (c < f.lines[p.l].charLen) {
      return Position(l: p.l, c: c);
    } else {
      int l = p.l + 1;
      if (l >= f.lines.length) {
        return p;
      }
      return Position(l: l, c: 0);
    }
  }

  static Position charPrev(FileBuffer f, Position p, [bool incl = false]) {
    int c = p.c - 1;
    if (c >= 0) {
      return Position(l: p.l, c: c);
    } else {
      int l = p.l - 1;
      if (l < 0) {
        return p;
      }
      return Position(l: l, c: f.lines[l].charLen - 1);
    }
  }

  static Position lineUp(FileBuffer f, Position p, [bool incl = false]) {
    final line = max(0, p.l - 1);
    final char = clamp(p.c, 0, f.lines[line].charLen - 1);
    return Position(l: line, c: char);
  }

  static Position lineDown(FileBuffer f, Position p, [bool incl = false]) {
    final line = min(p.l + 1, f.lines.length - 1);
    final char = clamp(p.c, 0, f.lines[line].charLen - 1);
    return Position(l: line, c: char);
  }

  static Position fileStart(FileBuffer f, Position p, [bool incl = false]) {
    int line = f.action.count == null
        ? 0
        : clamp(f.action.count! - 1, 0, f.lines.length - 1);
    return Motions.firstNonBlank(f, Position(l: line, c: 0), incl);
  }

  static Position fileEnd(FileBuffer f, Position p, [bool incl = false]) {
    int line = f.action.count == null
        ? max(0, f.lines.length - 1)
        : clamp(f.action.count! - 1, 0, f.lines.length - 1);
    return Motions.firstNonBlank(f, Position(l: line, c: 0), incl);
  }

  static Position lineStart(FileBuffer f, Position p, [bool incl = false]) {
    return Position(l: p.l, c: 0);
  }

  static Position lineEndExcl(FileBuffer f, Position p, [bool incl = false]) {
    return Position(l: p.l, c: f.lines[p.l].charLen - 1);
  }

  static Position lineEndIncl(FileBuffer f, Position p, [bool incl = true]) {
    return p.l + 1 < f.lines.length
        ? Position(l: p.l + 1, c: 0)
        : Position(l: p.l, c: f.lines[p.l].charLen);
  }

  static Position firstNonBlank(FileBuffer f, Position p, [bool incl = false]) {
    final firstNonBlank = f.lines[p.l].str.indexOf(RegExp(r'\S'));
    return Position(l: p.l, c: firstNonBlank == -1 ? 0 : firstNonBlank);
  }

  static Position wordNext(FileBuffer f, Position p, [bool incl = false]) {
    final start = f.byteIndexFromPosition(p);
    final matches = wordRegex.allMatches(f.text, start);
    if (matches.isEmpty) return p;
    final match =
        matches.firstWhere((m) => m.start > start, orElse: () => matches.first);
    return f.positionFromByteIndex(match.start);
  }

  static Position sameWordNext(FileBuffer f, Position p, [bool incl = false]) {
    final start = f.byteIndexFromPosition(p);
    final matches = wordRegex.allMatches(f.text);
    if (matches.isEmpty) return p;
    final match =
        matches.firstWhere((m) => start < m.end, orElse: () => matches.first);
    // we are not on the word
    if (match.start > start || match.end <= start) {
      return f.positionFromByteIndex(match.start);
    }
    // we are on the word and we want to find the next same word
    final wordToMatch = f.text.substring(match.start, match.end);
    final index = f.text.indexOf(RegExp('\\b$wordToMatch\\b'), match.end);
    return index == -1
        ? f.positionFromByteIndex(match.start)
        : f.positionFromByteIndex(index);
  }

  static Position sameWordPrev(FileBuffer f, Position p, [bool incl = false]) {
    final start = f.byteIndexFromPosition(p);
    final matches = wordRegex.allMatches(f.text);
    if (matches.isEmpty) return p;
    final match =
        matches.firstWhere((e) => e.end >= start, orElse: () => matches.first);
    // we are not on the word
    if (start < match.start || start >= match.end) {
      return f.positionFromByteIndex(match.start);
    }
    // we are on the word and we want to find the prev same word
    final wordToMatch = f.text.substring(match.start, match.end);
    final index = f.text
        .substring(0, match.start)
        .lastIndexOf(RegExp('\\b$wordToMatch\\b'));
    return index == -1
        ? f.positionFromByteIndex(match.start)
        : f.positionFromByteIndex(index);
  }

  static Position wordEnd(FileBuffer f, Position p, [bool incl = false]) {
    final start = f.byteIndexFromPosition(p);
    final matches = wordRegex.allMatches(f.text, start);
    if (matches.isEmpty) return p;
    final match = matches.firstWhere((m) => m.end - 1 > start,
        orElse: () => matches.first);
    return f.positionFromByteIndex(match.end - (incl ? 0 : 1));
  }

  static Position wordPrev(FileBuffer f, Position p, [bool incl = false]) {
    final start = f.byteIndexFromPosition(p);
    final matches = wordRegex.allMatches(f.text.substring(0, start));
    if (matches.isEmpty) return p;
    return f.positionFromByteIndex(matches.last.start);
  }

  static Position wordEndPrev(FileBuffer f, Position p, [bool incl = false]) {
    final start = f.byteIndexFromPosition(p);
    final matches = wordRegex.allMatches(f.text);
    if (matches.isEmpty) return p;
    final match =
        matches.lastWhere((e) => e.end < start, orElse: () => matches.last);
    return f.positionFromByteIndex(match.end - 1);
  }

  static Position escape(FileBuffer f, Position p, [bool incl = false]) {
    f.mode = Mode.normal;
    f.action = Action();
    return p;
  }
}
