import 'dart:math';

import 'file_buffer.dart';
import 'file_buffer_ext.dart';
import 'modes.dart';
import 'position.dart';
import 'utils.dart';

typedef Motion = Position Function(FileBuffer, Position);

Position motionCharNext(FileBuffer f, Position p) {
  return Position(
    y: p.y,
    x: clamp(p.x + 1, 0, f.lines[p.y].charLen - 1),
  );
}

Position motionCharPrev(FileBuffer f, Position p) {
  return Position(
    y: p.y,
    x: max(0, p.x - 1),
  );
}

Position motionCharUp(FileBuffer f, Position p) {
  final line = clamp(p.y - 1, 0, f.lines.length - 1);
  final char = clamp(p.x, 0, f.lines[line].charLen - 1);
  return Position(y: line, x: char);
}

Position motionCharDown(FileBuffer f, Position p) {
  final line = clamp(p.y + 1, 0, f.lines.length - 1);
  final char = clamp(p.x, 0, f.lines[line].charLen - 1);
  return Position(y: line, x: char);
}

Position motionFileStart(FileBuffer f, Position p) {
  return Position(y: 0, x: 0);
}

Position motionFileEnd(FileBuffer f, Position position) {
  return Position(
    x: f.lines.last.charLen,
    y: max(0, f.lines.length - 1),
  );
}

Position motionLineStart(FileBuffer f, Position p) {
  return Position(y: p.y, x: 0);
}

Position motionLineEnd(FileBuffer f, Position p) {
  return Position(y: p.y, x: max(0, f.lines[p.y].charLen - 1));
}

Position motionWordNext(FileBuffer f, Position p) {
  final start = f.byteIndexFromPosition(p);
  final matches = RegExp(r'\S+').allMatches(f.text.string, start);
  if (matches.isEmpty) return p;
  final match =
      matches.firstWhere((m) => m.start > start, orElse: () => matches.first);
  return f.positionFromByteIndex(match.start);
}

Position motionWordEnd(FileBuffer f, Position p) {
  final start = f.byteIndexFromPosition(p);
  final matches = RegExp(r'\S+').allMatches(f.text.string, start);
  if (matches.isEmpty) return p;
  final match =
      matches.firstWhere((m) => m.end - 1 > start, orElse: () => matches.first);
  return f.positionFromByteIndex(match.end - 1);
}

Position motionWordPrev(FileBuffer f, Position p) {
  final start = f.byteIndexFromPosition(p);
  final matches = RegExp(r'\S+').allMatches(f.text.string.substring(0, start));
  if (matches.isEmpty) return p;
  return f.positionFromByteIndex(matches.last.start);
}

// exit insert mode
Position motionEscape(FileBuffer f, Position p) {
  f.mode = Mode.normal;
  f.pendingAction = null;
  return p;
}

// find the next occurence of the given character on the current line
Position motionFindNextChar(FileBuffer f, Position p, String char) {
  final pnew = Position(x: p.x + 1, y: p.y);
  final start = f.byteIndexFromPosition(pnew);
  final match = char.allMatches(f.text.string, start).firstOrNull;
  if (match == null) return p;
  return f.positionFromByteIndex(match.start);
}

Position motionTillNextChar(FileBuffer f, Position p, String char) {
  final pnew = motionFindNextChar(f, p, char);
  pnew.x = max(pnew.x - 1, p.x);
  return pnew;
}

// find the previous occurence of the given character on the current line
Position motionFindPrevChar(FileBuffer f, Position p, String char) {
  final start = f.byteIndexFromPosition(p);
  final matches = char.allMatches(f.text.string.substring(0, start));
  if (matches.isEmpty) return p;
  final match = matches.last;
  return f.positionFromByteIndex(match.start);
}

Position motionTillPrevChar(FileBuffer f, Position p, String char) {
  final pnew = motionFindPrevChar(f, p, char);
  pnew.x = min(pnew.x + 1, p.x);
  return pnew;
}
