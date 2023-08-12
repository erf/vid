import 'dart:math';

import 'file_buffer.dart';
import 'file_buffer_text.dart';
import 'modes.dart';
import 'position.dart';
import 'utils.dart';

class Motions {
  static final wordRegex = RegExp(r'(\w+|[^\w\s]+)');

  static Position charNext(FileBuffer f, Position p) {
    return Position(
      l: p.l,
      c: min(p.c + 1, f.lines[p.l].charLen - 1),
    );
  }

  static Position charPrev(FileBuffer f, Position p) {
    return Position(
      l: p.l,
      c: max(0, p.c - 1),
    );
  }

  static Position charUp(FileBuffer f, Position p) {
    final line = max(0, p.l - 1);
    final char = clamp(p.c, 0, f.lines[line].charLen - 1);
    return Position(l: line, c: char);
  }

  static Position charDown(FileBuffer f, Position p) {
    final line = min(p.l + 1, f.lines.length - 1);
    final char = clamp(p.c, 0, f.lines[line].charLen - 1);
    return Position(l: line, c: char);
  }

  static Position fileStart(FileBuffer f, Position p) {
    return Position(l: 0, c: 0);
  }

  static Position fileEnd(FileBuffer f, Position position) {
    return Position(
      l: max(0, f.lines.length - 1),
      c: max(0, f.lines.last.charLen - 1),
    );
  }

  static Position lineStart(FileBuffer f, Position p) {
    return Position(l: p.l, c: 0);
  }

  static Position firstNonBlank(FileBuffer f, Position p) {
    final firstNonBlank = f.lines[p.l].text.string.indexOf(RegExp(r'\S'));
    return Position(l: p.l, c: firstNonBlank == -1 ? 0 : firstNonBlank);
  }

  static Position lineEnd(FileBuffer f, Position p) {
    return Position(l: p.l, c: f.lines[p.l].charLen - 1);
  }

  static Position wordNext(FileBuffer f, Position p) {
    final start = f.byteIndexFromPosition(p);
    final matches = wordRegex.allMatches(f.text, start);
    if (matches.isEmpty) return p;
    final match =
        matches.firstWhere((m) => m.start > start, orElse: () => matches.first);
    return f.positionFromByteIndex(match.start);
  }

  static Position sameWordNext(FileBuffer f, Position p) {
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

  static Position sameWordPrev(FileBuffer f, Position p) {
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

  static Position wordEnd(FileBuffer f, Position p) {
    final start = f.byteIndexFromPosition(p);
    final matches = wordRegex.allMatches(f.text, start);
    if (matches.isEmpty) return p;
    final match = matches.firstWhere((m) => m.end - 1 > start,
        orElse: () => matches.first);
    return f.positionFromByteIndex(match.end);
  }

  static Position wordPrev(FileBuffer f, Position p) {
    final start = f.byteIndexFromPosition(p);
    final matches = wordRegex.allMatches(f.text.substring(0, start));
    if (matches.isEmpty) return p;
    return f.positionFromByteIndex(matches.last.start);
  }

  static Position wordEndPrev(FileBuffer f, Position p) {
    final start = f.byteIndexFromPosition(p);
    final matches = wordRegex.allMatches(f.text);
    if (matches.isEmpty) return p;
    final match =
        matches.lastWhere((e) => e.end < start, orElse: () => matches.last);
    return f.positionFromByteIndex(match.end - 1);
  }

// exit insert mode
  static Position escape(FileBuffer f, Position p) {
    f.mode = Mode.normal;
    f.operator = null;
    return p;
  }
}
