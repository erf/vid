import 'dart:math';

import 'file_buffer.dart';
import 'file_buffer_text.dart';
import 'modes.dart';
import 'position.dart';
import 'utils.dart';

typedef Motion = Position Function(FileBuffer, Position);

Position motionCharNext(FileBuffer f, Position p) {
  return Position(
    l: p.l,
    c: min(p.c + 1, f.lines[p.l].charLen - 1),
  );
}

Position motionCharPrev(FileBuffer f, Position p) {
  return Position(
    l: p.l,
    c: max(0, p.c - 1),
  );
}

Position motionCharUp(FileBuffer f, Position p) {
  final line = max(0, p.l - 1);
  final char = clamp(p.c, 0, f.lines[line].charLen - 1);
  return Position(l: line, c: char);
}

Position motionCharDown(FileBuffer f, Position p) {
  final line = min(p.l + 1, f.lines.length - 1);
  final char = clamp(p.c, 0, f.lines[line].charLen - 1);
  return Position(l: line, c: char);
}

Position motionFileStart(FileBuffer f, Position p) {
  return Position(l: 0, c: 0);
}

Position motionFileEnd(FileBuffer f, Position position) {
  return Position(
    l: max(0, f.lines.length - 1),
    c: max(0, f.lines.last.charLen - 1),
  );
}

Position motionLineStart(FileBuffer f, Position p) {
  return Position(l: p.l, c: 0);
}

Position motionFirstNonBlank(FileBuffer f, Position p) {
  final firstNonBlank = f.lines[p.l].text.string.indexOf(RegExp(r'\S'));
  return Position(l: p.l, c: firstNonBlank == -1 ? 0 : firstNonBlank);
}

Position motionLineEnd(FileBuffer f, Position p) {
  return Position(l: p.l, c: f.lines[p.l].charLen - 1);
}

Position motionWordNext(FileBuffer f, Position p) {
  final start = f.byteIndexFromPosition(p);
  final matches = RegExp(r'\w+').allMatches(f.text, start);
  if (matches.isEmpty) return p;
  final match =
      matches.firstWhere((m) => m.start > start, orElse: () => matches.first);
  return f.positionFromByteIndex(match.start);
}

Position motionSameWordNext(FileBuffer f, Position p) {
  final start = f.byteIndexFromPosition(p);
  final matches = RegExp(r'\w+').allMatches(f.text);
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

Position motionSameWordPrev(FileBuffer f, Position p) {
  final start = f.byteIndexFromPosition(p);
  final matches = RegExp(r'\w+').allMatches(f.text);
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

Position motionWordEnd(FileBuffer f, Position p) {
  final start = f.byteIndexFromPosition(p);
  final matches = RegExp(r'\w+').allMatches(f.text, start);
  if (matches.isEmpty) return p;
  final match =
      matches.firstWhere((m) => m.end - 1 > start, orElse: () => matches.first);
  return f.positionFromByteIndex(match.end);
}

Position motionWordPrev(FileBuffer f, Position p) {
  final start = f.byteIndexFromPosition(p);
  final matches = RegExp(r'\w+').allMatches(f.text.substring(0, start));
  if (matches.isEmpty) return p;
  return f.positionFromByteIndex(matches.last.start);
}

Position motionWordEndPrev(FileBuffer f, Position p) {
  final start = f.byteIndexFromPosition(p);
  final matches = RegExp(r'\w+').allMatches(f.text);
  if (matches.isEmpty) return p;
  final match =
      matches.lastWhere((e) => e.end < start, orElse: () => matches.last);
  return f.positionFromByteIndex(match.end - 1);
}

// exit insert mode
Position motionEscape(FileBuffer f, Position p) {
  f.mode = Mode.normal;
  f.pendingAction = null;
  return p;
}

// find the next occurence of the given character on the current line
Position motionFindNextChar(FileBuffer f, Position p, String char) {
  final pnew = Position(c: p.c + 1, l: p.l);
  final start = f.byteIndexFromPosition(pnew);
  final match = char.allMatches(f.text, start).firstOrNull;
  if (match == null) return p;
  return f.positionFromByteIndex(match.start);
}

Position motionTillNextChar(FileBuffer f, Position p, String char) {
  final pnew = motionFindNextChar(f, p, char);
  pnew.c = max(pnew.c - 1, p.c);
  return pnew;
}

// find the previous occurence of the given character on the current line
Position motionFindPrevChar(FileBuffer f, Position p, String char) {
  final start = f.byteIndexFromPosition(p);
  final matches = char.allMatches(f.text.substring(0, start));
  if (matches.isEmpty) return p;
  final match = matches.last;
  return f.positionFromByteIndex(match.start);
}

Position motionTillPrevChar(FileBuffer f, Position p, String char) {
  final pnew = motionFindPrevChar(f, p, char);
  pnew.c = min(pnew.c + 1, p.c);
  return pnew;
}
